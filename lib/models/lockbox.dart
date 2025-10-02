/// Backup configuration constraints
class LockboxBackupConstraints {
  /// Minimum threshold value for Shamir's Secret Sharing
  static const int minThreshold = 1;

  /// Maximum number of total keys/shards for backup distribution
  static const int maxTotalKeys = 10;

  /// Default threshold value for new backups
  static const int defaultThreshold = 2;

  /// Default total keys value for new backups
  static const int defaultTotalKeys = 3;
}

/// Data model for a secure lockbox containing encrypted text content
class Lockbox {
  final String id;
  final String name;
  final String content;
  final DateTime createdAt;

  Lockbox({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Lockbox.fromJson(Map<String, dynamic> json) {
    return Lockbox(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lockbox && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Lockbox{id: $id, name: $name, createdAt: $createdAt}';
  }
}
