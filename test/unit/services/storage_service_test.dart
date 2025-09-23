import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/services/storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('StorageService Tests', () {
    late MockSharedPreferences mockPrefs;
    late StorageService storageService;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      storageService = StorageService(prefs: mockPrefs);
    });

    group('Lockbox Storage', () {
      test('should store lockboxes correctly', () async {
        // Arrange
        final lockboxes = [
          LockboxMetadata(
            id: 'test-id-1',
            name: 'Test Lockbox 1',
            createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
            size: 100,
          ),
          LockboxMetadata(
            id: 'test-id-2',
            name: 'Test Lockbox 2',
            createdAt: DateTime.parse('2024-01-02T12:00:00.000Z'),
            size: 200,
          ),
        ];
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await storageService.storeLockboxes(lockboxes);

        // Assert
        final expectedJson = jsonEncode(lockboxes.map((lb) => lb.toJson()).toList());
        verify(mockPrefs.setString('lockboxes', expectedJson)).called(1);
      });

      test('should retrieve lockboxes correctly', () async {
        // Arrange
        final lockboxesJson = jsonEncode([
          {
            'id': 'test-id-1',
            'name': 'Test Lockbox 1',
            'createdAt': '2024-01-01T12:00:00.000Z',
            'size': 100,
          },
          {
            'id': 'test-id-2',
            'name': 'Test Lockbox 2',
            'createdAt': '2024-01-02T12:00:00.000Z',
            'size': 200,
          },
        ]);
        when(mockPrefs.getString('lockboxes')).thenReturn(lockboxesJson);

        // Act
        final result = await storageService.getLockboxes();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, equals('test-id-1'));
        expect(result[0].name, equals('Test Lockbox 1'));
        expect(result[0].size, equals(100));
        expect(result[1].id, equals('test-id-2'));
        expect(result[1].name, equals('Test Lockbox 2'));
        expect(result[1].size, equals(200));
        verify(mockPrefs.getString('lockboxes')).called(1);
      });

      test('should return empty list when no lockboxes stored', () async {
        // Arrange
        when(mockPrefs.getString('lockboxes')).thenReturn(null);

        // Act
        final result = await storageService.getLockboxes();

        // Assert
        expect(result, isEmpty);
        verify(mockPrefs.getString('lockboxes')).called(1);
      });

      test('should throw StorageException when storing lockboxes fails', () async {
        // Arrange
        final lockboxes = [
          LockboxMetadata(
            id: 'test-id',
            name: 'Test',
            createdAt: DateTime.now(),
            size: 100,
          ),
        ];
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => storageService.storeLockboxes(lockboxes),
          throwsA(isA<StorageException>().having(
            (e) => e.errorCode,
            'error code',
            'STORE_LOCKBOXES_FAILED',
          )),
        );
      });

      test('should throw StorageException when retrieving lockboxes fails', () async {
        // Arrange
        when(mockPrefs.getString('lockboxes')).thenThrow(Exception('Retrieval error'));

        // Act & Assert
        expect(
          () => storageService.getLockboxes(),
          throwsA(isA<StorageException>().having(
            (e) => e.errorCode,
            'error code',
            'GET_LOCKBOXES_FAILED',
          )),
        );
      });
    });

    group('Lockbox Content Storage', () {
      test('should store lockbox content correctly', () async {
        // Arrange
        const lockboxId = 'test-id';
        const encryptedContent = 'encrypted-content-here';
        when(mockPrefs.getString('lockbox_contents')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await storageService.storeLockboxContent(lockboxId, encryptedContent);

        // Assert
        final expectedJson = jsonEncode({lockboxId: encryptedContent});
        verify(mockPrefs.setString('lockbox_contents', expectedJson)).called(1);
      });

      test('should update existing lockbox content', () async {
        // Arrange
        const lockboxId = 'test-id';
        const newEncryptedContent = 'new-encrypted-content';
        final existingContents = {'other-id': 'other-content'};
        when(mockPrefs.getString('lockbox_contents'))
            .thenReturn(jsonEncode(existingContents));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await storageService.storeLockboxContent(lockboxId, newEncryptedContent);

        // Assert
        final expectedContents = {
          'other-id': 'other-content',
          lockboxId: newEncryptedContent,
        };
        verify(mockPrefs.setString('lockbox_contents', jsonEncode(expectedContents)))
            .called(1);
      });

      test('should retrieve lockbox content correctly', () async {
        // Arrange
        const lockboxId = 'test-id';
        const encryptedContent = 'encrypted-content';
        final contents = {lockboxId: encryptedContent};
        when(mockPrefs.getString('lockbox_contents')).thenReturn(jsonEncode(contents));

        // Act
        final result = await storageService.getLockboxContent(lockboxId);

        // Assert
        expect(result, equals(encryptedContent));
        verify(mockPrefs.getString('lockbox_contents')).called(1);
      });

      test('should return null when lockbox content not found', () async {
        // Arrange
        const lockboxId = 'non-existent-id';
        when(mockPrefs.getString('lockbox_contents')).thenReturn(null);

        // Act
        final result = await storageService.getLockboxContent(lockboxId);

        // Assert
        expect(result, isNull);
      });

      test('should return null when lockbox ID not in contents', () async {
        // Arrange
        const lockboxId = 'missing-id';
        final contents = {'other-id': 'content'};
        when(mockPrefs.getString('lockbox_contents')).thenReturn(jsonEncode(contents));

        // Act
        final result = await storageService.getLockboxContent(lockboxId);

        // Assert
        expect(result, isNull);
      });
    });

    group('Lockbox Management', () {
      test('should add new lockbox correctly', () async {
        // Arrange
        final newLockbox = LockboxMetadata(
          id: 'new-id',
          name: 'New Lockbox',
          createdAt: DateTime.now(),
          size: 150,
        );
        final existingLockboxes = [
          LockboxMetadata(
            id: 'existing-id',
            name: 'Existing',
            createdAt: DateTime.now(),
            size: 100,
          ),
        ];
        when(mockPrefs.getString('lockboxes'))
            .thenReturn(jsonEncode(existingLockboxes.map((lb) => lb.toJson()).toList()));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await storageService.addLockbox(newLockbox);

        // Assert
        final allLockboxes = [...existingLockboxes, newLockbox];
        final expectedJson = jsonEncode(allLockboxes.map((lb) => lb.toJson()).toList());
        verify(mockPrefs.setString('lockboxes', expectedJson)).called(1);
      });

      test('should throw StorageException when adding duplicate lockbox', () async {
        // Arrange
        final existingLockbox = LockboxMetadata(
          id: 'duplicate-id',
          name: 'Existing',
          createdAt: DateTime.now(),
          size: 100,
        );
        final duplicateLockbox = LockboxMetadata(
          id: 'duplicate-id',
          name: 'Duplicate',
          createdAt: DateTime.now(),
          size: 200,
        );
        when(mockPrefs.getString('lockboxes'))
            .thenReturn(jsonEncode([existingLockbox.toJson()]));

        // Act & Assert
        expect(
          () => storageService.addLockbox(duplicateLockbox),
          throwsA(isA<StorageException>().having(
            (e) => e.errorCode,
            'error code',
            'LOCKBOX_ALREADY_EXISTS',
          )),
        );
      });

      test('should update existing lockbox correctly', () async {
        // Arrange
        final originalLockbox = LockboxMetadata(
          id: 'test-id',
          name: 'Original',
          createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
          size: 100,
        );
        final updatedLockbox = originalLockbox.copyWith(name: 'Updated', size: 200);
        when(mockPrefs.getString('lockboxes'))
            .thenReturn(jsonEncode([originalLockbox.toJson()]));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await storageService.updateLockbox(updatedLockbox);

        // Assert
        final expectedJson = jsonEncode([updatedLockbox.toJson()]);
        verify(mockPrefs.setString('lockboxes', expectedJson)).called(1);
      });

      test('should throw StorageException when updating non-existent lockbox', () async {
        // Arrange
        final nonExistentLockbox = LockboxMetadata(
          id: 'non-existent',
          name: 'Test',
          createdAt: DateTime.now(),
          size: 100,
        );
        when(mockPrefs.getString('lockboxes')).thenReturn(jsonEncode([]));

        // Act & Assert
        expect(
          () => storageService.updateLockbox(nonExistentLockbox),
          throwsA(isA<StorageException>().having(
            (e) => e.errorCode,
            'error code',
            'LOCKBOX_NOT_FOUND',
          )),
        );
      });

      test('should remove lockbox correctly', () async {
        // Arrange
        const lockboxIdToRemove = 'remove-id';
        final lockboxToKeep = LockboxMetadata(
          id: 'keep-id',
          name: 'Keep',
          createdAt: DateTime.now(),
          size: 100,
        );
        final lockboxToRemove = LockboxMetadata(
          id: lockboxIdToRemove,
          name: 'Remove',
          createdAt: DateTime.now(),
          size: 200,
        );
        final allLockboxes = [lockboxToKeep, lockboxToRemove];
        final contents = {
          'keep-id': 'keep-content',
          lockboxIdToRemove: 'remove-content',
        };

        when(mockPrefs.getString('lockboxes'))
            .thenReturn(jsonEncode(allLockboxes.map((lb) => lb.toJson()).toList()));
        when(mockPrefs.getString('lockbox_contents'))
            .thenReturn(jsonEncode(contents));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await storageService.removeLockbox(lockboxIdToRemove);

        // Assert
        final expectedLockboxes = jsonEncode([lockboxToKeep.toJson()]);
        final expectedContents = jsonEncode({'keep-id': 'keep-content'});
        
        verify(mockPrefs.setString('lockboxes', expectedLockboxes)).called(1);
        verify(mockPrefs.setString('lockbox_contents', expectedContents)).called(1);
      });
    });

    group('User Preferences', () {
      test('should store user preferences correctly', () async {
        // Arrange
        final preferences = {'theme': 'dark', 'notifications': true};
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await storageService.storeUserPreferences(preferences);

        // Assert
        verify(mockPrefs.setString('user_preferences', jsonEncode(preferences))).called(1);
      });

      test('should retrieve user preferences correctly', () async {
        // Arrange
        final preferences = {'theme': 'light', 'notifications': false};
        when(mockPrefs.getString('user_preferences')).thenReturn(jsonEncode(preferences));

        // Act
        final result = await storageService.getUserPreferences();

        // Assert
        expect(result, equals(preferences));
        verify(mockPrefs.getString('user_preferences')).called(1);
      });

      test('should return empty map when no preferences stored', () async {
        // Arrange
        when(mockPrefs.getString('user_preferences')).thenReturn(null);

        // Act
        final result = await storageService.getUserPreferences();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Clear Data', () {
      test('should clear all data correctly', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        // Act
        await storageService.clearAll();

        // Assert
        verify(mockPrefs.remove('lockboxes')).called(1);
        verify(mockPrefs.remove('lockbox_contents')).called(1);
        verify(mockPrefs.remove('user_preferences')).called(1);
      });

      test('should throw StorageException when clear fails', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenThrow(Exception('Clear error'));

        // Act & Assert
        expect(
          () => storageService.clearAll(),
          throwsA(isA<StorageException>().having(
            (e) => e.errorCode,
            'error code',
            'CLEAR_ALL_FAILED',
          )),
        );
      });
    });

    group('Storage Statistics', () {
      test('should calculate storage stats correctly', () async {
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
        final contents = {
          'id1': 'content1' * 25, // 100 chars
          'id2': 'content2' * 50, // 200 chars
        };

        when(mockPrefs.getString('lockboxes'))
            .thenReturn(jsonEncode(lockboxes.map((lb) => lb.toJson()).toList()));
        when(mockPrefs.getString('lockbox_contents'))
            .thenReturn(jsonEncode(contents));

        // Act
        final stats = await storageService.getStorageStats();

        // Assert
        expect(stats.totalLockboxes, equals(2));
        expect(stats.totalContentSize, equals(300)); // 100 + 200
        expect(stats.averageLockboxSize, equals(150.0)); // 300 / 2
      });

      test('should handle empty storage in stats', () async {
        // Arrange
        when(mockPrefs.getString('lockboxes')).thenReturn(jsonEncode([]));
        when(mockPrefs.getString('lockbox_contents')).thenReturn(null);

        // Act
        final stats = await storageService.getStorageStats();

        // Assert
        expect(stats.totalLockboxes, equals(0));
        expect(stats.totalContentSize, equals(0));
        expect(stats.averageLockboxSize, equals(0.0));
      });
    });
  });

  group('StorageException Tests', () {
    test('should create exception with message only', () {
      // Act
      final exception = StorageException('Test error message');

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, isNull);
    });

    test('should create exception with message and error code', () {
      // Act
      final exception = StorageException(
        'Test error message',
        errorCode: 'TEST_ERROR',
      );

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, equals('TEST_ERROR'));
    });

    test('toString should include error code when present', () {
      // Arrange
      final exception = StorageException(
        'Test error',
        errorCode: 'TEST_ERROR',
      );

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('StorageException(TEST_ERROR)'));
      expect(stringRepresentation, contains('Test error'));
    });

    test('toString should work without error code', () {
      // Arrange
      final exception = StorageException('Test error');

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('StorageException:'));
      expect(stringRepresentation, contains('Test error'));
    });
  });

  group('StorageStats Tests', () {
    test('should create storage stats correctly', () {
      // Act
      const stats = StorageStats(
        totalLockboxes: 5,
        totalContentSize: 1000,
        averageLockboxSize: 200.0,
      );

      // Assert
      expect(stats.totalLockboxes, equals(5));
      expect(stats.totalContentSize, equals(1000));
      expect(stats.averageLockboxSize, equals(200.0));
    });

    test('toString should provide meaningful representation', () {
      // Arrange
      const stats = StorageStats(
        totalLockboxes: 3,
        totalContentSize: 750,
        averageLockboxSize: 250.0,
      );

      // Act
      final stringRepresentation = stats.toString();

      // Assert
      expect(stringRepresentation, contains('StorageStats'));
      expect(stringRepresentation, contains('totalLockboxes: 3'));
      expect(stringRepresentation, contains('totalContentSize: 750'));
      expect(stringRepresentation, contains('averageLockboxSize: 250.0'));
    });
  });
}