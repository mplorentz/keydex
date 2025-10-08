import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/recovery_response.dart';
import '../models/recovery_status.dart';
import '../services/recovery_service.dart';
import '../services/logger.dart';

/// StreamProvider for recovery notifications
final recoveryNotificationsProvider = StreamProvider<List<RecoveryRequest>>((ref) async* {
  // Get initial notifications
  try {
    final initialNotifications = await RecoveryService.getPendingNotifications();
    yield initialNotifications;
  } catch (e) {
    Log.error('Error loading initial notifications', e);
    yield [];
  }

  // Listen to the stream for updates
  await for (final notifications in RecoveryService.notificationStream) {
    yield notifications;
  }
});

/// StreamProvider for recovery requests
final recoveryRequestStreamProvider = StreamProvider<RecoveryRequest>((ref) async* {
  await for (final request in RecoveryService.recoveryRequestStream) {
    yield request;
  }
});

/// FutureProvider for getting recovery requests
final recoveryRequestsProvider = FutureProvider<List<RecoveryRequest>>((ref) async {
  return await RecoveryService.getRecoveryRequests();
});

/// FutureProvider family for getting a specific recovery request
final recoveryRequestProvider = FutureProvider.family<RecoveryRequest?, String>((ref, id) async {
  return await RecoveryService.getRecoveryRequest(id);
});

/// FutureProvider family for getting recovery status
final recoveryStatusProvider = FutureProvider.family<RecoveryStatus?, String>((ref, id) async {
  return await RecoveryService.getRecoveryStatus(id);
});

/// FutureProvider family for checking if lockbox can be recovered
final canRecoverLockboxProvider = FutureProvider.family<bool, String>((ref, lockboxId) async {
  return await RecoveryService.canRecoverLockbox(lockboxId);
});

/// FutureProvider family for getting key holder responses
final keyHolderResponsesProvider =
    FutureProvider.family<List<RecoveryResponse>, String>((ref, recoveryRequestId) async {
  return await RecoveryService.getKeyHolderResponses(recoveryRequestId);
});

/// FutureProvider for pending notifications
final pendingNotificationsProvider = FutureProvider<List<RecoveryRequest>>((ref) async {
  return await RecoveryService.getPendingNotifications();
});

/// FutureProvider for all notifications
final allNotificationsProvider = FutureProvider<List<RecoveryRequest>>((ref) async {
  return await RecoveryService.getAllNotifications();
});

/// FutureProvider for notification count
final notificationCountProvider = FutureProvider<int>((ref) async {
  return await RecoveryService.getNotificationCount();
});

/// Provider for recovery repository operations
final recoveryRepositoryProvider = Provider<RecoveryRepository>((ref) {
  return RecoveryRepository(ref);
});

/// Repository class to handle recovery operations
class RecoveryRepository {
  final Ref _ref;

  RecoveryRepository(this._ref);

  /// Initiate a recovery request
  Future<RecoveryRequest> initiateRecovery(
    String lockboxId, {
    required String initiatorPubkey,
    required List<String> keyHolderPubkeys,
    required int threshold,
  }) async {
    final request = await RecoveryService.initiateRecovery(
      lockboxId,
      initiatorPubkey: initiatorPubkey,
      keyHolderPubkeys: keyHolderPubkeys,
      threshold: threshold,
    );
    _refreshProviders();
    return request;
  }

  /// Add an incoming recovery request
  Future<void> addIncomingRecoveryRequest(RecoveryRequest request) async {
    await RecoveryService.addIncomingRecoveryRequest(request);
    _refreshProviders();
  }

  /// Respond to a recovery request
  Future<void> respondToRecoveryRequest(
    String recoveryRequestId, {
    required bool approved,
    String? shardData,
    String? reason,
  }) async {
    await RecoveryService.respondToRecoveryRequest(
      recoveryRequestId,
      approved: approved,
      shardData: shardData,
      reason: reason,
    );
    _refreshProviders(recoveryRequestId);
  }

  /// Cancel a recovery request
  Future<void> cancelRecoveryRequest(String recoveryRequestId) async {
    await RecoveryService.cancelRecoveryRequest(recoveryRequestId);
    _refreshProviders(recoveryRequestId);
  }

  /// Perform recovery (reconstruct content from shards)
  Future<String> performRecovery(String recoveryRequestId) async {
    final content = await RecoveryService.performRecovery(recoveryRequestId);
    _refreshProviders(recoveryRequestId);
    return content;
  }

  /// Update recovery request status
  Future<void> updateRecoveryRequestStatus(
    String recoveryRequestId,
    RecoveryStatus status,
  ) async {
    await RecoveryService.updateRecoveryRequestStatus(recoveryRequestId, status);
    _refreshProviders(recoveryRequestId);
  }

  /// Send recovery request via Nostr
  Future<List<String>> sendRecoveryRequestViaNostr(
    RecoveryRequest request, {
    required List<String> relays,
  }) async {
    return await RecoveryService.sendRecoveryRequestViaNostr(request, relays: relays);
  }

  /// Send recovery response via Nostr
  Future<String> sendRecoveryResponseViaNostr(
    RecoveryResponse response, {
    required List<String> relays,
  }) async {
    return await RecoveryService.sendRecoveryResponseViaNostr(response, relays: relays);
  }

  /// Mark notification as viewed
  Future<void> markNotificationAsViewed(String recoveryRequestId) async {
    await RecoveryService.markNotificationAsViewed(recoveryRequestId);
    _refreshNotificationProviders();
  }

  /// Mark notification as unviewed
  Future<void> markNotificationAsUnviewed(String recoveryRequestId) async {
    await RecoveryService.markNotificationAsUnviewed(recoveryRequestId);
    _refreshNotificationProviders();
  }

  /// Clear viewed notifications
  Future<void> clearViewedNotifications() async {
    await RecoveryService.clearViewedNotifications();
    _refreshNotificationProviders();
  }

  /// Clear all recovery data (for testing/debugging)
  Future<void> clearAll() async {
    await RecoveryService.clearAll();
    _refreshProviders();
    _refreshNotificationProviders();
  }

  /// Refresh providers after an operation
  void _refreshProviders([String? recoveryRequestId]) {
    _ref.invalidate(recoveryRequestsProvider);
    if (recoveryRequestId != null) {
      _ref.invalidate(recoveryRequestProvider(recoveryRequestId));
      _ref.invalidate(recoveryStatusProvider(recoveryRequestId));
      _ref.invalidate(keyHolderResponsesProvider(recoveryRequestId));
    }
  }

  /// Refresh notification providers
  void _refreshNotificationProviders() {
    _ref.invalidate(pendingNotificationsProvider);
    _ref.invalidate(allNotificationsProvider);
    _ref.invalidate(notificationCountProvider);
  }
}
