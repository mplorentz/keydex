import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'logger.dart';

/// Key management service for storing Nostr keys securely
/// Only stores the private key - public key is derived as needed
class KeyService {
  static const _storage = FlutterSecureStorage();
  static const String _nostrPrivateKeyKey = 'nostr_private_key';

  static KeyPair? _cachedKeyPair;

  /// Generate a new Nostr key pair and store only the private key securely
  static Future<KeyPair> generateAndStoreNostrKey() async {
    Log.info('Generating and storing new Nostr key pair');
    final keyPair = Bip340.generatePrivateKey();

    // Only store the private key - public key can be derived
    await _storage.write(key: _nostrPrivateKeyKey, value: keyPair.privateKey);

    _cachedKeyPair = keyPair;
    return keyPair;
  }

  /// Get the stored Nostr key pair, deriving public key from private key
  static Future<KeyPair?> getStoredNostrKey() async {
    if (_cachedKeyPair != null) {
      return _cachedKeyPair;
    }

    try {
      final privateKey = await _storage.read(key: _nostrPrivateKeyKey);

      if (privateKey != null) {
        // Derive public key from private key
        final publicKey = Bip340.getPublicKey(privateKey);

        // Create full KeyPair with derived public key
        _cachedKeyPair = KeyPair(privateKey, publicKey, null, null);
        Log.info('Successfully loaded Nostr key pair from secure storage: $publicKey');
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
  static Future<KeyPair> initializeKey() async {
    final existingKey = await getStoredNostrKey();
    if (existingKey != null) {
      return existingKey;
    }

    // Generate new key if none exists
    return await generateAndStoreNostrKey();
  }

  /// Get the current user's public key
  /// Returns null if no key has been initialized
  static Future<String?> getCurrentPublicKey() async {
    final keyPair = await getStoredNostrKey();
    return keyPair?.publicKey;
  }

  /// Get the current user's public key in bech32 format (npub)
  /// Returns null if no key has been initialized
  static Future<String?> getCurrentPublicKeyBech32() async {
    final keyPair = await getStoredNostrKey();
    return keyPair?.publicKeyBech32;
  }

  /// Encrypt text using NIP-44 (self-encryption)
  static Future<String> encryptText(String plaintext) async {
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
  static Future<String> decryptText(String encryptedText) async {
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
  static Future<void> clearStoredKeys() async {
    await _storage.delete(key: _nostrPrivateKeyKey);
    _cachedKeyPair = null;
  }

  /// Test-only helper to reset the in-memory cache without touching storage
  @visibleForTesting
  static void resetCacheForTest() {
    _cachedKeyPair = null;
  }
}
