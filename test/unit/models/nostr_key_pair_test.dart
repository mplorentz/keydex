import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/models/nostr_key_pair.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() {
  group('NostrKeyPair Tests', () {
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
      test('should create valid NostrKeyPair with all properties', () {
        // Act
        final nostrKeyPair = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Test Key',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(nostrKeyPair.keyPair, equals(validKeyPair));
        expect(nostrKeyPair.label, equals('Test Key'));
        expect(nostrKeyPair.createdAt, equals(testCreatedAt));
      });

      test('should create NostrKeyPair with null optional properties', () {
        // Act
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Assert
        expect(nostrKeyPair.keyPair, equals(validKeyPair));
        expect(nostrKeyPair.label, isNull);
        expect(nostrKeyPair.createdAt, isNull);
      });

      test('should be immutable', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Assert - properties should be final
        expect(nostrKeyPair, isA<NostrKeyPair>());
      });
    });

    group('Factory Constructors', () {
      test('fromKeyPair should create with current timestamp', () {
        // Act
        final nostrKeyPair = NostrKeyPair.fromKeyPair(validKeyPair, label: 'Test Label');

        // Assert
        expect(nostrKeyPair.keyPair, equals(validKeyPair));
        expect(nostrKeyPair.label, equals('Test Label'));
        expect(nostrKeyPair.createdAt, isNotNull);
        expect(nostrKeyPair.createdAt!.isAfter(DateTime.now().subtract(Duration(seconds: 1))), isTrue);
      });

      test('fromKeyPair should work without label', () {
        // Act
        final nostrKeyPair = NostrKeyPair.fromKeyPair(validKeyPair);

        // Assert
        expect(nostrKeyPair.keyPair, equals(validKeyPair));
        expect(nostrKeyPair.label, isNull);
        expect(nostrKeyPair.createdAt, isNotNull);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly with all properties', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Test Label',
          createdAt: testCreatedAt,
        );

        // Act
        final json = nostrKeyPair.toJson();

        // Assert
        expect(json, equals({
          'privateKey': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'publicKey': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'label': 'Test Label',
          'createdAt': '2024-01-01T12:00:00.000Z',
        }));
      });

      test('should serialize to JSON correctly with null optional properties', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act
        final json = nostrKeyPair.toJson();

        // Assert
        expect(json['privateKey'], equals(validKeyPair.privateKey));
        expect(json['publicKey'], equals(validKeyPair.publicKey));
        expect(json['label'], isNull);
        expect(json['createdAt'], isNull);
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'privateKey': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'publicKey': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'label': 'Test Label',
          'createdAt': '2024-01-01T12:00:00.000Z',
        };

        // Act
        final nostrKeyPair = NostrKeyPair.fromJson(json);

        // Assert
        expect(nostrKeyPair.privateKey, equals(json['privateKey']));
        expect(nostrKeyPair.publicKey, equals(json['publicKey']));
        expect(nostrKeyPair.label, equals(json['label']));
        expect(nostrKeyPair.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
      });

      test('should deserialize from JSON with null optional properties', () {
        // Arrange
        final json = {
          'privateKey': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'publicKey': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'label': null,
          'createdAt': null,
        };

        // Act
        final nostrKeyPair = NostrKeyPair.fromJson(json);

        // Assert
        expect(nostrKeyPair.privateKey, equals(json['privateKey']));
        expect(nostrKeyPair.publicKey, equals(json['publicKey']));
        expect(nostrKeyPair.label, isNull);
        expect(nostrKeyPair.createdAt, isNull);
      });

      test('should round-trip through JSON serialization', () {
        // Arrange
        final original = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Round Trip Test',
          createdAt: testCreatedAt,
        );

        // Act
        final json = original.toJson();
        final deserialized = NostrKeyPair.fromJson(json);

        // Assert
        expect(deserialized.privateKey, equals(original.privateKey));
        expect(deserialized.publicKey, equals(original.publicKey));
        expect(deserialized.label, equals(original.label));
        expect(deserialized.createdAt, equals(original.createdAt));
      });
    });

    group('Key Access Properties', () {
      test('should provide access to private key', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.privateKey, equals(validKeyPair.privateKey));
      });

      test('should provide access to public key', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.publicKey, equals(validKeyPair.publicKey));
      });

      test('should provide access to private key in bech32 format', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.privateKeyBech32, equals(validKeyPair.privateKeyBech32));
      });

      test('should provide access to public key in bech32 format', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.publicKeyBech32, equals(validKeyPair.publicKeyBech32));
      });
    });

    group('Validation', () {
      test('should be valid with correct 64-character hex keys', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.isValid(), isTrue);
      });

      test('should be invalid with short private key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: 'short', // invalid length
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final nostrKeyPair = NostrKeyPair(keyPair: invalidKeyPair);

        // Act & Assert
        expect(nostrKeyPair.isValid(), isFalse);
      });

      test('should be invalid with short public key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          publicKey: 'short', // invalid length
        );
        final nostrKeyPair = NostrKeyPair(keyPair: invalidKeyPair);

        // Act & Assert
        expect(nostrKeyPair.isValid(), isFalse);
      });

      test('should be invalid with non-hex private key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: 'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg', // invalid hex
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final nostrKeyPair = NostrKeyPair(keyPair: invalidKeyPair);

        // Act & Assert
        expect(nostrKeyPair.isValid(), isFalse);
      });

      test('should be invalid with non-hex public key', () {
        // Arrange
        final invalidKeyPair = KeyPair(
          privateKey: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          publicKey: 'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg', // invalid hex
        );
        final nostrKeyPair = NostrKeyPair(keyPair: invalidKeyPair);

        // Act & Assert
        expect(nostrKeyPair.isValid(), isFalse);
      });

      test('should be valid with null private key (public-key-only)', () {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final nostrKeyPair = NostrKeyPair(keyPair: publicOnlyKeyPair);

        // Act & Assert
        expect(nostrKeyPair.isValid(), isTrue);
      });
    });

    group('Key Type Checks', () {
      test('canSign should return true when private key exists', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.canSign, isTrue);
        expect(nostrKeyPair.isPublicOnly, isFalse);
      });

      test('canSign should return false when private key is null', () {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final nostrKeyPair = NostrKeyPair(keyPair: publicOnlyKeyPair);

        // Act & Assert
        expect(nostrKeyPair.canSign, isFalse);
        expect(nostrKeyPair.isPublicOnly, isTrue);
      });
    });

    group('Display Properties', () {
      test('shortId should return first 8 characters of public key', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.shortId, equals('abcdef12'));
      });

      test('displayName should return label when available', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'My Test Key',
        );

        // Act & Assert
        expect(nostrKeyPair.displayName, equals('My Test Key'));
      });

      test('displayName should return shortId when label is null', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act & Assert
        expect(nostrKeyPair.displayName, equals('abcdef12'));
      });
    });

    group('Public-Only Conversion', () {
      test('toPublicOnly should create public-key-only version', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Original Key',
          createdAt: testCreatedAt,
        );

        // Act
        final publicOnly = nostrKeyPair.toPublicOnly();

        // Assert
        expect(publicOnly.privateKey, isNull);
        expect(publicOnly.publicKey, equals(nostrKeyPair.publicKey));
        expect(publicOnly.label, equals(nostrKeyPair.label));
        expect(publicOnly.createdAt, equals(nostrKeyPair.createdAt));
        expect(publicOnly.isPublicOnly, isTrue);
        expect(publicOnly.canSign, isFalse);
      });

      test('toPublicOnly should preserve public-only state', () {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final nostrKeyPair = NostrKeyPair(keyPair: publicOnlyKeyPair);

        // Act
        final publicOnly = nostrKeyPair.toPublicOnly();

        // Assert
        expect(publicOnly.privateKey, isNull);
        expect(publicOnly.publicKey, equals(nostrKeyPair.publicKey));
        expect(publicOnly.isPublicOnly, isTrue);
      });
    });

    group('CopyWith', () {
      test('should create copy with updated keyPair', () {
        // Arrange
        final original = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Original Label',
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
        expect(updated.label, equals(original.label)); // unchanged
        expect(updated.createdAt, equals(original.createdAt)); // unchanged
      });

      test('should create copy with updated label', () {
        // Arrange
        final original = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Original Label',
          createdAt: testCreatedAt,
        );

        // Act
        final updated = original.copyWith(label: 'Updated Label');

        // Assert
        expect(updated.keyPair, equals(original.keyPair)); // unchanged
        expect(updated.label, equals('Updated Label'));
        expect(updated.createdAt, equals(original.createdAt)); // unchanged
      });

      test('should create copy with updated createdAt', () {
        // Arrange
        final original = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Test Label',
          createdAt: testCreatedAt,
        );
        final newCreatedAt = DateTime.now();

        // Act
        final updated = original.copyWith(createdAt: newCreatedAt);

        // Assert
        expect(updated.keyPair, equals(original.keyPair)); // unchanged
        expect(updated.label, equals(original.label)); // unchanged
        expect(updated.createdAt, equals(newCreatedAt));
      });

      test('should preserve original values when no updates provided', () {
        // Arrange
        final original = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Test Label',
          createdAt: testCreatedAt,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.keyPair, equals(original.keyPair));
        expect(copy.label, equals(original.label));
        expect(copy.createdAt, equals(original.createdAt));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties match', () {
        // Arrange
        final nostrKeyPair1 = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Same Label',
          createdAt: testCreatedAt,
        );
        final nostrKeyPair2 = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Same Label',
          createdAt: testCreatedAt,
        );

        // Act & Assert
        expect(nostrKeyPair1, equals(nostrKeyPair2));
        expect(nostrKeyPair1.hashCode, equals(nostrKeyPair2.hashCode));
      });

      test('should not be equal when keyPair differs', () {
        // Arrange
        final differentKeyPair = KeyPair(
          privateKey: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
          publicKey: '0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba',
        );
        final nostrKeyPair1 = NostrKeyPair(keyPair: validKeyPair);
        final nostrKeyPair2 = NostrKeyPair(keyPair: differentKeyPair);

        // Act & Assert
        expect(nostrKeyPair1, isNot(equals(nostrKeyPair2)));
      });

      test('should not be equal when label differs', () {
        // Arrange
        final nostrKeyPair1 = NostrKeyPair(keyPair: validKeyPair, label: 'Label 1');
        final nostrKeyPair2 = NostrKeyPair(keyPair: validKeyPair, label: 'Label 2');

        // Act & Assert
        expect(nostrKeyPair1, isNot(equals(nostrKeyPair2)));
      });

      test('should not be equal when createdAt differs', () {
        // Arrange
        final differentCreatedAt = DateTime.now();
        final nostrKeyPair1 = NostrKeyPair(
          keyPair: validKeyPair,
          createdAt: testCreatedAt,
        );
        final nostrKeyPair2 = NostrKeyPair(
          keyPair: validKeyPair,
          createdAt: differentCreatedAt,
        );

        // Act & Assert
        expect(nostrKeyPair1, isNot(equals(nostrKeyPair2)));
      });
    });

    group('ToString', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(
          keyPair: validKeyPair,
          label: 'Test Label',
        );

        // Act
        final stringRepresentation = nostrKeyPair.toString();

        // Assert
        expect(stringRepresentation, contains('NostrKeyPair'));
        expect(stringRepresentation, contains('abcdef12')); // shortId
        expect(stringRepresentation, contains('canSign: true'));
        expect(stringRepresentation, contains('Test Label'));
      });

      test('should handle null label in toString', () {
        // Arrange
        final nostrKeyPair = NostrKeyPair(keyPair: validKeyPair);

        // Act
        final stringRepresentation = nostrKeyPair.toString();

        // Assert
        expect(stringRepresentation, contains('NostrKeyPair'));
        expect(stringRepresentation, contains('abcdef12')); // shortId
        expect(stringRepresentation, contains('label: null'));
      });

      test('should handle public-key-only in toString', () {
        // Arrange
        final publicOnlyKeyPair = KeyPair(
          privateKey: null,
          publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final nostrKeyPair = NostrKeyPair(keyPair: publicOnlyKeyPair);

        // Act
        final stringRepresentation = nostrKeyPair.toString();

        // Assert
        expect(stringRepresentation, contains('canSign: false'));
      });
    });
  });

  group('NostrKeyPairException Tests', () {
    test('should create exception with message only', () {
      // Act
      final exception = NostrKeyPairException('Test error message');

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, isNull);
    });

    test('should create exception with message and error code', () {
      // Act
      final exception = NostrKeyPairException(
        'Test error message',
        errorCode: 'TEST_ERROR',
      );

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, equals('TEST_ERROR'));
    });

    test('toString should include error code when present', () {
      // Arrange
      final exception = NostrKeyPairException(
        'Test error',
        errorCode: 'TEST_ERROR',
      );

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('NostrKeyPairException(TEST_ERROR)'));
      expect(stringRepresentation, contains('Test error'));
    });

    test('toString should work without error code', () {
      // Arrange
      final exception = NostrKeyPairException('Test error');

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('NostrKeyPairException:'));
      expect(stringRepresentation, contains('Test error'));
      expect(stringRepresentation, isNot(contains('TEST_ERROR')));
    });
  });
}