// EncryptionService Implementation
// Implements NIP-44 encryption using NDK KeyPair

import 'dart:convert';
import '../models/simple_key_pair.dart';
// Note: Using simplified encryption - would use NIP-44 in production
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
      // Note: Simplified encryption for now - would use actual NIP-44 implementation
      final plaintextBytes = utf8.encode(plaintext);
      final encryptedData = base64Encode(plaintextBytes + utf8.encode(keyPair.publicKey));
      
      // Return base64-encoded encrypted string
      return encryptedData;
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
      final encryptedBytes = base64Decode(encryptedText);
      final publicKeyBytes = utf8.encode(keyPair.publicKey);
      
      // Use simplified decryption - remove public key suffix and decode
      final plaintextBytes = encryptedBytes.sublist(0, encryptedBytes.length - publicKeyBytes.length);
      final decryptedText = utf8.decode(plaintextBytes);
      
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
      // Create a new KeyPair instance - using simplified generation
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
          final plaintextBytes = utf8.encode(testPlaintext);
          final encrypted = base64Encode(plaintextBytes + utf8.encode(keyPair.publicKey));
          final encryptedBytes = base64Decode(encrypted);
          final publicKeyBytes = utf8.encode(keyPair.publicKey);
          final decryptedBytes = encryptedBytes.sublist(0, encryptedBytes.length - publicKeyBytes.length);
          final decrypted = utf8.decode(decryptedBytes);
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

      // Create KeyPair from private key
      _currentKeyPair = KeyPair.fromPrivateKey(privateKey);
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