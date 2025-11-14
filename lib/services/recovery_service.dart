import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nostr_kinds.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart';
import '../models/shard_data.dart';
import '../providers/lockbox_provider.dart';
import '../utils/invite_code_utils.dart';
import 'backup_service.dart';
import 'ndk_service.dart';
import 'lockbox_share_service.dart';
import '../providers/file_storage_provider.dart';
import '../providers/file_distribution_provider.dart';
import '../services/file_storage_service.dart';
import '../services/file_distribution_service.dart';
import 'logger.dart';

/// Provider for RecoveryService
/// This service depends on LockboxRepository for recovery operations
final Provider<RecoveryService> recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final repository = ref.watch(lockboxRepositoryProvider);
  final backupService = ref.read(backupServiceProvider);
  // Use ref.read() to break circular dependency with NdkService
  final NdkService ndkService = ref.read(ndkServiceProvider);
  final lockboxShareService = ref.read(lockboxShareServiceProvider);
  final fileStorageService = ref.read(fileStorageServiceProvider);
  final fileDistributionService = ref.read(fileDistributionServiceProvider);
  final service = RecoveryService(
    repository,
    backupService,
    ndkService,
    lockboxShareService,
    fileStorageService,
    fileDistributionService,
  );

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
  final NdkService _ndkService;
  final LockboxShareService _lockboxShareService;
  final FileStorageService _fileStorageService;
  final FileDistributionService _fileDistributionService;

  static const String _viewedNotificationIdsKey = 'viewed_recovery_notification_ids';

  Set<String>? _viewedNotificationIds;
  bool _isInitialized = false;

  // Stream for real-time notification updates
  final _notificationController = StreamController<List<RecoveryRequest>>.broadcast();
  Stream<List<RecoveryRequest>> get notificationStream => _notificationController.stream;

  // Stream for recovery request updates (for status screen)
  final _recoveryRequestController = StreamController<RecoveryRequest>.broadcast();
  Stream<RecoveryRequest> get recoveryRequestStream => _recoveryRequestController.stream;

  RecoveryService(
    this.repository,
    this.backupService,
    this._ndkService,
    this._lockboxShareService,
    this._fileStorageService,
    this._fileDistributionService,
  ) {
    _loadViewedNotificationIds();
    _setupNdkStreamListeners();
  }

  /// Set up listeners for incoming NDK events
  void _setupNdkStreamListeners() {
    // Listen for incoming recovery requests
    _ndkService.recoveryRequestStream.listen(
      (recoveryRequest) async {
        try {
          await addIncomingRecoveryRequest(recoveryRequest);
        } catch (e) {
          Log.error('Error processing incoming recovery request from stream', e);
        }
      },
      onError: (error) {
        Log.error('Error in recovery request stream', error);
      },
    );

    // Listen for incoming recovery responses
    _ndkService.recoveryResponseStream.listen(
      (responseEvent) async {
        try {
          await respondToRecoveryRequest(
            responseEvent.recoveryRequestId,
            responseEvent.senderPubkey,
            responseEvent.approved,
            shardData: responseEvent.shardData,
            nostrEventId: responseEvent.nostrEventId,
          );
        } catch (e) {
          Log.error('Error processing recovery response from stream', e);
        }
      },
      onError: (error) {
        Log.error('Error in recovery response stream', error);
      },
    );

    Log.info('RecoveryService listening to NdkService event streams');
  }

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
  /// Throws an exception if the user already has an active recovery request for this lockbox
  Future<RecoveryRequest> initiateRecovery(
    String lockboxId, {
    required String initiatorPubkey,
    required List<String> keyHolderPubkeys,
    required int threshold,
    Duration? expirationDuration,
  }) async {
    await initialize();

    // Check if user already has an active recovery request for this lockbox
    final existingRequests = await repository.getRecoveryRequestsForLockbox(lockboxId);
    final hasActiveRequest = existingRequests.any(
      (r) => r.initiatorPubkey == initiatorPubkey && r.status.isActive,
    );

    if (hasActiveRequest) {
      throw StateError(
        'You already have an active recovery request for this lockbox. Please manage your existing recovery request.',
      );
    }

    // Create recovery request
    // Generate cryptographically secure request ID
    final requestId = '${generateSecureID()}_$lockboxId';
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

    // T028: Send file request to key holders if lockbox has files
    final lockbox = await repository.getLockbox(lockboxId);
    if (lockbox != null && lockbox.files.isNotEmpty) {
      try {
        await _sendFileRequest(recoveryRequest, keyHolderPubkeys);
        Log.info('Sent file request for recovery $requestId');
      } catch (e) {
        Log.error('Error sending file request for recovery $requestId', e);
        // Don't fail recovery initiation if file request fails
      }
    }

    // Emit notification update
    await _emitNotificationUpdate();

    Log.info('Created recovery request $requestId for lockbox $lockboxId');
    return recoveryRequest;
  }

  /// Add an incoming recovery request (received via Nostr)
  /// This is different from initiateRecovery which creates a new request
  /// Since events are immutable, we skip processing if the request already exists locally
  Future<void> addIncomingRecoveryRequest(RecoveryRequest request) async {
    await initialize();

    // Check if request already exists in lockbox (source of truth)
    final existingRequests = await repository.getRecoveryRequestsForLockbox(request.lockboxId);
    final existingRequest = existingRequests.where((r) => r.id == request.id).firstOrNull;

    if (existingRequest != null) {
      // Since events are immutable, skip processing if we already have this request locally
      Log.info(
          'Ignoring incoming recovery request ${request.id} - already exists locally (status: ${existingRequest.status.name})');
      return;
    }

    // Add new request to lockbox
    await repository.addRecoveryRequestToLockbox(request.lockboxId, request);
    Log.info('Added incoming recovery request ${request.id}');

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
  /// Since events are immutable, we skip processing if the response already exists
  Future<void> respondToRecoveryRequest(
    String recoveryRequestId,
    String responderPubkey,
    bool approved, {
    ShardData? shardData,
    String? nostrEventId,
  }) async {
    await initialize();

    // Get the request from lockbox repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Check if response already exists for this pubkey
    final existingResponse = request.keyHolderResponses[responderPubkey];
    if (existingResponse != null) {
      // Check if this is a duplicate by comparing nostrEventId if provided
      if (nostrEventId != null && existingResponse.nostrEventId == nostrEventId) {
        Log.info(
            'Ignoring duplicate recovery response for request $recoveryRequestId from $responderPubkey (nostrEventId: $nostrEventId)');
        return;
      }
      // If response already exists and has respondedAt, skip processing (immutable event)
      if (existingResponse.respondedAt != null) {
        Log.info(
            'Ignoring recovery response for request $recoveryRequestId from $responderPubkey - response already exists');
        return;
      }
    }

    // Update the response
    final updatedResponses = Map<String, RecoveryResponse>.from(request.keyHolderResponses);
    updatedResponses[responderPubkey] = RecoveryResponse(
      pubkey: responderPubkey,
      approved: approved,
      respondedAt: DateTime.now(),
      shardData: shardData,
      nostrEventId: nostrEventId,
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

  /// Approve or deny a recovery request with automatic shard data retrieval and Nostr sending
  /// This is a convenience method that handles the complete approval flow:
  /// 1. Retrieves shard data if approving
  /// 2. Records the response locally
  /// 3. Sends the response via Nostr using relay URLs from shard data
  Future<void> respondToRecoveryRequestWithShard(
    String recoveryRequestId,
    String responderPubkey,
    bool approved,
  ) async {
    await initialize();

    // Get the recovery request to find the lockbox ID
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    ShardData? shardData;

    // If approving, get the shard data for this lockbox
    if (approved) {
      final shards = await repository.getShardsForLockbox(request.lockboxId);
      if (shards.isEmpty) {
        throw ArgumentError('No shard data found for lockbox ${request.lockboxId}');
      }
      shardData = shards.first;
    }

    // Submit response locally
    await respondToRecoveryRequest(
      recoveryRequestId,
      responderPubkey,
      approved,
      shardData: shardData,
    );

    // Send response via Nostr if approved and relay URLs are available in shard data
    if (approved &&
        shardData != null &&
        shardData.relayUrls != null &&
        shardData.relayUrls!.isNotEmpty) {
      try {
        await sendRecoveryResponseViaNostr(
          request,
          shardData,
          approved,
          relays: shardData.relayUrls!,
        );
        Log.info('Sent recovery response via Nostr for request $recoveryRequestId');
      } catch (e) {
        Log.error('Failed to send recovery response via Nostr', e);
        // Continue anyway - the response is still recorded locally
      }
    }
  }

  /// Helper method to update recovery request status
  Future<void> _updateRecoveryRequestStatus(
    String recoveryRequestId,
    RecoveryRequestStatus status,
  ) async {
    await initialize();

    // Get the request from lockbox repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final updatedRequest = request.copyWith(
      status: status,
    );

    // Update in lockbox (single source of truth)
    await repository.updateRecoveryRequestInLockbox(
      request.lockboxId,
      recoveryRequestId,
      updatedRequest,
    );

    Log.info('Updated recovery request $recoveryRequestId status to ${status.displayName}');
  }

  /// Cancel a recovery request
  Future<void> cancelRecoveryRequest(String recoveryRequestId) async {
    await _updateRecoveryRequestStatus(recoveryRequestId, RecoveryRequestStatus.cancelled);

    // Delete all recovery shards for this recovery request
    // Note: User's own shard is stored separately in _cachedShardData (keyed by lockboxId)
    // and won't be affected by removeRecoveryShards() which only deletes recovery shards
    // (keyed by recoveryRequestId)
    await _lockboxShareService.removeRecoveryShards(recoveryRequestId);
    Log.info('Deleted recovery shards for cancelled recovery request $recoveryRequestId');
  }

  /// Exit recovery mode after successful recovery
  /// Archives the recovery request, deletes recovered content and recovery shards,
  /// while preserving the user's own key holder shard
  Future<void> exitRecoveryMode(String recoveryRequestId) async {
    await initialize();

    // Get the request from lockbox repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Update recovery request status to archived
    await _updateRecoveryRequestStatus(recoveryRequestId, RecoveryRequestStatus.archived);

    // Delete recovered content from lockbox (set to null)
    final lockbox = await repository.getLockbox(request.lockboxId);
    if (lockbox != null) {
      await repository.saveLockbox(
        lockbox.copyWith(files: const []),
      );
      Log.info('Deleted recovered content from lockbox ${request.lockboxId}');
    }

    // Delete all recovery shards for this recovery request
    // Note: User's own shard is stored separately in _cachedShardData (keyed by lockboxId)
    // and won't be affected by removeRecoveryShards() which only deletes recovery shards
    // (keyed by recoveryRequestId)
    await _lockboxShareService.removeRecoveryShards(recoveryRequestId);
    Log.info('Deleted recovery shards for recovery request $recoveryRequestId');

    Log.info('Exited recovery mode for recovery request $recoveryRequestId');
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

    // Reconstruct the lockbox secret from the shards
    // For file-based lockboxes, this is the encryption key
    final secret = await backupService.reconstructFromShares(shares: shards);

    // Update the lockbox name
    final lockbox = await repository.getLockbox(request.lockboxId);
    if (lockbox != null) {
      await repository.updateLockbox(
        request.lockboxId,
        lockbox.name,
      );

      // T029: Download and decrypt files if lockbox has files
      if (lockbox.files.isNotEmpty) {
        try {
          // Files will be downloaded on-demand via UI after recovery completes
          // The encryption key is available via the reconstructed secret
          Log.info('Recovery completed for lockbox ${request.lockboxId} with ${lockbox.files.length} files');
        } catch (e) {
          Log.error('Error preparing files for recovery', e);
          // Don't fail recovery if file download fails - user can download manually
        }
      }
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
      final currentPubkey = await _ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        throw Exception('Unable to get current user keys for signing');
      }

      Log.info(
          'Sending recovery request ${request.id} to ${request.keyHolderResponses.length} key holders');

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

      // Send gift wrap to each key holder using NdkService
      final eventIds = await _ndkService.publishEncryptedEventToMultiple(
        content: requestJson,
        kind: NostrKind.recoveryRequest.value,
        recipientPubkeys: request.keyHolderResponses.keys.toList(),
        relays: relays,
        tags: [
          ['d', 'recovery_request_${request.id}'],
          ['lockbox_id', request.lockboxId],
          ['recovery_request_id', request.id],
        ],
        customPubkey: currentPubkey,
      );

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
      final currentPubkey = await _ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        throw Exception('Unable to get current user keys for signing');
      }

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

      // Publish using NdkService
      final eventId = await _ndkService.publishEncryptedEvent(
        content: responseJson,
        kind: NostrKind.recoveryResponse.value,
        recipientPubkey: request.initiatorPubkey,
        relays: relays,
        tags: [
          ['d', 'recovery_response_${request.id}_$currentPubkey'],
          ['lockbox_id', request.lockboxId],
          ['recovery_request_id', request.id],
          ['approved', approved.toString()],
        ],
      );

      if (eventId == null) {
        throw Exception('Failed to publish recovery response event');
      }

      Log.info(
          'Sent recovery response to ${request.initiatorPubkey.substring(0, 8)}... (event: ${eventId.substring(0, 8)}..., approved: $approved)');
      return eventId;
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

  // T028: File recovery helper methods

  /// Send file request to key holders (kind 2440)
  Future<void> _sendFileRequest(RecoveryRequest request, List<String> keyHolderPubkeys) async {
    try {
      final relays = _ndkService.getActiveRelays();
      if (relays.isEmpty) {
        Log.warning('No active relays available for file request');
        return;
      }

      final content = json.encode({
        'recovery_request_id': request.id,
        'lockbox_id': request.lockboxId,
        'requested_at': request.requestedAt.toIso8601String(),
      });

      // Send to each key holder
      for (final pubkey in keyHolderPubkeys) {
        try {
          await _ndkService.publishEncryptedEvent(
            content: content,
            kind: NostrKind.fileRequest.toInt(),
            recipientPubkey: pubkey,
            relays: relays,
            tags: [
              ['p', pubkey],
              ['recovery_request_id', request.id],
              ['lockbox_id', request.lockboxId],
            ],
          );
          Log.info('Sent file request to key holder $pubkey for recovery ${request.id}');
        } catch (e) {
          Log.error('Error sending file request to key holder $pubkey', e);
          // Continue with other key holders
        }
      }
    } catch (e) {
      Log.error('Error in _sendFileRequest', e);
      rethrow;
    }
  }

  /// Handle file response (kind 2441) - T029
  /// Called when key holder responds with file location
  Future<void> handleFileResponse({
    required String recoveryRequestId,
    required String senderPubkey,
    required Map<String, dynamic> responseData,
  }) async {
    try {
      await initialize();

      final request = await getRecoveryRequest(recoveryRequestId);
      if (request == null) {
        Log.warning('Recovery request not found for file response: $recoveryRequestId');
        return;
      }

      // Extract file URLs and hashes from response
      final fileUrls = (responseData['file_urls'] as List<dynamic>?)?.cast<String>() ?? [];
      final fileHashes = (responseData['file_hashes'] as List<dynamic>?)?.cast<String>() ?? [];
      final fileNames = (responseData['file_names'] as List<dynamic>?)?.cast<String>() ?? [];

      if (fileUrls.isEmpty || fileUrls.length != fileHashes.length || fileUrls.length != fileNames.length) {
        Log.warning('Invalid file response data for recovery $recoveryRequestId');
        return;
      }

      // Get encryption key from reconstructed secret
      // TODO: This requires reconstructing the secret from shards
      // For now, we'll need to get it during performRecovery
      // Store file URLs temporarily for later download
      Log.info('Received file response for recovery $recoveryRequestId with ${fileUrls.length} files');
      
      // Files will be downloaded during performRecovery when we have the encryption key
    } catch (e) {
      Log.error('Error handling file response', e);
      rethrow;
    }
  }

  /// Download and decrypt files during recovery (T029)
  Future<List<Uint8List>> downloadRecoveryFiles({
    required String recoveryRequestId,
    required List<String> fileUrls,
    required List<String> fileHashes,
    required List<String> fileNames,
    required Uint8List encryptionKey,
  }) async {
    try {
      final downloadedFiles = <Uint8List>[];

      for (int i = 0; i < fileUrls.length; i++) {
        try {
          final decryptedBytes = await _fileStorageService.downloadAndDecryptFile(
            blossomUrl: fileUrls[i],
            blossomHash: fileHashes[i],
            encryptionKey: encryptionKey,
          );
          downloadedFiles.add(decryptedBytes);
          Log.info('Downloaded and decrypted file ${fileNames[i]} for recovery $recoveryRequestId');
        } catch (e) {
          Log.error('Error downloading file ${fileNames[i]}', e);
          rethrow;
        }
      }

      return downloadedFiles;
    } catch (e) {
      Log.error('Error downloading recovery files', e);
      rethrow;
    }
  }

  /// Convert secret string to 32-byte encryption key
  Uint8List _secretToEncryptionKey(String secret) {
    // If secret is hex, decode it
    if (secret.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(secret)) {
      final bytes = <int>[];
      for (int i = 0; i < 64; i += 2) {
        bytes.add(int.parse(secret.substring(i, i + 2), radix: 16));
      }
      return Uint8List.fromList(bytes);
    }
    // Otherwise, use first 32 bytes of UTF-8 encoding
    final utf8Bytes = utf8.encode(secret);
    if (utf8Bytes.length >= 32) {
      return Uint8List.fromList(utf8Bytes.sublist(0, 32));
    }
    // Pad with zeros if needed
    final key = Uint8List(32);
    key.setRange(0, utf8Bytes.length, utf8Bytes);
    return key;
  }
}
