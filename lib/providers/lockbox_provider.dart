import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
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

/// FutureProvider family for getting a single lockbox by ID
/// This will automatically cache the result and can be invalidated
final lockboxProvider = FutureProvider.family<Lockbox?, String>((ref, id) async {
  return await LockboxService.getLockbox(id);
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
