// LockboxService Contract
// This file defines the interface for lockbox operations

// Note: LockboxMetadata and LockboxContent classes are imported from ../models/lockbox.dart
abstract class LockboxService {
  /// Creates a new encrypted lockbox
  /// Returns the created lockbox ID on success
  Future<String> createLockbox({
    required String name,
    required String content,
  });

  /// Retrieves all user lockboxes (metadata only)
  /// Returns list of lockbox metadata without decrypted content
  Future<List<LockboxMetadata>> getAllLockboxes();

  /// Retrieves and decrypts a specific lockbox
  /// Requires authentication before decryption
  Future<LockboxContent> getLockboxContent(String lockboxId);

  /// Updates an existing lockbox's content
  /// Re-encrypts the new content
  Future<void> updateLockbox({
    required String lockboxId,
    required String content,
  });

  /// Updates an existing lockbox's name
  Future<void> updateLockboxName({
    required String lockboxId,
    required String name,
  });

  /// Permanently deletes a lockbox
  Future<void> deleteLockbox(String lockboxId);

  /// Authenticates user before sensitive operations
  Future<bool> authenticateUser();
}


class LockboxException implements Exception {
  final String message;
  final String? errorCode;

  LockboxException(this.message, {this.errorCode});
}
