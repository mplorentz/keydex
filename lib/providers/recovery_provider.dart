import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../services/lockbox_service.dart';
import '../services/logger.dart';

/// Provider for recovery status of a specific lockbox
/// This provides information about whether recovery is available and active recovery requests
final recoveryStatusProvider =
    FutureProvider.family<RecoveryStatus, String>((ref, lockboxId) async {
  try {
    // Get the lockbox to check for active recovery requests
    final lockbox = await LockboxService.getLockbox(lockboxId);

    if (lockbox == null) {
      return const RecoveryStatus(
        hasActiveRecovery: false,
        canRecover: false,
        activeRecoveryRequest: null,
      );
    }

    // Use the embedded active recovery request
    final activeRequest = lockbox.activeRecoveryRequest;

    // Check if we can recover (has sufficient shards)
    final canRecover =
        activeRequest != null && activeRequest.approvedCount >= activeRequest.threshold;

    return RecoveryStatus(
      hasActiveRecovery: activeRequest != null,
      canRecover: canRecover,
      activeRecoveryRequest: activeRequest,
    );
  } catch (e) {
    Log.error('Error checking recovery status', e);
    return const RecoveryStatus(
      hasActiveRecovery: false,
      canRecover: false,
      activeRecoveryRequest: null,
    );
  }
});

/// Data class for recovery status information
class RecoveryStatus {
  final bool hasActiveRecovery;
  final bool canRecover;
  final RecoveryRequest? activeRecoveryRequest;

  const RecoveryStatus({
    required this.hasActiveRecovery,
    required this.canRecover,
    required this.activeRecoveryRequest,
  });
}
