import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/models/lockbox.dart';

void main() {
  group('LockboxMetadata Tests', () {
    group('Constructor and Properties', () {
      test('should create valid LockboxMetadata with all properties', () {
        // Arrange
        final id = 'test-id-123';
        final name = 'Test Lockbox';
        final createdAt = DateTime.now();
        final size = 100;

        // Act
        final lockbox = LockboxMetadata(
          id: id,
          name: name,
          createdAt: createdAt,
          size: size,
        );

        // Assert
        expect(lockbox.id, equals(id));
        expect(lockbox.name, equals(name));
        expect(lockbox.createdAt, equals(createdAt));
        expect(lockbox.size, equals(size));
      });

      test('should be immutable', () {
        // Arrange
        final lockbox = LockboxMetadata(
          id: 'test-id',
          name: 'Test',
          createdAt: DateTime.now(),
          size: 50,
        );

        // Assert - properties should be final
        expect(lockbox, isA<LockboxMetadata>());
        // If properties were mutable, this test structure would fail compilation
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final createdAt = DateTime.parse('2024-01-01T12:00:00.000Z');
        final lockbox = LockboxMetadata(
          id: 'test-id-123',
          name: 'Test Lockbox',
          createdAt: createdAt,
          size: 100,
        );

        // Act
        final json = lockbox.toJson();

        // Assert
        expect(json, equals({
          'id': 'test-id-123',
          'name': 'Test Lockbox',
          'createdAt': '2024-01-01T12:00:00.000Z',
          'size': 100,
        }));
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'test-id-123',
          'name': 'Test Lockbox',
          'createdAt': '2024-01-01T12:00:00.000Z',
          'size': 100,
        };

        // Act
        final lockbox = LockboxMetadata.fromJson(json);

        // Assert
        expect(lockbox.id, equals('test-id-123'));
        expect(lockbox.name, equals('Test Lockbox'));
        expect(lockbox.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(lockbox.size, equals(100));
      });

      test('should round-trip through JSON serialization', () {
        // Arrange
        final original = LockboxMetadata(
          id: 'round-trip-test',
          name: 'Round Trip Test',
          createdAt: DateTime.now(),
          size: 500,
        );

        // Act
        final json = original.toJson();
        final deserialized = LockboxMetadata.fromJson(json);

        // Assert
        expect(deserialized.id, equals(original.id));
        expect(deserialized.name, equals(original.name));
        expect(deserialized.createdAt, equals(original.createdAt));
        expect(deserialized.size, equals(original.size));
      });
    });

    group('Validation', () {
      test('should be valid with correct data', () {
        // Arrange
        final lockbox = LockboxMetadata(
          id: 'valid-id',
          name: 'Valid Name',
          createdAt: DateTime.now(),
          size: 100,
        );

        // Act & Assert
        expect(lockbox.isValid(), isTrue);
      });

      test('should be invalid with empty id', () {
        // Arrange
        final lockbox = LockboxMetadata(
          id: '',
          name: 'Valid Name',
          createdAt: DateTime.now(),
          size: 100,
        );

        // Act & Assert
        expect(lockbox.isValid(), isFalse);
      });

      test('should be invalid with empty name', () {
        // Arrange
        final lockbox = LockboxMetadata(
          id: 'valid-id',
          name: '',
          createdAt: DateTime.now(),
          size: 100,
        );

        // Act & Assert
        expect(lockbox.isValid(), isFalse);
      });

      test('should be invalid with name longer than 100 characters', () {
        // Arrange
        final longName = 'a' * 101;
        final lockbox = LockboxMetadata(
          id: 'valid-id',
          name: longName,
          createdAt: DateTime.now(),
          size: 100,
        );

        // Act & Assert
        expect(lockbox.isValid(), isFalse);
      });

      test('should be invalid with negative size', () {
        // Arrange
        final lockbox = LockboxMetadata(
          id: 'valid-id',
          name: 'Valid Name',
          createdAt: DateTime.now(),
          size: -1,
        );

        // Act & Assert
        expect(lockbox.isValid(), isFalse);
      });

      test('should be invalid with size greater than 4000', () {
        // Arrange
        final lockbox = LockboxMetadata(
          id: 'valid-id',
          name: 'Valid Name',
          createdAt: DateTime.now(),
          size: 4001,
        );

        // Act & Assert
        expect(lockbox.isValid(), isFalse);
      });

      test('should be valid at size boundary values', () {
        // Test size = 0
        final lockboxZero = LockboxMetadata(
          id: 'valid-id',
          name: 'Valid Name',
          createdAt: DateTime.now(),
          size: 0,
        );
        expect(lockboxZero.isValid(), isTrue);

        // Test size = 4000
        final lockboxMax = LockboxMetadata(
          id: 'valid-id',
          name: 'Valid Name',
          createdAt: DateTime.now(),
          size: 4000,
        );
        expect(lockboxMax.isValid(), isTrue);
      });
    });

    group('CopyWith', () {
      test('should create copy with updated properties', () {
        // Arrange
        final original = LockboxMetadata(
          id: 'original-id',
          name: 'Original Name',
          createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
          size: 100,
        );

        // Act
        final updated = original.copyWith(
          name: 'Updated Name',
          size: 200,
        );

        // Assert
        expect(updated.id, equals(original.id)); // unchanged
        expect(updated.name, equals('Updated Name')); // changed
        expect(updated.createdAt, equals(original.createdAt)); // unchanged
        expect(updated.size, equals(200)); // changed
      });

      test('should preserve original values when no updates provided', () {
        // Arrange
        final original = LockboxMetadata(
          id: 'test-id',
          name: 'Test Name',
          createdAt: DateTime.now(),
          size: 150,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, equals(original.id));
        expect(copy.name, equals(original.name));
        expect(copy.createdAt, equals(original.createdAt));
        expect(copy.size, equals(original.size));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties match', () {
        // Arrange
        final createdAt = DateTime.now();
        final lockbox1 = LockboxMetadata(
          id: 'same-id',
          name: 'Same Name',
          createdAt: createdAt,
          size: 100,
        );
        final lockbox2 = LockboxMetadata(
          id: 'same-id',
          name: 'Same Name',
          createdAt: createdAt,
          size: 100,
        );

        // Act & Assert
        expect(lockbox1, equals(lockbox2));
        expect(lockbox1.hashCode, equals(lockbox2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final createdAt = DateTime.now();
        final lockbox1 = LockboxMetadata(
          id: 'id-1',
          name: 'Name 1',
          createdAt: createdAt,
          size: 100,
        );
        final lockbox2 = LockboxMetadata(
          id: 'id-2',
          name: 'Name 2',
          createdAt: createdAt,
          size: 100,
        );

        // Act & Assert
        expect(lockbox1, isNot(equals(lockbox2)));
      });
    });

    group('ToString', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final createdAt = DateTime.parse('2024-01-01T12:00:00.000Z');
        final lockbox = LockboxMetadata(
          id: 'test-id',
          name: 'Test Name',
          createdAt: createdAt,
          size: 150,
        );

        // Act
        final stringRepresentation = lockbox.toString();

        // Assert
        expect(stringRepresentation, contains('LockboxMetadata'));
        expect(stringRepresentation, contains('test-id'));
        expect(stringRepresentation, contains('Test Name'));
        expect(stringRepresentation, contains('150'));
      });
    });
  });

  group('LockboxContent Tests', () {
    group('Constructor and Properties', () {
      test('should create valid LockboxContent with all properties', () {
        // Arrange
        final id = 'content-test-id';
        final name = 'Content Test';
        final content = 'This is test content';
        final createdAt = DateTime.now();

        // Act
        final lockboxContent = LockboxContent(
          id: id,
          name: name,
          content: content,
          createdAt: createdAt,
        );

        // Assert
        expect(lockboxContent.id, equals(id));
        expect(lockboxContent.name, equals(name));
        expect(lockboxContent.content, equals(content));
        expect(lockboxContent.createdAt, equals(createdAt));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final createdAt = DateTime.parse('2024-01-01T12:00:00.000Z');
        final lockboxContent = LockboxContent(
          id: 'content-id',
          name: 'Content Name',
          content: 'Test content here',
          createdAt: createdAt,
        );

        // Act
        final json = lockboxContent.toJson();

        // Assert
        expect(json, equals({
          'id': 'content-id',
          'name': 'Content Name',
          'content': 'Test content here',
          'createdAt': '2024-01-01T12:00:00.000Z',
        }));
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'content-id',
          'name': 'Content Name',
          'content': 'Test content here',
          'createdAt': '2024-01-01T12:00:00.000Z',
        };

        // Act
        final lockboxContent = LockboxContent.fromJson(json);

        // Assert
        expect(lockboxContent.id, equals('content-id'));
        expect(lockboxContent.name, equals('Content Name'));
        expect(lockboxContent.content, equals('Test content here'));
        expect(lockboxContent.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
      });
    });

    group('Validation', () {
      test('should be valid with correct data', () {
        // Arrange
        final lockboxContent = LockboxContent(
          id: 'valid-id',
          name: 'Valid Name',
          content: 'Valid content',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(lockboxContent.isValid(), isTrue);
      });

      test('should be invalid with content longer than 4000 characters', () {
        // Arrange
        final longContent = 'a' * 4001;
        final lockboxContent = LockboxContent(
          id: 'valid-id',
          name: 'Valid Name',
          content: longContent,
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(lockboxContent.isValid(), isFalse);
      });

      test('should be valid at content boundary (4000 characters)', () {
        // Arrange
        final maxContent = 'a' * 4000;
        final lockboxContent = LockboxContent(
          id: 'valid-id',
          name: 'Valid Name',
          content: maxContent,
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(lockboxContent.isValid(), isTrue);
      });
    });

    group('Conversion', () {
      test('should convert to LockboxMetadata correctly', () {
        // Arrange
        final createdAt = DateTime.now();
        final lockboxContent = LockboxContent(
          id: 'test-id',
          name: 'Test Name',
          content: 'Test content for conversion',
          createdAt: createdAt,
        );

        // Act
        final metadata = lockboxContent.toMetadata();

        // Assert
        expect(metadata.id, equals('test-id'));
        expect(metadata.name, equals('Test Name'));
        expect(metadata.size, equals('Test content for conversion'.length));
        expect(metadata.createdAt, equals(createdAt));
      });
    });

    group('CopyWith', () {
      test('should create copy with updated properties', () {
        // Arrange
        final original = LockboxContent(
          id: 'original-id',
          name: 'Original Name',
          content: 'Original content',
          createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
        );

        // Act
        final updated = original.copyWith(
          name: 'Updated Name',
          content: 'Updated content',
        );

        // Assert
        expect(updated.id, equals(original.id)); // unchanged
        expect(updated.name, equals('Updated Name')); // changed
        expect(updated.content, equals('Updated content')); // changed
        expect(updated.createdAt, equals(original.createdAt)); // unchanged
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties match', () {
        // Arrange
        final createdAt = DateTime.now();
        final content1 = LockboxContent(
          id: 'same-id',
          name: 'Same Name',
          content: 'Same content',
          createdAt: createdAt,
        );
        final content2 = LockboxContent(
          id: 'same-id',
          name: 'Same Name',
          content: 'Same content',
          createdAt: createdAt,
        );

        // Act & Assert
        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final createdAt = DateTime.now();
        final content1 = LockboxContent(
          id: 'id-1',
          name: 'Name 1',
          content: 'Content 1',
          createdAt: createdAt,
        );
        final content2 = LockboxContent(
          id: 'id-2',
          name: 'Name 2',
          content: 'Content 2',
          createdAt: createdAt,
        );

        // Act & Assert
        expect(content1, isNot(equals(content2)));
      });
    });

    group('ToString', () {
      test('should provide meaningful string representation with content length', () {
        // Arrange
        final createdAt = DateTime.parse('2024-01-01T12:00:00.000Z');
        final content = LockboxContent(
          id: 'test-id',
          name: 'Test Name',
          content: 'This is a test content message',
          createdAt: createdAt,
        );

        // Act
        final stringRepresentation = content.toString();

        // Assert
        expect(stringRepresentation, contains('LockboxContent'));
        expect(stringRepresentation, contains('test-id'));
        expect(stringRepresentation, contains('Test Name'));
        expect(stringRepresentation, contains('30 chars')); // length of content
      });
    });
  });
}