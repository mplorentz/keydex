import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart';
import 'logger.dart';

/// Service for managing lockbox recovery operations
class RecoveryService {
  static const String _recoveryRequestsKey = 'recovery_requests';
  static List<RecoveryRequest>? _cachedRequests;
  static bool _isInitialized = false;

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadRecoveryRequests();
      _isInitialized = true;
      Log.info('RecoveryService initialized with ${_cachedRequests?.length ?? 0} requests');
    } catch (e) {
      Log.error('Error initializing RecoveryService', e);
      _cachedRequests = [];
      _isInitialized = true;
    }
  }

  /// Load recovery requests from storage
  static Future<void> _loadRecoveryRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_recoveryRequestsKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedRequests = [];
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      _cachedRequests =
          jsonList.map((json) => RecoveryRequest.fromJson(json as Map<String, dynamic>)).toList();
      Log.info('Loaded ${_cachedRequests!.length} recovery requests from storage');
    } catch (e) {
      Log.error('Error loading recovery requests', e);
      _cachedRequests = [];
    }
  }

  /// Save recovery requests to storage
  static Future<void> _saveRecoveryRequests() async {
    if (_cachedRequests == null) return;

    try {
      final jsonList = _cachedRequests!.map((request) => request.toJson()).toList();
      final jsonString = json.encode(jsonList);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recoveryRequestsKey, jsonString);
      Log.info('Saved ${jsonList.length} recovery requests to storage');
    } catch (e) {
      Log.error('Error saving recovery requests', e);
      throw Exception('Failed to save recovery requests: $e');
    }
  }

  /// Initiate recovery for a lockbox
  /// Returns the created recovery request
  static Future<RecoveryRequest> initiateRecovery(
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
        status: RecoveryResponseStatus.pending,
      );
    }

    final recoveryRequest = RecoveryRequest(
      id: requestId,
      lockboxId: lockboxId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now(),
      status: RecoveryRequestStatus.pending,
      expiresAt: expiresAt,
      keyHolderResponses: keyHolderResponses,
    );

    // Validate and save
    if (!recoveryRequest.isValid) {
      throw ArgumentError('Invalid recovery request');
    }

    _cachedRequests!.add(recoveryRequest);
    await _saveRecoveryRequests();

    Log.info('Created recovery request $requestId for lockbox $lockboxId');
    return recoveryRequest;
  }

  /// Get all recovery requests for the current user
  static Future<List<RecoveryRequest>> getRecoveryRequests({
    String? lockboxId,
    RecoveryRequestStatus? status,
  }) async {
    await initialize();

    var requests = List<RecoveryRequest>.from(_cachedRequests ?? []);

    // Filter by lockbox ID if provided
    if (lockboxId != null) {
      requests = requests.where((r) => r.lockboxId == lockboxId).toList();
    }

    // Filter by status if provided
    if (status != null) {
      requests = requests.where((r) => r.status == status).toList();
    }

    return requests;
  }

  /// Get a specific recovery request by ID
  static Future<RecoveryRequest?> getRecoveryRequest(String recoveryRequestId) async {
    await initialize();

    try {
      return _cachedRequests!.firstWhere((r) => r.id == recoveryRequestId);
    } catch (e) {
      return null;
    }
  }

  /// Get recovery status for a specific request
  static Future<RecoveryStatus?> getRecoveryStatus(String recoveryRequestId) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) return null;

    final collectedShardIds = request.keyHolderResponses.values
        .where((r) => r.shardDataId != null)
        .map((r) => r.shardDataId!)
        .toList();

    // Determine if recovery is possible
    // For now, we use a simple heuristic based on the number of key holders
    // In a real implementation, this would check against the Shamir threshold
    final threshold = (request.totalKeyHolders * 0.67).ceil(); // Example: need 67% of key holders

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

  /// Respond to a recovery request
  static Future<void> respondToRecoveryRequest(
    String recoveryRequestId,
    String responderPubkey,
    RecoveryResponseStatus responseStatus, {
    String? shardDataId,
  }) async {
    await initialize();

    final requestIndex = _cachedRequests!.indexWhere((r) => r.id == recoveryRequestId);
    if (requestIndex == -1) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final request = _cachedRequests![requestIndex];

    // Check if this pubkey is a valid key holder
    if (!request.keyHolderResponses.containsKey(responderPubkey)) {
      throw ArgumentError('Responder is not a key holder for this request');
    }

    // Update the response
    final updatedResponses = Map<String, RecoveryResponse>.from(request.keyHolderResponses);
    updatedResponses[responderPubkey] = RecoveryResponse(
      pubkey: responderPubkey,
      status: responseStatus,
      respondedAt: DateTime.now(),
      shardDataId: shardDataId,
    );

    // Update request status
    var newStatus = request.status;
    if (request.status == RecoveryRequestStatus.pending ||
        request.status == RecoveryRequestStatus.sent) {
      newStatus = RecoveryRequestStatus.inProgress;
    }

    // Check if we have enough approvals to complete
    final approvedCount =
        updatedResponses.values.where((r) => r.status == RecoveryResponseStatus.approved).length;
    final threshold = (request.totalKeyHolders * 0.67).ceil();

    if (approvedCount >= threshold) {
      newStatus = RecoveryRequestStatus.completed;
    }

    // Update the request
    final updatedRequest = request.copyWith(
      status: newStatus,
      keyHolderResponses: updatedResponses,
    );

    _cachedRequests![requestIndex] = updatedRequest;
    await _saveRecoveryRequests();

    Log.info(
        'Updated recovery request $recoveryRequestId with response from ${responderPubkey.substring(0, 8)}...');
  }

  /// Cancel a recovery request
  static Future<void> cancelRecoveryRequest(String recoveryRequestId) async {
    await initialize();

    final requestIndex = _cachedRequests!.indexWhere((r) => r.id == recoveryRequestId);
    if (requestIndex == -1) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final request = _cachedRequests![requestIndex];
    final updatedRequest = request.copyWith(
      status: RecoveryRequestStatus.cancelled,
    );

    _cachedRequests![requestIndex] = updatedRequest;
    await _saveRecoveryRequests();

    Log.info('Cancelled recovery request $recoveryRequestId');
  }

  /// Check if recovery is possible for a lockbox
  static Future<bool> canRecoverLockbox(String lockboxId) async {
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

  /// Get key holder responses for a recovery request
  static Future<List<RecoveryResponse>> getKeyHolderResponses(String recoveryRequestId) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) return [];

    return request.keyHolderResponses.values.toList();
  }

  /// Update recovery request status (for Nostr event tracking)
  static Future<void> updateRecoveryRequestStatus(
    String recoveryRequestId,
    RecoveryRequestStatus status, {
    String? nostrEventId,
  }) async {
    await initialize();

    final requestIndex = _cachedRequests!.indexWhere((r) => r.id == recoveryRequestId);
    if (requestIndex == -1) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final request = _cachedRequests![requestIndex];
    final updatedRequest = request.copyWith(
      status: status,
      nostrEventId: nostrEventId ?? request.nostrEventId,
    );

    _cachedRequests![requestIndex] = updatedRequest;
    await _saveRecoveryRequests();

    Log.info('Updated recovery request $recoveryRequestId status to ${status.displayName}');
  }

  /// Clear all recovery requests (for testing)
  static Future<void> clearAll() async {
    _cachedRequests = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recoveryRequestsKey);
    _isInitialized = false;
    Log.info('Cleared all recovery requests');
  }

  /// Refresh the cached data from storage
  static Future<void> refresh() async {
    _isInitialized = false;
    _cachedRequests = null;
    await initialize();
  }
}
