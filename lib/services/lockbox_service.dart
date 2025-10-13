import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lockbox.dart';
import '../models/shard_data.dart';
import '../models/recovery_request.dart';
import 'key_service.dart';
import 'logger.dart';

/// Service for managing persistent, encrypted lockbox storage
class LockboxService {
  static const String _lockboxesKey = 'encrypted_lockboxes';
  static List<Lockbox>? _cachedLockboxes;
  static bool _isInitialized = false;

  // Stream controller for notifying listeners when lockboxes change
  static final StreamController<List<Lockbox>> _lockboxesController =
      StreamController<List<Lockbox>>.broadcast();

  /// Stream that emits the updated list of lockboxes whenever they change
  static Stream<List<Lockbox>> get lockboxesStream => _lockboxesController.stream;

  /// Initialize the storage and load existing lockboxes
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadLockboxes();

      // If no lockboxes exist, create some sample data for first-time users
      // if (_cachedLockboxes!.isEmpty && !_disableSampleDataForTest) {
      //   await _createSampleData();
      // }

      _isInitialized = true;
    } catch (e) {
      Log.error('Error initializing LockboxService', e);
      _cachedLockboxes = [];
      _isInitialized = true;
    }
  }

  /// Load lockboxes from SharedPreferences and decrypt them
  static Future<void> _loadLockboxes() async {
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
      final decryptedJson = await KeyService.decryptText(encryptedData);
      final List<dynamic> jsonList = json.decode(decryptedJson);
      Log.info('Decrypted ${jsonList.length} lockboxes');

      // TODO: Don't cache these decrypted in memory
      _cachedLockboxes =
          jsonList.map((json) => Lockbox.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      Log.error('Error decrypting lockboxes', e);
      _cachedLockboxes = [];
    }
  }

  /// Save lockboxes to SharedPreferences with encryption
  static Future<void> _saveLockboxes() async {
    if (_cachedLockboxes == null) return;

    try {
      // Convert to JSON
      final jsonList = _cachedLockboxes!.map((lockbox) => lockbox.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // Encrypt the JSON data using our Nostr key
      final encryptedData = await KeyService.encryptText(jsonString);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lockboxesKey, encryptedData);
      Log.info('Saved ${jsonList.length} encrypted lockboxes to SharedPreferences');

      // Notify listeners that lockboxes have changed
      _lockboxesController.add(List.unmodifiable(_cachedLockboxes!));
    } catch (e) {
      Log.error('Error encrypting and saving lockboxes', e);
      throw Exception('Failed to save lockboxes: $e');
    }
  }

  /// Get all lockboxes
  static Future<List<Lockbox>> getAllLockboxes() async {
    await initialize();
    return List.unmodifiable(_cachedLockboxes ?? []);
  }

  /// Add a new lockbox
  static Future<void> addLockbox(Lockbox lockbox) async {
    await initialize();
    _cachedLockboxes!.add(lockbox);
    await _saveLockboxes();
  }

  /// Update an existing lockbox
  static Future<void> updateLockbox(String id, String name, String content) async {
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
  static Future<void> deleteLockbox(String id) async {
    await initialize();
    _cachedLockboxes!.removeWhere((lb) => lb.id == id);
    await _saveLockboxes();
  }

  /// Get a specific lockbox by ID
  static Future<Lockbox?> getLockbox(String id) async {
    await initialize();
    try {
      return _cachedLockboxes!.firstWhere((lb) => lb.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== Shard Management Methods ==========

  /// Add a shard to a lockbox (supports multiple shards during recovery)
  static Future<void> addShardToLockbox(String lockboxId, ShardData shard) async {
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
  static Future<List<ShardData>> getShardsForLockbox(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return List.unmodifiable(lockbox.shards);
  }

  /// Clear all shards for a lockbox
  static Future<void> clearShardsForLockbox(String lockboxId) async {
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
  static Future<bool> isKeyHolderForLockbox(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return lockbox.isKeyHolder;
  }

  // ========== Recovery Request Management Methods ==========

  /// Add a recovery request to a lockbox
  static Future<void> addRecoveryRequestToLockbox(
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
  static Future<void> updateRecoveryRequestInLockbox(
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
  static Future<List<RecoveryRequest>> getRecoveryRequestsForLockbox(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return List.unmodifiable(lockbox.recoveryRequests);
  }

  /// Get the active recovery request for a lockbox (if any)
  static Future<RecoveryRequest?> getActiveRecoveryRequest(String lockboxId) async {
    await initialize();

    final lockbox = _cachedLockboxes!.firstWhere(
      (lb) => lb.id == lockboxId,
      orElse: () => throw ArgumentError('Lockbox not found: $lockboxId'),
    );

    return lockbox.activeRecoveryRequest;
  }

  /// Get all recovery requests across all lockboxes
  static Future<List<RecoveryRequest>> getAllRecoveryRequests() async {
    await initialize();

    final allRequests = <RecoveryRequest>[];
    for (final lockbox in _cachedLockboxes!) {
      allRequests.addAll(lockbox.recoveryRequests);
    }

    return allRequests;
  }

  /// Clear all lockboxes (for testing)
  static Future<void> clearAll() async {
    _cachedLockboxes = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockboxesKey);
    _isInitialized = false;
  }

  /// Refresh the cached data from storage
  static Future<void> refresh() async {
    _isInitialized = false;
    _cachedLockboxes = null;
    await initialize();
  }
}
