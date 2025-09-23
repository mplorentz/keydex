// LockboxService Implementation
// Implements lockbox operations with encryption and storage

import 'package:uuid/uuid.dart';
import '../contracts/lockbox_service.dart';
import '../models/lockbox.dart';
import '../models/text_content.dart';
import 'storage_service.dart';
import 'encryption_service.dart';
import 'auth_service.dart';

class LockboxServiceImpl implements LockboxService {
  final StorageService _storageService;
  final EncryptionService _encryptionService;
  final AuthService _authService;
  final Uuid _uuid = const Uuid();

  LockboxServiceImpl(
    this._storageService,
    this._encryptionService,
    this._authService,
  );

  @override
  Future<String> createLockbox({
    required String name,
    required String content,
  }) async {
    try {
      // Validate input
      _validateLockboxName(name);
      _validateContent(content);

      // Check if encryption key is available
      final hasKey = await _encryptionService.getCurrentKeyPair();
      if (hasKey == null) {
        throw LockboxException(
          'No encryption key available. Please set up encryption first.',
          errorCode: 'NO_ENCRYPTION_KEY',
        );
      }

      // Generate unique ID for the lockbox
      final lockboxId = _uuid.v4();

      // Create text content model
      final textContent = TextContent(
        content: content,
        lockboxId: lockboxId,
      );
      textContent.validate(); // Validate content

      // Encrypt the content
      final encryptedContent = await _encryptionService.encryptText(content);

      // Create lockbox metadata
      final lockboxMetadata = LockboxMetadata(
        id: lockboxId,
        name: name,
        createdAt: DateTime.now(),
        size: content.length,
      );

      // Store the lockbox metadata and encrypted content
      await _storageService.addLockbox(lockboxMetadata);
      await _storageService.saveEncryptedContent(lockboxId, encryptedContent);

      return lockboxId;
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to create lockbox: ${e.toString()}',
        errorCode: 'CREATE_FAILED',
      );
    }
  }

  @override
  Future<List<LockboxMetadata>> getAllLockboxes() async {
    try {
      return await _storageService.getAllLockboxes();
    } catch (e) {
      throw LockboxException(
        'Failed to retrieve lockboxes: ${e.toString()}',
        errorCode: 'RETRIEVAL_FAILED',
      );
    }
  }

  @override
  Future<LockboxContent> getLockboxContent(String lockboxId) async {
    try {
      // Authenticate user before accessing sensitive content
      final isAuthenticated = await authenticateUser();
      if (!isAuthenticated) {
        throw LockboxException(
          'Authentication required to access lockbox content.',
          errorCode: 'AUTHENTICATION_REQUIRED',
        );
      }

      // Get lockbox metadata
      final lockboxMetadata = await _storageService.getLockboxById(lockboxId);
      if (lockboxMetadata == null) {
        throw LockboxException(
          'Lockbox with ID $lockboxId not found.',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      // Get encrypted content
      final encryptedContent = await _storageService.getEncryptedContent(lockboxId);
      if (encryptedContent == null) {
        throw LockboxException(
          'Encrypted content for lockbox $lockboxId not found.',
          errorCode: 'CONTENT_NOT_FOUND',
        );
      }

      // Decrypt the content
      final decryptedContent = await _encryptionService.decryptText(encryptedContent);

      // Return lockbox content
      return LockboxContent(
        id: lockboxMetadata.id,
        name: lockboxMetadata.name,
        content: decryptedContent,
        createdAt: lockboxMetadata.createdAt,
      );
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to get lockbox content: ${e.toString()}',
        errorCode: 'CONTENT_RETRIEVAL_FAILED',
      );
    }
  }

  @override
  Future<void> updateLockbox({
    required String lockboxId,
    required String content,
  }) async {
    try {
      // Validate input
      _validateContent(content);

      // Check if lockbox exists
      final existingLockbox = await _storageService.getLockboxById(lockboxId);
      if (existingLockbox == null) {
        throw LockboxException(
          'Lockbox with ID $lockboxId not found.',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      // Encrypt the new content
      final encryptedContent = await _encryptionService.encryptText(content);

      // Update lockbox metadata with new size
      final updatedMetadata = existingLockbox.copyWith(size: content.length);
      await _storageService.updateLockbox(updatedMetadata);

      // Save the new encrypted content
      await _storageService.saveEncryptedContent(lockboxId, encryptedContent);
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to update lockbox: ${e.toString()}',
        errorCode: 'UPDATE_FAILED',
      );
    }
  }

  @override
  Future<void> updateLockboxName({
    required String lockboxId,
    required String name,
  }) async {
    try {
      // Validate input
      _validateLockboxName(name);

      // Check if lockbox exists
      final existingLockbox = await _storageService.getLockboxById(lockboxId);
      if (existingLockbox == null) {
        throw LockboxException(
          'Lockbox with ID $lockboxId not found.',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      // Update lockbox metadata with new name
      final updatedMetadata = existingLockbox.copyWith(name: name);
      await _storageService.updateLockbox(updatedMetadata);
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to update lockbox name: ${e.toString()}',
        errorCode: 'NAME_UPDATE_FAILED',
      );
    }
  }

  @override
  Future<void> deleteLockbox(String lockboxId) async {
    try {
      // Check if lockbox exists
      final existingLockbox = await _storageService.getLockboxById(lockboxId);
      if (existingLockbox == null) {
        throw LockboxException(
          'Lockbox with ID $lockboxId not found.',
          errorCode: 'LOCKBOX_NOT_FOUND',
        );
      }

      // Delete the lockbox and its encrypted content
      await _storageService.deleteLockbox(lockboxId);
    } catch (e) {
      if (e is LockboxException) rethrow;
      throw LockboxException(
        'Failed to delete lockbox: ${e.toString()}',
        errorCode: 'DELETE_FAILED',
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

  // Additional utility methods
  Future<int> getLockboxCount() async {
    try {
      final lockboxes = await getAllLockboxes();
      return lockboxes.length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> lockboxExists(String lockboxId) async {
    try {
      return await _storageService.hasLockbox(lockboxId);
    } catch (e) {
      return false;
    }
  }

  Future<List<LockboxMetadata>> searchLockboxes(String query) async {
    try {
      final allLockboxes = await getAllLockboxes();
      if (query.trim().isEmpty) return allLockboxes;

      final lowercaseQuery = query.toLowerCase();
      return allLockboxes
          .where((lockbox) => lockbox.name.toLowerCase().contains(lowercaseQuery))
          .toList();
    } catch (e) {
      throw LockboxException(
        'Failed to search lockboxes: ${e.toString()}',
        errorCode: 'SEARCH_FAILED',
      );
    }
  }

  Future<Map<String, dynamic>> getLockboxStatistics() async {
    try {
      final lockboxes = await getAllLockboxes();
      
      if (lockboxes.isEmpty) {
        return {
          'totalCount': 0,
          'totalSize': 0,
          'averageSize': 0,
          'oldestCreated': null,
          'newestCreated': null,
        };
      }

      final totalSize = lockboxes.fold<int>(0, (sum, lockbox) => sum + lockbox.size);
      final sortedByDate = lockboxes.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return {
        'totalCount': lockboxes.length,
        'totalSize': totalSize,
        'averageSize': (totalSize / lockboxes.length).round(),
        'oldestCreated': sortedByDate.first.createdAt.toIso8601String(),
        'newestCreated': sortedByDate.last.createdAt.toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  // Private validation methods
  void _validateLockboxName(String name) {
    if (name.trim().isEmpty) {
      throw LockboxException(
        'Lockbox name cannot be empty.',
        errorCode: 'INVALID_NAME',
      );
    }

    if (name.length > 100) {
      throw LockboxException(
        'Lockbox name cannot exceed 100 characters.',
        errorCode: 'NAME_TOO_LONG',
      );
    }
  }

  void _validateContent(String content) {
    if (content.length > 4000) {
      throw LockboxException(
        'Content cannot exceed 4000 characters.',
        errorCode: 'CONTENT_TOO_LONG',
      );
    }
  }
}