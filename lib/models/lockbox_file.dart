import 'package:uuid/uuid.dart';

/// Represents a single file stored in a lockbox
class LockboxFile {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final String blossomHash;
  final String blossomUrl;
  final DateTime uploadedAt;
  final String encryptionSalt;

  LockboxFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.blossomHash,
    required this.blossomUrl,
    required this.uploadedAt,
    required this.encryptionSalt,
  });

  /// Create a new LockboxFile with generated UUID
  factory LockboxFile.create({
    required String name,
    required int sizeBytes,
    required String mimeType,
    required String blossomHash,
    required String blossomUrl,
    required String encryptionSalt,
  }) {
    return LockboxFile(
      id: const Uuid().v4(),
      name: name,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      blossomHash: blossomHash,
      blossomUrl: blossomUrl,
      uploadedAt: DateTime.now(),
      encryptionSalt: encryptionSalt,
    );
  }

  /// Validate this file
  void validate() {
    if (id.isEmpty || !_isValidUuid(id)) {
      throw ArgumentError('Invalid UUID format for file ID: $id');
    }
    if (name.isEmpty || name.length > 255) {
      throw ArgumentError('File name must be between 1 and 255 characters');
    }
    if (sizeBytes <= 0 || sizeBytes > 1073741824) {
      throw ArgumentError('File size must be between 1 byte and 1GB');
    }
    if (!_isValidMimeType(mimeType)) {
      throw ArgumentError('Invalid MIME type format: $mimeType');
    }
    if (blossomHash.length != 64 || !_isHexString(blossomHash)) {
      throw ArgumentError('Blossom hash must be valid SHA-256 hex (64 characters)');
    }
    if (!_isValidUrl(blossomUrl)) {
      throw ArgumentError('Invalid Blossom URL format: $blossomUrl');
    }
    if (uploadedAt.isAfter(DateTime.now())) {
      throw ArgumentError('Upload time cannot be in the future');
    }
    if (encryptionSalt.isEmpty) {
      throw ArgumentError('Encryption salt cannot be empty');
    }
  }

  bool _isValidUuid(String str) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(str);
  }

  bool _isValidMimeType(String str) {
    final mimeRegex = RegExp(r'^[a-z]+/[a-z0-9][a-z0-9\-_]*$', caseSensitive: false);
    return mimeRegex.hasMatch(str);
  }

  bool _isHexString(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
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
      'name': name,
      'sizeBytes': sizeBytes,
      'mimeType': mimeType,
      'blossomHash': blossomHash,
      'blossomUrl': blossomUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
      'encryptionSalt': encryptionSalt,
    };
  }

  /// Create from JSON
  factory LockboxFile.fromJson(Map<String, dynamic> json) {
    final file = LockboxFile(
      id: json['id'] as String,
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      mimeType: json['mimeType'] as String,
      blossomHash: json['blossomHash'] as String,
      blossomUrl: json['blossomUrl'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      encryptionSalt: json['encryptionSalt'] as String,
    );
    file.validate();
    return file;
  }

  /// Create a copy with updated fields
  LockboxFile copyWith({
    String? id,
    String? name,
    int? sizeBytes,
    String? mimeType,
    String? blossomHash,
    String? blossomUrl,
    DateTime? uploadedAt,
    String? encryptionSalt,
  }) {
    return LockboxFile(
      id: id ?? this.id,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      blossomHash: blossomHash ?? this.blossomHash,
      blossomUrl: blossomUrl ?? this.blossomUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      encryptionSalt: encryptionSalt ?? this.encryptionSalt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockboxFile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LockboxFile{id: $id, name: $name, sizeBytes: $sizeBytes}';
  }
}

