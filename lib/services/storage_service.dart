// StorageService Implementation
// Handles shared_preferences storage for lockboxes and app data

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lockbox.dart';

class StorageService {
  static const String _lockboxesKey = 'lockboxes';
  static const String _lockboxContentsKey = 'lockbox_contents';
  static const String _userPreferencesKey = 'user_preferences';

  // Lockbox Metadata Operations
  Future<List<LockboxMetadata>> getAllLockboxes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockboxesJson = prefs.getString(_lockboxesKey);
      
      if (lockboxesJson == null) {
        return [];
      }

      final lockboxesList = jsonDecode(lockboxesJson) as List<dynamic>;
      return lockboxesList
          .map((json) => LockboxMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageException(
        'Failed to retrieve lockboxes: ${e.toString()}',
        errorCode: 'LOCKBOX_RETRIEVAL_FAILED',
      );
    }
  }

  Future<void> saveLockboxes(List<LockboxMetadata> lockboxes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockboxesJson = jsonEncode(
        lockboxes.map((lockbox) => lockbox.toJson()).toList(),
      );
      
      await prefs.setString(_lockboxesKey, lockboxesJson);
    } catch (e) {
      throw StorageException(
        'Failed to save lockboxes: ${e.toString()}',
        errorCode: 'LOCKBOX_SAVE_FAILED',
      );
    }
  }

  Future<void> addLockbox(LockboxMetadata lockbox) async {
    try {
      final existingLockboxes = await getAllLockboxes();
      
      // Check for duplicate IDs
      if (existingLockboxes.any((lb) => lb.id == lockbox.id)) {
        throw StorageException(
          'Lockbox with ID ${lockbox.id} already exists.',
          errorCode: 'DUPLICATE_LOCKBOX_ID',
        );
      }
      
      existingLockboxes.add(lockbox);
      await saveLockboxes(existingLockboxes);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to add lockbox: ${e.toString()}',
        errorCode: 'LOCKBOX_ADD_FAILED',
      );
    }
  }

  Future<void> updateLockbox(LockboxMetadata lockbox) async {
    try {
      final existingLockboxes = await getAllLockboxes();
      final index = existingLockboxes.indexWhere((lb) => lb.id == lockbox.id);
      
      if (index == -1) {
        throw StorageException(
          'Lockbox with ID ${lockbox.id} not found.',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }
      
      existingLockboxes[index] = lockbox;
      await saveLockboxes(existingLockboxes);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to update lockbox: ${e.toString()}',
        errorCode: 'LOCKBOX_UPDATE_FAILED',
      );
    }
  }

  Future<void> deleteLockbox(String lockboxId) async {
    try {
      final existingLockboxes = await getAllLockboxes();
      existingLockboxes.removeWhere((lb) => lb.id == lockboxId);
      await saveLockboxes(existingLockboxes);
      
      // Also remove the encrypted content
      await deleteEncryptedContent(lockboxId);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to delete lockbox: ${e.toString()}',
        errorCode: 'LOCKBOX_DELETE_FAILED',
      );
    }
  }

  // Encrypted Content Operations
  Future<Map<String, String>> getAllEncryptedContents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contentsJson = prefs.getString(_lockboxContentsKey);
      
      if (contentsJson == null) {
        return {};
      }

      final contentsMap = jsonDecode(contentsJson) as Map<String, dynamic>;
      return contentsMap.cast<String, String>();
    } catch (e) {
      throw StorageException(
        'Failed to retrieve encrypted contents: ${e.toString()}',
        errorCode: 'CONTENT_RETRIEVAL_FAILED',
      );
    }
  }

  Future<String?> getEncryptedContent(String lockboxId) async {
    try {
      final allContents = await getAllEncryptedContents();
      return allContents[lockboxId];
    } catch (e) {
      throw StorageException(
        'Failed to retrieve encrypted content for lockbox $lockboxId: ${e.toString()}',
        errorCode: 'CONTENT_RETRIEVAL_FAILED',
      );
    }
  }

  Future<void> saveEncryptedContent(String lockboxId, String encryptedContent) async {
    try {
      final allContents = await getAllEncryptedContents();
      allContents[lockboxId] = encryptedContent;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lockboxContentsKey, jsonEncode(allContents));
    } catch (e) {
      throw StorageException(
        'Failed to save encrypted content: ${e.toString()}',
        errorCode: 'CONTENT_SAVE_FAILED',
      );
    }
  }

  Future<void> deleteEncryptedContent(String lockboxId) async {
    try {
      final allContents = await getAllEncryptedContents();
      allContents.remove(lockboxId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lockboxContentsKey, jsonEncode(allContents));
    } catch (e) {
      throw StorageException(
        'Failed to delete encrypted content: ${e.toString()}',
        errorCode: 'CONTENT_DELETE_FAILED',
      );
    }
  }

  // User Preferences Operations
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_userPreferencesKey);
      
      if (preferencesJson == null) {
        return {};
      }

      return jsonDecode(preferencesJson) as Map<String, dynamic>;
    } catch (e) {
      throw StorageException(
        'Failed to retrieve user preferences: ${e.toString()}',
        errorCode: 'PREFERENCES_RETRIEVAL_FAILED',
      );
    }
  }

  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPreferencesKey, jsonEncode(preferences));
    } catch (e) {
      throw StorageException(
        'Failed to save user preferences: ${e.toString()}',
        errorCode: 'PREFERENCES_SAVE_FAILED',
      );
    }
  }

  Future<T?> getUserPreference<T>(String key) async {
    try {
      final preferences = await getUserPreferences();
      return preferences[key] as T?;
    } catch (e) {
      return null;
    }
  }

  Future<void> setUserPreference<T>(String key, T value) async {
    try {
      final preferences = await getUserPreferences();
      preferences[key] = value;
      await saveUserPreferences(preferences);
    } catch (e) {
      throw StorageException(
        'Failed to set user preference: ${e.toString()}',
        errorCode: 'PREFERENCE_SET_FAILED',
      );
    }
  }

  // Utility Operations
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lockboxesKey);
      await prefs.remove(_lockboxContentsKey);
      await prefs.remove(_userPreferencesKey);
    } catch (e) {
      throw StorageException(
        'Failed to clear all data: ${e.toString()}',
        errorCode: 'CLEAR_DATA_FAILED',
      );
    }
  }

  Future<int> getStorageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int totalSize = 0;
      
      final lockboxes = prefs.getString(_lockboxesKey);
      if (lockboxes != null) totalSize += lockboxes.length;
      
      final contents = prefs.getString(_lockboxContentsKey);
      if (contents != null) totalSize += contents.length;
      
      final preferences = prefs.getString(_userPreferencesKey);
      if (preferences != null) totalSize += preferences.length;
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> hasLockbox(String lockboxId) async {
    try {
      final lockboxes = await getAllLockboxes();
      return lockboxes.any((lb) => lb.id == lockboxId);
    } catch (e) {
      return false;
    }
  }

  Future<LockboxMetadata?> getLockboxById(String lockboxId) async {
    try {
      final lockboxes = await getAllLockboxes();
      return lockboxes.where((lb) => lb.id == lockboxId).firstOrNull;
    } catch (e) {
      return null;
    }
  }
}

// Exception for storage-related errors
class StorageException implements Exception {
  final String message;
  final String? errorCode;

  const StorageException(this.message, {this.errorCode});

  @override
  String toString() => 'StorageException: $message${errorCode != null ? ' ($errorCode)' : ''}';
}