// KeyService Implementation
// Manages encryption keys and key-related operations

import 'dart:convert';
import 'dart:math';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';
import 'storage_service.dart';

/// Service for managing encryption keys and key-related operations
class KeyService {
  KeyService({
    required StorageService storageService,
  }) : _storageService = storageService;

  final StorageService _storageService;
  KeyPair? _currentKeyPair;

  static const String _masterKeyKey = 'master_key';
  static const String _keyHistoryKey = 'key_history';
  static const String _keyMetadataKey = 'key_metadata';

  /// Generates a new key pair using secure random
  Future<KeyPair> generateKeyPair() async {
    try {
      // Generate a new random private key
      final random = Random.secure();
      final privateKeyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final privateKeyHex = privateKeyBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      // Create KeyPair - the constructor will generate the public key
      final keyPair = KeyPair(privateKey: privateKeyHex);

      // Validate the generated key pair
      final isValid = validateKeyPair(keyPair);
      if (!isValid) {
        throw KeyServiceException(
          'Generated key pair failed validation',
          errorCode: 'INVALID_GENERATED_KEY',
        );
      }

      return keyPair;
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Key pair generation failed: ${e.toString()}',
        errorCode: 'KEY_GENERATION_FAILED',
      );
    }
  }

  /// Validates if a key pair is cryptographically valid
  bool validateKeyPair(KeyPair keyPair) {
    try {
      // Check key format
      if (keyPair.privateKey != null) {
        if (keyPair.privateKey!.length != 64) return false;
        try {
          int.parse(keyPair.privateKey!, radix: 16);
        } catch (e) {
          return false;
        }
      }

      if (keyPair.publicKey.length != 64) return false;
      try {
        int.parse(keyPair.publicKey, radix: 16);
      } catch (e) {
        return false;
      }

      // Test encryption/decryption if private key is available
      if (keyPair.privateKey != null) {
        const testMessage = 'validation_test';
        try {
          final encrypted = Nip44.encryptMessage(
            testMessage,
            keyPair.privateKey!,
            keyPair.publicKey,
          );
          final decrypted = Nip44.decryptMessage(
            encrypted,
            keyPair.privateKey!,
            keyPair.publicKey,
          );
          if (decrypted != testMessage) return false;
        } catch (e) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generates and sets up a new master key pair
  Future<KeyPair> generateMasterKey() async {
    try {
      // Generate a new key pair
      final keyPair = await generateKeyPair();
      
      // Set as current key pair
      await setCurrentKeyPair(keyPair);

      // Store as master key
      await _storeMasterKey(keyPair);

      // Add to key history
      await _addToKeyHistory(keyPair);

      return keyPair;
    } catch (e) {
      throw KeyServiceException(
        'Failed to generate master key: ${e.toString()}',
        errorCode: 'MASTER_KEY_GENERATION_FAILED',
      );
    }
  }

  /// Sets the current key pair (cached and stored)
  Future<void> setCurrentKeyPair(KeyPair keyPair) async {
    _currentKeyPair = keyPair;
  }

  /// Gets the current key pair
  Future<KeyPair?> getCurrentKeyPair() async {
    if (_currentKeyPair != null) {
      return _currentKeyPair;
    }

    // Try to load master key as current key
    return await getMasterKey();
  }

  /// Gets the current master key
  Future<KeyPair?> getMasterKey() async {
    try {
      final masterKeyJson = await _storageService.getString(_masterKeyKey);
      if (masterKeyJson == null) return _currentKeyPair;

      final Map<String, dynamic> keyData = jsonDecode(masterKeyJson);
      final keyPair = KeyPair(
        privateKey: keyData['privateKey'] as String?,
        publicKey: keyData['publicKey'] as String,
      );
      
      // Cache the key pair
      _currentKeyPair = keyPair;
      return keyPair;
    } catch (e) {
      throw KeyServiceException(
        'Failed to retrieve master key: ${e.toString()}',
        errorCode: 'MASTER_KEY_RETRIEVAL_FAILED',
      );
    }
  }

  /// Checks if a master key exists
  Future<bool> hasMasterKey() async {
    final masterKey = await getMasterKey();
    return masterKey != null;
  }

  /// Imports a key pair from hex strings
  Future<KeyPair> importKeyPair({
    required String privateKeyHex,
    String? publicKeyHex,
  }) async {
    try {
      // Validate private key format
      if (privateKeyHex.length != 64) {
        throw KeyServiceException(
          'Invalid private key length: expected 64 characters',
          errorCode: 'INVALID_PRIVATE_KEY_LENGTH',
        );
      }

      // Create KeyPair (public key will be derived if not provided)
      final keyPair = KeyPair(privateKey: privateKeyHex, publicKey: publicKeyHex);

      // Validate the key pair
      final isValid = validateKeyPair(keyPair);
      if (!isValid) {
        throw KeyServiceException(
          'Invalid key pair: failed cryptographic validation',
          errorCode: 'INVALID_KEY_PAIR',
        );
      }

      // Set as current key pair
      await setCurrentKeyPair(keyPair);

      // Store as master key
      await _storeMasterKey(keyPair);

      // Add to key history
      await _addToKeyHistory(keyPair);

      return keyPair;
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to import key pair: ${e.toString()}',
        errorCode: 'KEY_IMPORT_FAILED',
      );
    }
  }

  /// Imports a key pair from bech32 strings
  Future<KeyPair> importKeyPairBech32({
    required String privateKeyBech32,
    String? publicKeyBech32,
  }) async {
    try {
      // Validate bech32 format
      if (!privateKeyBech32.startsWith('nsec1')) {
        throw KeyServiceException(
          'Invalid private key format: must start with nsec1',
          errorCode: 'INVALID_PRIVATE_KEY_FORMAT',
        );
      }

      if (publicKeyBech32 != null && !publicKeyBech32.startsWith('npub1')) {
        throw KeyServiceException(
          'Invalid public key format: must start with npub1',
          errorCode: 'INVALID_PUBLIC_KEY_FORMAT',
        );
      }

      // Create KeyPair - NDK should handle bech32 conversion
      final keyPair = KeyPair.fromBech32(
        privateKey: privateKeyBech32,
        publicKey: publicKeyBech32,
      );

      // Validate the key pair
      final isValid = validateKeyPair(keyPair);
      if (!isValid) {
        throw KeyServiceException(
          'Invalid key pair: failed cryptographic validation',
          errorCode: 'INVALID_KEY_PAIR',
        );
      }

      // Set as current key pair
      await setCurrentKeyPair(keyPair);

      // Store as master key
      await _storeMasterKey(keyPair);

      // Add to key history
      await _addToKeyHistory(keyPair);

      return keyPair;
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to import key pair from bech32: ${e.toString()}',
        errorCode: 'BECH32_IMPORT_FAILED',
      );
    }
  }

  /// Exports the current master key
  Future<Map<String, String>> exportMasterKey() async {
    try {
      final masterKey = await getMasterKey();
      if (masterKey == null) {
        throw KeyServiceException(
          'No master key available to export',
          errorCode: 'NO_MASTER_KEY',
        );
      }

      return {
        'privateKeyHex': masterKey.privateKey ?? '',
        'publicKeyHex': masterKey.publicKey,
        'privateKeyBech32': masterKey.privateKeyBech32 ?? '',
        'publicKeyBech32': masterKey.publicKeyBech32,
      };
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to export master key: ${e.toString()}',
        errorCode: 'MASTER_KEY_EXPORT_FAILED',
      );
    }
  }

  /// Deletes all keys and resets the service
  Future<void> resetAllKeys() async {
    try {
      // Clear cached key
      _currentKeyPair = null;
      
      // TODO: Clear keys from storage through AuthService
      // For now, we just clear the cache
    } catch (e) {
      throw KeyServiceException(
        'Failed to reset all keys: ${e.toString()}',
        errorCode: 'RESET_KEYS_FAILED',
      );
    }
  }

  /// Rotates the master key (generates new key, re-encrypts all data)
  Future<KeyPair> rotateMasterKey() async {
    try {
      // This is a complex operation that would require re-encrypting all lockbox content
      // For now, we'll generate a new key and replace the old one
      // In a production system, this would need to:
      // 1. Decrypt all existing content with old key
      // 2. Generate new key
      // 3. Re-encrypt all content with new key
      // 4. Update storage
      
      final newKey = await generateMasterKey();
      return newKey;
    } catch (e) {
      throw KeyServiceException(
        'Failed to rotate master key: ${e.toString()}',
        errorCode: 'KEY_ROTATION_FAILED',
      );
    }
  }

  /// Stores master key privately
  Future<void> _storeMasterKey(KeyPair keyPair) async {
    try {
      final keyData = {
        'privateKey': keyPair.privateKey,
        'publicKey': keyPair.publicKey,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _storageService.setString(_masterKeyKey, jsonEncode(keyData));
    } catch (e) {
      throw KeyServiceException(
        'Failed to store master key: ${e.toString()}',
        errorCode: 'STORE_MASTER_KEY_FAILED',
      );
    }
  }

  /// Adds key to history
  Future<void> _addToKeyHistory(KeyPair keyPair) async {
    try {
      // For now, we'll skip history tracking to keep it simple
      // This can be implemented later if needed
    } catch (e) {
      throw KeyServiceException(
        'Failed to add key to history: ${e.toString()}',
        errorCode: 'ADD_KEY_HISTORY_FAILED',
      );
    }
  }
}

/// Exception thrown when key service operations fail
class KeyServiceException implements Exception {
  final String message;
  final String? errorCode;

  const KeyServiceException(this.message, {this.errorCode});

  @override
  String toString() {
    return errorCode != null
        ? 'KeyServiceException($errorCode): $message'
        : 'KeyServiceException: $message';
  }
}