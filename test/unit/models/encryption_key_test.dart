import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/models/encryption_key.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() {
  group('EncryptionKey Tests', () {
    late KeyPair validKeyPair;
    late DateTime testCreatedAt;

    setUp(() {
      // Valid 64-character hex keys for testing
      validKeyPair = KeyPair(
        privateKey: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      );
      testCreatedAt = DateTime.parse('2024-01-01T12:00:00.000Z');
    });

    group('Constructor and Properties', () {
      test('should create valid EncryptionKey with all properties', () {
        // Act
        final encryptionKey = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );

        // Assert
        expect(encryptionKey.keyPair, equals(validKeyPair));
        expect(encryptionKey.createdAt, equals(testCreatedAt));
      });

      test('should create EncryptionKey with null createdAt', () {
        // Act
        final encryptionKey = EncryptionKey(
          keyPair: validKeyPair,
        );

        // Assert
        expect(encryptionKey.keyPair, equals(validKeyPair));
        expect(encryptionKey.createdAt, isNull);
      });

      test('should be immutable', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Assert - properties should be final
        expect(encryptionKey, isA<EncryptionKey>());
      });
    });

    group('Factory Constructors', () {
      test('fromKeyPair should create with current timestamp', () {
        // Act
        final encryptionKey = EncryptionKey.fromKeyPair(validKeyPair);

        // Assert
        expect(encryptionKey.keyPair, equals(validKeyPair));
        expect(encryptionKey.createdAt, isNotNull);
        expect(encryptionKey.createdAt!.isAfter(DateTime.now().subtract(Duration(seconds: 1))), isTrue);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly with all properties', () {
        // Arrange
        final encryptionKey = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );

        // Act
        final json = encryptionKey.toJson();

        // Assert
        expect(json, equals({
          'privateKey': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'publicKey': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'createdAt': '2024-01-01T12:00:00.000Z',
        }));
      });

      test('should serialize to JSON correctly with null createdAt', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Act
        final json = encryptionKey.toJson();

        // Assert
        expect(json['privateKey'], equals(validKeyPair.privateKey));
        expect(json['publicKey'], equals(validKeyPair.publicKey));
        expect(json['createdAt'], isNull);
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'privateKey': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'publicKey': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'createdAt': '2024-01-01T12:00:00.000Z',
        };

        // Act
        final encryptionKey = EncryptionKey.fromJson(json);

        // Assert
        expect(encryptionKey.privateKeyHex, equals(json['privateKey']));
        expect(encryptionKey.publicKeyHex, equals(json['publicKey']));
        expect(encryptionKey.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
      });

      test('should deserialize from JSON with null createdAt', () {
        // Arrange
        final json = {
          'privateKey': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'publicKey': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'createdAt': null,
        };

        // Act
        final encryptionKey = EncryptionKey.fromJson(json);

        // Assert
        expect(encryptionKey.privateKeyHex, equals(json['privateKey']));
        expect(encryptionKey.publicKeyHex, equals(json['publicKey']));
        expect(encryptionKey.createdAt, isNull);
      });

      test('should round-trip through JSON serialization', () {
        // Arrange
        final original = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );

        // Act
        final json = original.toJson();
        final deserialized = EncryptionKey.fromJson(json);

        // Assert
        expect(deserialized.privateKeyHex, equals(original.privateKeyHex));
        expect(deserialized.publicKeyHex, equals(original.publicKeyHex));
        expect(deserialized.createdAt, equals(original.createdAt));
      });
    });

    group('Key Access Properties', () {
      test('should provide access to private key in hex format', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Act & Assert
        expect(encryptionKey.privateKeyHex, equals(validKeyPair.privateKey));
      });

      test('should provide access to public key in hex format', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Act & Assert
        expect(encryptionKey.publicKeyHex, equals(validKeyPair.publicKey));
      });

      test('should provide access to private key in bech32 format', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Act & Assert
        expect(encryptionKey.privateKeyBech32, equals(validKeyPair.privateKeyBech32));
      });

      test('should provide access to public key in bech32 format', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Act & Assert
        expect(encryptionKey.publicKeyBech32, equals(validKeyPair.publicKeyBech32));
      });
    });

    group('Validation', () {
      test('should be valid with correct 64-character hex keys', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Act & Assert
        expect(encryptionKey.isValid(), isTrue);
      });

      test('should be invalid with short private key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: 'short', // invalid length
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final encryptionKey = EncryptionKey(keyPair: invalidKeyPair);

        // Act & Assert
        expect(encryptionKey.isValid(), isFalse);
      });

      test('should be invalid with short public key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          publicKey: 'short', // invalid length
        );
        final encryptionKey = EncryptionKey(keyPair: invalidKeyPair);

        // Act & Assert
        expect(encryptionKey.isValid(), isFalse);
      });

      test('should be invalid with non-hex private key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: 'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg', // invalid hex
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final encryptionKey = EncryptionKey(keyPair: invalidKeyPair);

        // Act & Assert
        expect(encryptionKey.isValid(), isFalse);
      });

      test('should be invalid with non-hex public key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          publicKey: 'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg', // invalid hex
        );
        final encryptionKey = EncryptionKey(keyPair: invalidKeyPair);

        // Act & Assert
        expect(encryptionKey.isValid(), isFalse);
      });

      test('should be valid with null private key (public-key-only)', () {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final encryptionKey = EncryptionKey(keyPair: publicOnlyKeyPair);

        // Act & Assert
        expect(encryptionKey.isValid(), isTrue);
      });
    });

    group('Key Type Checks', () {
      test('hasPrivateKey should return true when private key exists', () {
        // Arrange
        final encryptionKey = EncryptionKey(keyPair: validKeyPair);

        // Act & Assert
        expect(encryptionKey.hasPrivateKey, isTrue);
        expect(encryptionKey.isPublicKeyOnly, isFalse);
      });

      test('hasPrivateKey should return false when private key is null', () {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final encryptionKey = EncryptionKey(keyPair: publicOnlyKeyPair);

        // Act & Assert
        expect(encryptionKey.hasPrivateKey, isFalse);
        expect(encryptionKey.isPublicKeyOnly, isTrue);
      });
    });

    group('CopyWith', () {
      test('should create copy with updated keyPair', () {
        // Arrange
        final original = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );
        final newKeyPair = KeyPair(
          privateKey: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
          publicKey: '0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba',
        );

        // Act
        final updated = original.copyWith(keyPair: newKeyPair);

        // Assert
        expect(updated.keyPair, equals(newKeyPair));
        expect(updated.createdAt, equals(original.createdAt)); // unchanged
      });

      test('should create copy with updated createdAt', () {
        // Arrange
        final original = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );
        final newCreatedAt = DateTime.now();

        // Act
        final updated = original.copyWith(createdAt: newCreatedAt);

        // Assert
        expect(updated.keyPair, equals(original.keyPair)); // unchanged
        expect(updated.createdAt, equals(newCreatedAt));
      });

      test('should preserve original values when no updates provided', () {
        // Arrange
        final original = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.keyPair, equals(original.keyPair));
        expect(copy.createdAt, equals(original.createdAt));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties match', () {
        // Arrange
        final encryptionKey1 = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );
        final encryptionKey2 = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );

        // Act & Assert
        expect(encryptionKey1, equals(encryptionKey2));
        expect(encryptionKey1.hashCode, equals(encryptionKey2.hashCode));
      });

      test('should not be equal when keyPair differs', () {
        // Arrange
        final differentKeyPair = KeyPair(
          privateKey: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
          publicKey: '0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba',
        );
        final encryptionKey1 = EncryptionKey(keyPair: validKeyPair);
        final encryptionKey2 = EncryptionKey(keyPair: differentKeyPair);

        // Act & Assert
        expect(encryptionKey1, isNot(equals(encryptionKey2)));
      });

      test('should not be equal when createdAt differs', () {
        // Arrange
        final differentCreatedAt = DateTime.now();
        final encryptionKey1 = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );
        final encryptionKey2 = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: differentCreatedAt,
        );

        // Act & Assert
        expect(encryptionKey1, isNot(equals(encryptionKey2)));
      });
    });

    group('ToString', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final encryptionKey = EncryptionKey(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );

        // Act
        final stringRepresentation = encryptionKey.toString();

        // Assert
        expect(stringRepresentation, contains('EncryptionKey'));
        expect(stringRepresentation, contains('abcdef12')); // first 8 chars of public key
        expect(stringRepresentation, contains('hasPrivateKey: true'));
        expect(stringRepresentation, contains('2024-01-01'));
      });

      test('should handle public-key-only in toString', () {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final encryptionKey = EncryptionKey(keyPair: publicOnlyKeyPair);

        // Act
        final stringRepresentation = encryptionKey.toString();

        // Assert
        expect(stringRepresentation, contains('hasPrivateKey: false'));
      });
    });
  });

  group('EncryptionKeyException Tests', () {
    test('should create exception with message only', () {
      // Act
      final exception = EncryptionKeyException('Test error message');

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, isNull);
    });

    test('should create exception with message and error code', () {
      // Act
      final exception = EncryptionKeyException(
        'Test error message',
        errorCode: 'TEST_ERROR',
      );

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, equals('TEST_ERROR'));
    });

    test('toString should include error code when present', () {
      // Arrange
      final exception = EncryptionKeyException(
        'Test error',
        errorCode: 'TEST_ERROR',
      );

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('EncryptionKeyException(TEST_ERROR)'));
      expect(stringRepresentation, contains('Test error'));
    });

    test('toString should work without error code', () {
      // Arrange
      final exception = EncryptionKeyException('Test error');

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('EncryptionKeyException:'));
      expect(stringRepresentation, contains('Test error'));
      expect(stringRepresentation, isNot(contains('TEST_ERROR')));
    });
  });
}