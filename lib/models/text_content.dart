// TextContent Model - Represents plaintext content before encryption
// Based on data-model.md specifications

class TextContent {
  final String content;
  final String lockboxId;

  const TextContent({
    required this.content,
    required this.lockboxId,
  });

  // Validation
  bool get isValid {
    return content.length <= 4000 && lockboxId.isNotEmpty;
  }

  // Get content size
  int get size => content.length;

  // Check if content is empty
  bool get isEmpty => content.isEmpty;

  // Check if content is not empty
  bool get isNotEmpty => content.isNotEmpty;

  // Factory for creating from JSON
  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      content: json['content'] as String,
      lockboxId: json['lockboxId'] as String,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'lockboxId': lockboxId,
    };
  }

  // Copy with modifications
  TextContent copyWith({
    String? content,
    String? lockboxId,
  }) {
    return TextContent(
      content: content ?? this.content,
      lockboxId: lockboxId ?? this.lockboxId,
    );
  }

  // Validate content length
  void validateLength() {
    if (content.length > 4000) {
      throw TextContentValidationException(
        'Content exceeds maximum length of 4000 characters (${content.length})',
        field: 'content',
      );
    }
  }

  // Validate lockbox reference
  void validateLockboxId() {
    if (lockboxId.isEmpty) {
      throw TextContentValidationException(
        'Lockbox ID cannot be empty',
        field: 'lockboxId',
      );
    }
  }

  // Validate all fields
  void validate() {
    validateLength();
    validateLockboxId();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextContent &&
           other.content == content &&
           other.lockboxId == lockboxId;
  }

  @override
  int get hashCode => Object.hash(content, lockboxId);

  @override
  String toString() {
    return 'TextContent{lockboxId: $lockboxId, content: [${content.length} chars]}';
  }
}

// Exception for text content validation errors
class TextContentValidationException implements Exception {
  final String message;
  final String? field;

  const TextContentValidationException(this.message, {this.field});

  @override
  String toString() => 'TextContentValidationException: $message${field != null ? ' (field: $field)' : ''}';
}