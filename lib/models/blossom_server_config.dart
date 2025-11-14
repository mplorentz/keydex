import 'package:uuid/uuid.dart';

/// Configuration for a Blossom file storage server
class BlossomServerConfig {
  final String id;
  final String url;
  final String name;
  final bool isEnabled;
  final DateTime? lastUsed;
  final bool isDefault;

  BlossomServerConfig({
    required this.id,
    required this.url,
    required this.name,
    this.isEnabled = true,
    this.lastUsed,
    this.isDefault = false,
  });

  /// Create a new BlossomServerConfig with generated UUID
  factory BlossomServerConfig.create({
    required String url,
    required String name,
    bool isEnabled = true,
    bool isDefault = false,
  }) {
    return BlossomServerConfig(
      id: const Uuid().v4(),
      url: url,
      name: name,
      isEnabled: isEnabled,
      isDefault: isDefault,
    );
  }

  /// Validate this configuration
  void validate() {
    if (id.isEmpty || !_isValidUuid(id)) {
      throw ArgumentError('Invalid UUID format for config ID: $id');
    }
    if (!_isValidUrl(url)) {
      throw ArgumentError('Invalid URL format: $url');
    }
    if (url.endsWith('/')) {
      throw ArgumentError('URL must not end with trailing slash');
    }
    if (name.isEmpty || name.length > 100) {
      throw ArgumentError('Name must be between 1 and 100 characters');
    }
  }

  bool _isValidUuid(String str) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(str);
  }

  bool _isValidUrl(String str) {
    try {
      final uri = Uri.parse(str);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'isEnabled': isEnabled,
      'lastUsed': lastUsed?.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// Create from JSON
  factory BlossomServerConfig.fromJson(Map<String, dynamic> json) {
    final config = BlossomServerConfig(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
    config.validate();
    return config;
  }

  /// Create a copy with updated fields
  BlossomServerConfig copyWith({
    String? id,
    String? url,
    String? name,
    bool? isEnabled,
    DateTime? lastUsed,
    bool? isDefault,
  }) {
    return BlossomServerConfig(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      lastUsed: lastUsed ?? this.lastUsed,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlossomServerConfig && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BlossomServerConfig{id: $id, name: $name, url: $url, isDefault: $isDefault}';
  }
}

