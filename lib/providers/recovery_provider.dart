import '../services/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart' as recovery_status;
import 'lockbox_provider.dart';
import '../services/recovery_service.dart';
import 'key_provider.dart';

/// Provider for recovery status of a specific lockbox
/// This provides information about whether recovery is available and active recovery requests
final recoveryStatusProvider =
    Provider.family<AsyncValue<RecoveryStatus>, String>((ref, lockboxId) {
  // Watch the lockbox async value and transform it to recovery status
  final lockboxAsync = ref.watch(lockboxProvider(lockboxId));
  final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

  return lockboxAsync.when(
    data: (lockbox) {
      if (lockbox == null) {
        return const AsyncValue.data(RecoveryStatus(
          hasActiveRecovery: false,
          canRecover: false,
          activeRecoveryRequest: null,
          isInitiator: false,
        ));
      }

      // Get active OR completed recovery requests
      // Completed requests need to be manageable so users can click "Recover Lockbox"
      // Sort by requestedAt descending to get the most recent request first
      RecoveryRequest? manageableRequest;
      final manageableRequests = lockbox.recoveryRequests
          .where((r) => r.status.isActive || r.status == RecoveryRequestStatus.completed)
          .toList();

      if (manageableRequests.isNotEmpty) {
        // Sort by requestedAt descending (most recent first)
        manageableRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        manageableRequest = manageableRequests.first;
      }

      // Check if we can recover (has sufficient shards)
      final canRecover = manageableRequest != null &&
          manageableRequest.approvedCount >= manageableRequest.threshold;

      // Check if current user is the initiator
      final currentPubkey = currentPubkeyAsync.value;
      final isInitiator = manageableRequest != null &&
          currentPubkey != null &&
          manageableRequest.initiatorPubkey == currentPubkey;

      return AsyncValue.data(RecoveryStatus(
        hasActiveRecovery: manageableRequest != null,
        canRecover: canRecover,
        activeRecoveryRequest: manageableRequest,
        isInitiator: isInitiator,
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
  final bool isInitiator;

  const RecoveryStatus({
    required this.hasActiveRecovery,
    required this.canRecover,
    required this.activeRecoveryRequest,
    required this.isInitiator,
  });
}

/// Provider for a specific recovery request by ID
/// This watches the lockbox stream and extracts the recovery request, so it updates automatically
// TODO: This should probably be a StreamProvider? I don't really understand the point of
// providers that don't live update.
final recoveryRequestByIdProvider =
    Provider.family<AsyncValue<RecoveryRequest?>, String>((ref, recoveryRequestId) {
  // We need to find which lockbox contains this recovery request
  // Since we don't know the lockbox ID upfront, we get it from the service once
  // then watch that lockbox's stream
  return ref.watch(_recoveryRequestLockboxIdProvider(recoveryRequestId)).when(
        data: (lockboxId) {
          if (lockboxId == null) {
            return const AsyncValue.data(null);
          }

          // Now watch the lockbox stream and extract the recovery request
          final lockboxAsync = ref.watch(lockboxProvider(lockboxId));

          return lockboxAsync.when(
            data: (lockbox) {
              if (lockbox == null) {
                return const AsyncValue.data(null);
              }

              // Find the recovery request in the lockbox
              try {
                final request =
                    lockbox.recoveryRequests.firstWhere((r) => r.id == recoveryRequestId);
                return AsyncValue.data(request);
              } catch (e) {
                return const AsyncValue.data(null);
              }
            },
            loading: () => const AsyncValue.loading(),
            error: (error, stack) => AsyncValue.error(error, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
});

/// Helper provider to get the lockbox ID for a recovery request
/// This only needs to be called once since recovery requests don't move between lockboxes
final _recoveryRequestLockboxIdProvider =
    FutureProvider.family<String?, String>((ref, recoveryRequestId) async {
  final service = ref.watch(recoveryServiceProvider);
  final request = await service.getRecoveryRequest(recoveryRequestId);
  return request?.lockboxId;
});

/// Provider for recovery status by recovery request ID
/// This watches the recovery request and computes the status automatically
final recoveryStatusByIdProvider =
    Provider.family<AsyncValue<recovery_status.RecoveryStatus?>, String>((ref, recoveryRequestId) {
  final requestAsync = ref.watch(recoveryRequestByIdProvider(recoveryRequestId));

  return requestAsync.when(
    data: (request) {
      if (request == null) return const AsyncValue.data(null);

      // Compute recovery status from the request
      final collectedShardIds = request.keyHolderResponses.values
          .where((r) => r.shardData != null)
          .map((r) => r.pubkey)
          .toList();

      final threshold = request.threshold;
      final totalKeyHolders = request.totalKeyHolders;
      final respondedCount = request.respondedCount;
      final approvedCount = request.approvedCount;
      final deniedCount = request.deniedCount;
      final canRecover = approvedCount >= threshold;

      return AsyncValue.data(recovery_status.RecoveryStatus(
        recoveryRequestId: recoveryRequestId,
        totalKeyHolders: totalKeyHolders,
        respondedCount: respondedCount,
        approvedCount: approvedCount,
        deniedCount: deniedCount,
        collectedShardIds: collectedShardIds,
        threshold: threshold,
        canRecover: canRecover,
        lastUpdated: DateTime.now(),
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
