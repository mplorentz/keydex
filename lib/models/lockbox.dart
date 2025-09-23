// Lockbox Model
// Represents lockbox metadata and content for the encrypted text storage

import 'package:flutter/foundation.dart';

/// Lockbox metadata record - immutable data container
@immutable
class LockboxMetadata {
  const LockboxMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int size;

  /// Creates a LockboxMetadata from JSON
  factory LockboxMetadata.fromJson(Map<String, dynamic> json) {
    return LockboxMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      size: json['size'] as int,
    );
  }

  /// Converts LockboxMetadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'size': size,
    };
  }

  /// Validates the lockbox metadata
  bool isValid() {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        name.length <= 100 &&
        size >= 0 &&
        size <= 4000;
  }

  /// Creates a copy with updated fields
  LockboxMetadata copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? size,
  }) {
    return LockboxMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockboxMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          createdAt == other.createdAt &&
          size == other.size;

  @override
  int get hashCode => Object.hash(id, name, createdAt, size);

  @override
  String toString() {
    return 'LockboxMetadata{id: $id, name: $name, createdAt: $createdAt, size: $size}';
  }
}

/// Lockbox content record - immutable data container
@immutable
class LockboxContent {
  const LockboxContent({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String content;
  final DateTime createdAt;

  /// Creates a LockboxContent from JSON
  factory LockboxContent.fromJson(Map<String, dynamic> json) {
    return LockboxContent(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts LockboxContent to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Validates the lockbox content
  bool isValid() {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        name.length <= 100 &&
        content.length <= 4000;
  }

  /// Creates a copy with updated fields
  LockboxContent copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? createdAt,
  }) {
    return LockboxContent(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts to LockboxMetadata
  LockboxMetadata toMetadata() {
    return LockboxMetadata(
      id: id,
      name: name,
      createdAt: createdAt,
      size: content.length,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockboxContent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          content == other.content &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, content, createdAt);

  @override
  String toString() {
    return 'LockboxContent{id: $id, name: $name, content: [${content.length} chars], createdAt: $createdAt}';
  }
}