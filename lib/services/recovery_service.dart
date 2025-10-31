import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ndk/ndk.dart';
import '../models/nostr_kinds.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart';
import '../models/shard_data.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import 'key_service.dart';
import 'backup_service.dart';
import 'logger.dart';

/// Provider for RecoveryService
/// This service depends on LockboxRepository for recovery operations
final recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final repository = ref.watch(lockboxRepositoryProvider);
  final backupService = ref.read(backupServiceProvider);
  final keyService = ref.read(keyServiceProvider);
  final service = RecoveryService(repository, backupService, keyService);

  // Clean up streams when disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Service for managing lockbox recovery operations
/// Includes notification tracking for incoming recovery requests
class RecoveryService {
  final LockboxRepository repository;
  final BackupService backupService;
  final KeyService _keyService;

  static const String _viewedNotificationIdsKey = 'viewed_recovery_notification_ids';

  Set<String>? _viewedNotificationIds;
  bool _isInitialized = false;

  // Stream for real-time notification updates
  final _notificationController = StreamController<List<RecoveryRequest>>.broadcast();
  Stream<List<RecoveryRequest>> get notificationStream => _notificationController.stream;

  // Stream for recovery request updates (for status screen)
  final _recoveryRequestController = StreamController<RecoveryRequest>.broadcast();
  Stream<RecoveryRequest> get recoveryRequestStream => _recoveryRequestController.stream;

  RecoveryService(this.repository, this.backupService, this._keyService);

  /// Dispose resources
  void dispose() {
    _notificationController.close();
    _recoveryRequestController.close();
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadViewedNotificationIds();
      _isInitialized = true;
      Log.info('RecoveryService initialized');
    } catch (e) {
      Log.error('Error initializing RecoveryService', e);
      _viewedNotificationIds = {};
      _isInitialized = true;
    }
  }

  /// Load viewed notification IDs from storage
  Future<void> _loadViewedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_viewedNotificationIdsKey);

    if (jsonData == null || jsonData.isEmpty) {
      _viewedNotificationIds = {};
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      _viewedNotificationIds = Set<String>.from(jsonList);
      Log.info('Loaded ${_viewedNotificationIds!.length} viewed notification IDs from storage');
    } catch (e) {
      Log.error('Error loading viewed notification IDs', e);
      _viewedNotificationIds = {};
    }
  }

  /// Save viewed notification IDs to storage
  Future<void> _saveViewedNotificationIds() async {
    if (_viewedNotificationIds == null) return;

    try {
      final jsonList = _viewedNotificationIds!.toList();
      final jsonString = json.encode(jsonList);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewedNotificationIdsKey, jsonString);
      Log.info('Saved ${jsonList.length} viewed notification IDs to storage');
    } catch (e) {
      Log.error('Error saving viewed notification IDs', e);
      throw Exception('Failed to save viewed notification IDs: $e');
    }
  }

  /// Emit notification update to stream
  Future<void> _emitNotificationUpdate() async {
    if (_viewedNotificationIds == null) return;

    // Get all recovery requests from lockbox repository
    final allRequests = await repository.getAllRecoveryRequests();
    final unviewed = allRequests.where((req) => !_viewedNotificationIds!.contains(req.id)).toList();
    _notificationController.add(unviewed);
  }

  /// Initiate recovery for a lockbox
  /// Returns the created recovery request
  Future<RecoveryRequest> initiateRecovery(
    String lockboxId, {
    required String initiatorPubkey,
    required List<String> keyHolderPubkeys,
    required int threshold,
    Duration? expirationDuration,
  }) async {
    await initialize();

    // Create recovery request
    final requestId = '${DateTime.now().millisecondsSinceEpoch}_$lockboxId';
    final expiresAt = expirationDuration != null
        ? DateTime.now().add(expirationDuration)
        : DateTime.now().add(const Duration(hours: 24)); // Default 24 hour expiration

    // Initialize key holder responses
    final keyHolderResponses = <String, RecoveryResponse>{};
    for (final pubkey in keyHolderPubkeys) {
      keyHolderResponses[pubkey] = RecoveryResponse(
        pubkey: pubkey,
        approved: false,
      );
    }

    final recoveryRequest = RecoveryRequest(
      id: requestId,
      lockboxId: lockboxId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now(),
      status: RecoveryRequestStatus.pending,
      threshold: threshold,
      expiresAt: expiresAt,
      keyHolderResponses: keyHolderResponses,
    );

    // Validate and save
    if (!recoveryRequest.isValid) {
      throw ArgumentError('Invalid recovery request');
    }

    // Add to lockbox (single source of truth)
    await repository.addRecoveryRequestToLockbox(lockboxId, recoveryRequest);

    // Emit notification update
    await _emitNotificationUpdate();

    Log.info('Created recovery request $requestId for lockbox $lockboxId');
    return recoveryRequest;
  }

  /// Add an incoming recovery request (received via Nostr)
  /// This is different from initiateRecovery which creates a new request
  Future<void> addIncomingRecoveryRequest(RecoveryRequest request) async {
    await initialize();

    // Check if request already exists in lockbox (source of truth)
    final existingRequests = await repository.getRecoveryRequestsForLockbox(request.lockboxId);
    final existingRequest = existingRequests.where((r) => r.id == request.id).firstOrNull;

    if (existingRequest != null) {
      // Don't overwrite requests in terminal states (cancelled, completed, failed)
      if (existingRequest.status.isTerminal) {
        Log.info(
            'Ignoring incoming recovery request ${request.id} - already in terminal state: ${existingRequest.status.name}');
        return;
      }

      // Update existing request in lockbox
      await repository.updateRecoveryRequestInLockbox(
        request.lockboxId,
        request.id,
        request,
      );
      Log.info('Updated existing recovery request ${request.id}');
    } else {
      // Add new request to lockbox
      await repository.addRecoveryRequestToLockbox(request.lockboxId, request);
      Log.info('Added incoming recovery request ${request.id}');
    }

    // Emit notification update
    await _emitNotificationUpdate();
  }

  /// Get all recovery requests for the current user
  Future<List<RecoveryRequest>> getRecoveryRequests({
    String? lockboxId,
    RecoveryRequestStatus? status,
  }) async {
    await initialize();

    // Get requests from lockbox repository (source of truth)
    List<RecoveryRequest> requests;
    if (lockboxId != null) {
      // Get requests for a specific lockbox
      requests = await repository.getRecoveryRequestsForLockbox(lockboxId);
    } else {
      // Get all requests across all lockboxes
      requests = await repository.getAllRecoveryRequests();
    }

    // Filter by status if provided
    if (status != null) {
      requests = requests.where((r) => r.status == status).toList();
    }

    return requests;
  }

  /// Get a specific recovery request by ID
  Future<RecoveryRequest?> getRecoveryRequest(String recoveryRequestId) async {
    await initialize();

    // Get all requests from lockbox repository and find the matching one
    final allRequests = await repository.getAllRecoveryRequests();
    try {
      return allRequests.firstWhere((r) => r.id == recoveryRequestId);
    } catch (e) {
      return null;
    }
  }

  /// Get recovery status for a specific request
  Future<RecoveryStatus?> getRecoveryStatus(String recoveryRequestId) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) return null;

    // Count responses that have shard data (approved responses)
    final collectedShardIds = request.keyHolderResponses.values
        .where((r) => r.shardData != null)
        .map((r) => r.pubkey) // Use pubkey as identifier
        .toList();

    // Use the actual Shamir threshold from the recovery request
    final threshold = request.threshold;

    return RecoveryStatus(
      recoveryRequestId: recoveryRequestId,
      totalKeyHolders: request.totalKeyHolders,
      respondedCount: request.respondedCount,
      approvedCount: request.approvedCount,
      deniedCount: request.deniedCount,
      collectedShardIds: collectedShardIds,
      threshold: threshold,
      canRecover: request.approvedCount >= threshold,
      lastUpdated: DateTime.now(),
    );
  }

  /// Respond to a recovery request (from a key holder)
  Future<void> respondToRecoveryRequest(
    String recoveryRequestId,
    String responderPubkey,
    bool approved, {
    ShardData? shardData,
  }) async {
    await initialize();

    // Get the request from lockbox repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Update the response
    final updatedResponses = Map<String, RecoveryResponse>.from(request.keyHolderResponses);
    updatedResponses[responderPubkey] = RecoveryResponse(
      pubkey: responderPubkey,
      approved: approved,
      respondedAt: DateTime.now(),
      shardData: shardData,
    );

    // Update request status
    var newStatus = request.status;
    if (request.status == RecoveryRequestStatus.pending ||
        request.status == RecoveryRequestStatus.sent) {
      newStatus = RecoveryRequestStatus.inProgress;
    }

    // Check if we have enough approvals to complete
    final approvedCount = updatedResponses.values.where((r) => r.approved).length;

    if (approvedCount >= request.threshold) {
      newStatus = RecoveryRequestStatus.completed;
    }

    // Update the request
    final updatedRequest = request.copyWith(
      status: newStatus,
      keyHolderResponses: updatedResponses,
    );

    // Update in lockbox (single source of truth)
    try {
      await repository.updateRecoveryRequestInLockbox(
        request.lockboxId,
        recoveryRequestId,
        updatedRequest,
      );
    } catch (e) {
      Log.error('Error updating recovery request in lockbox', e);
      rethrow;
    }

    // Emit update to stream for real-time UI updates
    _recoveryRequestController.add(updatedRequest);

    Log.info(
        'Updated recovery request $recoveryRequestId with response from ${responderPubkey.substring(0, 8)}... (approved: $approved)');
  }

  /// Cancel a recovery request
  Future<void> cancelRecoveryRequest(String recoveryRequestId) async {
    await initialize();

    // Get the request from lockbox repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final updatedRequest = request.copyWith(
      status: RecoveryRequestStatus.cancelled,
    );

    // Update in lockbox (single source of truth)
    await repository.updateRecoveryRequestInLockbox(
      request.lockboxId,
      recoveryRequestId,
      updatedRequest,
    );

    Log.info('Cancelled recovery request $recoveryRequestId');
  }

  /// Check if recovery is possible for a lockbox
  Future<bool> canRecoverLockbox(String lockboxId) async {
    await initialize();

    // Check if there are any active recovery requests for this lockbox
    final requests = await getRecoveryRequests(lockboxId: lockboxId);

    for (final request in requests) {
      if (request.status.isActive) {
        final status = await getRecoveryStatus(request.id);
        if (status != null && status.canRecover) {
          return true;
        }
      }
    }

    return false;
  }

  /// Perform lockbox recovery using collected shards
  /// Returns the recovered lockbox content
  Future<String> performRecovery(String recoveryRequestId) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Get the recovery status to check if recovery is possible
    final status = await getRecoveryStatus(recoveryRequestId);
    if (status == null || !status.canRecover) {
      throw Exception('Recovery is not yet possible - insufficient shares collected');
    }

    // Collect shards from approved responses
    final shards = request.keyHolderResponses.values
        .where((r) => r.approved && r.shardData != null)
        .map((r) => r.shardData!)
        .toList();

    if (shards.isEmpty) {
      throw Exception('No recovery shards found');
    }

    if (shards.length < request.threshold) {
      throw Exception('Insufficient shards: need ${request.threshold}, have ${shards.length}');
    }

    // Reconstruct the lockbox content from the shards
    final content = await backupService.reconstructFromShares(shares: shards);

    // Update the lockbox with recovered content
    final lockbox = await repository.getLockbox(request.lockboxId);
    if (lockbox != null) {
      await repository.updateLockbox(
        request.lockboxId,
        lockbox.name,
        content,
      );
    }

    // Update the recovery request status to completed
    final updatedRequest = request.copyWith(
      status: RecoveryRequestStatus.completed,
    );

    // Update in lockbox (single source of truth)
    try {
      await repository.updateRecoveryRequestInLockbox(
        request.lockboxId,
        recoveryRequestId,
        updatedRequest,
      );
    } catch (e) {
      Log.error('Error updating completed recovery request in lockbox', e);
      rethrow;
    }

    Log.info('Successfully recovered lockbox ${request.lockboxId} from $recoveryRequestId');
    return content;
  }

  /// Get key holder responses for a recovery request
  Future<List<RecoveryResponse>> getKeyHolderResponses(String recoveryRequestId) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) return [];

    return request.keyHolderResponses.values.toList();
  }

  /// Update recovery request status (for Nostr event tracking)
  Future<void> updateRecoveryRequestStatus(
    String recoveryRequestId,
    RecoveryRequestStatus status, {
    String? nostrEventId,
  }) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final updatedRequest = request.copyWith(
      status: status,
      nostrEventId: nostrEventId ?? request.nostrEventId,
    );

    // Update in lockbox (single source of truth)
    try {
      await repository.updateRecoveryRequestInLockbox(
        request.lockboxId,
        recoveryRequestId,
        updatedRequest,
      );
    } catch (e) {
      Log.error('Error updating recovery request status in lockbox', e);
      rethrow;
    }

    Log.info('Updated recovery request $recoveryRequestId status to ${status.displayName}');
  }

  /// Send recovery request to key holders via Nostr gift wraps
  /// Returns the list of gift wrap event IDs
  Future<List<String>> sendRecoveryRequestViaNostr(
    RecoveryRequest request, {
    required List<String> relays,
  }) async {
    try {
      // Get current user's keys
      final keyPair = await _keyService.getStoredNostrKey();
      final currentPubkey = keyPair?.publicKey;
      final currentPrivkey = keyPair?.privateKey;

      if (currentPubkey == null || currentPrivkey == null) {
        throw Exception('Unable to get current user keys for signing');
      }

      // Initialize NDK
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: currentPubkey, privkey: currentPrivkey);
      Log.info('Initialized NDK for recovery request distribution');

      // Prepare recovery request data
      final requestData = {
        'type': 'recovery_request',
        'recovery_request_id': request.id,
        'lockbox_id': request.lockboxId,
        'initiator_pubkey': request.initiatorPubkey,
        'requested_at': request.requestedAt.toIso8601String(),
        'expires_at': request.expiresAt?.toIso8601String(),
        'threshold': request.threshold,
      };

      final requestJson = json.encode(requestData);
      final eventIds = <String>[];

      // Send gift wrap to each key holder
      for (final pubkey in request.keyHolderResponses.keys) {
        try {
          Log.debug('Sending recovery request to ${pubkey.substring(0, 8)}...');

          // Create rumor event with recovery request data
          final rumor = await ndk.giftWrap.createRumor(
            customPubkey: currentPubkey,
            content: requestJson,
            kind: NostrKind.recoveryRequest.value, // Keydex custom kind for recovery requests
            tags: [
              ['d', 'recovery_request_${request.id}'],
              ['lockbox_id', request.lockboxId],
              ['recovery_request_id', request.id],
            ],
          );

          // Wrap the rumor in a gift wrap for the recipient
          final giftWrap = await ndk.giftWrap.toGiftWrap(
            rumor: rumor,
            recipientPubkey: pubkey,
          );

          // Broadcast the gift wrap event
          ndk.broadcast.broadcast(
            nostrEvent: giftWrap,
            specificRelays: relays,
          );

          eventIds.add(giftWrap.id);
          Log.info(
              'Sent recovery request to ${pubkey.substring(0, 8)}... (event: ${giftWrap.id.substring(0, 8)}...)');
        } catch (e) {
          Log.error('Failed to send recovery request to ${pubkey.substring(0, 8)}...', e);
        }
      }

      // Update request status to sent
      await updateRecoveryRequestStatus(
        request.id,
        RecoveryRequestStatus.sent,
        nostrEventId: eventIds.isNotEmpty ? eventIds.first : null,
      );

      Log.info(
          'Successfully sent recovery request ${request.id} to ${eventIds.length} key holders');
      return eventIds;
    } catch (e) {
      Log.error('Failed to send recovery request via Nostr', e);
      rethrow;
    }
  }

  /// Send recovery response (shard data) back to initiator via Nostr gift wrap
  /// Returns the gift wrap event ID
  Future<String> sendRecoveryResponseViaNostr(
    RecoveryRequest request,
    ShardData shardData,
    bool approved, {
    required List<String> relays,
  }) async {
    try {
      // Get current user's keys
      final keyPair = await _keyService.getStoredNostrKey();
      final currentPubkey = keyPair?.publicKey;
      final currentPrivkey = keyPair?.privateKey;

      if (currentPubkey == null || currentPrivkey == null) {
        throw Exception('Unable to get current user keys for signing');
      }

      // Initialize NDK
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: currentPubkey, privkey: currentPrivkey);
      Log.info('Initialized NDK for recovery response');

      // Prepare recovery response data
      final responseData = {
        'type': 'recovery_response',
        'recovery_request_id': request.id,
        'lockbox_id': request.lockboxId,
        'responder_pubkey': currentPubkey,
        'approved': approved,
        'responded_at': DateTime.now().toIso8601String(),
      };

      // Include shard data if approved
      if (approved) {
        responseData['shard_data'] = shardDataToJson(shardData);
      }

      final responseJson = json.encode(responseData);

      Log.debug('Sending recovery response to ${request.initiatorPubkey.substring(0, 8)}...');

      // Create rumor event with recovery response data
      final rumor = await ndk.giftWrap.createRumor(
        customPubkey: currentPubkey,
        content: responseJson,
        kind: NostrKind.recoveryResponse.value, // Keydex custom kind for recovery responses
        tags: [
          ['d', 'recovery_response_${request.id}_$currentPubkey'],
          ['lockbox_id', request.lockboxId],
          ['recovery_request_id', request.id],
          ['approved', approved.toString()],
        ],
      );

      // Wrap the rumor in a gift wrap for the initiator
      final giftWrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: request.initiatorPubkey,
      );

      // Broadcast the gift wrap event
      ndk.broadcast.broadcast(
        nostrEvent: giftWrap,
        specificRelays: relays,
      );

      Log.info(
          'Sent recovery response to ${request.initiatorPubkey.substring(0, 8)}... (event: ${giftWrap.id.substring(0, 8)}..., approved: $approved)');

      return giftWrap.id;
    } catch (e) {
      Log.error('Failed to send recovery response via Nostr', e);
      rethrow;
    }
  }

  // ========== Notification Methods ==========

  /// Get pending (unviewed) recovery request notifications
  Future<List<RecoveryRequest>> getPendingNotifications() async {
    await initialize();

    final allRequests = await repository.getAllRecoveryRequests();
    return allRequests.where((request) => !_viewedNotificationIds!.contains(request.id)).toList();
  }

  /// Get all recovery request notifications (including viewed)
  Future<List<RecoveryRequest>> getAllNotifications() async {
    await initialize();
    return await repository.getAllRecoveryRequests();
  }

  /// Mark a recovery request notification as viewed
  Future<void> markNotificationAsViewed(String recoveryRequestId) async {
    await initialize();

    if (!_viewedNotificationIds!.contains(recoveryRequestId)) {
      _viewedNotificationIds!.add(recoveryRequestId);
      await _saveViewedNotificationIds();
      await _emitNotificationUpdate();
      Log.info('Marked recovery request $recoveryRequestId as viewed');
    }
  }

  /// Mark a recovery request notification as unviewed
  Future<void> markNotificationAsUnviewed(String recoveryRequestId) async {
    await initialize();

    if (_viewedNotificationIds!.contains(recoveryRequestId)) {
      _viewedNotificationIds!.remove(recoveryRequestId);
      await _saveViewedNotificationIds();
      await _emitNotificationUpdate();
      Log.info('Marked recovery request $recoveryRequestId as unviewed');
    }
  }

  /// Get notification count
  Future<int> getNotificationCount({bool unviewedOnly = true}) async {
    await initialize();

    final allRequests = await repository.getAllRecoveryRequests();
    if (unviewedOnly) {
      return allRequests.where((request) => !_viewedNotificationIds!.contains(request.id)).length;
    } else {
      return allRequests.length;
    }
  }

  /// Check if a notification has been viewed
  Future<bool> isNotificationViewed(String recoveryRequestId) async {
    await initialize();
    return _viewedNotificationIds!.contains(recoveryRequestId);
  }

  /// Clear all viewed notification markers (doesn't delete requests)
  Future<void> clearViewedNotifications() async {
    await initialize();

    _viewedNotificationIds!.clear();
    await _saveViewedNotificationIds();
    await _emitNotificationUpdate();
    Log.info('Cleared all viewed notification markers');
  }

  /// Clear all recovery requests (for testing)
  Future<void> clearAll() async {
    _viewedNotificationIds = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewedNotificationIdsKey);
    _isInitialized = false;
    _notificationController.add([]);
    Log.info('Cleared all recovery request notifications');
  }

  /// Refresh the cached data from storage
  Future<void> refresh() async {
    _isInitialized = false;
    _viewedNotificationIds = null;
    await initialize();
  }
}
