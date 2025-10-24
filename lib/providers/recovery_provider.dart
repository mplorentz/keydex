import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import 'lockbox_provider.dart';

/// Provider for recovery status of a specific lockbox
/// This provides information about whether recovery is available and active recovery requests
final recoveryStatusProvider =
    Provider.family<AsyncValue<RecoveryStatus>, String>((ref, lockboxId) {
  // Watch the lockbox async value and transform it to recovery status
  final lockboxAsync = ref.watch(lockboxProvider(lockboxId));

  return lockboxAsync.when(
    data: (lockbox) {
      if (lockbox == null) {
        return const AsyncValue.data(RecoveryStatus(
          hasActiveRecovery: false,
          canRecover: false,
          activeRecoveryRequest: null,
        ));
      }

      // Use the embedded active recovery request
      final activeRequest = lockbox.activeRecoveryRequest;

      // Check if we can recover (has sufficient shards)
      final canRecover =
          activeRequest != null && activeRequest.approvedCount >= activeRequest.threshold;

      return AsyncValue.data(RecoveryStatus(
        hasActiveRecovery: activeRequest != null,
        canRecover: canRecover,
        activeRecoveryRequest: activeRequest,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
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
