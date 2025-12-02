import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'logger.dart';

/// Login service for managing user's Nostr authentication credentials
/// Only stores the private key - public key is derived as needed
class LoginService {
  static const _storage = FlutterSecureStorage();
  static const String _nostrPrivateKeyKey = 'nostr_private_key';

  static KeyPair? _cachedKeyPair;

  // Regular constructor - Riverpod manages the singleton behavior
  LoginService();

  /// Generate a new Nostr key pair and store only the private key securely
  Future<KeyPair> generateAndStoreNostrKey() async {
    Log.info('Generating and storing new Nostr key pair');
    final keyPair = Bip340.generatePrivateKey();

    // Only store the private key - public key can be derived
    await _storage.write(key: _nostrPrivateKeyKey, value: keyPair.privateKey);

    _cachedKeyPair = keyPair;
    Log.info(
      'Generated new Nostr key pair with public key: ${keyPair.publicKeyBech32}',
    );
    return keyPair;
  }

  /// Get the stored Nostr key pair, deriving public key from private key
  Future<KeyPair?> getStoredNostrKey() async {
    if (_cachedKeyPair != null) {
      return _cachedKeyPair;
    }

    try {
      final privateKey = await _storage.read(key: _nostrPrivateKeyKey);

      if (privateKey != null) {
        // Derive public key from private key
        final publicKey = Bip340.getPublicKey(privateKey);

        // Create full KeyPair with derived public key
        // Convert hex keys to bech32 format using NDK helpers
        final privateKeyBech32 = Helpers.encodeBech32(privateKey, 'nsec');
        final publicKeyBech32 = Helpers.encodeBech32(publicKey, 'npub');

        _cachedKeyPair = KeyPair(
          privateKey,
          publicKey,
          privateKeyBech32,
          publicKeyBech32,
        );
        Log.info(
          'Successfully loaded Nostr key pair from secure storage: $publicKey',
        );
        return _cachedKeyPair;
      } else {
        Log.error('No private key found in secure storage');
      }
    } catch (e) {
      Log.error('Error reading stored key', e);
    }

    return null;
  }

  /// Initialize key (generate if doesn't exist, or load existing)
  Future<KeyPair> initializeKey() async {
    final existingKey = await getStoredNostrKey();
    if (existingKey != null) {
      return existingKey;
    }

    // Generate new key if none exists
    return await generateAndStoreNostrKey();
  }

  /// Get the current user's public key
  /// Returns null if no key has been initialized
  Future<String?> getCurrentPublicKey() async {
    final keyPair = await getStoredNostrKey();
    return keyPair?.publicKey;
  }

  /// Get the current user's public key in bech32 format (npub)
  /// Returns null if no key has been initialized
  Future<String?> getCurrentPublicKeyBech32() async {
    final keyPair = await getStoredNostrKey();
    return keyPair?.publicKeyBech32;
  }

  /// Encrypt text using NIP-44 (self-encryption)
  Future<String> encryptText(String plaintext) async {
    final keyPair = await getStoredNostrKey();
    if (keyPair?.privateKey == null || keyPair?.publicKey == null) {
      throw Exception('No key pair available for encryption');
    }

    // Use NIP-44 to encrypt to ourselves (same key for sender and recipient)
    return await Nip44.encryptMessage(
      plaintext,
      keyPair!.privateKey!,
      keyPair.publicKey,
    );
  }

  /// Decrypt text using NIP-44 (self-decryption)
  Future<String> decryptText(String encryptedText) async {
    final keyPair = await getStoredNostrKey();
    if (keyPair?.privateKey == null || keyPair?.publicKey == null) {
      throw Exception('No key pair available for decryption');
    }

    // Use NIP-44 to decrypt from ourselves (same key for sender and recipient)
    return await Nip44.decryptMessage(
      encryptedText,
      keyPair!.privateKey!,
      keyPair.publicKey,
    );
  }

  /// Clear stored keys (for testing or reset purposes)
  Future<void> clearStoredKeys() async {
    await _storage.delete(key: _nostrPrivateKeyKey);
    _cachedKeyPair = null;
  }

  /// Test-only helper to reset the in-memory cache without touching storage
  @visibleForTesting
  void resetCacheForTest() {
    _cachedKeyPair = null;
  }

  /// Convert bech32 npub to hex public key
  String? npubToHex(String npub) {
    try {
      final decoded = Helpers.decodeBech32(npub);
      return decoded[0]; // First element is the hex key
    } catch (e) {
      Log.error('Error converting npub to hex', e);
      return null;
    }
  }

  /// Encrypt text for a specific recipient using NIP-44
  Future<String> encryptForRecipient({
    required String plaintext,
    required String recipientPubkey, // Expects hex public key
  }) async {
    final keyPair = await getStoredNostrKey();
    if (keyPair?.privateKey == null || keyPair?.publicKey == null) {
      throw Exception('No key pair available for encryption');
    }

    // Use NIP-44 to encrypt to the recipient
    return await Nip44.encryptMessage(
      plaintext,
      keyPair!.privateKey!,
      recipientPubkey, // Already in hex format
    );
  }

  /// Decrypt text from a specific sender using NIP-44
  Future<String> decryptFromSender({
    required String encryptedText,
    required String senderPubkey, // Expects hex public key
  }) async {
    final keyPair = await getStoredNostrKey();
    if (keyPair?.privateKey == null || keyPair?.publicKey == null) {
      throw Exception('No key pair available for decryption');
    }

    // Use NIP-44 to decrypt from the sender
    return await Nip44.decryptMessage(
      encryptedText,
      keyPair!.privateKey!,
      senderPubkey, // Already in hex format
    );
  }

  /// Import key from nsec (bech32 format)
  /// Decodes the bech32 nsec string to hex, validates it, and stores it
  /// Returns the KeyPair with both hex and bech32 formats
  Future<KeyPair> importNsecKey(String nsec) async {
    Log.info('Importing key from nsec');

    try {
      // Decode bech32 to get hex private key
      final decoded = Helpers.decodeBech32(nsec);
      if (decoded.isEmpty) {
        throw Exception('Failed to decode nsec: invalid bech32 format');
      }

      final hexPrivkey = decoded[0]; // First element is the hex key
      final prefix = decoded.length > 1 ? decoded[1] : null;

      // Validate that the prefix is 'nsec'
      if (prefix != 'nsec') {
        throw Exception('Invalid key type: expected nsec, got $prefix');
      }

      // Validate hex format (64 characters)
      if (hexPrivkey.length != 64) {
        throw Exception('Invalid private key length: expected 64 characters, got ${hexPrivkey.length}');
      }

      // Store the hex private key
      await _storage.write(key: _nostrPrivateKeyKey, value: hexPrivkey);

      // Derive public key from private key
      final publicKey = Bip340.getPublicKey(hexPrivkey);

      // Create bech32 formats
      final privateKeyBech32 = Helpers.encodeBech32(hexPrivkey, 'nsec');
      final publicKeyBech32 = Helpers.encodeBech32(publicKey, 'npub');

      _cachedKeyPair = KeyPair(hexPrivkey, publicKey, privateKeyBech32, publicKeyBech32);
      Log.info('Successfully imported nsec key with public key: $publicKeyBech32');
      return _cachedKeyPair!;
    } catch (e) {
      Log.error('Error importing nsec key', e);
      rethrow;
    }
  }

  /// Import key from hex private key
  /// Validates the hex format and stores it
  /// Returns the KeyPair with both hex and bech32 formats
  Future<KeyPair> importHexPrivateKey(String hexPrivkey) async {
    Log.info('Importing key from hex private key');

    try {
      // Validate hex format (64 characters, valid hex)
      if (hexPrivkey.length != 64) {
        throw Exception('Invalid private key length: expected 64 characters, got ${hexPrivkey.length}');
      }

      // Validate that it's valid hex
      final hexRegex = RegExp(r'^[0-9a-fA-F]{64}$');
      if (!hexRegex.hasMatch(hexPrivkey)) {
        throw Exception('Invalid hex format: must be 64 hexadecimal characters');
      }

      // Store the hex private key
      await _storage.write(key: _nostrPrivateKeyKey, value: hexPrivkey.toLowerCase());

      // Derive public key from private key
      final publicKey = Bip340.getPublicKey(hexPrivkey);

      // Create bech32 formats
      final privateKeyBech32 = Helpers.encodeBech32(hexPrivkey, 'nsec');
      final publicKeyBech32 = Helpers.encodeBech32(publicKey, 'npub');

      _cachedKeyPair = KeyPair(hexPrivkey.toLowerCase(), publicKey, privateKeyBech32, publicKeyBech32);
      Log.info('Successfully imported hex private key with public key: $publicKeyBech32');
      return _cachedKeyPair!;
    } catch (e) {
      Log.error('Error importing hex private key', e);
      rethrow;
    }
  }

  /// Placeholder for bunker URL login (NIP-46)
  /// Currently not supported by NDK 0.5.1
  /// Throws UnimplementedError
  Future<KeyPair?> loginWithBunker(String bunkerUrl) async {
    Log.info('Attempted bunker login with URL: $bunkerUrl');
    throw UnimplementedError(
      'Bunker URL login (NIP-46) is not yet supported. '
      'Please use nsec or hex private key instead.',
    );
  }
}
