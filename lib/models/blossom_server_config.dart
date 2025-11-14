/// Configuration for a Blossom file storage server
class BlossomServerConfig {
  final String id; // UUID for this config
  final String url; // HTTP/HTTPS URL (e.g., "https://blossom.example.com")
  final String name; // User-friendly name
  final bool isEnabled; // Whether to use this server
  final DateTime? lastUsed; // Last successful upload/download
  final bool isDefault; // Default server for new lockboxes

  BlossomServerConfig({
    required this.id,
    required this.url,
    required this.name,
    required this.isEnabled,
    this.lastUsed,
    required this.isDefault,
  }) {
    _validate();
  }

  void _validate() {
    if (id.isEmpty) {
      throw ArgumentError('Server config ID cannot be empty');
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw ArgumentError('URL must be HTTP or HTTPS (not WebSocket)');
    }
    if (url.endsWith('/')) {
      throw ArgumentError('URL must not end with trailing slash');
    }
    if (name.isEmpty || name.length > 100) {
      throw ArgumentError('Server name must be 1-100 characters');
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'isEnabled': isEnabled,
      if (lastUsed != null) 'lastUsed': lastUsed!.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// Create from JSON
  factory BlossomServerConfig.fromJson(Map<String, dynamic> json) {
    return BlossomServerConfig(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      isEnabled: json['isEnabled'] as bool,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
      isDefault: json['isDefault'] as bool,
    );
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

  /// Create default localhost configuration
  factory BlossomServerConfig.localhost() {
    return BlossomServerConfig(
      id: 'default-localhost',
      url: 'http://localhost:10548',
      name: 'Local Blossom Server',
      isEnabled: true,
      lastUsed: null,
      isDefault: true,
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

