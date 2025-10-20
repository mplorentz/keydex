import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../models/recovery_request.dart';
import '../services/lockbox_service.dart';
import '../services/logger.dart';

/// Stream provider that automatically subscribes to lockbox changes
/// This will emit a new list whenever lockboxes are added, updated, or deleted
final lockboxListProvider = StreamProvider<List<Lockbox>>((ref) async* {
  // First, ensure the service is initialized and yield initial data
  try {
    final initialLockboxes = await LockboxService.getAllLockboxes();
    yield initialLockboxes;
  } catch (e) {
    Log.error('Error loading initial lockboxes', e);
    yield [];
  }

  // Then listen to the stream for updates
  await for (final lockboxes in LockboxService.lockboxesStream) {
    yield lockboxes;
  }
});

/// Provider for a specific lockbox by ID
/// This will automatically update when the lockbox changes
final lockboxProvider = Provider.family<AsyncValue<Lockbox?>, String>((ref, lockboxId) {
  final lockboxesAsync = ref.watch(lockboxListProvider);

  return lockboxesAsync.when(
    data: (lockboxes) {
      try {
        final lockbox = lockboxes.firstWhere((box) => box.id == lockboxId);
        return AsyncValue.data(lockbox);
      } catch (e) {
        // Lockbox not found in the list
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for lockbox repository operations
/// This is a simple Provider (not StateProvider) because it provides
/// a stateless repository object
final lockboxRepositoryProvider = Provider<LockboxRepository>((ref) {
  return LockboxRepository();
});

/// Repository class to handle lockbox operations
/// This provides a clean API layer between the UI and the service
class LockboxRepository {
  /// Get all lockboxes
  Future<List<Lockbox>> getAllLockboxes() async {
    return await LockboxService.getAllLockboxes();
  }

  /// Get a specific lockbox by ID
  Future<Lockbox?> getLockbox(String id) async {
    return await LockboxService.getLockbox(id);
  }

  /// Add a new lockbox
  Future<void> addLockbox(Lockbox lockbox) async {
    await LockboxService.addLockbox(lockbox);
  }

  /// Update an existing lockbox
  Future<void> updateLockbox(String id, String name, String content) async {
    await LockboxService.updateLockbox(id, name, content);
  }

  /// Delete a lockbox
  Future<void> deleteLockbox(String id) async {
    await LockboxService.deleteLockbox(id);
  }

  /// Clear all lockboxes (for testing/debugging)
  Future<void> clearAll() async {
    await LockboxService.clearAll();
  }

  /// Refresh lockboxes from storage
  Future<void> refresh() async {
    await LockboxService.refresh();
  }
}

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
