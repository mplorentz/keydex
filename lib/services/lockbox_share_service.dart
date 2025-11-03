import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shard_data.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import 'logger.dart';

/// Provider for LockboxShareService
/// This service depends on LockboxRepository for shard management
final lockboxShareServiceProvider = Provider<LockboxShareService>((ref) {
  final repository = ref.watch(lockboxRepositoryProvider);
  return LockboxShareService(repository);
});

/// Service for managing lockbox shares and recovery operations
///
/// Manages two types of shards:
/// 1. Key holder shards: Shards we hold as a key holder for others (one per lockbox)
/// 2. Recovery shards: Shards we collect during recovery (multiple per recovery request)
class LockboxShareService {
  final LockboxRepository repository;

  LockboxShareService(this.repository);
  static const String _shardDataKey = 'lockbox_shard_data';
  static const String _recoveryShardDataKey = 'recovery_shard_data';

  // Shards we hold as a key holder (one per lockbox)
  static Map<String, ShardData>? _cachedShardData; // lockboxId -> ShardData

  // Shards collected during recovery (multiple per recovery request)
  static Map<String, List<ShardData>>?
      _cachedRecoveryShards; // recoveryRequestId -> List<ShardData>

  static bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadShardData();
      await _loadRecoveryShardData();
      _isInitialized = true;
      Log.info(
          'LockboxShareService initialized with ${_cachedShardData?.length ?? 0} key holder shards and ${_cachedRecoveryShards?.length ?? 0} recovery requests');
    } catch (e) {
      Log.error('Error initializing LockboxShareService', e);
      _cachedShardData = {};
      _cachedRecoveryShards = {};
      _isInitialized = true;
    }
  }

  /// Load shard data from storage
  Future<void> _loadShardData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_shardDataKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedShardData = {};
      return;
    }

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonData);
      _cachedShardData = jsonMap.map((lockboxId, shardJson) {
        final shard = shardDataFromJson(shardJson as Map<String, dynamic>);
        return MapEntry(lockboxId, shard);
      });
      Log.info('Loaded shard data for ${_cachedShardData!.length} lockboxes from storage');
    } catch (e) {
      Log.error('Error loading shard data', e);
      _cachedShardData = {};
    }
  }

  /// Save shard data to storage
  Future<void> _saveShardData() async {
    if (_cachedShardData == null) return;

    try {
      final jsonMap = _cachedShardData!.map((lockboxId, shard) {
        final shardJson = shardDataToJson(shard);
        return MapEntry(lockboxId, shardJson);
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

  /// Load recovery shard data from storage
  Future<void> _loadRecoveryShardData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_recoveryShardDataKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedRecoveryShards = {};
      return;
    }

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonData);
      _cachedRecoveryShards = jsonMap.map((recoveryRequestId, shardListJson) {
        final shardList = (shardListJson as List<dynamic>)
            .map((json) => shardDataFromJson(json as Map<String, dynamic>))
            .toList();
        return MapEntry(recoveryRequestId, shardList);
      });
      Log.info(
          'Loaded recovery shards for ${_cachedRecoveryShards!.length} recovery requests from storage');
    } catch (e) {
      Log.error('Error loading recovery shard data', e);
      _cachedRecoveryShards = {};
    }
  }

  /// Save recovery shard data to storage
  Future<void> _saveRecoveryShardData() async {
    if (_cachedRecoveryShards == null) return;

    try {
      final jsonMap = _cachedRecoveryShards!.map((recoveryRequestId, shardList) {
        final shardListJson = shardList.map((shard) => shardDataToJson(shard)).toList();
        return MapEntry(recoveryRequestId, shardListJson);
      });
      final jsonString = json.encode(jsonMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recoveryShardDataKey, jsonString);
      Log.info(
          'Saved recovery shards for ${_cachedRecoveryShards!.length} recovery requests to storage');
    } catch (e) {
      Log.error('Error saving recovery shard data', e);
      throw Exception('Failed to save recovery shard data: $e');
    }
  }

  /// Get all shares for a lockbox
  /// Now delegates to LockboxService
  Future<List<ShardData>> getLockboxShares(String lockboxId) async {
    return await repository.getShardsForLockbox(lockboxId);
  }

  /// Get the share for a lockbox (returns first shard if multiple exist)
  /// Now delegates to LockboxRepository
  Future<ShardData?> getLockboxShare(String lockboxId) async {
    final shards = await repository.getShardsForLockbox(lockboxId);
    return shards.isNotEmpty ? shards.first : null;
  }

  /// Get a specific share by nostr event ID
  Future<ShardData?> getShareByEventId(String nostrEventId) async {
    await initialize();

    for (final shard in _cachedShardData!.values) {
      if (shard.nostrEventId == nostrEventId) {
        return shard;
      }
    }

    return null;
  }

  /// Add or update shard data for a lockbox
  /// Now delegates to LockboxService
  Future<void> addLockboxShare(String lockboxId, ShardData shardData) async {
    // Validate shard data
    if (!shardData.isValid) {
      throw ArgumentError('Invalid shard data');
    }

    // Create a lockbox record if one doesn't exist yet
    await _ensureLockboxExists(lockboxId, shardData);

    // Add shard to lockbox via LockboxService
    await repository.addShardToLockbox(lockboxId, shardData);
    Log.info('Added shard for lockbox $lockboxId (event: ${shardData.nostrEventId})');
  }

  /// Ensure a lockbox record exists for received shares
  Future<void> _ensureLockboxExists(String lockboxId, ShardData shardData) async {
    try {
      // Check if lockbox already exists
      final existingLockbox = await repository.getLockbox(lockboxId);
      if (existingLockbox != null) {
        // Lockbox exists - check if it's a stub (no shards, no content)
        // If stub, update it with shard data
        if (existingLockbox.shards.isEmpty && existingLockbox.content == null) {
          // This is a stub lockbox created when invitation was accepted
          // Update it with shard data and name from ShardData if available
          final updatedLockbox = existingLockbox.copyWith(
            name: shardData.lockboxName ?? existingLockbox.name,
            // createdAt stays the same (from invitation)
            // ownerPubkey stays the same (from invitation)
            // shards will be added via addShardToLockbox below
          );
          await repository.saveLockbox(updatedLockbox);
          Log.info('Updated stub lockbox $lockboxId with shard data');
        } else {
          Log.info('Lockbox $lockboxId already exists with shards/content');
        }
        return;
      }

      // Create a new lockbox entry for the shared key
      final lockboxName = shardData.lockboxName ?? 'Shared Lockbox';

      final lockbox = Lockbox(
        id: lockboxId,
        name: lockboxName,
        content: null, // No decrypted content yet - we only have a shard
        createdAt: DateTime.fromMillisecondsSinceEpoch(shardData.createdAt * 1000),
        ownerPubkey: shardData.creatorPubkey, // Owner is the creator of the shard
      );

      await repository.addLockbox(lockbox);
      Log.info('Created lockbox record for shared key: $lockboxId ($lockboxName)');
    } catch (e) {
      Log.error('Error creating lockbox record for $lockboxId', e);
      // Don't throw - we don't want to fail shard storage just because lockbox creation failed
    }
  }

  /// Mark a share as received
  Future<void> markShareAsReceived(String lockboxId) async {
    await initialize();

    final shard = _cachedShardData![lockboxId];
    if (shard == null) {
      throw ArgumentError('No share found for lockbox: $lockboxId');
    }

    // Update shard data with received information
    final updatedShard = copyShardData(
      shard,
      isReceived: true,
      receivedAt: DateTime.now(),
    );

    _cachedShardData![lockboxId] = updatedShard;
    await _saveShardData();
    Log.info('Marked share as received for lockbox $lockboxId (event: ${shard.nostrEventId})');
  }

  /// Mark a share as received by event ID
  Future<void> markShareAsReceivedByEventId(String nostrEventId) async {
    await initialize();

    for (final entry in _cachedShardData!.entries) {
      if (entry.value.nostrEventId == nostrEventId) {
        await markShareAsReceived(entry.key);
        return;
      }
    }

    throw ArgumentError('Share not found with nostr event ID: $nostrEventId');
  }

  /// Reassemble lockbox content from collected shares
  /// Note: This service now only stores a single shard per lockbox.
  /// For full recovery, you need to collect shards from multiple key holders.
  Future<String?> reassembleLockboxContent(String lockboxId) async {
    await initialize();

    final shard = _cachedShardData![lockboxId];
    if (shard == null) {
      Log.warning('No shard found for lockbox $lockboxId');
      return null;
    }

    Log.warning(
        'Cannot reassemble from single shard - need ${shard.threshold} shards from recovery process');
    return null;
  }

  /// Check if we have a shard for this lockbox
  /// Note: This returns true if we have ANY shard, but doesn't indicate if we have sufficient shards for recovery
  Future<bool> hasShard(String lockboxId) async {
    await initialize();
    return _cachedShardData!.containsKey(lockboxId);
  }

  /// Get all collected shard data (returns all shards we hold as a key holder)
  Future<List<ShardData>> getAllCollectedShards() async {
    await initialize();
    return _cachedShardData!.values.toList();
  }

  /// Get all lockboxes that have shares (indicating key holder status)
  Future<List<String>> getLockboxesWithShares() async {
    await initialize();
    return _cachedShardData!.keys.toList();
  }

  /// Check if user is a key holder for a lockbox
  /// Now delegates to LockboxService
  Future<bool> isKeyHolderForLockbox(String lockboxId) async {
    return await repository.isKeyHolderForLockbox(lockboxId);
  }

  /// Get shard count for a lockbox
  /// Now delegates to LockboxService
  Future<int> getShardCount(String lockboxId) async {
    final shards = await repository.getShardsForLockbox(lockboxId);
    return shards.length;
  }

  /// Remove shard for a lockbox
  /// Now delegates to LockboxService
  Future<void> removeLockboxShare(String lockboxId) async {
    await repository.clearShardsForLockbox(lockboxId);
    Log.info('Removed all shards for lockbox $lockboxId');
  }

  /// Remove a specific shard by nostr event ID
  Future<void> removeShareByEventId(String nostrEventId) async {
    await initialize();

    for (final entry in _cachedShardData!.entries) {
      if (entry.value.nostrEventId == nostrEventId) {
        await removeLockboxShare(entry.key);
        return;
      }
    }

    throw ArgumentError('Share not found with nostr event ID: $nostrEventId');
  }

  /// Get total shard count across all lockboxes (equals number of lockboxes we're a key holder for)
  Future<int> getTotalShardCount() async {
    await initialize();
    return _cachedShardData!.length;
  }

  // ========== Recovery Shard Methods ==========
  // These methods manage shards collected during recovery

  /// Add a recovery shard (for recovery initiator collecting shards from key holders)
  Future<void> addRecoveryShard(String recoveryRequestId, ShardData shardData) async {
    await initialize();

    // Validate shard data
    if (!shardData.isValid) {
      throw ArgumentError('Invalid shard data');
    }

    // Get existing shards for this recovery request
    final existingShards = _cachedRecoveryShards![recoveryRequestId] ?? [];

    // Check if shard with this nostrEventId already exists
    final existingIndex = existingShards.indexWhere(
      (s) => s.nostrEventId != null && s.nostrEventId == shardData.nostrEventId,
    );

    if (existingIndex != -1) {
      // Update existing shard
      existingShards[existingIndex] = shardData;
      Log.info(
          'Updated recovery shard for request $recoveryRequestId (event: ${shardData.nostrEventId})');
    } else {
      // Add new shard
      existingShards.add(shardData);
      Log.info(
          'Added recovery shard for request $recoveryRequestId (event: ${shardData.nostrEventId}, total: ${existingShards.length})');
    }

    _cachedRecoveryShards![recoveryRequestId] = existingShards;
    await _saveRecoveryShardData();
  }

  /// Get all recovery shards for a recovery request
  Future<List<ShardData>> getRecoveryShards(String recoveryRequestId) async {
    await initialize();

    final shards = _cachedRecoveryShards![recoveryRequestId];
    if (shards == null) return [];

    return List.unmodifiable(shards);
  }

  /// Get recovery shard count for a recovery request
  Future<int> getRecoveryShardCount(String recoveryRequestId) async {
    await initialize();

    final shards = _cachedRecoveryShards![recoveryRequestId];
    return shards?.length ?? 0;
  }

  /// Check if we have sufficient recovery shards for a recovery request
  Future<bool> hasSufficientRecoveryShards(String recoveryRequestId, int threshold) async {
    await initialize();

    final shards = _cachedRecoveryShards![recoveryRequestId];
    return (shards?.length ?? 0) >= threshold;
  }

  /// Remove all recovery shards for a recovery request
  Future<void> removeRecoveryShards(String recoveryRequestId) async {
    await initialize();

    if (_cachedRecoveryShards!.containsKey(recoveryRequestId)) {
      final count = _cachedRecoveryShards![recoveryRequestId]!.length;
      _cachedRecoveryShards!.remove(recoveryRequestId);
      await _saveRecoveryShardData();
      Log.info('Removed $count recovery shards for request $recoveryRequestId');
    }
  }

  /// Clear all shard data (for testing)
  Future<void> clearAll() async {
    _cachedShardData = {};
    _cachedRecoveryShards = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shardDataKey);
    await prefs.remove(_recoveryShardDataKey);
    _isInitialized = false;
    Log.info('Cleared all shard data and recovery shards');
  }

  /// Refresh the cached data from storage
  Future<void> refresh() async {
    _isInitialized = false;
    _cachedShardData = null;
    _cachedRecoveryShards = null;
    await initialize();
  }
}
