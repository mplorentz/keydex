// Lockbox Model - Immutable data containers for lockbox metadata and content
// Based on data-model.md specifications

class LockboxMetadata {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;

  const LockboxMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
  });

  // Validation
  bool get isValid {
    return name.isNotEmpty &&
           name.length <= 100 &&
           size >= 0 &&
           size <= 4000;
  }

  // Factory for creating from JSON
  factory LockboxMetadata.fromJson(Map<String, dynamic> json) {
    return LockboxMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      size: json['size'] as int,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'size': size,
    };
  }

  // Copy with modifications
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LockboxMetadata &&
           other.id == id &&
           other.name == name &&
           other.createdAt == createdAt &&
           other.size == size;
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, size);

  @override
  String toString() {
    return 'LockboxMetadata{id: $id, name: $name, createdAt: $createdAt, size: $size}';
  }
}

class LockboxContent {
  final String id;
  final String name;
  final String content;
  final DateTime createdAt;

  const LockboxContent({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
  });

  // Validation
  bool get isValid {
    return name.isNotEmpty &&
           name.length <= 100 &&
           content.length <= 4000;
  }

  // Factory for creating from JSON
  factory LockboxContent.fromJson(Map<String, dynamic> json) {
    return LockboxContent(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create metadata from content
  LockboxMetadata toMetadata() {
    return LockboxMetadata(
      id: id,
      name: name,
      createdAt: createdAt,
      size: content.length,
    );
  }

  // Copy with modifications
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LockboxContent &&
           other.id == id &&
           other.name == name &&
           other.content == content &&
           other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, content, createdAt);

  @override
  String toString() {
    return 'LockboxContent{id: $id, name: $name, content: [${content.length} chars], createdAt: $createdAt}';
  }
}

// Exception for lockbox-related errors
class LockboxValidationException implements Exception {
  final String message;
  final String? field;

  const LockboxValidationException(this.message, {this.field});

  @override
  String toString() => 'LockboxValidationException: $message${field != null ? ' (field: $field)' : ''}';
}