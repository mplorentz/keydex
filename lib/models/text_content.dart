// TextContent Model
// Represents the plaintext content before encryption

import 'package:flutter/foundation.dart';

/// Represents the plaintext content before encryption
@immutable
class TextContent {
  const TextContent({
    required this.content,
    required this.lockboxId,
  });

  final String content;
  final String lockboxId;

  /// Creates a TextContent from JSON
  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      content: json['content'] as String,
      lockboxId: json['lockboxId'] as String,
    );
  }

  /// Converts TextContent to JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'lockboxId': lockboxId,
    };
  }

  /// Validates the text content
  bool isValid() {
    return content.length <= 4000 && lockboxId.isNotEmpty;
  }

  /// Gets the character count
  int get size => content.length;

  /// Checks if content is empty
  bool get isEmpty => content.isEmpty;

  /// Checks if content is not empty
  bool get isNotEmpty => content.isNotEmpty;

  /// Creates a copy with updated fields
  TextContent copyWith({
    String? content,
    String? lockboxId,
  }) {
    return TextContent(
      content: content ?? this.content,
      lockboxId: lockboxId ?? this.lockboxId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextContent &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          lockboxId == other.lockboxId;

  @override
  int get hashCode => Object.hash(content, lockboxId);

  @override
  String toString() {
    return 'TextContent{content: [${content.length} chars], lockboxId: $lockboxId}';
  }
}

/// Exception thrown when text content validation fails
class TextContentException implements Exception {
  final String message;
  final String? errorCode;

  const TextContentException(this.message, {this.errorCode});

  @override
  String toString() {
    return errorCode != null
        ? 'TextContentException($errorCode): $message'
        : 'TextContentException: $message';
  }
}