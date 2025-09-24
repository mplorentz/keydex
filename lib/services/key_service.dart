// KeyService Implementation
// Handles encryption key management and operations

import 'dart:convert';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/encryption_key.dart';
import '../models/nostr_key_pair.dart';
import 'encryption_service.dart';

class KeyService {
  final EncryptionService _encryptionService;
  static const String _keyBackupKey = 'key_backup';
  static const String _keyCreatedAtKey = 'key_created_at';
  
  KeyService(this._encryptionService);

  // Key Generation
  Future<EncryptionKey> generateNewKey() async {
    try {
      final keyPair = await _encryptionService.generateKeyPair();
      final encryptionKey = EncryptionKey.fromKeyPair(keyPair);
      
      // Store key creation timestamp
      await _storeKeyCreationTime();
      
      return encryptionKey;
    } catch (e) {
      throw KeyServiceException(
        'Failed to generate new key: ${e.toString()}',
        errorCode: 'KEY_GENERATION_FAILED',
      );
    }
  }

  Future<NostrKeyPair> generateNewNostrKeyPair() async {
    try {
      final keyPair = await _encryptionService.generateKeyPair();
      return NostrKeyPair.fromKeyPair(keyPair);
    } catch (e) {
      throw KeyServiceException(
        'Failed to generate new Nostr key pair: ${e.toString()}',
        errorCode: 'NOSTR_KEY_GENERATION_FAILED',
      );
    }
  }

  // Key Retrieval
  Future<EncryptionKey?> getCurrentKey() async {
    try {
      final keyPair = await _encryptionService.getCurrentKeyPair();
      if (keyPair == null) return null;
      return EncryptionKey.fromKeyPair(keyPair);
    } catch (e) {
      throw KeyServiceException(
        'Failed to retrieve current key: ${e.toString()}',
        errorCode: 'KEY_RETRIEVAL_FAILED',
      );
    }
  }

  Future<NostrKeyPair?> getCurrentNostrKeyPair() async {
    try {
      final keyPair = await _encryptionService.getCurrentKeyPair();
      if (keyPair == null) return null;
      return NostrKeyPair.fromKeyPair(keyPair);
    } catch (e) {
      throw KeyServiceException(
        'Failed to retrieve current Nostr key pair: ${e.toString()}',
        errorCode: 'NOSTR_KEY_RETRIEVAL_FAILED',
      );
    }
  }

  // Key Validation
  Future<bool> validateKey(EncryptionKey key) async {
    try {
      return await _encryptionService.validateKeyPair(key.keyPair);
    } catch (e) {
      return false;
    }
  }

  Future<bool> validateNostrKeyPair(NostrKeyPair nostrKeyPair) async {
    try {
      return await _encryptionService.validateKeyPair(nostrKeyPair.keyPair);
    } catch (e) {
      return false;
    }
  }

  // Key Management
  Future<void> setKey(EncryptionKey key) async {
    try {
      // Validate the key first
      final isValid = await validateKey(key);
      if (!isValid) {
        throw KeyServiceException(
          'Invalid encryption key provided.',
          errorCode: 'INVALID_KEY',
        );
      }

      await _encryptionService.setKeyPair(key.keyPair);
      await _storeKeyCreationTime();
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to set key: ${e.toString()}',
        errorCode: 'KEY_SET_FAILED',
      );
    }
  }

  Future<void> setNostrKeyPair(NostrKeyPair nostrKeyPair) async {
    try {
      // Validate the key pair first
      final isValid = await validateNostrKeyPair(nostrKeyPair);
      if (!isValid) {
        throw KeyServiceException(
          'Invalid Nostr key pair provided.',
          errorCode: 'INVALID_NOSTR_KEY_PAIR',
        );
      }

      await _encryptionService.setKeyPair(nostrKeyPair.keyPair);
      await _storeKeyCreationTime();
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to set Nostr key pair: ${e.toString()}',
        errorCode: 'NOSTR_KEY_SET_FAILED',
      );
    }
  }

  // Key Backup and Recovery
  Future<String> exportKeyBackup() async {
    try {
      final key = await getCurrentKey();
      if (key == null) {
        throw KeyServiceException(
          'No key available to export.',
          errorCode: 'NO_KEY_TO_EXPORT',
        );
      }

      if (!key.isFullKeyPair) {
        throw KeyServiceException(
          'Cannot export public-only key.',
          errorCode: 'PUBLIC_KEY_ONLY',
        );
      }

      final backup = {
        'privateKey': key.privateKey,
        'publicKey': key.publicKey,
        'createdAt': await _getKeyCreationTime(),
        'version': 1,
      };

      return base64Encode(utf8.encode(jsonEncode(backup)));
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to export key backup: ${e.toString()}',
        errorCode: 'KEY_EXPORT_FAILED',
      );
    }
  }

  Future<EncryptionKey> importKeyFromBackup(String backupData) async {
    try {
      final decodedData = utf8.decode(base64Decode(backupData));
      final backup = jsonDecode(decodedData) as Map<String, dynamic>;

      final privateKey = backup['privateKey'] as String?;
      if (privateKey == null) {
        throw KeyServiceException(
          'Invalid backup format: missing private key.',
          errorCode: 'INVALID_BACKUP_FORMAT',
        );
      }

      final keyPair = KeyPair.fromPrivateKeyHex(privateKey);
      final encryptionKey = EncryptionKey.fromKeyPair(keyPair);

      // Validate the imported key
      final isValid = await validateKey(encryptionKey);
      if (!isValid) {
        throw KeyServiceException(
          'Imported key is not valid.',
          errorCode: 'INVALID_IMPORTED_KEY',
        );
      }

      return encryptionKey;
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to import key from backup: ${e.toString()}',
        errorCode: 'KEY_IMPORT_FAILED',
      );
    }
  }

  Future<void> restoreFromBackup(String backupData) async {
    try {
      final encryptionKey = await importKeyFromBackup(backupData);
      await setKey(encryptionKey);
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to restore from backup: ${e.toString()}',
        errorCode: 'KEY_RESTORE_FAILED',
      );
    }
  }

  // Key Information
  Future<bool> hasKey() async {
    try {
      final key = await getCurrentKey();
      return key != null;
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getKeyCreationTime() async {
    try {
      return await _getKeyCreationTime();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getKeyInfo() async {
    try {
      final key = await getCurrentKey();
      if (key == null) {
        return {
          'hasKey': false,
          'keyType': null,
          'createdAt': null,
          'isValid': false,
        };
      }

      final creationTime = await getKeyCreationTime();
      final isValid = await validateKey(key);

      return {
        'hasKey': true,
        'keyType': key.isFullKeyPair ? 'full' : 'public_only',
        'createdAt': creationTime?.toIso8601String(),
        'isValid': isValid,
        'publicKey': key.publicKey,
      };
    } catch (e) {
      return {
        'hasKey': false,
        'error': e.toString(),
      };
    }
  }

  // Key Rotation
  Future<EncryptionKey> rotateKey() async {
    try {
      // Generate new key
      final newKey = await generateNewKey();
      
      // Store old key as backup before rotating
      final oldKey = await getCurrentKey();
      if (oldKey != null) {
        await _storeOldKeyBackup(oldKey);
      }
      
      return newKey;
    } catch (e) {
      throw KeyServiceException(
        'Failed to rotate key: ${e.toString()}',
        errorCode: 'KEY_ROTATION_FAILED',
      );
    }
  }

  // Private helper methods
  Future<void> _storeKeyCreationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCreatedAtKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Non-critical error, log but don't throw
    }
  }

  Future<DateTime?> _getKeyCreationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_keyCreatedAtKey);
      if (timeString == null) return null;
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeOldKeyBackup(EncryptionKey oldKey) async {
    try {
      if (!oldKey.isFullKeyPair) return;
      
      final prefs = await SharedPreferences.getInstance();
      final backup = {
        'privateKey': oldKey.privateKey,
        'publicKey': oldKey.publicKey,
        'replacedAt': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_keyBackupKey, jsonEncode(backup));
    } catch (e) {
      // Non-critical error, log but don't throw
    }
  }

  // Clear all keys
  Future<void> clearKeys() async {
    await _encryptionService.clearKeyPair();
  }
}

// Exception for key service related errors
class KeyServiceException implements Exception {
  final String message;
  final String? errorCode;

  const KeyServiceException(this.message, {this.errorCode});

  @override
  String toString() => 'KeyServiceException: $message${errorCode != null ? ' ($errorCode)' : ''}';
}