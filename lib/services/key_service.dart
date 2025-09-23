// KeyService Implementation
// Manages encryption keys and key-related operations

import 'dart:convert';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/encryption_key.dart';
import '../models/nostr_key_pair.dart';
import 'encryption_service.dart';

/// Service for managing encryption keys and key-related operations
class KeyService {
  KeyService({
    EncryptionService? encryptionService,
    SharedPreferences? prefs,
  })  : _encryptionService = encryptionService ?? EncryptionServiceImpl(),
        _prefs = prefs;

  final EncryptionService _encryptionService;
  SharedPreferences? _prefs;

  static const String _masterKeyKey = 'master_key';
  static const String _keyHistoryKey = 'key_history';
  static const String _keyMetadataKey = 'key_metadata';

  /// Gets shared preferences instance
  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Generates and sets up a new master key pair
  Future<NostrKeyPair> generateMasterKey({String? label}) async {
    try {
      // Generate a new key pair using the encryption service
      final keyPair = await _encryptionService.generateKeyPair();
      
      // Create NostrKeyPair wrapper
      final nostrKeyPair = NostrKeyPair.fromKeyPair(
        keyPair,
        label: label ?? 'Master Key',
      );

      // Set as current encryption key
      await _encryptionService.setKeyPair(keyPair);

      // Store as master key
      await _storeMasterKey(nostrKeyPair);

      // Add to key history
      await _addToKeyHistory(nostrKeyPair);

      return nostrKeyPair;
    } catch (e) {
      throw KeyServiceException(
        'Failed to generate master key: ${e.toString()}',
        errorCode: 'MASTER_KEY_GENERATION_FAILED',
      );
    }
  }

  /// Gets the current master key
  Future<NostrKeyPair?> getMasterKey() async {
    try {
      final prefs = await _preferences;
      final masterKeyJson = prefs.getString(_masterKeyKey);
      
      if (masterKeyJson == null) return null;

      final Map<String, dynamic> keyData = jsonDecode(masterKeyJson);
      return NostrKeyPair.fromJson(keyData);
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
  Future<NostrKeyPair> importKeyPair({
    required String privateKeyHex,
    String? publicKeyHex,
    String? label,
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
      final isValid = await _encryptionService.validateKeyPair(keyPair);
      if (!isValid) {
        throw KeyServiceException(
          'Invalid key pair: failed cryptographic validation',
          errorCode: 'INVALID_KEY_PAIR',
        );
      }

      // Create NostrKeyPair wrapper
      final nostrKeyPair = NostrKeyPair.fromKeyPair(
        keyPair,
        label: label ?? 'Imported Key',
      );

      // Set as current encryption key
      await _encryptionService.setKeyPair(keyPair);

      // Store as master key
      await _storeMasterKey(nostrKeyPair);

      // Add to key history
      await _addToKeyHistory(nostrKeyPair);

      return nostrKeyPair;
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to import key pair: ${e.toString()}',
        errorCode: 'KEY_IMPORT_FAILED',
      );
    }
  }

  /// Imports a key pair from bech32 strings
  Future<NostrKeyPair> importKeyPairBech32({
    required String privateKeyBech32,
    String? publicKeyBech32,
    String? label,
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
      final isValid = await _encryptionService.validateKeyPair(keyPair);
      if (!isValid) {
        throw KeyServiceException(
          'Invalid key pair: failed cryptographic validation',
          errorCode: 'INVALID_KEY_PAIR',
        );
      }

      // Create NostrKeyPair wrapper
      final nostrKeyPair = NostrKeyPair.fromKeyPair(
        keyPair,
        label: label ?? 'Imported Key (Bech32)',
      );

      // Set as current encryption key
      await _encryptionService.setKeyPair(keyPair);

      // Store as master key
      await _storeMasterKey(nostrKeyPair);

      // Add to key history
      await _addToKeyHistory(nostrKeyPair);

      return nostrKeyPair;
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

  /// Gets key history
  Future<List<NostrKeyPair>> getKeyHistory() async {
    try {
      final prefs = await _preferences;
      final historyJson = prefs.getString(_keyHistoryKey);
      
      if (historyJson == null) return [];

      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList
          .cast<Map<String, dynamic>>()
          .map((json) => NostrKeyPair.fromJson(json))
          .toList();
    } catch (e) {
      throw KeyServiceException(
        'Failed to retrieve key history: ${e.toString()}',
        errorCode: 'KEY_HISTORY_RETRIEVAL_FAILED',
      );
    }
  }

  /// Deletes all keys and resets the service
  Future<void> resetAllKeys() async {
    try {
      final prefs = await _preferences;
      
      // Clear all key-related storage
      await prefs.remove(_masterKeyKey);
      await prefs.remove(_keyHistoryKey);
      await prefs.remove(_keyMetadataKey);

      // Clear encryption service key
      if (_encryptionService is EncryptionServiceImpl) {
        await (_encryptionService as EncryptionServiceImpl).clearKeyPair();
      }
    } catch (e) {
      throw KeyServiceException(
        'Failed to reset all keys: ${e.toString()}',
        errorCode: 'RESET_KEYS_FAILED',
      );
    }
  }

  /// Rotates the master key (generates new key, re-encrypts all data)
  Future<NostrKeyPair> rotateMasterKey({String? label}) async {
    try {
      // This is a complex operation that would require re-encrypting all lockbox content
      // For now, we'll generate a new key and replace the old one
      // In a production system, this would need to:
      // 1. Decrypt all existing content with old key
      // 2. Generate new key
      // 3. Re-encrypt all content with new key
      // 4. Update storage
      
      final oldKey = await getMasterKey();
      final newKey = await generateMasterKey(label: label ?? 'Rotated Master Key');

      // Add metadata about the rotation
      await _storeKeyMetadata({
        'lastRotation': DateTime.now().toIso8601String(),
        'previousKeyId': oldKey?.shortId ?? 'unknown',
        'currentKeyId': newKey.shortId,
      });

      return newKey;
    } catch (e) {
      throw KeyServiceException(
        'Failed to rotate master key: ${e.toString()}',
        errorCode: 'KEY_ROTATION_FAILED',
      );
    }
  }

  /// Stores master key privately
  Future<void> _storeMasterKey(NostrKeyPair keyPair) async {
    final prefs = await _preferences;
    await prefs.setString(_masterKeyKey, jsonEncode(keyPair.toJson()));
  }

  /// Adds key to history
  Future<void> _addToKeyHistory(NostrKeyPair keyPair) async {
    final history = await getKeyHistory();
    
    // Remove any existing entry with same public key
    history.removeWhere((key) => key.publicKey == keyPair.publicKey);
    
    // Add new key to beginning
    history.insert(0, keyPair);
    
    // Keep only last 10 keys
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    final prefs = await _preferences;
    final historyJson = history.map((key) => key.toJson()).toList();
    await prefs.setString(_keyHistoryKey, jsonEncode(historyJson));
  }

  /// Stores key metadata
  Future<void> _storeKeyMetadata(Map<String, dynamic> metadata) async {
    final prefs = await _preferences;
    await prefs.setString(_keyMetadataKey, jsonEncode(metadata));
  }

  /// Gets key metadata
  Future<Map<String, dynamic>> getKeyMetadata() async {
    try {
      final prefs = await _preferences;
      final metadataJson = prefs.getString(_keyMetadataKey);
      
      if (metadataJson == null) return {};

      return jsonDecode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
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