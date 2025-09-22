// LockboxService Contract
// This file defines the interface for lockbox operations

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

class LockboxMetadata {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int size;

  LockboxMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.size,
  });
}

class LockboxContent {
  final String id;
  final String name;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  LockboxContent({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}

class LockboxException implements Exception {
  final String message;
  final String? errorCode;

  LockboxException(this.message, {this.errorCode});
}
