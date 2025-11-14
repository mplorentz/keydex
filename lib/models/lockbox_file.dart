/// Represents a single file stored in a lockbox
class LockboxFile {
  final String id; // UUID for this file
  final String name; // Original filename (e.g., "passport.pdf")
  final int sizeBytes; // File size in bytes
  final String mimeType; // MIME type (e.g., "application/pdf")
  final String blossomHash; // SHA-256 hash of encrypted file on Blossom
  final String blossomUrl; // Full Blossom URL for retrieval
  final DateTime uploadedAt; // When file was uploaded
  final String encryptionSalt; // Salt used for this file's encryption

  LockboxFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.blossomHash,
    required this.blossomUrl,
    required this.uploadedAt,
    required this.encryptionSalt,
  }) {
    _validate();
  }

  void _validate() {
    if (id.isEmpty) {
      throw ArgumentError('File ID cannot be empty');
    }
    if (name.isEmpty || name.length > 255) {
      throw ArgumentError('File name must be 1-255 characters');
    }
    if (sizeBytes <= 0 || sizeBytes > 1073741824) {
      // 1GB limit
      throw ArgumentError('File size must be between 1 byte and 1GB');
    }
    if (mimeType.isEmpty) {
      throw ArgumentError('MIME type cannot be empty');
    }
    if (blossomHash.length != 64 || !_isHexString(blossomHash)) {
      throw ArgumentError('Blossom hash must be valid SHA-256 hex (64 characters)');
    }
    if (!blossomUrl.startsWith('http://') && !blossomUrl.startsWith('https://')) {
      throw ArgumentError('Blossom URL must be HTTP or HTTPS');
    }
    if (uploadedAt.isAfter(DateTime.now())) {
      throw ArgumentError('Upload date cannot be in the future');
    }
    if (encryptionSalt.isEmpty) {
      throw ArgumentError('Encryption salt cannot be empty');
    }
  }

  static bool _isHexString(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
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
    return LockboxFile(
      id: json['id'] as String,
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      mimeType: json['mimeType'] as String,
      blossomHash: json['blossomHash'] as String,
      blossomUrl: json['blossomUrl'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      encryptionSalt: json['encryptionSalt'] as String,
    );
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
    return 'LockboxFile{id: $id, name: $name, size: $sizeBytes bytes}';
  }
}

