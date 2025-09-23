// LockboxService Implementation
// Handles lockbox operations including creation, retrieval, update, and deletion

import 'dart:math';
import '../contracts/lockbox_service.dart';
import '../models/lockbox.dart';
import '../models/text_content.dart';
import 'auth_service.dart';
import 'encryption_service.dart';
import 'storage_service.dart';

/// Implementation of LockboxService
class LockboxServiceImpl implements LockboxService {
  LockboxServiceImpl({
    required AuthService authService,
    required EncryptionService encryptionService,
    required StorageService storageService,
  })  : _authService = authService,
        _encryptionService = encryptionService,
        _storageService = storageService;

  final AuthService _authService;
  final EncryptionService _encryptionService;
  final StorageService _storageService;

  @override
  Future<String> createLockbox({
    required String name,
    required String content,
  }) async {
    try {
      // Validate input
      if (name.isEmpty) {
        throw LockboxException(
          'Lockbox name cannot be empty',
          errorCode: 'EMPTY_NAME',
        );
      }

      if (name.length > 100) {
        throw LockboxException(
          'Lockbox name too long: ${name.length} characters (max 100)',
          errorCode: 'NAME_TOO_LONG',
        );
      }

      if (content.length > 4000) {
        throw LockboxException(
          'Content too large: ${content.length} characters (max 4000)',
          errorCode: 'CONTENT_TOO_LARGE',
        );
      }

      // Generate unique ID
      final lockboxId = _generateId();

      // Create text content
      final textContent = TextContent(
        content: content,
        lockboxId: lockboxId,
      );

      // Validate text content
      if (!textContent.isValid()) {
        throw LockboxException(
          'Invalid text content',
          errorCode: 'INVALID_CONTENT',
        );
      }

      // Encrypt the content
      final encryptedContent = await _encryptionService.encryptText(content);

      // Create lockbox metadata
      final now = DateTime.now();
      final metadata = LockboxMetadata(
        id: lockboxId,
        name: name,
        createdAt: now,
        size: content.length,
      );

      // Validate metadata
      if (!metadata.isValid()) {
        throw LockboxException(
          'Invalid lockbox metadata',
          errorCode: 'INVALID_METADATA',
        );
      }

      // Store lockbox and encrypted content
      await _storageService.addLockbox(metadata);
      await _storageService.storeLockboxContent(lockboxId, encryptedContent);

      return lockboxId;
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to create lockbox: ${e.toString()}',
        errorCode: 'CREATE_LOCKBOX_FAILED',
      );
    }
  }

  @override
  Future<List<LockboxMetadata>> getAllLockboxes() async {
    try {
      return await _storageService.getLockboxes();
    } catch (e) {
      throw LockboxException(
        'Failed to retrieve lockboxes: ${e.toString()}',
        errorCode: 'GET_LOCKBOXES_FAILED',
      );
    }
  }

  @override
  Future<LockboxContent> getLockboxContent(String lockboxId) async {
    try {
      // Authenticate user before decryption
      final isAuthenticated = await authenticateUser();
      if (!isAuthenticated) {
        throw LockboxException(
          'Authentication required to access lockbox content',
          errorCode: 'AUTHENTICATION_REQUIRED',
        );
      }

      // Get lockbox metadata
      final lockboxes = await _storageService.getLockboxes();
      final lockbox = lockboxes.cast<LockboxMetadata?>().firstWhere(
        (lb) => lb?.id == lockboxId,
        orElse: () => null,
      );

      if (lockbox == null) {
        throw LockboxException(
          'Lockbox not found: $lockboxId',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      // Get encrypted content
      final encryptedContent = await _storageService.getLockboxContent(lockboxId);
      if (encryptedContent == null) {
        throw LockboxException(
          'Lockbox content not found: $lockboxId',
          errorCode: 'CONTENT_NOT_FOUND',
        );
      }

      // Decrypt the content
      final decryptedContent = await _encryptionService.decryptText(encryptedContent);

      // Create and return LockboxContent
      return LockboxContent(
        id: lockbox.id,
        name: lockbox.name,
        content: decryptedContent,
        createdAt: lockbox.createdAt,
      );
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to get lockbox content: ${e.toString()}',
        errorCode: 'GET_CONTENT_FAILED',
      );
    }
  }

  @override
  Future<void> updateLockbox({
    required String lockboxId,
    required String content,
  }) async {
    try {
      // Validate content
      if (content.length > 4000) {
        throw LockboxException(
          'Content too large: ${content.length} characters (max 4000)',
          errorCode: 'CONTENT_TOO_LARGE',
        );
      }

      // Get existing lockbox metadata
      final lockboxes = await _storageService.getLockboxes();
      final lockboxIndex = lockboxes.indexWhere((lb) => lb.id == lockboxId);

      if (lockboxIndex == -1) {
        throw LockboxException(
          'Lockbox not found: $lockboxId',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      final existingLockbox = lockboxes[lockboxIndex];

      // Encrypt the new content
      final encryptedContent = await _encryptionService.encryptText(content);

      // Update lockbox metadata with new size
      final updatedMetadata = existingLockbox.copyWith(
        size: content.length,
      );

      // Store updated content and metadata
      await _storageService.storeLockboxContent(lockboxId, encryptedContent);
      await _storageService.updateLockbox(updatedMetadata);
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to update lockbox: ${e.toString()}',
        errorCode: 'UPDATE_LOCKBOX_FAILED',
      );
    }
  }

  @override
  Future<void> updateLockboxName({
    required String lockboxId,
    required String name,
  }) async {
    try {
      // Validate name
      if (name.isEmpty) {
        throw LockboxException(
          'Lockbox name cannot be empty',
          errorCode: 'EMPTY_NAME',
        );
      }

      if (name.length > 100) {
        throw LockboxException(
          'Lockbox name too long: ${name.length} characters (max 100)',
          errorCode: 'NAME_TOO_LONG',
        );
      }

      // Get existing lockbox metadata
      final lockboxes = await _storageService.getLockboxes();
      final lockboxIndex = lockboxes.indexWhere((lb) => lb.id == lockboxId);

      if (lockboxIndex == -1) {
        throw LockboxException(
          'Lockbox not found: $lockboxId',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      final existingLockbox = lockboxes[lockboxIndex];

      // Update lockbox metadata with new name
      final updatedMetadata = existingLockbox.copyWith(name: name);

      // Store updated metadata
      await _storageService.updateLockbox(updatedMetadata);
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to update lockbox name: ${e.toString()}',
        errorCode: 'UPDATE_NAME_FAILED',
      );
    }
  }

  @override
  Future<void> deleteLockbox(String lockboxId) async {
    try {
      // Verify lockbox exists before deletion
      final lockboxes = await _storageService.getLockboxes();
      final lockboxExists = lockboxes.any((lb) => lb.id == lockboxId);

      if (!lockboxExists) {
        throw LockboxException(
          'Lockbox not found: $lockboxId',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      // Remove lockbox and its content
      await _storageService.removeLockbox(lockboxId);
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to delete lockbox: ${e.toString()}',
        errorCode: 'DELETE_LOCKBOX_FAILED',
      );
    }
  }

  @override
  Future<bool> authenticateUser() async {
    try {
      return await _authService.authenticateUser();
    } catch (e) {
      throw LockboxException(
        'Authentication failed: ${e.toString()}',
        errorCode: 'AUTHENTICATION_FAILED',
      );
    }
  }

  /// Generates a unique ID for lockboxes
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp.toRadixString(36)}-${random.toRadixString(36)}';
  }

  /// Validates lockbox ID format
  bool _isValidLockboxId(String lockboxId) {
    return lockboxId.isNotEmpty && lockboxId.contains('-');
  }

  /// Gets lockbox statistics
  Future<LockboxStats> getStatistics() async {
    try {
      final lockboxes = await _storageService.getLockboxes();
      
      if (lockboxes.isEmpty) {
        return const LockboxStats(
          totalLockboxes: 0,
          totalSize: 0,
          averageSize: 0,
          oldestLockbox: null,
          newestLockbox: null,
        );
      }

      final totalSize = lockboxes.fold(0, (sum, lb) => sum + lb.size);
      final averageSize = totalSize / lockboxes.length;
      
      // Find oldest and newest
      final sortedByDate = List<LockboxMetadata>.from(lockboxes)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return LockboxStats(
        totalLockboxes: lockboxes.length,
        totalSize: totalSize,
        averageSize: averageSize,
        oldestLockbox: sortedByDate.first.createdAt,
        newestLockbox: sortedByDate.last.createdAt,
      );
    } catch (e) {
      throw LockboxException(
        'Failed to get statistics: ${e.toString()}',
        errorCode: 'GET_STATS_FAILED',
      );
    }
  }
}

/// Lockbox statistics information
class LockboxStats {
  const LockboxStats({
    required this.totalLockboxes,
    required this.totalSize,
    required this.averageSize,
    required this.oldestLockbox,
    required this.newestLockbox,
  });

  final int totalLockboxes;
  final int totalSize;
  final double averageSize;
  final DateTime? oldestLockbox;
  final DateTime? newestLockbox;

  @override
  String toString() {
    return 'LockboxStats{totalLockboxes: $totalLockboxes, totalSize: $totalSize, averageSize: ${averageSize.toStringAsFixed(1)}}';
  }
}