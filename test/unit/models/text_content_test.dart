import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/models/text_content.dart';

void main() {
  group('TextContent Tests', () {
    group('Constructor and Properties', () {
      test('should create valid TextContent with all properties', () {
        // Arrange
        final content = 'This is test content';
        final lockboxId = 'test-lockbox-id';

        // Act
        final textContent = TextContent(
          content: content,
          lockboxId: lockboxId,
        );

        // Assert
        expect(textContent.content, equals(content));
        expect(textContent.lockboxId, equals(lockboxId));
      });

      test('should be immutable', () {
        // Arrange
        final textContent = TextContent(
          content: 'Test content',
          lockboxId: 'test-id',
        );

        // Assert - properties should be final
        expect(textContent, isA<TextContent>());
        // If properties were mutable, this test structure would fail compilation
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final textContent = TextContent(
          content: 'Test content for serialization',
          lockboxId: 'test-lockbox-123',
        );

        // Act
        final json = textContent.toJson();

        // Assert
        expect(json, equals({
          'content': 'Test content for serialization',
          'lockboxId': 'test-lockbox-123',
        }));
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'content': 'Test content from JSON',
          'lockboxId': 'json-lockbox-456',
        };

        // Act
        final textContent = TextContent.fromJson(json);

        // Assert
        expect(textContent.content, equals('Test content from JSON'));
        expect(textContent.lockboxId, equals('json-lockbox-456'));
      });

      test('should round-trip through JSON serialization', () {
        // Arrange
        final original = TextContent(
          content: 'Round trip test content',
          lockboxId: 'round-trip-id',
        );

        // Act
        final json = original.toJson();
        final deserialized = TextContent.fromJson(json);

        // Assert
        expect(deserialized.content, equals(original.content));
        expect(deserialized.lockboxId, equals(original.lockboxId));
      });
    });

    group('Validation', () {
      test('should be valid with correct data', () {
        // Arrange
        final textContent = TextContent(
          content: 'Valid content',
          lockboxId: 'valid-lockbox-id',
        );

        // Act & Assert
        expect(textContent.isValid(), isTrue);
      });

      test('should be valid with empty content', () {
        // Arrange
        final textContent = TextContent(
          content: '',
          lockboxId: 'valid-lockbox-id',
        );

        // Act & Assert
        expect(textContent.isValid(), isTrue);
      });

      test('should be invalid with empty lockboxId', () {
        // Arrange
        final textContent = TextContent(
          content: 'Valid content',
          lockboxId: '',
        );

        // Act & Assert
        expect(textContent.isValid(), isFalse);
      });

      test('should be invalid with content longer than 4000 characters', () {
        // Arrange
        final longContent = 'a' * 4001;
        final textContent = TextContent(
          content: longContent,
          lockboxId: 'valid-lockbox-id',
        );

        // Act & Assert
        expect(textContent.isValid(), isFalse);
      });

      test('should be valid at content boundary (4000 characters)', () {
        // Arrange
        final maxContent = 'a' * 4000;
        final textContent = TextContent(
          content: maxContent,
          lockboxId: 'valid-lockbox-id',
        );

        // Act & Assert
        expect(textContent.isValid(), isTrue);
      });
    });

    group('Size and Empty Properties', () {
      test('should return correct size', () {
        // Arrange
        final content = 'This content has 25 chars';
        final textContent = TextContent(
          content: content,
          lockboxId: 'test-id',
        );

        // Act & Assert
        expect(textContent.size, equals(25));
      });

      test('should return size 0 for empty content', () {
        // Arrange
        final textContent = TextContent(
          content: '',
          lockboxId: 'test-id',
        );

        // Act & Assert
        expect(textContent.size, equals(0));
      });

      test('isEmpty should return true for empty content', () {
        // Arrange
        final textContent = TextContent(
          content: '',
          lockboxId: 'test-id',
        );

        // Act & Assert
        expect(textContent.isEmpty, isTrue);
        expect(textContent.isNotEmpty, isFalse);
      });

      test('isEmpty should return false for non-empty content', () {
        // Arrange
        final textContent = TextContent(
          content: 'Not empty',
          lockboxId: 'test-id',
        );

        // Act & Assert
        expect(textContent.isEmpty, isFalse);
        expect(textContent.isNotEmpty, isTrue);
      });
    });

    group('CopyWith', () {
      test('should create copy with updated content', () {
        // Arrange
        final original = TextContent(
          content: 'Original content',
          lockboxId: 'original-id',
        );

        // Act
        final updated = original.copyWith(content: 'Updated content');

        // Assert
        expect(updated.content, equals('Updated content'));
        expect(updated.lockboxId, equals(original.lockboxId)); // unchanged
      });

      test('should create copy with updated lockboxId', () {
        // Arrange
        final original = TextContent(
          content: 'Test content',
          lockboxId: 'original-id',
        );

        // Act
        final updated = original.copyWith(lockboxId: 'updated-id');

        // Assert
        expect(updated.content, equals(original.content)); // unchanged
        expect(updated.lockboxId, equals('updated-id'));
      });

      test('should create copy with both properties updated', () {
        // Arrange
        final original = TextContent(
          content: 'Original content',
          lockboxId: 'original-id',
        );

        // Act
        final updated = original.copyWith(
          content: 'Updated content',
          lockboxId: 'updated-id',
        );

        // Assert
        expect(updated.content, equals('Updated content'));
        expect(updated.lockboxId, equals('updated-id'));
      });

      test('should preserve original values when no updates provided', () {
        // Arrange
        final original = TextContent(
          content: 'Test content',
          lockboxId: 'test-id',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.content, equals(original.content));
        expect(copy.lockboxId, equals(original.lockboxId));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties match', () {
        // Arrange
        final textContent1 = TextContent(
          content: 'Same content',
          lockboxId: 'same-id',
        );
        final textContent2 = TextContent(
          content: 'Same content',
          lockboxId: 'same-id',
        );

        // Act & Assert
        expect(textContent1, equals(textContent2));
        expect(textContent1.hashCode, equals(textContent2.hashCode));
      });

      test('should not be equal when content differs', () {
        // Arrange
        final textContent1 = TextContent(
          content: 'Content 1',
          lockboxId: 'same-id',
        );
        final textContent2 = TextContent(
          content: 'Content 2',
          lockboxId: 'same-id',
        );

        // Act & Assert
        expect(textContent1, isNot(equals(textContent2)));
      });

      test('should not be equal when lockboxId differs', () {
        // Arrange
        final textContent1 = TextContent(
          content: 'Same content',
          lockboxId: 'id-1',
        );
        final textContent2 = TextContent(
          content: 'Same content',
          lockboxId: 'id-2',
        );

        // Act & Assert
        expect(textContent1, isNot(equals(textContent2)));
      });
    });

    group('ToString', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final textContent = TextContent(
          content: 'This is test content for toString',
          lockboxId: 'test-lockbox-id',
        );

        // Act
        final stringRepresentation = textContent.toString();

        // Assert
        expect(stringRepresentation, contains('TextContent'));
        expect(stringRepresentation, contains('34 chars')); // content length
        expect(stringRepresentation, contains('test-lockbox-id'));
      });

      test('should handle empty content in toString', () {
        // Arrange
        final textContent = TextContent(
          content: '',
          lockboxId: 'empty-content-id',
        );

        // Act
        final stringRepresentation = textContent.toString();

        // Assert
        expect(stringRepresentation, contains('TextContent'));
        expect(stringRepresentation, contains('0 chars'));
        expect(stringRepresentation, contains('empty-content-id'));
      });
    });
  });

  group('TextContentException Tests', () {
    test('should create exception with message only', () {
      // Act
      final exception = TextContentException('Test error message');

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, isNull);
    });

    test('should create exception with message and error code', () {
      // Act
      final exception = TextContentException(
        'Test error message',
        errorCode: 'TEST_ERROR',
      );

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, equals('TEST_ERROR'));
    });

    test('toString should include error code when present', () {
      // Arrange
      final exception = TextContentException(
        'Test error',
        errorCode: 'TEST_ERROR',
      );

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('TextContentException(TEST_ERROR)'));
      expect(stringRepresentation, contains('Test error'));
    });

    test('toString should work without error code', () {
      // Arrange
      final exception = TextContentException('Test error');

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('TextContentException:'));
      expect(stringRepresentation, contains('Test error'));
      expect(stringRepresentation, isNot(contains('TEST_ERROR')));
    });
  });
}