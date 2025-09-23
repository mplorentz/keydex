import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/contracts/auth_service.dart';
import 'package:keydex/contracts/encryption_service.dart';
import 'package:keydex/contracts/lockbox_service.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/services/lockbox_service.dart';
import 'package:keydex/services/storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'lockbox_service_test.mocks.dart';

@GenerateMocks([AuthService, EncryptionService, StorageService])
void main() {
  group('LockboxServiceImpl Tests', () {
    late MockAuthService mockAuthService;
    late MockEncryptionService mockEncryptionService;
    late MockStorageService mockStorageService;
    late LockboxServiceImpl lockboxService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockEncryptionService = MockEncryptionService();
      mockStorageService = MockStorageService();
      lockboxService = LockboxServiceImpl(
        authService: mockAuthService,
        encryptionService: mockEncryptionService,
        storageService: mockStorageService,
      );
    });

    group('Create Lockbox', () {
      test('should create lockbox successfully', () async {
        // Arrange
        const name = 'Test Lockbox';
        const content = 'This is test content for the lockbox';
        const encryptedContent = 'encrypted-content-base64';
        
        when(mockEncryptionService.encryptText(content))
            .thenAnswer((_) async => encryptedContent);
        when(mockStorageService.addLockbox(any)).thenAnswer((_) async {});
        when(mockStorageService.storeLockboxContent(any, any)).thenAnswer((_) async {});

        // Act
        final lockboxId = await lockboxService.createLockbox(
          name: name,
          content: content,
        );

        // Assert
        expect(lockboxId, isNotEmpty);
        expect(lockboxId, contains('-')); // Should contain separator
        verify(mockEncryptionService.encryptText(content)).called(1);
        verify(mockStorageService.addLockbox(any)).called(1);
        verify(mockStorageService.storeLockboxContent(lockboxId, encryptedContent)).called(1);
      });

      test('should throw LockboxException for empty name', () async {
        // Act & Assert
        expect(
          () => lockboxService.createLockbox(name: '', content: 'content'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'EMPTY_NAME',
          )),
        );
      });

      test('should throw LockboxException for name too long', () async {
        // Arrange
        final longName = 'a' * 101;

        // Act & Assert
        expect(
          () => lockboxService.createLockbox(name: longName, content: 'content'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'NAME_TOO_LONG',
          )),
        );
      });

      test('should throw LockboxException for content too large', () async {
        // Arrange
        final largeContent = 'a' * 4001;

        // Act & Assert
        expect(
          () => lockboxService.createLockbox(name: 'Test', content: largeContent),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'CONTENT_TOO_LARGE',
          )),
        );
      });

      test('should handle encryption failure', () async {
        // Arrange
        when(mockEncryptionService.encryptText(any))
            .thenThrow(Exception('Encryption failed'));

        // Act & Assert
        expect(
          () => lockboxService.createLockbox(name: 'Test', content: 'content'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'CREATE_LOCKBOX_FAILED',
          )),
        );
      });

      test('should handle storage failure', () async {
        // Arrange
        when(mockEncryptionService.encryptText(any))
            .thenAnswer((_) async => 'encrypted');
        when(mockStorageService.addLockbox(any))
            .thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => lockboxService.createLockbox(name: 'Test', content: 'content'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'CREATE_LOCKBOX_FAILED',
          )),
        );
      });

      test('should validate lockbox name at boundary', () async {
        // Arrange - Name exactly 100 characters
        final boundaryName = 'a' * 100;
        when(mockEncryptionService.encryptText(any))
            .thenAnswer((_) async => 'encrypted');
        when(mockStorageService.addLockbox(any)).thenAnswer((_) async {});
        when(mockStorageService.storeLockboxContent(any, any)).thenAnswer((_) async {});

        // Act
        final lockboxId = await lockboxService.createLockbox(
          name: boundaryName,
          content: 'content',
        );

        // Assert
        expect(lockboxId, isNotEmpty);
      });

      test('should validate content at boundary', () async {
        // Arrange - Content exactly 4000 characters
        final boundaryContent = 'a' * 4000;
        when(mockEncryptionService.encryptText(any))
            .thenAnswer((_) async => 'encrypted');
        when(mockStorageService.addLockbox(any)).thenAnswer((_) async {});
        when(mockStorageService.storeLockboxContent(any, any)).thenAnswer((_) async {});

        // Act
        final lockboxId = await lockboxService.createLockbox(
          name: 'Test',
          content: boundaryContent,
        );

        // Assert
        expect(lockboxId, isNotEmpty);
      });
    });

    group('Get All Lockboxes', () {
      test('should retrieve all lockboxes successfully', () async {
        // Arrange
        final lockboxes = [
          LockboxMetadata(
            id: 'id1',
            name: 'Lockbox 1',
            createdAt: DateTime.now(),
            size: 100,
          ),
          LockboxMetadata(
            id: 'id2',
            name: 'Lockbox 2',
            createdAt: DateTime.now(),
            size: 200,
          ),
        ];
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => lockboxes);

        // Act
        final result = await lockboxService.getAllLockboxes();

        // Assert
        expect(result, equals(lockboxes));
        verify(mockStorageService.getLockboxes()).called(1);
      });

      test('should return empty list when no lockboxes exist', () async {
        // Arrange
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => []);

        // Act
        final result = await lockboxService.getAllLockboxes();

        // Assert
        expect(result, isEmpty);
      });

      test('should handle storage failure', () async {
        // Arrange
        when(mockStorageService.getLockboxes())
            .thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => lockboxService.getAllLockboxes(),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'GET_LOCKBOXES_FAILED',
          )),
        );
      });
    });

    group('Get Lockbox Content', () {
      test('should get lockbox content successfully', () async {
        // Arrange
        const lockboxId = 'test-id';
        final lockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Test Lockbox',
          createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
          size: 100,
        );
        const encryptedContent = 'encrypted-content';
        const decryptedContent = 'This is the decrypted content';

        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => [lockbox]);
        when(mockStorageService.getLockboxContent(lockboxId))
            .thenAnswer((_) async => encryptedContent);
        when(mockEncryptionService.decryptText(encryptedContent))
            .thenAnswer((_) async => decryptedContent);

        // Act
        final result = await lockboxService.getLockboxContent(lockboxId);

        // Assert
        expect(result.id, equals(lockboxId));
        expect(result.name, equals('Test Lockbox'));
        expect(result.content, equals(decryptedContent));
        expect(result.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        
        verify(mockAuthService.authenticateUser()).called(1);
        verify(mockStorageService.getLockboxes()).called(1);
        verify(mockStorageService.getLockboxContent(lockboxId)).called(1);
        verify(mockEncryptionService.decryptText(encryptedContent)).called(1);
      });

      test('should throw LockboxException when authentication fails', () async {
        // Arrange
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => lockboxService.getLockboxContent('test-id'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'AUTHENTICATION_REQUIRED',
          )),
        );
        
        verifyNever(mockStorageService.getLockboxes());
      });

      test('should throw LockboxException when lockbox not found', () async {
        // Arrange
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => lockboxService.getLockboxContent('non-existent-id'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'LOCKBOX_NOT_FOUND',
          )),
        );
      });

      test('should throw LockboxException when content not found', () async {
        // Arrange
        const lockboxId = 'test-id';
        final lockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Test',
          createdAt: DateTime.now(),
          size: 100,
        );
        
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => [lockbox]);
        when(mockStorageService.getLockboxContent(lockboxId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => lockboxService.getLockboxContent(lockboxId),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'CONTENT_NOT_FOUND',
          )),
        );
      });

      test('should handle decryption failure', () async {
        // Arrange
        const lockboxId = 'test-id';
        final lockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Test',
          createdAt: DateTime.now(),
          size: 100,
        );
        
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => [lockbox]);
        when(mockStorageService.getLockboxContent(lockboxId))
            .thenAnswer((_) async => 'encrypted');
        when(mockEncryptionService.decryptText(any))
            .thenThrow(Exception('Decryption failed'));

        // Act & Assert
        expect(
          () => lockboxService.getLockboxContent(lockboxId),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'GET_CONTENT_FAILED',
          )),
        );
      });

      test('should handle authentication exception', () async {
        // Arrange
        when(mockAuthService.authenticateUser())
            .thenThrow(Exception('Auth failed'));

        // Act & Assert
        expect(
          () => lockboxService.getLockboxContent('test-id'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'GET_CONTENT_FAILED',
          )),
        );
      });
    });

    group('Update Lockbox Content', () {
      test('should update lockbox content successfully', () async {
        // Arrange
        const lockboxId = 'test-id';
        const newContent = 'Updated content';
        const encryptedContent = 'encrypted-updated-content';
        final existingLockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Test Lockbox',
          createdAt: DateTime.now(),
          size: 100,
        );

        when(mockStorageService.getLockboxes())
            .thenAnswer((_) async => [existingLockbox]);
        when(mockEncryptionService.encryptText(newContent))
            .thenAnswer((_) async => encryptedContent);
        when(mockStorageService.storeLockboxContent(any, any))
            .thenAnswer((_) async {});
        when(mockStorageService.updateLockbox(any))
            .thenAnswer((_) async {});

        // Act
        await lockboxService.updateLockbox(
          lockboxId: lockboxId,
          content: newContent,
        );

        // Assert
        verify(mockEncryptionService.encryptText(newContent)).called(1);
        verify(mockStorageService.storeLockboxContent(lockboxId, encryptedContent)).called(1);
        verify(mockStorageService.updateLockbox(any)).called(1);
      });

      test('should throw LockboxException for content too large', () async {
        // Arrange
        final largeContent = 'a' * 4001;

        // Act & Assert
        expect(
          () => lockboxService.updateLockbox(
            lockboxId: 'test-id',
            content: largeContent,
          ),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'CONTENT_TOO_LARGE',
          )),
        );
      });

      test('should throw LockboxException when lockbox not found', () async {
        // Arrange
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => lockboxService.updateLockbox(
            lockboxId: 'non-existent-id',
            content: 'content',
          ),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'LOCKBOX_NOT_FOUND',
          )),
        );
      });

      test('should update metadata with new content size', () async {
        // Arrange
        const lockboxId = 'test-id';
        const newContent = 'Updated content with different length';
        final existingLockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Test',
          createdAt: DateTime.now(),
          size: 100,
        );

        when(mockStorageService.getLockboxes())
            .thenAnswer((_) async => [existingLockbox]);
        when(mockEncryptionService.encryptText(any))
            .thenAnswer((_) async => 'encrypted');
        when(mockStorageService.storeLockboxContent(any, any))
            .thenAnswer((_) async {});
        when(mockStorageService.updateLockbox(any))
            .thenAnswer((_) async {});

        // Act
        await lockboxService.updateLockbox(
          lockboxId: lockboxId,
          content: newContent,
        );

        // Assert
        final capturedMetadata = verify(mockStorageService.updateLockbox(captureAny))
            .captured.first as LockboxMetadata;
        expect(capturedMetadata.size, equals(newContent.length));
      });
    });

    group('Update Lockbox Name', () {
      test('should update lockbox name successfully', () async {
        // Arrange
        const lockboxId = 'test-id';
        const newName = 'Updated Name';
        final existingLockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Original Name',
          createdAt: DateTime.now(),
          size: 100,
        );

        when(mockStorageService.getLockboxes())
            .thenAnswer((_) async => [existingLockbox]);
        when(mockStorageService.updateLockbox(any))
            .thenAnswer((_) async {});

        // Act
        await lockboxService.updateLockboxName(
          lockboxId: lockboxId,
          name: newName,
        );

        // Assert
        final capturedMetadata = verify(mockStorageService.updateLockbox(captureAny))
            .captured.first as LockboxMetadata;
        expect(capturedMetadata.name, equals(newName));
      });

      test('should throw LockboxException for empty name', () async {
        // Act & Assert
        expect(
          () => lockboxService.updateLockboxName(
            lockboxId: 'test-id',
            name: '',
          ),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'EMPTY_NAME',
          )),
        );
      });

      test('should throw LockboxException for name too long', () async {
        // Arrange
        final longName = 'a' * 101;

        // Act & Assert
        expect(
          () => lockboxService.updateLockboxName(
            lockboxId: 'test-id',
            name: longName,
          ),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'NAME_TOO_LONG',
          )),
        );
      });

      test('should throw LockboxException when lockbox not found', () async {
        // Arrange
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => lockboxService.updateLockboxName(
            lockboxId: 'non-existent-id',
            name: 'New Name',
          ),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'LOCKBOX_NOT_FOUND',
          )),
        );
      });
    });

    group('Delete Lockbox', () {
      test('should delete lockbox successfully', () async {
        // Arrange
        const lockboxId = 'test-id';
        final existingLockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Test',
          createdAt: DateTime.now(),
          size: 100,
        );

        when(mockStorageService.getLockboxes())
            .thenAnswer((_) async => [existingLockbox]);
        when(mockStorageService.removeLockbox(lockboxId))
            .thenAnswer((_) async {});

        // Act
        await lockboxService.deleteLockbox(lockboxId);

        // Assert
        verify(mockStorageService.removeLockbox(lockboxId)).called(1);
      });

      test('should throw LockboxException when lockbox not found', () async {
        // Arrange
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => lockboxService.deleteLockbox('non-existent-id'),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'LOCKBOX_NOT_FOUND',
          )),
        );
      });

      test('should handle storage deletion failure', () async {
        // Arrange
        const lockboxId = 'test-id';
        final existingLockbox = LockboxMetadata(
          id: lockboxId,
          name: 'Test',
          createdAt: DateTime.now(),
          size: 100,
        );

        when(mockStorageService.getLockboxes())
            .thenAnswer((_) async => [existingLockbox]);
        when(mockStorageService.removeLockbox(lockboxId))
            .thenThrow(Exception('Deletion failed'));

        // Act & Assert
        expect(
          () => lockboxService.deleteLockbox(lockboxId),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'DELETE_LOCKBOX_FAILED',
          )),
        );
      });
    });

    group('Authenticate User', () {
      test('should authenticate user successfully', () async {
        // Arrange
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);

        // Act
        final result = await lockboxService.authenticateUser();

        // Assert
        expect(result, isTrue);
        verify(mockAuthService.authenticateUser()).called(1);
      });

      test('should return false when authentication fails', () async {
        // Arrange
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => false);

        // Act
        final result = await lockboxService.authenticateUser();

        // Assert
        expect(result, isFalse);
      });

      test('should handle authentication exception', () async {
        // Arrange
        when(mockAuthService.authenticateUser())
            .thenThrow(Exception('Auth failed'));

        // Act & Assert
        expect(
          () => lockboxService.authenticateUser(),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'AUTHENTICATION_FAILED',
          )),
        );
      });
    });

    group('Statistics', () {
      test('should calculate statistics correctly', () async {
        // Arrange
        final lockboxes = [
          LockboxMetadata(
            id: 'id1',
            name: 'Lockbox 1',
            createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
            size: 100,
          ),
          LockboxMetadata(
            id: 'id2',
            name: 'Lockbox 2',
            createdAt: DateTime.parse('2024-01-02T12:00:00.000Z'),
            size: 200,
          ),
          LockboxMetadata(
            id: 'id3',
            name: 'Lockbox 3',
            createdAt: DateTime.parse('2024-01-03T12:00:00.000Z'),
            size: 300,
          ),
        ];
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => lockboxes);

        // Act
        final stats = await lockboxService.getStatistics();

        // Assert
        expect(stats.totalLockboxes, equals(3));
        expect(stats.totalSize, equals(600)); // 100 + 200 + 300
        expect(stats.averageSize, equals(200.0)); // 600 / 3
        expect(stats.oldestLockbox, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(stats.newestLockbox, equals(DateTime.parse('2024-01-03T12:00:00.000Z')));
      });

      test('should handle empty lockbox list', () async {
        // Arrange
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => []);

        // Act
        final stats = await lockboxService.getStatistics();

        // Assert
        expect(stats.totalLockboxes, equals(0));
        expect(stats.totalSize, equals(0));
        expect(stats.averageSize, equals(0.0));
        expect(stats.oldestLockbox, isNull);
        expect(stats.newestLockbox, isNull);
      });

      test('should handle single lockbox', () async {
        // Arrange
        final singleLockbox = LockboxMetadata(
          id: 'single-id',
          name: 'Single Lockbox',
          createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
          size: 150,
        );
        when(mockStorageService.getLockboxes()).thenAnswer((_) async => [singleLockbox]);

        // Act
        final stats = await lockboxService.getStatistics();

        // Assert
        expect(stats.totalLockboxes, equals(1));
        expect(stats.totalSize, equals(150));
        expect(stats.averageSize, equals(150.0));
        expect(stats.oldestLockbox, equals(stats.newestLockbox));
      });

      test('should handle storage failure', () async {
        // Arrange
        when(mockStorageService.getLockboxes())
            .thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => lockboxService.getStatistics(),
          throwsA(isA<LockboxException>().having(
            (e) => e.errorCode,
            'error code',
            'GET_STATS_FAILED',
          )),
        );
      });
    });

    group('ID Generation', () {
      test('should generate valid lockbox IDs', () async {
        // Arrange
        when(mockEncryptionService.encryptText(any))
            .thenAnswer((_) async => 'encrypted');
        when(mockStorageService.addLockbox(any)).thenAnswer((_) async {});
        when(mockStorageService.storeLockboxContent(any, any)).thenAnswer((_) async {});

        // Act
        final id1 = await lockboxService.createLockbox(name: 'Test 1', content: 'content 1');
        final id2 = await lockboxService.createLockbox(name: 'Test 2', content: 'content 2');

        // Assert
        expect(id1, isNotEmpty);
        expect(id2, isNotEmpty);
        expect(id1, isNot(equals(id2))); // IDs should be unique
        expect(id1, contains('-')); // Should contain separator
        expect(id2, contains('-'));
      });
    });
  });

  group('LockboxStats Tests', () {
    test('should create stats correctly', () {
      // Act
      final stats = LockboxStats(
        totalLockboxes: 5,
        totalSize: 1000,
        averageSize: 200.0,
        oldestLockbox: DateTime.parse('2024-01-01T12:00:00.000Z'),
        newestLockbox: DateTime.parse('2024-01-05T12:00:00.000Z'),
      );

      // Assert
      expect(stats.totalLockboxes, equals(5));
      expect(stats.totalSize, equals(1000));
      expect(stats.averageSize, equals(200.0));
      expect(stats.oldestLockbox, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
      expect(stats.newestLockbox, equals(DateTime.parse('2024-01-05T12:00:00.000Z')));
    });

    test('toString should provide meaningful representation', () {
      // Arrange
      final stats = LockboxStats(
        totalLockboxes: 3,
        totalSize: 750,
        averageSize: 250.0,
        oldestLockbox: DateTime.now(),
        newestLockbox: DateTime.now(),
      );

      // Act
      final stringRepresentation = stats.toString();

      // Assert
      expect(stringRepresentation, contains('LockboxStats'));
      expect(stringRepresentation, contains('totalLockboxes: 3'));
      expect(stringRepresentation, contains('totalSize: 750'));
      expect(stringRepresentation, contains('averageSize: 250.0'));
    });
  });
}