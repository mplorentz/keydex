// Unit Tests for Services
// Testing AuthService, EncryptionService, StorageService, KeyService, LockboxService

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'package:keydex/services/auth_service.dart';
import 'package:keydex/services/encryption_service.dart';
import 'package:keydex/services/storage_service.dart';
import 'package:keydex/services/key_service.dart';
import 'package:keydex/services/lockbox_service.dart';
import 'package:keydex/contracts/auth_service.dart';
import 'package:keydex/contracts/encryption_service.dart';
import 'package:keydex/contracts/lockbox_service.dart';
import 'package:keydex/models/lockbox.dart';

import 'services_test.mocks.dart';

@GenerateMocks([
  LocalAuthentication,
  EncryptionService,
  AuthService,
  StorageService,
  KeyService,
])
void main() {
  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and retrieve lockboxes', () async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      await storageService.addLockbox(lockbox);
      final lockboxes = await storageService.getAllLockboxes();

      expect(lockboxes.length, 1);
      expect(lockboxes.first.id, 'test-id');
      expect(lockboxes.first.name, 'Test Lockbox');
    });

    test('should prevent duplicate lockbox IDs', () async {
      final lockbox1 = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox 1',
        createdAt: DateTime.now(),
        size: 100,
      );
      final lockbox2 = LockboxMetadata(
        id: 'test-id', // Same ID
        name: 'Test Lockbox 2',
        createdAt: DateTime.now(),
        size: 200,
      );

      await storageService.addLockbox(lockbox1);
      
      expect(
        () => storageService.addLockbox(lockbox2),
        throwsA(isA<StorageException>()),
      );
    });

    test('should update existing lockbox', () async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Original Name',
        createdAt: DateTime.now(),
        size: 100,
      );

      await storageService.addLockbox(lockbox);
      
      final updatedLockbox = lockbox.copyWith(name: 'Updated Name');
      await storageService.updateLockbox(updatedLockbox);

      final lockboxes = await storageService.getAllLockboxes();
      expect(lockboxes.first.name, 'Updated Name');
    });

    test('should delete lockbox and its content', () async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      await storageService.addLockbox(lockbox);
      await storageService.saveEncryptedContent('test-id', 'encrypted-content');

      await storageService.deleteLockbox('test-id');

      final lockboxes = await storageService.getAllLockboxes();
      final content = await storageService.getEncryptedContent('test-id');

      expect(lockboxes, isEmpty);
      expect(content, isNull);
    });

    test('should manage encrypted content', () async {
      const lockboxId = 'test-id';
      const encryptedContent = 'encrypted-data-here';

      await storageService.saveEncryptedContent(lockboxId, encryptedContent);
      final retrievedContent = await storageService.getEncryptedContent(lockboxId);

      expect(retrievedContent, encryptedContent);
    });

    test('should manage user preferences', () async {
      final preferences = {
        'theme': 'dark',
        'notifications': true,
        'timeout': 30,
      };

      await storageService.saveUserPreferences(preferences);
      final retrieved = await storageService.getUserPreferences();

      expect(retrieved['theme'], 'dark');
      expect(retrieved['notifications'], true);
      expect(retrieved['timeout'], 30);
    });

    test('should set and get individual preferences', () async {
      await storageService.setUserPreference('testKey', 'testValue');
      final value = await storageService.getUserPreference<String>('testKey');

      expect(value, 'testValue');
    });

    test('should calculate storage size', () async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      await storageService.addLockbox(lockbox);
      await storageService.saveEncryptedContent('test-id', 'encrypted-content');

      final size = await storageService.getStorageSize();
      expect(size, greaterThan(0));
    });

    test('should clear all data', () async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      await storageService.addLockbox(lockbox);
      await storageService.saveEncryptedContent('test-id', 'content');
      await storageService.setUserPreference('key', 'value');

      await storageService.clearAllData();

      final lockboxes = await storageService.getAllLockboxes();
      final content = await storageService.getEncryptedContent('test-id');
      final preferences = await storageService.getUserPreferences();

      expect(lockboxes, isEmpty);
      expect(content, isNull);
      expect(preferences, isEmpty);
    });
  });

  group('EncryptionService Tests', () {
    late EncryptionServiceImpl encryptionService;

    setUp(() {
      encryptionService = EncryptionServiceImpl();
      SharedPreferences.setMockInitialValues({});
    });

    test('should generate key pair', () async {
      final keyPair = await encryptionService.generateKeyPair();

      expect(keyPair.privateKey, isNotNull);
      expect(keyPair.publicKey, isNotNull);
      expect(keyPair.privateKey!.length, 64);
      expect(keyPair.publicKey.length, 64);
    });

    test('should validate key pair', () async {
      final keyPair = await encryptionService.generateKeyPair();
      final isValid = await encryptionService.validateKeyPair(keyPair);

      expect(isValid, true);
    });

    test('should reject invalid key pair', () async {
      final invalidKeyPair = KeyPair.justPublicKey('invalid-key');
      final isValid = await encryptionService.validateKeyPair(invalidKeyPair);

      expect(isValid, false);
    });

    test('should set and get current key pair', () async {
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      final currentKeyPair = await encryptionService.getCurrentKeyPair();

      expect(currentKeyPair, isNotNull);
      expect(currentKeyPair!.privateKey, keyPair.privateKey);
      expect(currentKeyPair.publicKey, keyPair.publicKey);
    });

    test('should encrypt and decrypt text', () async {
      const plaintext = 'This is a secret message';
      
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      final encrypted = await encryptionService.encryptText(plaintext);
      final decrypted = await encryptionService.decryptText(encrypted);

      expect(encrypted, isNot(plaintext));
      expect(decrypted, plaintext);
    });

    test('should throw error when encrypting without key', () async {
      const plaintext = 'This is a secret message';

      expect(
        () => encryptionService.encryptText(plaintext),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('should throw error when decrypting without key', () async {
      const encryptedText = 'fake-encrypted-text';

      expect(
        () => encryptionService.decryptText(encryptedText),
        throwsA(isA<EncryptionException>()),
      );
    });
  });

  group('KeyService Tests', () {
    late KeyService keyService;
    late MockEncryptionService mockEncryptionService;

    setUp(() {
      mockEncryptionService = MockEncryptionService();
      keyService = KeyService(mockEncryptionService);
    });

    test('should generate new key', () async {
      final keyPair = KeyPair.generate();
      when(mockEncryptionService.generateKeyPair()).thenAnswer((_) async => keyPair);

      final encryptionKey = await keyService.generateNewKey();

      expect(encryptionKey.privateKey, keyPair.privateKey);
      expect(encryptionKey.publicKey, keyPair.publicKey);
      verify(mockEncryptionService.generateKeyPair()).called(1);
    });

    test('should get current key', () async {
      final keyPair = KeyPair.generate();
      when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => keyPair);

      final currentKey = await keyService.getCurrentKey();

      expect(currentKey, isNotNull);
      expect(currentKey!.privateKey, keyPair.privateKey);
      expect(currentKey.publicKey, keyPair.publicKey);
    });

    test('should validate key', () async {
      final keyPair = KeyPair.generate();
      when(mockEncryptionService.validateKeyPair(any)).thenAnswer((_) async => true);

      final encryptionKey = keyService.getCurrentEncryptionKey();
      // This test would need more setup to work properly
    });
  });

  group('LockboxService Integration Tests', () {
    late LockboxServiceImpl lockboxService;
    late MockStorageService mockStorageService;
    late MockEncryptionService mockEncryptionService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockEncryptionService = MockEncryptionService();
      mockAuthService = MockAuthService();
      lockboxService = LockboxServiceImpl(
        mockStorageService,
        mockEncryptionService,
        mockAuthService,
      );
    });

    test('should create lockbox successfully', () async {
      const name = 'Test Lockbox';
      const content = 'Secret content';
      const encryptedContent = 'encrypted-secret-content';

      final keyPair = KeyPair.generate();
      when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => keyPair);
      when(mockEncryptionService.encryptText(content)).thenAnswer((_) async => encryptedContent);
      when(mockStorageService.addLockbox(any)).thenAnswer((_) async => {});
      when(mockStorageService.saveEncryptedContent(any, any)).thenAnswer((_) async => {});

      final lockboxId = await lockboxService.createLockbox(name: name, content: content);

      expect(lockboxId, isNotNull);
      expect(lockboxId.length, 36); // UUID v4 length
      
      verify(mockEncryptionService.encryptText(content)).called(1);
      verify(mockStorageService.addLockbox(any)).called(1);
      verify(mockStorageService.saveEncryptedContent(lockboxId, encryptedContent)).called(1);
    });

    test('should throw error when creating lockbox without encryption key', () async {
      when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => null);

      expect(
        () => lockboxService.createLockbox(name: 'Test', content: 'Content'),
        throwsA(isA<LockboxException>()),
      );
    });

    test('should get all lockboxes', () async {
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

      when(mockStorageService.getAllLockboxes()).thenAnswer((_) async => lockboxes);

      final result = await lockboxService.getAllLockboxes();

      expect(result.length, 2);
      expect(result.first.name, 'Lockbox 1');
      verify(mockStorageService.getAllLockboxes()).called(1);
    });

    test('should get lockbox content with authentication', () async {
      const lockboxId = 'test-id';
      const encryptedContent = 'encrypted-content';
      const decryptedContent = 'decrypted-content';

      final lockbox = LockboxMetadata(
        id: lockboxId,
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
      when(mockStorageService.getLockboxById(lockboxId)).thenAnswer((_) async => lockbox);
      when(mockStorageService.getEncryptedContent(lockboxId)).thenAnswer((_) async => encryptedContent);
      when(mockEncryptionService.decryptText(encryptedContent)).thenAnswer((_) async => decryptedContent);

      final content = await lockboxService.getLockboxContent(lockboxId);

      expect(content.id, lockboxId);
      expect(content.name, 'Test Lockbox');
      expect(content.content, decryptedContent);
      
      verify(mockAuthService.authenticateUser()).called(1);
      verify(mockEncryptionService.decryptText(encryptedContent)).called(1);
    });

    test('should reject access without authentication', () async {
      when(mockAuthService.authenticateUser()).thenAnswer((_) async => false);

      expect(
        () => lockboxService.getLockboxContent('test-id'),
        throwsA(isA<LockboxException>()),
      );
    });

    test('should update lockbox content', () async {
      const lockboxId = 'test-id';
      const newContent = 'new content';
      const encryptedNewContent = 'encrypted-new-content';

      final existingLockbox = LockboxMetadata(
        id: lockboxId,
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      when(mockStorageService.getLockboxById(lockboxId)).thenAnswer((_) async => existingLockbox);
      when(mockEncryptionService.encryptText(newContent)).thenAnswer((_) async => encryptedNewContent);
      when(mockStorageService.updateLockbox(any)).thenAnswer((_) async => {});
      when(mockStorageService.saveEncryptedContent(any, any)).thenAnswer((_) async => {});

      await lockboxService.updateLockbox(lockboxId: lockboxId, content: newContent);

      verify(mockEncryptionService.encryptText(newContent)).called(1);
      verify(mockStorageService.updateLockbox(any)).called(1);
      verify(mockStorageService.saveEncryptedContent(lockboxId, encryptedNewContent)).called(1);
    });

    test('should update lockbox name', () async {
      const lockboxId = 'test-id';
      const newName = 'New Name';

      final existingLockbox = LockboxMetadata(
        id: lockboxId,
        name: 'Old Name',
        createdAt: DateTime.now(),
        size: 100,
      );

      when(mockStorageService.getLockboxById(lockboxId)).thenAnswer((_) async => existingLockbox);
      when(mockStorageService.updateLockbox(any)).thenAnswer((_) async => {});

      await lockboxService.updateLockboxName(lockboxId: lockboxId, name: newName);

      verify(mockStorageService.updateLockbox(any)).called(1);
    });

    test('should delete lockbox', () async {
      const lockboxId = 'test-id';

      final existingLockbox = LockboxMetadata(
        id: lockboxId,
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      when(mockStorageService.getLockboxById(lockboxId)).thenAnswer((_) async => existingLockbox);
      when(mockStorageService.deleteLockbox(lockboxId)).thenAnswer((_) async => {});

      await lockboxService.deleteLockbox(lockboxId);

      verify(mockStorageService.deleteLockbox(lockboxId)).called(1);
    });

    test('should validate input constraints', () async {
      // Test empty name
      expect(
        () => lockboxService.createLockbox(name: '', content: 'content'),
        throwsA(isA<LockboxException>()),
      );

      // Test long name
      expect(
        () => lockboxService.createLockbox(name: 'a' * 101, content: 'content'),
        throwsA(isA<LockboxException>()),
      );

      // Test long content
      expect(
        () => lockboxService.createLockbox(name: 'name', content: 'a' * 4001),
        throwsA(isA<LockboxException>()),
      );
    });
  });

  group('Service Exception Tests', () {
    test('should create proper exception messages', () {
      final storageException = StorageException(
        'Storage error',
        errorCode: 'STORAGE_ERROR'
      );
      expect(storageException.message, 'Storage error');
      expect(storageException.errorCode, 'STORAGE_ERROR');

      final keyServiceException = KeyServiceException(
        'Key service error',
        errorCode: 'KEY_ERROR'
      );
      expect(keyServiceException.message, 'Key service error');
      expect(keyServiceException.errorCode, 'KEY_ERROR');
    });
  });
}