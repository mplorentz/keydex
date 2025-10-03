// Service interface for lockbox recovery functionality
// This file defines the contract for recovery operations

import '../data-model.dart';

/// Service for managing lockbox recovery operations
abstract class RecoveryService {
  /// Initiate recovery for a lockbox
  /// Returns the created recovery request
  Future<RecoveryRequest> initiateRecovery(String lockboxId);

  /// Get all recovery requests for the current user
  Future<List<RecoveryRequest>> getRecoveryRequests();

  /// Get recovery status for a specific request
  Future<RecoveryStatus?> getRecoveryStatus(String recoveryRequestId);

  /// Respond to a recovery request
  Future<void> respondToRecoveryRequest(
      String recoveryRequestId, RecoveryResponseStatus status, ShardData? shardData);

  /// Cancel a recovery request
  Future<void> cancelRecoveryRequest(String recoveryRequestId);

  /// Check if recovery is possible for a lockbox
  Future<bool> canRecoverLockbox(String lockboxId);

  /// Get key holder responses for a recovery request
  Future<List<RecoveryResponse>> getKeyHolderResponses(String recoveryRequestId);
}

/// Service for managing Nostr relay scanning and configuration
abstract class RelayScanService {
  /// Get all configured relays
  Future<List<RelayConfiguration>> getRelayConfigurations();

  /// Add a new relay configuration
  Future<void> addRelayConfiguration(RelayConfiguration relay);

  /// Update an existing relay configuration
  Future<void> updateRelayConfiguration(RelayConfiguration relay);

  /// Remove a relay configuration
  Future<void> removeRelayConfiguration(String relayId);

  /// Start scanning relays for new shares and recovery requests
  Future<void> startRelayScanning();

  /// Stop scanning relays
  Future<void> stopRelayScanning();

  /// Check if scanning is currently active
  Future<bool> isScanningActive();

  /// Get scanning status and statistics
  Future<ScanningStatus> getScanningStatus();
}

/// Service for managing lockbox shares
abstract class LockboxShareService {
  /// Get all shares for a lockbox
  Future<List<ShardData>> getLockboxShares(String lockboxId);

  /// Get a specific share by ID
  Future<ShardData?> getLockboxShare(String shareId);

  /// Mark a share as received
  Future<void> markShareAsReceived(String shareId, String nostrEventId);

  /// Reassemble lockbox content from collected shares
  Future<String?> reassembleLockboxContent(String lockboxId);

  /// Check if sufficient shares are available for recovery
  Future<bool> hasSufficientShares(String lockboxId, int threshold);

  /// Get shard data collected for a recovery request
  Future<List<ShardData>> getCollectedShardData(String recoveryRequestId);
}

/// Service for managing recovery notifications
abstract class RecoveryNotificationService {
  /// Get pending recovery request notifications
  Future<List<RecoveryRequest>> getPendingNotifications();

  /// Mark a notification as viewed
  Future<void> markNotificationAsViewed(String recoveryRequestId);

  /// Get notification count
  Future<int> getNotificationCount();

  /// Clear all notifications
  Future<void> clearAllNotifications();

  /// Subscribe to recovery request updates
  Stream<RecoveryRequest> get recoveryRequestStream;

  /// Subscribe to notification updates
  Stream<List<RecoveryRequest>> get notificationStream;
}

/// Data classes for service responses

class ScanningStatus {
  final bool isActive;
  final DateTime? lastScan;
  final int totalRelays;
  final int activeRelays;
  final int sharesFound;
  final int requestsFound;
  final String? lastError;

  const ScanningStatus({
    required this.isActive,
    this.lastScan,
    required this.totalRelays,
    required this.activeRelays,
    required this.sharesFound,
    required this.requestsFound,
    this.lastError,
  });
}
