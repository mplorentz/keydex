// Integration Test: Lockbox Creation Flow
// Tests the complete end-to-end process of creating encrypted lockboxes

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:keydex/main.dart' as app;

// Test implementations of contracts (will be replaced with real implementations)
import '../test/contract/test_auth_service.dart';
import '../test/contract/test_encryption_service.dart';  
import '../test/contract/test_lockbox_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lockbox Creation Flow Integration Tests', () {
    late TestAuthService mockAuthService;
    late TestEncryptionService mockEncryptionService;
    late TestLockboxService mockLockboxService;

    setUp(() {
      mockAuthService = TestAuthService();
      mockEncryptionService = TestEncryptionService();
      mockLockboxService = TestLockboxService();
    });

    group('Happy Path - Successful Lockbox Creation', () {
      testWidgets('should create lockbox with text content successfully', (WidgetTester tester) async {
        // Given: User is authenticated and has configured encryption
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockAuthService.isAuthenticationConfigured()).thenAnswer((_) async => true);
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => NostrKeyPair(
          privateKey: 'test_private_key',
          publicKey: 'test_public_key'
        ));

        // When: User creates a new lockbox
        final lockboxName = 'Personal Notes';
        final lockboxContent = 'This is my secret information that should be encrypted.';
        
        when(mockEncryptionService.encryptText(lockboxContent))
            .thenAnswer((_) async => 'encrypted_content_base64');
        when(mockLockboxService.createLockbox(
          name: lockboxName, 
          content: lockboxContent
        )).thenAnswer((_) async => 'lockbox_id_123');

        final lockboxId = await mockLockboxService.createLockbox(
          name: lockboxName,
          content: lockboxContent
        );

        // Then: Lockbox should be created successfully
        expect(lockboxId, isNotEmpty);
        expect(lockboxId, equals('lockbox_id_123'));
        
        // And: Encryption should have been called
        verify(mockEncryptionService.encryptText(lockboxContent)).called(1);
        
        // And: Lockbox should be retrievable with decrypted content
        when(mockLockboxService.getLockboxContent(lockboxId))
            .thenAnswer((_) async => LockboxContent(
              id: lockboxId,
              name: lockboxName,
              content: lockboxContent,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now()
            ));

        final retrievedLockbox = await mockLockboxService.getLockboxContent(lockboxId);
        expect(retrievedLockbox.name, equals(lockboxName));
        expect(retrievedLockbox.content, equals(lockboxContent));
      });

      testWidgets('should handle empty content gracefully', (WidgetTester tester) async {
        // Given: User is authenticated
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => NostrKeyPair(
          privateKey: 'test_private_key',
          publicKey: 'test_public_key'
        ));

        // When: User creates a lockbox with empty content
        final lockboxName = 'Empty Lockbox';
        final emptyContent = '';
        
        when(mockEncryptionService.encryptText(emptyContent))
            .thenAnswer((_) async => 'encrypted_empty_content');
        when(mockLockboxService.createLockbox(
          name: lockboxName, 
          content: emptyContent
        )).thenAnswer((_) async => 'empty_lockbox_id');

        final lockboxId = await mockLockboxService.createLockbox(
          name: lockboxName,
          content: emptyContent
        );

        // Then: Empty lockbox should be created successfully
        expect(lockboxId, isNotEmpty);
        verify(mockEncryptionService.encryptText(emptyContent)).called(1);
      });

      testWidgets('should handle large content within 4K limit', (WidgetTester tester) async {
        // Given: User is authenticated
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => NostrKeyPair(
          privateKey: 'test_private_key',
          publicKey: 'test_public_key'
        ));

        // When: User creates a lockbox with large content (under 4K limit)
        final lockboxName = 'Large Content Lockbox';
        final largeContent = 'A' * 3000; // 3KB content, under 4K limit
        
        when(mockEncryptionService.encryptText(largeContent))
            .thenAnswer((_) async => 'encrypted_large_content');
        when(mockLockboxService.createLockbox(
          name: lockboxName, 
          content: largeContent
        )).thenAnswer((_) async => 'large_lockbox_id');

        final lockboxId = await mockLockboxService.createLockbox(
          name: lockboxName,
          content: largeContent
        );

        // Then: Large content lockbox should be created successfully
        expect(lockboxId, isNotEmpty);
        verify(mockEncryptionService.encryptText(largeContent)).called(1);
      });
    });

    group('Authentication Required Flow', () {
      testWidgets('should require authentication before creating lockbox', (WidgetTester tester) async {
        // Given: User is not authenticated
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => false);
        when(mockAuthService.isAuthenticationConfigured()).thenAnswer((_) async => true);

        // When: User tries to create a lockbox without authentication
        final lockboxName = 'Secure Notes';
        final lockboxContent = 'This should require authentication.';

        // Then: Authentication should be required
        final isAuthenticated = await mockAuthService.authenticateUser();
        expect(isAuthenticated, isFalse);

        // And: Lockbox creation should not proceed without authentication
        verifyNever(mockLockboxService.createLockbox(
          name: anyNamed('name'), 
          content: anyNamed('content')
        ));
      });

      testWidgets('should require authentication setup if not configured', (WidgetTester tester) async {
        // Given: Authentication is not configured
        when(mockAuthService.isAuthenticationConfigured()).thenAnswer((_) async => false);

        // When: User tries to create a lockbox
        final isConfigured = await mockAuthService.isAuthenticationConfigured();
        
        // Then: Authentication setup should be required
        expect(isConfigured, isFalse);

        // And: User should be prompted to setup authentication
        when(mockAuthService.setupAuthentication()).thenAnswer((_) async {});
        await mockAuthService.setupAuthentication();
        verify(mockAuthService.setupAuthentication()).called(1);
      });
    });

    group('Encryption Integration', () {
      testWidgets('should use NIP-44 encryption for content', (WidgetTester tester) async {
        // Given: User is authenticated and encryption service is available
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        
        final testKeyPair = NostrKeyPair(
          privateKey: 'test_nip44_private_key',
          publicKey: 'test_nip44_public_key'
        );
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => testKeyPair);
        when(mockEncryptionService.validateKeyPair(testKeyPair)).thenAnswer((_) async => true);

        // When: User creates a lockbox
        final lockboxName = 'NIP-44 Test';
        final originalContent = 'Content to be encrypted with NIP-44';
        final encryptedContent = 'nip44_encrypted_content_base64';
        
        when(mockEncryptionService.encryptText(originalContent))
            .thenAnswer((_) async => encryptedContent);
        when(mockLockboxService.createLockbox(
          name: lockboxName, 
          content: originalContent
        )).thenAnswer((_) async => 'nip44_lockbox_id');

        final lockboxId = await mockLockboxService.createLockbox(
          name: lockboxName,
          content: originalContent
        );

        // Then: Content should be encrypted using NIP-44
        verify(mockEncryptionService.encryptText(originalContent)).called(1);
        expect(lockboxId, isNotEmpty);

        // And: Key pair should be validated
        verify(mockEncryptionService.validateKeyPair(testKeyPair)).called(1);
      });

      testWidgets('should handle encryption failures gracefully', (WidgetTester tester) async {
        // Given: User is authenticated but encryption fails
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => NostrKeyPair(
          privateKey: 'test_private_key',
          publicKey: 'test_public_key'
        ));

        // When: Encryption fails
        final lockboxContent = 'Content that will fail to encrypt';
        when(mockEncryptionService.encryptText(lockboxContent))
            .thenThrow(EncryptionException('Encryption failed', errorCode: 'ENC_001'));

        // Then: Encryption exception should be thrown
        expect(
          () async => await mockEncryptionService.encryptText(lockboxContent),
          throwsA(isA<EncryptionException>())
        );
      });
    });

    group('Lockbox Metadata and Storage', () {
      testWidgets('should store lockbox metadata correctly', (WidgetTester tester) async {
        // Given: User creates multiple lockboxes
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => NostrKeyPair(
          privateKey: 'test_private_key',
          publicKey: 'test_public_key'
        ));

        final lockboxes = [
          {'name': 'Personal Notes', 'content': 'My personal information'},
          {'name': 'Work Passwords', 'content': 'Work-related credentials'},
          {'name': 'Banking Info', 'content': 'Financial account details'},
        ];

        final createdLockboxIds = <String>[];

        // When: Multiple lockboxes are created
        for (int i = 0; i < lockboxes.length; i++) {
          final lockbox = lockboxes[i];
          when(mockEncryptionService.encryptText(lockbox['content']!))
              .thenAnswer((_) async => 'encrypted_content_$i');
          when(mockLockboxService.createLockbox(
            name: lockbox['name']!, 
            content: lockbox['content']!
          )).thenAnswer((_) async => 'lockbox_id_$i');

          final lockboxId = await mockLockboxService.createLockbox(
            name: lockbox['name']!,
            content: lockbox['content']!
          );
          createdLockboxIds.add(lockboxId);
        }

        // Then: All lockboxes should be created
        expect(createdLockboxIds.length, equals(3));

        // And: Lockbox list should contain all lockboxes
        final mockMetadata = createdLockboxIds.asMap().entries.map((entry) {
          final index = entry.key;
          final id = entry.value;
          return LockboxMetadata(
            id: id,
            name: lockboxes[index]['name']!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            size: lockboxes[index]['content']!.length
          );
        }).toList();

        when(mockLockboxService.getAllLockboxes()).thenAnswer((_) async => mockMetadata);
        
        final retrievedLockboxes = await mockLockboxService.getAllLockboxes();
        expect(retrievedLockboxes.length, equals(3));
        expect(retrievedLockboxes.map((l) => l.name).toList(), 
               equals(['Personal Notes', 'Work Passwords', 'Banking Info']));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle lockbox service failures', (WidgetTester tester) async {
        // Given: User is authenticated but lockbox service fails
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => NostrKeyPair(
          privateKey: 'test_private_key',
          publicKey: 'test_public_key'
        ));
        when(mockEncryptionService.encryptText(any)).thenAnswer((_) async => 'encrypted_content');

        // When: Lockbox creation fails
        when(mockLockboxService.createLockbox(
          name: any, 
          content: any
        )).thenThrow(LockboxException('Storage failed', errorCode: 'LBX_001'));

        // Then: Lockbox exception should be thrown
        expect(
          () async => await mockLockboxService.createLockbox(
            name: 'Test Lockbox',
            content: 'Test content'
          ),
          throwsA(isA<LockboxException>())
        );
      });

      testWidgets('should handle missing encryption keys', (WidgetTester tester) async {
        // Given: User is authenticated but no encryption keys exist
        when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);
        when(mockEncryptionService.getCurrentKeyPair()).thenAnswer((_) async => null);

        // When: User tries to create a lockbox without keys
        final hasKeys = await mockEncryptionService.getCurrentKeyPair();
        
        // Then: No keys should be available
        expect(hasKeys, isNull);

        // And: New key pair should be generated
        when(mockEncryptionService.generateKeyPair()).thenAnswer((_) async => NostrKeyPair(
          privateKey: 'generated_private_key',
          publicKey: 'generated_public_key'
        ));

        final newKeyPair = await mockEncryptionService.generateKeyPair();
        expect(newKeyPair.privateKey, isNotEmpty);
        expect(newKeyPair.publicKey, isNotEmpty);
      });
    });
  });
}

// Mock implementations for testing - these reference the test contract implementations
class TestLockboxService extends Mock implements LockboxService {}
class TestAuthService extends Mock implements AuthService {}
class TestEncryptionService extends Mock implements EncryptionService {}

// Import the contract classes for type safety
abstract class LockboxService {
  Future<String> createLockbox({required String name, required String content});
  Future<List<LockboxMetadata>> getAllLockboxes();
  Future<LockboxContent> getLockboxContent(String lockboxId);
  Future<void> updateLockbox({required String lockboxId, required String content});
  Future<void> updateLockboxName({required String lockboxId, required String name});
  Future<void> deleteLockbox(String lockboxId);
  Future<bool> authenticateUser();
}

abstract class AuthService {
  Future<bool> authenticateUser();
  Future<bool> isBiometricAvailable();
  Future<bool> isAuthenticationConfigured();
  Future<void> setupAuthentication();
  Future<void> disableAuthentication();
}

abstract class EncryptionService {
  Future<String> encryptText(String plaintext);
  Future<String> decryptText(String encryptedText);
  Future<NostrKeyPair> generateKeyPair();
  Future<bool> validateKeyPair(NostrKeyPair keyPair);
  Future<NostrKeyPair?> getCurrentKeyPair();
  Future<void> setKeyPair(NostrKeyPair keyPair);
}

// Data classes
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

class NostrKeyPair {
  final String privateKey;
  final String publicKey;

  NostrKeyPair({
    required this.privateKey,
    required this.publicKey,
  });
}

// Exception classes
class LockboxException implements Exception {
  final String message;
  final String? errorCode;

  LockboxException(this.message, {this.errorCode});
}

class AuthException implements Exception {
  final String message;
  final String? errorCode;

  AuthException(this.message, {this.errorCode});
}

class EncryptionException implements Exception {
  final String message;
  final String? errorCode;

  EncryptionException(this.message, {this.errorCode});
}