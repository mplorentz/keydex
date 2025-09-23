// EncryptionService Implementation
// Implements NIP-44 encryption using NDK KeyPair

import 'dart:convert';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/encryption_service.dart';
import '../models/encryption_key.dart';

class EncryptionServiceImpl implements EncryptionService {
  static const String _keyPairStorageKey = 'encryption_keypair';
  KeyPair? _currentKeyPair;

  @override
  Future<String> encryptText(String plaintext) async {
    try {
      final keyPair = await getCurrentKeyPair();
      if (keyPair == null) {
        throw EncryptionException(
          'No encryption key available. Please generate or set a key pair.',
          errorCode: 'NO_KEY_AVAILABLE',
        );
      }

      if (keyPair.privateKey == null) {
        throw EncryptionException(
          'Private key not available for encryption.',
          errorCode: 'PRIVATE_KEY_MISSING',
        );
      }

      // Use NIP-44 encryption with the key pair
      final encryptedData = Nip44.encrypt(plaintext, keyPair);
      
      // Return base64-encoded encrypted string
      return base64Encode(utf8.encode(encryptedData));
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
      final keyPair = await getCurrentKeyPair();
      if (keyPair == null) {
        throw EncryptionException(
          'No encryption key available. Please generate or set a key pair.',
          errorCode: 'NO_KEY_AVAILABLE',
        );
      }

      if (keyPair.privateKey == null) {
        throw EncryptionException(
          'Private key not available for decryption.',
          errorCode: 'PRIVATE_KEY_MISSING',
        );
      }

      // Decode base64-encoded encrypted string
      final encryptedData = utf8.decode(base64Decode(encryptedText));
      
      // Use NIP-44 decryption with the key pair
      final decryptedText = Nip44.decrypt(encryptedData, keyPair);
      
      return decryptedText;
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
      final keyPair = KeyPair.generate();
      await setKeyPair(keyPair);
      return keyPair;
    } catch (e) {
      throw EncryptionException(
        'Key pair generation failed: ${e.toString()}',
        errorCode: 'KEY_GENERATION_FAILED',
      );
    }
  }

  @override
  Future<bool> validateKeyPair(KeyPair keyPair) async {
    try {
      // Check if public key is valid hex (64 characters)
      if (keyPair.publicKey.length != 64) return false;
      
      // Check if private key (when present) is valid hex (64 characters)
      if (keyPair.privateKey != null && keyPair.privateKey!.length != 64) return false;
      
      // Validate hex format
      final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
      if (!hexRegex.hasMatch(keyPair.publicKey)) return false;
      if (keyPair.privateKey != null && !hexRegex.hasMatch(keyPair.privateKey!)) return false;
      
      // Test encryption/decryption if private key is available
      if (keyPair.privateKey != null) {
        try {
          const testPlaintext = 'test_encryption_validation';
          final encrypted = Nip44.encrypt(testPlaintext, keyPair);
          final decrypted = Nip44.decrypt(encrypted, keyPair);
          return decrypted == testPlaintext;
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
      if (_currentKeyPair != null) {
        return _currentKeyPair;
      }

      final prefs = await SharedPreferences.getInstance();
      final keyPairJson = prefs.getString(_keyPairStorageKey);
      
      if (keyPairJson == null) {
        return null;
      }

      final keyPairData = jsonDecode(keyPairJson) as Map<String, dynamic>;
      final privateKey = keyPairData['privateKey'] as String?;
      
      if (privateKey == null) {
        throw EncryptionException(
          'Stored key pair is missing private key.',
          errorCode: 'CORRUPTED_KEY_DATA',
        );
      }

      _currentKeyPair = KeyPair.fromPrivateKeyHex(privateKey);
      return _currentKeyPair;
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Failed to retrieve current key pair: ${e.toString()}',
        errorCode: 'KEY_RETRIEVAL_FAILED',
      );
    }
  }

  @override
  Future<void> setKeyPair(KeyPair keyPair) async {
    try {
      // Validate the key pair before storing
      final isValid = await validateKeyPair(keyPair);
      if (!isValid) {
        throw EncryptionException(
          'Invalid key pair provided.',
          errorCode: 'INVALID_KEY_PAIR',
        );
      }

      if (keyPair.privateKey == null) {
        throw EncryptionException(
          'Cannot store key pair without private key.',
          errorCode: 'PRIVATE_KEY_REQUIRED',
        );
      }

      // Store the key pair in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final keyPairData = {
        'privateKey': keyPair.privateKey,
        'publicKey': keyPair.publicKey,
      };
      
      await prefs.setString(_keyPairStorageKey, jsonEncode(keyPairData));
      _currentKeyPair = keyPair;
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Failed to set key pair: ${e.toString()}',
        errorCode: 'KEY_STORAGE_FAILED',
      );
    }
  }

  // Additional helper methods
  Future<void> clearKeyPair() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPairStorageKey);
      _currentKeyPair = null;
    } catch (e) {
      throw EncryptionException(
        'Failed to clear key pair: ${e.toString()}',
        errorCode: 'KEY_CLEAR_FAILED',
      );
    }
  }

  Future<bool> hasKeyPair() async {
    try {
      final keyPair = await getCurrentKeyPair();
      return keyPair != null;
    } catch (e) {
      return false;
    }
  }

  Future<EncryptionKey?> getCurrentEncryptionKey() async {
    try {
      final keyPair = await getCurrentKeyPair();
      if (keyPair == null) return null;
      return EncryptionKey.fromKeyPair(keyPair);
    } catch (e) {
      return null;
    }
  }
}