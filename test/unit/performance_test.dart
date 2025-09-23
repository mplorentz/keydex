// Performance Tests
// Testing encryption/decryption performance and app responsiveness

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'package:keydex/services/encryption_service.dart';
import 'package:keydex/services/storage_service.dart';
import 'package:keydex/services/lockbox_service.dart';
import 'package:keydex/services/auth_service.dart';
import 'package:keydex/models/lockbox.dart';

void main() {
  group('Encryption Performance Tests', () {
    late EncryptionServiceImpl encryptionService;

    setUp(() {
      encryptionService = EncryptionServiceImpl();
      SharedPreferences.setMockInitialValues({});
    });

    test('should encrypt text within 200ms', () async {
      // Generate and set key pair
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      const plaintext = '''
This is a longer text content to test encryption performance.
It contains multiple lines and various characters to ensure
realistic performance testing. The encryption should complete
within 200 milliseconds for good user experience.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
      ''';

      final stopwatch = Stopwatch()..start();
      final encrypted = await encryptionService.encryptText(plaintext);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plaintext)));
    });

    test('should decrypt text within 200ms', () async {
      // Generate and set key pair
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      const plaintext = '''
This is a longer text content to test decryption performance.
It contains multiple lines and various characters to ensure
realistic performance testing. The decryption should complete
within 200 milliseconds for good user experience.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
      ''';

      // First encrypt the text
      final encrypted = await encryptionService.encryptText(plaintext);

      // Then test decryption performance
      final stopwatch = Stopwatch()..start();
      final decrypted = await encryptionService.decryptText(encrypted);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(decrypted, equals(plaintext));
    });

    test('should handle maximum content size encryption within 500ms', () async {
      // Generate and set key pair
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      // Create maximum size content (4000 characters)
      final maxContent = 'A' * 4000;

      final stopwatch = Stopwatch()..start();
      final encrypted = await encryptionService.encryptText(maxContent);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(encrypted, isNotEmpty);
    });

    test('should handle maximum content size decryption within 500ms', () async {
      // Generate and set key pair
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      // Create maximum size content (4000 characters)
      final maxContent = 'B' * 4000;

      // First encrypt
      final encrypted = await encryptionService.encryptText(maxContent);

      // Then test decryption performance
      final stopwatch = Stopwatch()..start();
      final decrypted = await encryptionService.decryptText(encrypted);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(decrypted, equals(maxContent));
    });

    test('should generate key pair within 100ms', () async {
      final stopwatch = Stopwatch()..start();
      final keyPair = await encryptionService.generateKeyPair();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(keyPair.privateKey, isNotNull);
      expect(keyPair.publicKey, isNotNull);
    });

    test('should validate key pair within 50ms', () async {
      final keyPair = KeyPair.generate();

      final stopwatch = Stopwatch()..start();
      final isValid = await encryptionService.validateKeyPair(keyPair);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(isValid, true);
    });

    test('should perform multiple encryptions efficiently', () async {
      // Generate and set key pair
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      const plaintexts = [
        'First test message',
        'Second test message with more content',
        'Third message containing special characters: !@#\$%^&*()',
        'Fourth message with numbers: 1234567890',
        'Fifth and final test message for batch encryption',
      ];

      final stopwatch = Stopwatch()..start();
      
      final encrypted = <String>[];
      for (final plaintext in plaintexts) {
        final result = await encryptionService.encryptText(plaintext);
        encrypted.add(result);
      }
      
      stopwatch.stop();

      // Should complete all encryptions within 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(encrypted.length, equals(plaintexts.length));
      
      // Verify all encrypted texts are different from originals
      for (int i = 0; i < plaintexts.length; i++) {
        expect(encrypted[i], isNot(equals(plaintexts[i])));
        expect(encrypted[i], isNotEmpty);
      }
    });

    test('should perform encrypt-decrypt cycle efficiently', () async {
      // Generate and set key pair
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      const plaintext = 'Test message for encrypt-decrypt cycle performance';

      final stopwatch = Stopwatch()..start();
      
      // Encrypt
      final encrypted = await encryptionService.encryptText(plaintext);
      // Decrypt
      final decrypted = await encryptionService.decryptText(encrypted);
      
      stopwatch.stop();

      // Full cycle should complete within 400ms
      expect(stopwatch.elapsedMilliseconds, lessThan(400));
      expect(decrypted, equals(plaintext));
    });
  });

  group('Storage Performance Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
      SharedPreferences.setMockInitialValues({});
    });

    test('should save lockbox within 100ms', () async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      final stopwatch = Stopwatch()..start();
      await storageService.addLockbox(lockbox);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should retrieve lockboxes within 50ms', () async {
      // Add some test data first
      for (int i = 0; i < 10; i++) {
        final lockbox = LockboxMetadata(
          id: 'test-id-$i',
          name: 'Test Lockbox $i',
          createdAt: DateTime.now(),
          size: 100 + i * 10,
        );
        await storageService.addLockbox(lockbox);
      }

      final stopwatch = Stopwatch()..start();
      final lockboxes = await storageService.getAllLockboxes();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(lockboxes.length, equals(10));
    });

    test('should handle large encrypted content efficiently', () async {
      const lockboxId = 'large-content-test';
      final largeContent = 'X' * 10000; // 10KB of encrypted content

      final stopwatch = Stopwatch()..start();
      await storageService.saveEncryptedContent(lockboxId, largeContent);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200));

      // Test retrieval performance
      final retrievalStopwatch = Stopwatch()..start();
      final retrieved = await storageService.getEncryptedContent(lockboxId);
      retrievalStopwatch.stop();

      expect(retrievalStopwatch.elapsedMilliseconds, lessThan(100));
      expect(retrieved, equals(largeContent));
    });

    test('should handle multiple concurrent operations', () async {
      final stopwatch = Stopwatch()..start();

      // Perform multiple operations concurrently
      final futures = <Future<void>>[];
      
      for (int i = 0; i < 5; i++) {
        final lockbox = LockboxMetadata(
          id: 'concurrent-test-$i',
          name: 'Concurrent Test $i',
          createdAt: DateTime.now(),
          size: 100,
        );
        futures.add(storageService.addLockbox(lockbox));
        futures.add(storageService.saveEncryptedContent('concurrent-test-$i', 'encrypted-data-$i'));
      }

      await Future.wait(futures);
      stopwatch.stop();

      // All operations should complete within 500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      // Verify all data was saved
      final lockboxes = await storageService.getAllLockboxes();
      expect(lockboxes.length, equals(5));
    });
  });

  group('LockboxService Performance Tests', () {
    late LockboxServiceImpl lockboxService;
    late EncryptionServiceImpl encryptionService;
    late StorageService storageService;
    late AuthServiceImpl authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      storageService = StorageService();
      encryptionService = EncryptionServiceImpl();
      authService = AuthServiceImpl();
      
      lockboxService = LockboxServiceImpl(
        storageService,
        encryptionService,
        authService,
      );

      // Set up encryption key
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);
      
      // Disable authentication for testing
      await authService.disableAuthentication();
    });

    test('should create lockbox within 300ms', () async {
      const name = 'Performance Test Lockbox';
      const content = 'This is test content for performance testing';

      final stopwatch = Stopwatch()..start();
      final lockboxId = await lockboxService.createLockbox(
        name: name,
        content: content,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(300));
      expect(lockboxId, isNotNull);
      expect(lockboxId.length, equals(36)); // UUID length
    });

    test('should retrieve lockbox content within 300ms', () async {
      // First create a lockbox
      const name = 'Performance Test Lockbox';
      const content = 'This is test content for performance testing';
      
      final lockboxId = await lockboxService.createLockbox(
        name: name,
        content: content,
      );

      // Then test retrieval performance
      final stopwatch = Stopwatch()..start();
      final lockboxContent = await lockboxService.getLockboxContent(lockboxId);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(300));
      expect(lockboxContent.id, equals(lockboxId));
      expect(lockboxContent.content, equals(content));
    });

    test('should update lockbox within 300ms', () async {
      // First create a lockbox
      final lockboxId = await lockboxService.createLockbox(
        name: 'Original Name',
        content: 'Original content',
      );

      const newContent = 'Updated content for performance testing';

      final stopwatch = Stopwatch()..start();
      await lockboxService.updateLockbox(
        lockboxId: lockboxId,
        content: newContent,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(300));

      // Verify the update worked
      final updated = await lockboxService.getLockboxContent(lockboxId);
      expect(updated.content, equals(newContent));
    });

    test('should handle multiple lockboxes efficiently', () async {
      final stopwatch = Stopwatch()..start();

      // Create multiple lockboxes
      final lockboxIds = <String>[];
      for (int i = 0; i < 5; i++) {
        final id = await lockboxService.createLockbox(
          name: 'Batch Test $i',
          content: 'Content for lockbox number $i with some additional text',
        );
        lockboxIds.add(id);
      }

      stopwatch.stop();

      // Should create all lockboxes within 2 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(lockboxIds.length, equals(5));

      // Test retrieval performance
      final retrievalStopwatch = Stopwatch()..start();
      final allLockboxes = await lockboxService.getAllLockboxes();
      retrievalStopwatch.stop();

      expect(retrievalStopwatch.elapsedMilliseconds, lessThan(100));
      expect(allLockboxes.length, equals(5));
    });
  });

  group('Memory Performance Tests', () {
    test('should not leak memory during repeated operations', () async {
      SharedPreferences.setMockInitialValues({});
      
      final encryptionService = EncryptionServiceImpl();
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      const testContent = 'Memory test content';

      // Perform many encrypt/decrypt cycles
      for (int i = 0; i < 100; i++) {
        final encrypted = await encryptionService.encryptText('$testContent $i');
        final decrypted = await encryptionService.decryptText(encrypted);
        expect(decrypted, equals('$testContent $i'));
      }

      // Test should complete without memory issues
      // In a real environment, you might monitor memory usage here
    });

    test('should handle large data sets efficiently', () async {
      SharedPreferences.setMockInitialValues({});
      
      final storageService = StorageService();
      final stopwatch = Stopwatch()..start();

      // Create a large number of lockboxes
      for (int i = 0; i < 100; i++) {
        final lockbox = LockboxMetadata(
          id: 'memory-test-$i',
          name: 'Memory Test Lockbox $i',
          createdAt: DateTime.now(),
          size: 100 + i,
        );
        await storageService.addLockbox(lockbox);
      }

      final lockboxes = await storageService.getAllLockboxes();
      stopwatch.stop();

      expect(lockboxes.length, equals(100));
      // Should handle 100 lockboxes within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('Stress Tests', () {
    test('should handle rapid consecutive operations', () async {
      SharedPreferences.setMockInitialValues({});
      
      final encryptionService = EncryptionServiceImpl();
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      final stopwatch = Stopwatch()..start();

      // Perform rapid operations
      final futures = <Future<void>>[];
      for (int i = 0; i < 20; i++) {
        futures.add(
          encryptionService.encryptText('Stress test message $i').then((encrypted) {
            return encryptionService.decryptText(encrypted);
          })
        );
      }

      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, equals(20));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max

      // Verify all results are correct
      for (int i = 0; i < results.length; i++) {
        expect(results[i], equals('Stress test message $i'));
      }
    });

    test('should maintain performance with large content', () async {
      SharedPreferences.setMockInitialValues({});
      
      final encryptionService = EncryptionServiceImpl();
      final keyPair = await encryptionService.generateKeyPair();
      await encryptionService.setKeyPair(keyPair);

      // Test with near-maximum content (3900 chars)
      final largeContent = 'A' * 3900;

      final stopwatch = Stopwatch()..start();
      final encrypted = await encryptionService.encryptText(largeContent);
      final decrypted = await encryptionService.decryptText(encrypted);
      stopwatch.stop();

      expect(decrypted, equals(largeContent));
      // Large content should still complete within 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}