import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lockbox.dart';
import '../models/shard_data.dart';
import '../models/recovery_request.dart';
import '../models/backup_config.dart';
import '../services/key_service.dart';
import '../services/logger.dart';
import 'key_provider.dart';

/// Stream provider that automatically subscribes to lockbox changes
/// This will emit a new list whenever lockboxes are added, updated, or deleted
final lockboxListProvider = StreamProvider.autoDispose<List<Lockbox>>((ref) {
  final repository = ref.watch(lockboxRepositoryProvider);

  // Return the stream directly and let Riverpod handle the subscription
  return Stream.multi((controller) async {
    // First, load and emit initial data
    try {
      final initialLockboxes = await repository.getAllLockboxes();
      controller.add(initialLockboxes);
    } catch (e) {
      Log.error('Error loading initial lockboxes', e);
      controller.addError(e);
    }

    // Then listen to the repository stream for updates
    final subscription = repository.lockboxesStream.listen(
      (lockboxes) {
        controller.add(lockboxes);
      },
      onError: (error) {
        Log.error('Error in lockboxesStream', error);
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
    );

    // Clean up when the provider is disposed
    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

/// Provider for a specific lockbox by ID
/// This will automatically update when the lockbox changes
final lockboxProvider = StreamProvider.family<Lockbox?, String>((ref, lockboxId) {
  final repository = ref.watch(lockboxRepositoryProvider);

  // Return a stream that:
  // 1. Loads initial data
  // 2. Subscribes to updates from the repository stream
  return Stream.multi((controller) async {
    // First, load and emit initial lockbox
    try {
      final initialLockbox = await repository.getLockbox(lockboxId);
      controller.add(initialLockbox);
    } catch (e) {
      Log.error('Error loading initial lockbox', e);
      controller.addError(e);
    }

    // Then listen to the repository stream for updates
    final subscription = repository.lockboxesStream.listen(
      (lockboxes) {
        try {
          final lockbox = lockboxes.firstWhere((box) => box.id == lockboxId);
          controller.add(lockbox);
        } catch (e) {
          // Lockbox not found in the list (might have been deleted)
          controller.add(null);
        }
      },
      onError: (error) {
        Log.error('Error in lockboxesStream for $lockboxId', error);
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
    );

    // Clean up when the provider is disposed
    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

/// Provider for lockbox repository operations
/// Riverpod automatically ensures this is a singleton - only one instance exists
/// per ProviderScope. The instance is kept alive for the lifetime of the app.
final lockboxRepositoryProvider = Provider<LockboxRepository>((ref) {
  final repository = LockboxRepository(ref.read(keyServiceProvider));

  // Properly clean up when the app is disposed
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

/// Repository class to handle lockbox operations
/// This provides a clean API layer between the UI and the service
class LockboxRepository {
  final KeyService _keyService;
  static const String _lockboxesKey = 'encrypted_lockboxes';
  List<Lockbox>? _cachedLockboxes;
  bool _isInitialized = false;

  // Stream controller for notifying listeners when lockboxes change
  final StreamController<List<Lockbox>> _lockboxesController =
      StreamController<List<Lockbox>>.broadcast();

  // Regular constructor - Riverpod manages the singleton behavior
  LockboxRepository(this._keyService);

  /// Stream that emits the updated list of lockboxes whenever they change
  Stream<List<Lockbox>> get lockboxesStream => _lockboxesController.stream;

  /// Initialize the storage and load existing lockboxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadLockboxes();
      _isInitialized = true;
    } catch (e) {
      Log.error('Error initializing LockboxRepository', e);
      _cachedLockboxes = [];
      _isInitialized = true;
    }
  }

  /// Load lockboxes from SharedPreferences and decrypt them
  Future<void> _loadLockboxes() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_lockboxesKey);
    Log.info('Loading encrypted lockboxes from SharedPreferences');

    if (encryptedData == null || encryptedData.isEmpty) {
      _cachedLockboxes = [];
      Log.info('No encrypted lockboxes found in SharedPreferences');
      return;
    }

    try {
      // Decrypt the data using our Nostr key
      final decryptedJson = await _keyService.decryptText(encryptedData);
      final List<dynamic> jsonList = json.decode(decryptedJson);
      Log.info('Decrypted ${jsonList.length} lockboxes');

      _cachedLockboxes =
          jsonList.map((json) => Lockbox.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      Log.error('Error decrypting lockboxes', e);
      _cachedLockboxes = [];
    }
  }

  /// Save lockboxes to SharedPreferences with encryption
  Future<void> _saveLockboxes() async {
    if (_cachedLockboxes == null) return;

    try {
      Log.debug('Starting to save ${_cachedLockboxes!.length} lockboxes');

      // Convert to JSON with detailed error tracking
      final jsonList = <Map<String, dynamic>>[];
      for (var i = 0; i < _cachedLockboxes!.length; i++) {
        final lockbox = _cachedLockboxes![i];
        Log.debug('Converting lockbox $i (id: ${lockbox.id}) to JSON');
        Log.debug('  - Name: ${lockbox.name}');
        Log.debug('  - Owner: ${lockbox.ownerPubkey}');
        Log.debug('  - Shards count: ${lockbox.shards.length}');
        Log.debug('  - Recovery requests count: ${lockbox.recoveryRequests.length}');

        try {
          final lockboxJson = lockbox.toJson();
          jsonList.add(lockboxJson);
          Log.debug('  ✓ Lockbox $i converted successfully');
        } catch (e) {
          Log.error('  ✗ Error converting lockbox $i to JSON', e);

          // Try to identify which recovery request is causing the issue
          for (var j = 0; j < lockbox.recoveryRequests.length; j++) {
            final request = lockbox.recoveryRequests[j];
            Log.debug('    - Recovery request $j: id=${request.id}, status=${request.status.name}');
            Log.debug('      keyHolderResponses count: ${request.keyHolderResponses.length}');

            // Check each response
            for (var entry in request.keyHolderResponses.entries) {
              final pubkey = entry.key;
              final response = entry.value;
              Log.debug(
                  '        Response from ${pubkey.substring(0, 8)}: approved=${response.approved}, shardData=${response.shardData != null ? "present" : "null"}');

              if (response.shardData != null) {
                final shard = response.shardData!;
                Log.debug('          ShardData details:');
                Log.debug('            shard type: ${shard.shard.runtimeType}');
                Log.debug('            threshold type: ${shard.threshold.runtimeType}');
                Log.debug('            shardIndex type: ${shard.shardIndex.runtimeType}');
                Log.debug('            totalShards type: ${shard.totalShards.runtimeType}');
                Log.debug('            primeMod type: ${shard.primeMod.runtimeType}');
                Log.debug('            creatorPubkey type: ${shard.creatorPubkey.runtimeType}');
                Log.debug('            createdAt type: ${shard.createdAt.runtimeType}');
                Log.debug(
                    '            lockboxId: ${shard.lockboxId} (type: ${shard.lockboxId?.runtimeType})');
                Log.debug(
                    '            lockboxName: ${shard.lockboxName} (type: ${shard.lockboxName?.runtimeType})');
                Log.debug('            peers: ${shard.peers} (type: ${shard.peers?.runtimeType})');
                Log.debug(
                    '            recipientPubkey: ${shard.recipientPubkey} (type: ${shard.recipientPubkey?.runtimeType})');
                Log.debug(
                    '            nostrEventId: ${shard.nostrEventId} (type: ${shard.nostrEventId?.runtimeType})');
              }
            }
          }
          rethrow;
        }
      }

      Log.debug('All lockboxes converted to JSON, encoding...');
      final jsonString = json.encode(jsonList);
      Log.debug('JSON encoded successfully (${jsonString.length} characters)');

      // Encrypt the JSON data using our Nostr key
      final encryptedData = await _keyService.encryptText(jsonString);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lockboxesKey, encryptedData);
      Log.info('Saved ${jsonList.length} encrypted lockboxes to SharedPreferences');

      // Notify listeners that lockboxes have changed
      final lockboxesList = List<Lockbox>.unmodifiable(_cachedLockboxes!);
      _lockboxesController.add(lockboxesList);
    } catch (e) {
      Log.error('Error encrypting and saving lockboxes', e);
      throw Exception('Failed to save lockboxes: $e');
    }
  }

  /// Get all lockboxes
  Future<List<Lockbox>> getAllLockboxes() async {
    await initialize();
    return List.unmodifiable(_cachedLockboxes ?? []);
  }

  /// Get a specific lockbox by ID
  Future<Lockbox?> getLockbox(String id) async {
    await initialize();
    try {
      return _cachedLockboxes!.firstWhere((lb) => lb.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save a lockbox (add new or update existing)
  Future<void> saveLockbox(Lockbox lockbox) async {
    await initialize();

    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == lockbox.id);
    if (index == -1) {
      // Add new lockbox
      _cachedLockboxes!.add(lockbox);
    } else {
      // Update existing lockbox
      _cachedLockboxes![index] = lockbox;
    }

    await _saveLockboxes();
  }

  /// Add a new lockbox
  Future<void> addLockbox(Lockbox lockbox) async {
    await initialize();
    _cachedLockboxes!.add(lockbox);
    await _saveLockboxes();
  }

  /// Update an existing lockbox
  Future<void> updateLockbox(String id, String name, String content) async {
    await initialize();
    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == id);
    if (index != -1) {
      final existingLockbox = _cachedLockboxes![index];
      _cachedLockboxes![index] = existingLockbox.copyWith(
        name: name,
        content: content,
      );
      await _saveLockboxes();
    }
  }

  /// Delete a lockbox
  Future<void> deleteLockbox(String id) async {
    await initialize();
    _cachedLockboxes!.removeWhere((lb) => lb.id == id);
    await _saveLockboxes();
  }

  /// Clear all lockboxes (for testing/debugging)
  Future<void> clearAll() async {
    _cachedLockboxes = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockboxesKey);
    _isInitialized = false;
  }

  /// Refresh lockboxes from storage
  Future<void> refresh() async {
    _isInitialized = false;
    _cachedLockboxes = null;
    await initialize();
  }

  // ========== Backup Config Operations ==========

  /// Update backup configuration for a lockbox
  Future<void> updateBackupConfig(String lockboxId, BackupConfig config) async {
    await initialize();

    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == lockboxId);
    if (index == -1) {
      throw ArgumentError('Lockbox not found: $lockboxId');
    }

    final lockbox = _cachedLockboxes![index];
    _cachedLockboxes![index] = lockbox.copyWith(backupConfig: config);
    await _saveLockboxes();
    Log.info('Updated backup configuration for lockbox $lockboxId');
  }

  /// Get backup configuration for a lockbox
  Future<BackupConfig?> getBackupConfig(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return lockbox.backupConfig;
  }

  // ========== Shard Management Methods ==========

  /// Add a shard to a lockbox (supports multiple shards during recovery)
  Future<void> addShardToLockbox(String lockboxId, ShardData shard) async {
    await initialize();

    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == lockboxId);
    if (index == -1) {
      throw ArgumentError('Lockbox not found: $lockboxId');
    }

    final lockbox = _cachedLockboxes![index];
    final updatedShards = List<ShardData>.from(lockbox.shards)..add(shard);

    _cachedLockboxes![index] = lockbox.copyWith(shards: updatedShards);
    await _saveLockboxes();
    Log.info('Added shard to lockbox $lockboxId (total shards: ${updatedShards.length})');
  }

  /// Get all shards for a lockbox
  Future<List<ShardData>> getShardsForLockbox(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return List.unmodifiable(lockbox.shards);
  }

  /// Clear all shards for a lockbox
  Future<void> clearShardsForLockbox(String lockboxId) async {
    await initialize();

    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == lockboxId);
    if (index == -1) {
      throw ArgumentError('Lockbox not found: $lockboxId');
    }

    _cachedLockboxes![index] = _cachedLockboxes![index].copyWith(shards: []);
    await _saveLockboxes();
    Log.info('Cleared all shards for lockbox $lockboxId');
  }

  /// Check if we are a key holder for a lockbox (have any shards)
  Future<bool> isKeyHolderForLockbox(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return lockbox.isKeyHolder;
  }

  // ========== Recovery Request Management Methods ==========

  /// Add a recovery request to a lockbox
  Future<void> addRecoveryRequestToLockbox(
    String lockboxId,
    RecoveryRequest request,
  ) async {
    await initialize();

    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == lockboxId);
    if (index == -1) {
      throw ArgumentError('Lockbox not found: $lockboxId');
    }

    final lockbox = _cachedLockboxes![index];
    final updatedRequests = List<RecoveryRequest>.from(lockbox.recoveryRequests)..add(request);

    _cachedLockboxes![index] = lockbox.copyWith(recoveryRequests: updatedRequests);
    await _saveLockboxes();
    Log.info('Added recovery request ${request.id} to lockbox $lockboxId');
  }

  /// Update a recovery request in a lockbox
  Future<void> updateRecoveryRequestInLockbox(
    String lockboxId,
    String requestId,
    RecoveryRequest updatedRequest,
  ) async {
    await initialize();

    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == lockboxId);
    if (index == -1) {
      throw ArgumentError('Lockbox not found: $lockboxId');
    }

    final lockbox = _cachedLockboxes![index];
    final requestIndex = lockbox.recoveryRequests.indexWhere((r) => r.id == requestId);

    if (requestIndex == -1) {
      throw ArgumentError('Recovery request not found: $requestId');
    }

    final updatedRequests = List<RecoveryRequest>.from(lockbox.recoveryRequests);
    updatedRequests[requestIndex] = updatedRequest;

    _cachedLockboxes![index] = lockbox.copyWith(recoveryRequests: updatedRequests);
    await _saveLockboxes();
    Log.info('Updated recovery request $requestId in lockbox $lockboxId');
  }

  /// Get all recovery requests for a lockbox
  Future<List<RecoveryRequest>> getRecoveryRequestsForLockbox(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return List.unmodifiable(lockbox.recoveryRequests);
  }

  /// Get the active recovery request for a lockbox (if any)
  Future<RecoveryRequest?> getActiveRecoveryRequest(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return lockbox.activeRecoveryRequest;
  }

  /// Get all recovery requests across all lockboxes
  Future<List<RecoveryRequest>> getAllRecoveryRequests() async {
    await initialize();

    final allRequests = <RecoveryRequest>[];
    for (final lockbox in _cachedLockboxes!) {
      allRequests.addAll(lockbox.recoveryRequests);
    }

    return allRequests;
  }

  /// Dispose resources
  void dispose() {
    _lockboxesController.close();
  }
}
