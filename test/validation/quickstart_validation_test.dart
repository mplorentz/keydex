// Quickstart Validation Tests
// Testing the complete user flow scenarios from quickstart.md

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:keydex/services/auth_service.dart';
import 'package:keydex/services/encryption_service.dart';
import 'package:keydex/services/storage_service.dart';
import 'package:keydex/services/key_service.dart';
import 'package:keydex/services/lockbox_service.dart';

void main() {
  group('Quickstart Validation Scenarios', () {
    late AuthServiceImpl authService;
    late EncryptionServiceImpl encryptionService;
    late StorageService storageService;
    late KeyService keyService;
    late LockboxServiceImpl lockboxService;

    setUp(() async {
      // Reset shared preferences
      SharedPreferences.setMockInitialValues({});
      
      // Initialize services
      storageService = StorageService();
      encryptionService = EncryptionServiceImpl();
      authService = AuthServiceImpl();
      keyService = KeyService(encryptionService);
      lockboxService = LockboxServiceImpl(
        storageService,
        encryptionService,
        authService,
      );
    });

    group('Scenario 1: New User Setup', () {
      test('should complete initial setup flow', () async {
        // Step 1: Check initial state
        final isAuthConfigured = await authService.isAuthenticationConfigured();
        final hasKey = await keyService.hasKey();
        
        expect(isAuthConfigured, false);
        expect(hasKey, false);

        // Step 2: Generate encryption key
        final encryptionKey = await keyService.generateNewKey();
        expect(encryptionKey.isValid, true);
        expect(encryptionKey.isFullKeyPair, true);

        // Step 3: Verify key is stored
        final currentKey = await keyService.getCurrentKey();
        expect(currentKey, isNotNull);
        expect(currentKey!.publicKey, encryptionKey.publicKey);

        // Step 4: Disable auth for testing (simulating setup completion)
        await authService.disableAuthentication();

        // Verify setup completion
        final hasKeyAfterSetup = await keyService.hasKey();
        expect(hasKeyAfterSetup, true);
      });
    });

    group('Scenario 2: Create First Lockbox', () {
      test('should create and retrieve first lockbox', () async {
        // Prerequisites: Setup encryption
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        // Step 1: Create first lockbox
        const lockboxName = 'My First Password';
        const lockboxContent = 'username: john.doe@example.com\npassword: SuperSecret123!';

        final lockboxId = await lockboxService.createLockbox(
          name: lockboxName,
          content: lockboxContent,
        );

        expect(lockboxId, isNotNull);
        expect(lockboxId.length, 36); // UUID length

        // Step 2: Verify lockbox appears in list
        final allLockboxes = await lockboxService.getAllLockboxes();
        expect(allLockboxes.length, 1);
        expect(allLockboxes.first.id, lockboxId);
        expect(allLockboxes.first.name, lockboxName);
        expect(allLockboxes.first.size, lockboxContent.length);

        // Step 3: Retrieve and decrypt content
        final lockboxContentResult = await lockboxService.getLockboxContent(lockboxId);
        expect(lockboxContentResult.id, lockboxId);
        expect(lockboxContentResult.name, lockboxName);
        expect(lockboxContentResult.content, lockboxContent);
      });
    });

    group('Scenario 3: Manage Multiple Lockboxes', () {
      test('should handle multiple lockboxes efficiently', () async {
        // Prerequisites: Setup
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        // Create multiple lockboxes
        final testData = [
          ('Personal Email', 'email: personal@example.com\npassword: MyPersonalPass123'),
          ('Work VPN', 'server: vpn.company.com\nusername: employee123\npassword: WorkVPN456'),
          ('Bank Account', 'bank: Example Bank\naccount: 1234567890\npin: 9876'),
          ('API Keys', 'service: ExampleAPI\napi_key: sk_test_1234567890abcdef\napi_secret: secret_key_here'),
        ];

        final lockboxIds = <String>[];

        // Create all lockboxes
        for (final (name, content) in testData) {
          final id = await lockboxService.createLockbox(name: name, content: content);
          lockboxIds.add(id);
        }

        // Verify all lockboxes exist
        final allLockboxes = await lockboxService.getAllLockboxes();
        expect(allLockboxes.length, 4);

        // Verify each lockbox content
        for (int i = 0; i < testData.length; i++) {
          final (expectedName, expectedContent) = testData[i];
          final lockboxContent = await lockboxService.getLockboxContent(lockboxIds[i]);
          
          expect(lockboxContent.name, expectedName);
          expect(lockboxContent.content, expectedContent);
        }

        // Test search functionality (if implemented in service)
        final searchResults = await lockboxService.searchLockboxes('API');
        expect(searchResults.length, 1);
        expect(searchResults.first.name, 'API Keys');
      });
    });

    group('Scenario 4: Edit and Update Lockbox', () {
      test('should successfully update existing lockbox', () async {
        // Prerequisites: Setup and create initial lockbox
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        const originalName = 'Old Password';
        const originalContent = 'username: old_user\npassword: old_password';
        
        final lockboxId = await lockboxService.createLockbox(
          name: originalName,
          content: originalContent,
        );

        // Step 1: Update lockbox name
        const newName = 'Updated Password';
        await lockboxService.updateLockboxName(
          lockboxId: lockboxId,
          name: newName,
        );

        // Verify name update
        final lockboxes = await lockboxService.getAllLockboxes();
        expect(lockboxes.first.name, newName);

        // Step 2: Update lockbox content
        const newContent = 'username: new_user@example.com\npassword: NewSecurePassword123!\nnotes: Updated with stronger password';
        await lockboxService.updateLockbox(
          lockboxId: lockboxId,
          content: newContent,
        );

        // Verify content update
        final updatedContent = await lockboxService.getLockboxContent(lockboxId);
        expect(updatedContent.name, newName);
        expect(updatedContent.content, newContent);
        
        // Verify size was updated
        final updatedLockboxes = await lockboxService.getAllLockboxes();
        expect(updatedLockboxes.first.size, newContent.length);
      });
    });

    group('Scenario 5: Delete Lockbox', () {
      test('should successfully delete lockbox and cleanup', () async {
        // Prerequisites: Setup and create lockboxes
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        // Create multiple lockboxes
        final id1 = await lockboxService.createLockbox(name: 'Keep This', content: 'Keep');
        final id2 = await lockboxService.createLockbox(name: 'Delete This', content: 'Delete');
        final id3 = await lockboxService.createLockbox(name: 'Keep This Too', content: 'Keep');

        // Verify initial state
        var allLockboxes = await lockboxService.getAllLockboxes();
        expect(allLockboxes.length, 3);

        // Delete middle lockbox
        await lockboxService.deleteLockbox(id2);

        // Verify lockbox was removed
        allLockboxes = await lockboxService.getAllLockboxes();
        expect(allLockboxes.length, 2);
        
        final remainingIds = allLockboxes.map((lb) => lb.id).toList();
        expect(remainingIds, contains(id1));
        expect(remainingIds, contains(id3));
        expect(remainingIds, isNot(contains(id2)));

        // Verify encrypted content was also cleaned up
        final encryptedContent = await storageService.getEncryptedContent(id2);
        expect(encryptedContent, isNull);

        // Verify other lockboxes still accessible
        final content1 = await lockboxService.getLockboxContent(id1);
        final content3 = await lockboxService.getLockboxContent(id3);
        expect(content1.content, 'Keep');
        expect(content3.content, 'Keep');
      });
    });

    group('Scenario 6: Security Features', () {
      test('should handle key rotation correctly', () async {
        // Prerequisites: Setup with initial key
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        // Create lockbox with original key
        const originalContent = 'Content encrypted with original key';
        final lockboxId = await lockboxService.createLockbox(
          name: 'Test Lockbox',
          content: originalContent,
        );

        // Get original key info
        final originalKeyInfo = await keyService.getKeyInfo();
        final originalPublicKey = originalKeyInfo['publicKey'];

        // Rotate the key
        final newKey = await keyService.rotateKey();
        expect(newKey.isValid, true);

        // Verify key changed
        final newKeyInfo = await keyService.getKeyInfo();
        final newPublicKey = newKeyInfo['publicKey'];
        expect(newPublicKey, isNot(equals(originalPublicKey)));

        // Old lockbox should still be accessible (backward compatibility)
        final retrievedContent = await lockboxService.getLockboxContent(lockboxId);
        expect(retrievedContent.content, originalContent);

        // New lockboxes should use new key
        const newContent = 'Content encrypted with new key';
        final newLockboxId = await lockboxService.createLockbox(
          name: 'New Lockbox',
          content: newContent,
        );

        final newLockboxContent = await lockboxService.getLockboxContent(newLockboxId);
        expect(newLockboxContent.content, newContent);
      });

      test('should handle key backup and restore', () async {
        // Prerequisites: Setup
        await keyService.generateNewKey();
        const testContent = 'Test content for backup scenario';
        
        // Create lockbox
        final lockboxId = await lockboxService.createLockbox(
          name: 'Backup Test',
          content: testContent,
        );

        // Export key backup
        final backup = await keyService.exportKeyBackup();
        expect(backup, isNotEmpty);

        // Simulate key loss (clear key)
        await (keyService as KeyService).clearKeyPair();
        
        // Verify key is gone
        final hasKeyAfterClear = await keyService.hasKey();
        expect(hasKeyAfterClear, false);

        // Restore from backup
        await keyService.restoreFromBackup(backup);

        // Verify restoration worked
        final hasKeyAfterRestore = await keyService.hasKey();
        expect(hasKeyAfterRestore, true);

        // Verify lockbox is still accessible
        await authService.disableAuthentication();
        final restoredContent = await lockboxService.getLockboxContent(lockboxId);
        expect(restoredContent.content, testContent);
      });
    });

    group('Scenario 7: Error Handling', () {
      test('should handle invalid operations gracefully', () async {
        // Prerequisites: Setup
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        // Test creating lockbox with invalid data
        expect(
          () => lockboxService.createLockbox(name: '', content: 'content'),
          throwsA(isA<LockboxException>()),
        );

        expect(
          () => lockboxService.createLockbox(name: 'name', content: 'a' * 4001),
          throwsA(isA<LockboxException>()),
        );

        // Test accessing non-existent lockbox
        expect(
          () => lockboxService.getLockboxContent('non-existent-id'),
          throwsA(isA<LockboxException>()),
        );

        // Test updating non-existent lockbox
        expect(
          () => lockboxService.updateLockbox(
            lockboxId: 'non-existent-id',
            content: 'new content',
          ),
          throwsA(isA<LockboxException>()),
        );

        // Test deleting non-existent lockbox
        expect(
          () => lockboxService.deleteLockbox('non-existent-id'),
          throwsA(isA<LockboxException>()),
        );
      });

      test('should handle encryption errors', () async {
        // Test operations without encryption key
        expect(
          () => lockboxService.createLockbox(name: 'Test', content: 'Content'),
          throwsA(isA<LockboxException>()),
        );

        // Test with corrupted key data
        await keyService.generateNewKey();
        
        // Simulate corrupted storage (this would need service modification to test fully)
        // For now, verify that normal operations work
        await authService.disableAuthentication();
        
        final lockboxId = await lockboxService.createLockbox(
          name: 'Valid Test',
          content: 'Valid content',
        );
        
        final content = await lockboxService.getLockboxContent(lockboxId);
        expect(content.content, 'Valid content');
      });
    });

    group('Scenario 8: Performance Validation', () {
      test('should handle large content efficiently', () async {
        // Prerequisites: Setup
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        // Test with maximum allowed content
        final largeContent = 'A' * 4000;
        final stopwatch = Stopwatch()..start();

        final lockboxId = await lockboxService.createLockbox(
          name: 'Large Content Test',
          content: largeContent,
        );

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));

        // Test retrieval performance
        final retrievalStopwatch = Stopwatch()..start();
        final retrievedContent = await lockboxService.getLockboxContent(lockboxId);
        retrievalStopwatch.stop();

        expect(retrievalStopwatch.elapsedMilliseconds, lessThan(500));
        expect(retrievedContent.content, largeContent);
      });

      test('should handle many lockboxes efficiently', () async {
        // Prerequisites: Setup
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        final stopwatch = Stopwatch()..start();

        // Create 50 lockboxes
        final lockboxIds = <String>[];
        for (int i = 0; i < 50; i++) {
          final id = await lockboxService.createLockbox(
            name: 'Performance Test $i',
            content: 'Content for lockbox number $i with some additional text for testing',
          );
          lockboxIds.add(id);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max

        // Test retrieval performance
        final listStopwatch = Stopwatch()..start();
        final allLockboxes = await lockboxService.getAllLockboxes();
        listStopwatch.stop();

        expect(listStopwatch.elapsedMilliseconds, lessThan(200));
        expect(allLockboxes.length, 50);

        // Test individual access performance
        final accessStopwatch = Stopwatch()..start();
        for (final id in lockboxIds.take(10)) {
          await lockboxService.getLockboxContent(id);
        }
        accessStopwatch.stop();

        expect(accessStopwatch.elapsedMilliseconds, lessThan(2000)); // 2 seconds for 10 accesses
      });
    });

    group('Scenario 9: Data Integrity', () {
      test('should maintain data consistency', () async {
        // Prerequisites: Setup
        await keyService.generateNewKey();
        await authService.disableAuthentication();

        // Create test data
        final testCases = [
          ('Special Characters', 'Content with special chars: !@#\$%^&*()[]{}|\\:";\'<>?,./'),
          ('Unicode Content', 'Unicode: 🔐🔑💾📱🛡️ • ñáéíóú • 中文 • العربية'),
          ('Long Lines', 'This is a very long line that goes on and on and should test wrapping and handling of extended content without breaks'),
          ('Mixed Content', 'Line 1\nLine 2\n\nEmpty line above\n\tTabbed line\n  Spaced line'),
        ];

        final lockboxIds = <String>[];
        
        // Create lockboxes
        for (final (name, content) in testCases) {
          final id = await lockboxService.createLockbox(name: name, content: content);
          lockboxIds.add(id);
        }

        // Verify all content matches exactly
        for (int i = 0; i < testCases.length; i++) {
          final (expectedName, expectedContent) = testCases[i];
          final retrievedContent = await lockboxService.getLockboxContent(lockboxIds[i]);
          
          expect(retrievedContent.name, expectedName);
          expect(retrievedContent.content, expectedContent);
          expect(retrievedContent.content.length, expectedContent.length);
        }

        // Test update integrity
        const updatedContent = 'Updated content with emoji: ✅ and newlines:\nLine 2\nLine 3';
        await lockboxService.updateLockbox(
          lockboxId: lockboxIds[0],
          content: updatedContent,
        );

        final updated = await lockboxService.getLockboxContent(lockboxIds[0]);
        expect(updated.content, updatedContent);
      });
    });
  });
}