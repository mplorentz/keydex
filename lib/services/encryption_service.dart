// EncryptionService Implementation
// Handles NIP-44 encryption operations using NDK

import 'dart:convert';
import 'dart:math';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/encryption_service.dart';

/// Implementation of EncryptionService using NIP-44 encryption
class EncryptionServiceImpl implements EncryptionService {
  EncryptionServiceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  KeyPair? _currentKeyPair;

  static const String _keyPairKey = 'encryption_key_pair';

  /// Gets shared preferences instance
  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String> encryptText(String plaintext) async {
    try {
      if (plaintext.isEmpty) {
        throw EncryptionException(
          'Cannot encrypt empty text',
          errorCode: 'EMPTY_PLAINTEXT',
        );
      }

      if (plaintext.length > 4000) {
        throw EncryptionException(
          'Text too large: ${plaintext.length} characters (max 4000)',
          errorCode: 'TEXT_TOO_LARGE',
        );
      }

      final keyPair = await getCurrentKeyPair();
      if (keyPair == null) {
        throw EncryptionException(
          'No encryption key available. Generate a key pair first.',
          errorCode: 'NO_KEY_PAIR',
        );
      }

      if (keyPair.privateKey == null) {
        throw EncryptionException(
          'Private key not available for encryption',
          errorCode: 'NO_PRIVATE_KEY',
        );
      }

      // Use NIP-44 encryption
      final encrypted = Nip44.encryptMessage(
        plaintext,
        keyPair.privateKey!,
        keyPair.publicKey,
      );

      // Return base64-encoded encrypted string
      return base64Encode(utf8.encode(encrypted));
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Encryption failed: ${e.toString()}',
        errorCode: 'ENCRYPTION_FAILED',
      );
    }
  }

  @override
  Future<String> decryptText(String encryptedText) async {
    try {
      if (encryptedText.isEmpty) {
        throw EncryptionException(
          'Cannot decrypt empty text',
          errorCode: 'EMPTY_ENCRYPTED_TEXT',
        );
      }

      final keyPair = await getCurrentKeyPair();
      if (keyPair == null) {
        throw EncryptionException(
          'No encryption key available for decryption',
          errorCode: 'NO_KEY_PAIR',
        );
      }

      if (keyPair.privateKey == null) {
        throw EncryptionException(
          'Private key not available for decryption',
          errorCode: 'NO_PRIVATE_KEY',
        );
      }

      // Decode base64-encoded encrypted string
      final String encryptedMessage;
      try {
        encryptedMessage = utf8.decode(base64Decode(encryptedText));
      } catch (e) {
        throw EncryptionException(
          'Invalid encrypted text format',
          errorCode: 'INVALID_FORMAT',
        );
      }

      // Use NIP-44 decryption
      final decrypted = Nip44.decryptMessage(
        encryptedMessage,
        keyPair.privateKey!,
        keyPair.publicKey,
      );

      return decrypted;
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Decryption failed: ${e.toString()}',
        errorCode: 'DECRYPTION_FAILED',
      );
    }
  }

  @override
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
      final isValid = await validateKeyPair(keyPair);
      if (!isValid) {
        throw EncryptionException(
          'Generated key pair failed validation',
          errorCode: 'INVALID_GENERATED_KEY',
        );
      }

      return keyPair;
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Key pair generation failed: ${e.toString()}',
        errorCode: 'KEY_GENERATION_FAILED',
      );
    }
  }

  @override
  Future<bool> validateKeyPair(KeyPair keyPair) async {
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

  @override
  Future<KeyPair?> getCurrentKeyPair() async {
    try {
      // Return cached key pair if available
      if (_currentKeyPair != null) {
        return _currentKeyPair;
      }

      // Load from storage
      final prefs = await _preferences;
      final keyPairJson = prefs.getString(_keyPairKey);
      if (keyPairJson == null) return null;

      final Map<String, dynamic> keyPairData = jsonDecode(keyPairJson);
      _currentKeyPair = KeyPair(
        privateKey: keyPairData['privateKey'] as String?,
        publicKey: keyPairData['publicKey'] as String,
      );

      return _currentKeyPair;
    } catch (e) {
      throw EncryptionException(
        'Failed to retrieve key pair: ${e.toString()}',
        errorCode: 'KEY_RETRIEVAL_FAILED',
      );
    }
  }

  @override
  Future<void> setKeyPair(KeyPair keyPair) async {
    try {
      // Validate the key pair before setting
      final isValid = await validateKeyPair(keyPair);
      if (!isValid) {
        throw EncryptionException(
          'Invalid key pair provided',
          errorCode: 'INVALID_KEY_PAIR',
        );
      }

      // Save to storage
      final keyPairData = {
        'privateKey': keyPair.privateKey,
        'publicKey': keyPair.publicKey,
      };

      final prefs = await _preferences;
      await prefs.setString(_keyPairKey, jsonEncode(keyPairData));

      // Cache the key pair
      _currentKeyPair = keyPair;
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Failed to set key pair: ${e.toString()}',
        errorCode: 'KEY_SET_FAILED',
      );
    }
  }

  /// Removes the current key pair from storage and cache
  Future<void> clearKeyPair() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_keyPairKey);
      _currentKeyPair = null;
    } catch (e) {
      throw EncryptionException(
        'Failed to clear key pair: ${e.toString()}',
        errorCode: 'KEY_CLEAR_FAILED',
      );
    }
  }

  /// Checks if a key pair is currently available
  Future<bool> hasKeyPair() async {
    final keyPair = await getCurrentKeyPair();
    return keyPair != null;
  }
}