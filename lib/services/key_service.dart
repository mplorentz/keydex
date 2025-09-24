import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key management service for storing Nostr keys securely
/// Only stores the private key - public key is derived as needed
class KeyService {
  static const _storage = FlutterSecureStorage();
  static const String _nostrPrivateKeyKey = 'nostr_private_key';

  static KeyPair? _cachedKeyPair;

  /// Generate a new Nostr key pair and store only the private key securely
  static Future<KeyPair> generateAndStoreNostrKey() async {
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
        return _cachedKeyPair;
      }
    } catch (e) {
      print('Error reading stored key: $e');
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

  /// Clear stored keys (for testing or reset purposes)
  static Future<void> clearStoredKeys() async {
    await _storage.delete(key: _nostrPrivateKeyKey);
    _cachedKeyPair = null;
  }
}
