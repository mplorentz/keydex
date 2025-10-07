import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shard_data.dart';
import '../models/lockbox.dart';
import 'lockbox_service.dart';
import 'logger.dart';

/// Service for managing lockbox shares and recovery operations
class LockboxShareService {
  static const String _shardDataKey = 'lockbox_shard_data';
  static Map<String, List<ShardData>>? _cachedShardData; // lockboxId -> List<ShardData>
  static bool _isInitialized = false;

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadShardData();
      _isInitialized = true;
      Log.info('LockboxShareService initialized with ${_cachedShardData?.length ?? 0} lockboxes');
    } catch (e) {
      Log.error('Error initializing LockboxShareService', e);
      _cachedShardData = {};
      _isInitialized = true;
    }
  }

  /// Load shard data from storage
  static Future<void> _loadShardData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_shardDataKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedShardData = {};
      return;
    }

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonData);
      _cachedShardData = jsonMap.map((lockboxId, shardListJson) {
        final shardList = (shardListJson as List<dynamic>)
            .map((json) => shardDataFromJson(json as Map<String, dynamic>))
            .toList();
        return MapEntry(lockboxId, shardList);
      });
      Log.info('Loaded shard data for ${_cachedShardData!.length} lockboxes from storage');
    } catch (e) {
      Log.error('Error loading shard data', e);
      _cachedShardData = {};
    }
  }

  /// Save shard data to storage
  static Future<void> _saveShardData() async {
    if (_cachedShardData == null) return;

    try {
      final jsonMap = _cachedShardData!.map((lockboxId, shardList) {
        final shardListJson = shardList.map((shard) => shardDataToJson(shard)).toList();
        return MapEntry(lockboxId, shardListJson);
      });
      final jsonString = json.encode(jsonMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_shardDataKey, jsonString);
      Log.info('Saved shard data for ${_cachedShardData!.length} lockboxes to storage');
    } catch (e) {
      Log.error('Error saving shard data', e);
      throw Exception('Failed to save shard data: $e');
    }
  }

  /// Get all shares for a lockbox
  static Future<List<ShardData>> getLockboxShares(String lockboxId) async {
    await initialize();

    final shards = _cachedShardData![lockboxId];
    if (shards == null) return [];

    return List.unmodifiable(shards);
  }

  /// Get a specific share by nostr event ID
  static Future<ShardData?> getLockboxShare(String nostrEventId) async {
    await initialize();

    for (final shardList in _cachedShardData!.values) {
      try {
        final shard = shardList.firstWhere((s) => s.nostrEventId == nostrEventId);
        return shard;
      } catch (e) {
        // Continue searching
      }
    }

    return null;
  }

  /// Add or update shard data for a lockbox
  static Future<void> addLockboxShare(String lockboxId, ShardData shardData) async {
    await initialize();

    // Validate shard data
    if (!shardData.isValid) {
      throw ArgumentError('Invalid shard data');
    }

    // Get existing shards for this lockbox
    final existingShards = _cachedShardData![lockboxId] ?? [];

    // Check if shard with this nostrEventId already exists (since we removed id field)
    final existingIndex = existingShards.indexWhere(
      (s) => s.nostrEventId != null && s.nostrEventId == shardData.nostrEventId,
    );
    if (existingIndex != -1) {
      // Update existing shard
      existingShards[existingIndex] = shardData;
      Log.info('Updated shard for lockbox $lockboxId (event: ${shardData.nostrEventId})');
    } else {
      // Add new shard
      existingShards.add(shardData);
      Log.info('Added shard for lockbox $lockboxId (event: ${shardData.nostrEventId})');
    }

    _cachedShardData![lockboxId] = existingShards;
    await _saveShardData();

    // Create a lockbox record if one doesn't exist yet
    await _ensureLockboxExists(lockboxId, shardData);
  }

  /// Ensure a lockbox record exists for received shares
  static Future<void> _ensureLockboxExists(String lockboxId, ShardData shardData) async {
    try {
      // Check if lockbox already exists
      final existingLockbox = await LockboxService.getLockbox(lockboxId);
      if (existingLockbox != null) {
        Log.info('Lockbox $lockboxId already exists');
        return;
      }

      // Create a new lockbox entry for the shared key
      final lockboxName = shardData.lockboxName ?? 'Shared Lockbox';
      final content =
          '[Encrypted - Need ${shardData.threshold} of ${shardData.totalShards} keys to recover]';

      final lockbox = Lockbox(
        id: lockboxId,
        name: lockboxName,
        content: content,
        createdAt: DateTime.fromMillisecondsSinceEpoch(shardData.createdAt * 1000),
      );

      await LockboxService.addLockbox(lockbox);
      Log.info('Created lockbox record for shared key: $lockboxId ($lockboxName)');
    } catch (e) {
      Log.error('Error creating lockbox record for $lockboxId', e);
      // Don't throw - we don't want to fail shard storage just because lockbox creation failed
    }
  }

  /// Mark a share as received
  static Future<void> markShareAsReceived(
    String nostrEventId,
  ) async {
    await initialize();

    bool found = false;
    for (final entry in _cachedShardData!.entries) {
      final lockboxId = entry.key;
      final shardList = entry.value;

      for (int i = 0; i < shardList.length; i++) {
        if (shardList[i].nostrEventId == nostrEventId) {
          // Update shard data with received information
          final updatedShard = copyShardData(
            shardList[i],
            isReceived: true,
            receivedAt: DateTime.now(),
          );

          shardList[i] = updatedShard;
          _cachedShardData![lockboxId] = shardList;
          found = true;
          break;
        }
      }

      if (found) break;
    }

    if (!found) {
      throw ArgumentError('Share not found with nostr event ID: $nostrEventId');
    }

    await _saveShardData();
    Log.info('Marked share as received (event: $nostrEventId)');
  }

  /// Reassemble lockbox content from collected shares
  static Future<String?> reassembleLockboxContent(String lockboxId) async {
    await initialize();

    final shards = await getLockboxShares(lockboxId);
    if (shards.isEmpty) {
      Log.warning('No shards found for lockbox $lockboxId');
      return null;
    }

    // Check if we have sufficient shards
    final threshold = shards.first.threshold;
    if (shards.length < threshold) {
      Log.warning('Insufficient shards for lockbox $lockboxId: ${shards.length}/$threshold');
      return null;
    }

    try {
      // TODO: Implement actual Shamir's Secret Sharing reconstruction
      // For now, this is a placeholder that returns a mock result
      Log.info('Reassembling lockbox content from ${shards.length} shards (threshold: $threshold)');

      // In a real implementation, this would:
      // 1. Extract the shard values from each ShardData
      // 2. Use the prime modulus for finite field arithmetic
      // 3. Apply Lagrange interpolation to reconstruct the secret
      // 4. Decode the secret back to the original content

      // Placeholder implementation
      const reconstructedContent = 'RECONSTRUCTED_CONTENT_FROM_SHARDS';

      Log.info('Successfully reassembled lockbox content for $lockboxId');
      return reconstructedContent;
    } catch (e) {
      Log.error('Error reassembling lockbox content for $lockboxId', e);
      return null;
    }
  }

  /// Check if sufficient shares are available for recovery
  static Future<bool> hasSufficientShares(String lockboxId, int threshold) async {
    await initialize();

    final shards = await getLockboxShares(lockboxId);
    return shards.length >= threshold;
  }

  /// Get shard data collected for a recovery request
  static Future<List<ShardData>> getCollectedShardData(String recoveryRequestId) async {
    await initialize();

    final collectedShards = <ShardData>[];

    // Search through all shard data for shards associated with this recovery request
    for (final shardList in _cachedShardData!.values) {
      for (final shard in shardList) {
        // In a real implementation, we would track which shards belong to which recovery request
        // For now, we return shards that have been received
        if (shard.isReceived == true) {
          collectedShards.add(shard);
        }
      }
    }

    return collectedShards;
  }

  /// Get all lockboxes that have shares (indicating key holder status)
  static Future<List<String>> getLockboxesWithShares() async {
    await initialize();
    return _cachedShardData!.keys.toList();
  }

  /// Check if user is a key holder for a lockbox
  static Future<bool> isKeyHolderForLockbox(String lockboxId) async {
    await initialize();
    final shards = await getLockboxShares(lockboxId);
    return shards.isNotEmpty;
  }

  /// Get shard count for a lockbox
  static Future<int> getShardCount(String lockboxId) async {
    await initialize();
    final shards = await getLockboxShares(lockboxId);
    return shards.length;
  }

  /// Remove all shards for a lockbox
  static Future<void> removeLockboxShares(String lockboxId) async {
    await initialize();

    if (_cachedShardData!.containsKey(lockboxId)) {
      _cachedShardData!.remove(lockboxId);
      await _saveShardData();
      Log.info('Removed all shards for lockbox $lockboxId');
    }
  }

  /// Remove a specific shard by nostr event ID
  static Future<void> removeLockboxShare(String nostrEventId) async {
    await initialize();

    bool found = false;
    for (final entry in _cachedShardData!.entries) {
      final lockboxId = entry.key;
      final shardList = entry.value;

      final initialLength = shardList.length;
      shardList.removeWhere((s) => s.nostrEventId == nostrEventId);

      if (shardList.length < initialLength) {
        _cachedShardData![lockboxId] = shardList;
        found = true;
        break;
      }
    }

    if (!found) {
      throw ArgumentError('Share not found with nostr event ID: $nostrEventId');
    }

    await _saveShardData();
    Log.info('Removed share (event: $nostrEventId)');
  }

  /// Get total shard count across all lockboxes
  static Future<int> getTotalShardCount() async {
    await initialize();

    int total = 0;
    for (final shardList in _cachedShardData!.values) {
      total += shardList.length;
    }
    return total;
  }

  /// Clear all shard data (for testing)
  static Future<void> clearAll() async {
    _cachedShardData = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shardDataKey);
    _isInitialized = false;
    Log.info('Cleared all shard data');
  }

  /// Refresh the cached data from storage
  static Future<void> refresh() async {
    _isInitialized = false;
    _cachedShardData = null;
    await initialize();
  }
}
