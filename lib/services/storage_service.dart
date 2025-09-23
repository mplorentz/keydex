// StorageService Implementation
// Handles local storage operations using shared_preferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lockbox.dart';

/// Service for handling local storage operations
class StorageService {
  StorageService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const String _lockboxesKey = 'lockboxes';
  static const String _lockboxContentsKey = 'lockbox_contents';
  static const String _userPreferencesKey = 'user_preferences';

  /// Gets shared preferences instance
  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Stores lockbox metadata list
  Future<void> storeLockboxes(List<LockboxMetadata> lockboxes) async {
    try {
      final prefs = await _preferences;
      final lockboxesJson = lockboxes.map((lockbox) => lockbox.toJson()).toList();
      await prefs.setString(_lockboxesKey, jsonEncode(lockboxesJson));
    } catch (e) {
      throw StorageException(
        'Failed to store lockboxes: ${e.toString()}',
        errorCode: 'STORE_LOCKBOXES_FAILED',
      );
    }
  }

  /// Retrieves lockbox metadata list
  Future<List<LockboxMetadata>> getLockboxes() async {
    try {
      final prefs = await _preferences;
      final lockboxesJson = prefs.getString(_lockboxesKey);
      
      if (lockboxesJson == null) return [];

      final List<dynamic> lockboxesList = jsonDecode(lockboxesJson);
      return lockboxesList
          .cast<Map<String, dynamic>>()
          .map((json) => LockboxMetadata.fromJson(json))
          .toList();
    } catch (e) {
      throw StorageException(
        'Failed to retrieve lockboxes: ${e.toString()}',
        errorCode: 'GET_LOCKBOXES_FAILED',
      );
    }
  }

  /// Stores encrypted content for a specific lockbox
  Future<void> storeLockboxContent(String lockboxId, String encryptedContent) async {
    try {
      final prefs = await _preferences;
      final contentsJson = prefs.getString(_lockboxContentsKey);
      
      Map<String, dynamic> contents = {};
      if (contentsJson != null) {
        contents = jsonDecode(contentsJson) as Map<String, dynamic>;
      }

      contents[lockboxId] = encryptedContent;
      await prefs.setString(_lockboxContentsKey, jsonEncode(contents));
    } catch (e) {
      throw StorageException(
        'Failed to store lockbox content: ${e.toString()}',
        errorCode: 'STORE_CONTENT_FAILED',
      );
    }
  }

  /// Retrieves encrypted content for a specific lockbox
  Future<String?> getLockboxContent(String lockboxId) async {
    try {
      final prefs = await _preferences;
      final contentsJson = prefs.getString(_lockboxContentsKey);
      
      if (contentsJson == null) return null;

      final Map<String, dynamic> contents = jsonDecode(contentsJson) as Map<String, dynamic>;
      return contents[lockboxId] as String?;
    } catch (e) {
      throw StorageException(
        'Failed to retrieve lockbox content: ${e.toString()}',
        errorCode: 'GET_CONTENT_FAILED',
      );
    }
  }

  /// Removes a lockbox and its content
  Future<void> removeLockbox(String lockboxId) async {
    try {
      final prefs = await _preferences;

      // Remove from lockboxes list
      final lockboxes = await getLockboxes();
      final updatedLockboxes = lockboxes.where((lockbox) => lockbox.id != lockboxId).toList();
      await storeLockboxes(updatedLockboxes);

      // Remove encrypted content
      final contentsJson = prefs.getString(_lockboxContentsKey);
      if (contentsJson != null) {
        final Map<String, dynamic> contents = jsonDecode(contentsJson) as Map<String, dynamic>;
        contents.remove(lockboxId);
        await prefs.setString(_lockboxContentsKey, jsonEncode(contents));
      }
    } catch (e) {
      throw StorageException(
        'Failed to remove lockbox: ${e.toString()}',
        errorCode: 'REMOVE_LOCKBOX_FAILED',
      );
    }
  }

  /// Updates a lockbox metadata
  Future<void> updateLockbox(LockboxMetadata updatedLockbox) async {
    try {
      final lockboxes = await getLockboxes();
      final lockboxIndex = lockboxes.indexWhere((lockbox) => lockbox.id == updatedLockbox.id);
      
      if (lockboxIndex == -1) {
        throw StorageException(
          'Lockbox not found: ${updatedLockbox.id}',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      lockboxes[lockboxIndex] = updatedLockbox;
      await storeLockboxes(lockboxes);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to update lockbox: ${e.toString()}',
        errorCode: 'UPDATE_LOCKBOX_FAILED',
      );
    }
  }

  /// Adds a new lockbox
  Future<void> addLockbox(LockboxMetadata lockbox) async {
    try {
      final lockboxes = await getLockboxes();
      
      // Check if lockbox already exists
      final existingIndex = lockboxes.indexWhere((existing) => existing.id == lockbox.id);
      if (existingIndex != -1) {
        throw StorageException(
          'Lockbox already exists: ${lockbox.id}',
          errorCode: 'LOCKBOX_ALREADY_EXISTS',
        );
      }

      lockboxes.add(lockbox);
      await storeLockboxes(lockboxes);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to add lockbox: ${e.toString()}',
        errorCode: 'ADD_LOCKBOX_FAILED',
      );
    }
  }

  /// Stores user preferences
  Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_userPreferencesKey, jsonEncode(preferences));
    } catch (e) {
      throw StorageException(
        'Failed to store user preferences: ${e.toString()}',
        errorCode: 'STORE_PREFERENCES_FAILED',
      );
    }
  }

  /// Retrieves user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await _preferences;
      final preferencesJson = prefs.getString(_userPreferencesKey);
      
      if (preferencesJson == null) return {};

      return jsonDecode(preferencesJson) as Map<String, dynamic>;
    } catch (e) {
      throw StorageException(
        'Failed to retrieve user preferences: ${e.toString()}',
        errorCode: 'GET_PREFERENCES_FAILED',
      );
    }
  }

  /// Clears all stored data
  Future<void> clearAll() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_lockboxesKey);
      await prefs.remove(_lockboxContentsKey);
      await prefs.remove(_userPreferencesKey);
    } catch (e) {
      throw StorageException(
        'Failed to clear all data: ${e.toString()}',
        errorCode: 'CLEAR_ALL_FAILED',
      );
    }
  }

  /// Gets storage statistics
  Future<StorageStats> getStorageStats() async {
    try {
      final lockboxes = await getLockboxes();
      final prefs = await _preferences;
      final contentsJson = prefs.getString(_lockboxContentsKey);

      int totalLockboxes = lockboxes.length;
      int totalContentSize = 0;

      if (contentsJson != null) {
        final Map<String, dynamic> contents = jsonDecode(contentsJson) as Map<String, dynamic>;
        totalContentSize = contents.values.fold(0, (sum, content) => sum + (content as String).length);
      }

      return StorageStats(
        totalLockboxes: totalLockboxes,
        totalContentSize: totalContentSize,
        averageLockboxSize: totalLockboxes > 0 ? totalContentSize / totalLockboxes : 0,
      );
    } catch (e) {
      throw StorageException(
        'Failed to get storage statistics: ${e.toString()}',
        errorCode: 'GET_STATS_FAILED',
      );
    }
  }
}

/// Storage statistics information
class StorageStats {
  const StorageStats({
    required this.totalLockboxes,
    required this.totalContentSize,
    required this.averageLockboxSize,
  });

  final int totalLockboxes;
  final int totalContentSize;
  final double averageLockboxSize;

  @override
  String toString() {
    return 'StorageStats{totalLockboxes: $totalLockboxes, totalContentSize: $totalContentSize, averageLockboxSize: ${averageLockboxSize.toStringAsFixed(1)}}';
  }
}

/// Exception thrown when storage operations fail
class StorageException implements Exception {
  final String message;
  final String? errorCode;

  const StorageException(this.message, {this.errorCode});

  @override
  String toString() {
    return errorCode != null
        ? 'StorageException($errorCode): $message'
        : 'StorageException: $message';
  }
}