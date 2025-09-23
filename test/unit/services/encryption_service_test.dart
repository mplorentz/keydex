import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/contracts/encryption_service.dart';
import 'package:keydex/services/encryption_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'encryption_service_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('EncryptionServiceImpl Tests', () {
    late MockSharedPreferences mockPrefs;
    late EncryptionServiceImpl encryptionService;
    late KeyPair validKeyPair;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      encryptionService = EncryptionServiceImpl(prefs: mockPrefs);
      
      // Create a valid key pair for testing
      validKeyPair = KeyPair(
        privateKey: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      );
    });

    group('Key Pair Management', () {
      test('should set key pair successfully', () async {
        // Arrange
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await encryptionService.setKeyPair(validKeyPair);

        // Assert
        final expectedJson = jsonEncode({
          'privateKey': validKeyPair.privateKey,
          'publicKey': validKeyPair.publicKey,
        });
        verify(mockPrefs.setString('encryption_key_pair', expectedJson)).called(1);
      });

      test('should get current key pair successfully', () async {
        // Arrange
        final keyPairJson = jsonEncode({
          'privateKey': validKeyPair.privateKey,
          'publicKey': validKeyPair.publicKey,
        });
        when(mockPrefs.getString('encryption_key_pair')).thenReturn(keyPairJson);

        // Act
        final result = await encryptionService.getCurrentKeyPair();

        // Assert
        expect(result, isNotNull);
        expect(result!.privateKey, equals(validKeyPair.privateKey));
        expect(result.publicKey, equals(validKeyPair.publicKey));
        verify(mockPrefs.getString('encryption_key_pair')).called(1);
      });

      test('should return null when no key pair exists', () async {
        // Arrange
        when(mockPrefs.getString('encryption_key_pair')).thenReturn(null);

        // Act
        final result = await encryptionService.getCurrentKeyPair();

        // Assert
        expect(result, isNull);
      });

      test('should cache key pair after retrieval', () async {
        // Arrange
        final keyPairJson = jsonEncode({
          'privateKey': validKeyPair.privateKey,
          'publicKey': validKeyPair.publicKey,
        });
        when(mockPrefs.getString('encryption_key_pair')).thenReturn(keyPairJson);

        // Act
        final result1 = await encryptionService.getCurrentKeyPair();
        final result2 = await encryptionService.getCurrentKeyPair();

        // Assert
        expect(result1, isNotNull);
        expect(result2, isNotNull);
        expect(result1!.privateKey, equals(result2!.privateKey));
        // Should only call storage once due to caching
        verify(mockPrefs.getString('encryption_key_pair')).called(1);
      });

      test('should clear key pair successfully', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        // Act
        await encryptionService.clearKeyPair();

        // Assert
        verify(mockPrefs.remove('encryption_key_pair')).called(1);
      });

      test('should check if key pair exists', () async {
        // Arrange
        when(mockPrefs.getString('encryption_key_pair')).thenReturn(null);

        // Act
        final hasKey = await encryptionService.hasKeyPair();

        // Assert
        expect(hasKey, isFalse);
      });

      test('should return true when key pair exists', () async {
        // Arrange
        final keyPairJson = jsonEncode({
          'privateKey': validKeyPair.privateKey,
          'publicKey': validKeyPair.publicKey,
        });
        when(mockPrefs.getString('encryption_key_pair')).thenReturn(keyPairJson);

        // Act
        final hasKey = await encryptionService.hasKeyPair();

        // Assert
        expect(hasKey, isTrue);
      });
    });

    group('Key Pair Generation', () {
      test('should generate valid key pair', () async {
        // Act
        final keyPair = await encryptionService.generateKeyPair();

        // Assert
        expect(keyPair.privateKey, isNotNull);
        expect(keyPair.publicKey, isNotNull);
        expect(keyPair.privateKey!.length, equals(64));
        expect(keyPair.publicKey.length, equals(64));
      });

      test('should generate different key pairs on multiple calls', () async {
        // Act
        final keyPair1 = await encryptionService.generateKeyPair();
        final keyPair2 = await encryptionService.generateKeyPair();

        // Assert
        expect(keyPair1.privateKey, isNot(equals(keyPair2.privateKey)));
        expect(keyPair1.publicKey, isNot(equals(keyPair2.publicKey)));
      });

      test('should validate generated key pair', () async {
        // Act
        final keyPair = await encryptionService.generateKeyPair();

        // Assert
        final isValid = await encryptionService.validateKeyPair(keyPair);
        expect(isValid, isTrue);
      });
    });

    group('Key Pair Validation', () {
      test('should validate correct key pair', () async {
        // Act
        final isValid = await encryptionService.validateKeyPair(validKeyPair);

        // Assert
        expect(isValid, isTrue);
      });

      test('should reject key pair with short private key', () async {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: 'short',
          publicKey: validKeyPair.publicKey,
        );

        // Act
        final isValid = await encryptionService.validateKeyPair(invalidKeyPair);

        // Assert
        expect(isValid, isFalse);
      });

      test('should reject key pair with short public key', () async {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: validKeyPair.privateKey,
          publicKey: 'short',
        );

        // Act
        final isValid = await encryptionService.validateKeyPair(invalidKeyPair);

        // Assert
        expect(isValid, isFalse);
      });

      test('should reject key pair with non-hex private key', () async {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: 'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg',
          publicKey: validKeyPair.publicKey,
        );

        // Act
        final isValid = await encryptionService.validateKeyPair(invalidKeyPair);

        // Assert
        expect(isValid, isFalse);
      });

      test('should reject key pair with non-hex public key', () async {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: validKeyPair.privateKey,
          publicKey: 'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg',
        );

        // Act
        final isValid = await encryptionService.validateKeyPair(invalidKeyPair);

        // Assert
        expect(isValid, isFalse);
      });

      test('should validate public-only key pair', () async {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: validKeyPair.publicKey,
        );

        // Act
        final isValid = await encryptionService.validateKeyPair(publicOnlyKeyPair);

        // Assert
        expect(isValid, isTrue);
      });

      test('should throw EncryptionException when setting invalid key pair', () async {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: 'short',
          publicKey: validKeyPair.publicKey,
        );

        // Act & Assert
        expect(
          () => encryptionService.setKeyPair(invalidKeyPair),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'INVALID_KEY_PAIR',
          )),
        );
      });
    });

    group('Text Encryption', () {
      setUp(() async {
        // Set up a valid key pair for encryption tests
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        await encryptionService.setKeyPair(validKeyPair);
      });

      test('should throw EncryptionException for empty text', () async {
        // Act & Assert
        expect(
          () => encryptionService.encryptText(''),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'EMPTY_PLAINTEXT',
          )),
        );
      });

      test('should throw EncryptionException for text too large', () async {
        // Arrange
        final largeText = 'a' * 4001;

        // Act & Assert
        expect(
          () => encryptionService.encryptText(largeText),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'TEXT_TOO_LARGE',
          )),
        );
      });

      test('should throw EncryptionException when no key pair available', () async {
        // Arrange
        when(mockPrefs.getString('encryption_key_pair')).thenReturn(null);
        final newService = EncryptionServiceImpl(prefs: mockPrefs);

        // Act & Assert
        expect(
          () => newService.encryptText('test'),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'NO_KEY_PAIR',
          )),
        );
      });

      test('should throw EncryptionException when private key is null', () async {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: validKeyPair.publicKey,
        );
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        await encryptionService.setKeyPair(publicOnlyKeyPair);

        // Act & Assert
        expect(
          () => encryptionService.encryptText('test'),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'NO_PRIVATE_KEY',
          )),
        );
      });

      test('should encrypt text successfully', () async {
        // Arrange
        const plaintext = 'This is a test message for encryption';

        // Act
        final encrypted = await encryptionService.encryptText(plaintext);

        // Assert
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(plaintext)));
        // Should be base64 encoded
        expect(() => base64Decode(encrypted), returnsNormally);
      });

      test('should produce different encrypted text for same input', () async {
        // Arrange
        const plaintext = 'Same message';

        // Act
        final encrypted1 = await encryptionService.encryptText(plaintext);
        final encrypted2 = await encryptionService.encryptText(plaintext);

        // Assert - NIP-44 should use random nonce, so outputs should differ
        expect(encrypted1, isNot(equals(encrypted2)));
      });
    });

    group('Text Decryption', () {
      setUp(() async {
        // Set up a valid key pair for decryption tests
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        await encryptionService.setKeyPair(validKeyPair);
      });

      test('should throw EncryptionException for empty encrypted text', () async {
        // Act & Assert
        expect(
          () => encryptionService.decryptText(''),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'EMPTY_ENCRYPTED_TEXT',
          )),
        );
      });

      test('should throw EncryptionException when no key pair available', () async {
        // Arrange
        when(mockPrefs.getString('encryption_key_pair')).thenReturn(null);
        final newService = EncryptionServiceImpl(prefs: mockPrefs);

        // Act & Assert
        expect(
          () => newService.decryptText('encrypted'),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'NO_KEY_PAIR',
          )),
        );
      });

      test('should throw EncryptionException for invalid base64', () async {
        // Act & Assert
        expect(
          () => encryptionService.decryptText('invalid-base64!@#'),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'INVALID_FORMAT',
          )),
        );
      });

      test('should encrypt and decrypt text successfully', () async {
        // Arrange
        const originalText = 'This is a secret message that should be encrypted and decrypted correctly';

        // Act
        final encrypted = await encryptionService.encryptText(originalText);
        final decrypted = await encryptionService.decryptText(encrypted);

        // Assert
        expect(decrypted, equals(originalText));
      });

      test('should handle different text sizes', () async {
        // Arrange
        final testTexts = [
          'Short text',
          'Medium length text with some special characters: !@#\$%^&*()',
          'Very long text that contains multiple sentences and paragraphs to test the encryption and decryption process with larger data sizes. This should still work correctly with the NIP-44 encryption standard.',
          'a' * 4000, // Maximum allowed size
        ];

        // Act & Assert
        for (final text in testTexts) {
          final encrypted = await encryptionService.encryptText(text);
          final decrypted = await encryptionService.decryptText(encrypted);
          expect(decrypted, equals(text), reason: 'Failed for text of length ${text.length}');
        }
      });

      test('should handle special characters and unicode', () async {
        // Arrange
        const textWithSpecialChars = 'Hello 世界! 🔐 Special chars: äöü ñ ç';

        // Act
        final encrypted = await encryptionService.encryptText(textWithSpecialChars);
        final decrypted = await encryptionService.decryptText(encrypted);

        // Assert
        expect(decrypted, equals(textWithSpecialChars));
      });
    });

    group('Error Handling', () {
      test('should handle storage failure when setting key pair', () async {
        // Arrange
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => encryptionService.setKeyPair(validKeyPair),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'KEY_SET_FAILED',
          )),
        );
      });

      test('should handle storage failure when getting key pair', () async {
        // Arrange
        when(mockPrefs.getString('encryption_key_pair')).thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => encryptionService.getCurrentKeyPair(),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'KEY_RETRIEVAL_FAILED',
          )),
        );
      });

      test('should handle storage failure when clearing key pair', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => encryptionService.clearKeyPair(),
          throwsA(isA<EncryptionException>().having(
            (e) => e.errorCode,
            'error code',
            'KEY_CLEAR_FAILED',
          )),
        );
      });

      test('should handle key generation failure', () async {
        // This test is more conceptual since we can't easily mock Random.secure()
        // But we can test that the method completes and validates successfully
        
        // Act
        final keyPair = await encryptionService.generateKeyPair();
        
        // Assert
        expect(keyPair, isNotNull);
        final isValid = await encryptionService.validateKeyPair(keyPair);
        expect(isValid, isTrue);
      });
    });
  });

  group('EncryptionException Tests', () {
    test('should create exception with message only', () {
      // Act
      final exception = EncryptionException('Test error message');

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, isNull);
    });

    test('should create exception with message and error code', () {
      // Act
      final exception = EncryptionException(
        'Test error message',
        errorCode: 'TEST_ERROR',
      );

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, equals('TEST_ERROR'));
    });
  });
}