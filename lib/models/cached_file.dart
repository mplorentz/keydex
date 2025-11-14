import 'dart:io';

/// Tracks locally cached encrypted files for key holders
class CachedFile {
  final String lockboxId;
  final String fileHash;
  final String fileName;
  final int sizeBytes;
  final DateTime cachedAt;
  final String cachePath;

  CachedFile({
    required this.lockboxId,
    required this.fileHash,
    required this.fileName,
    required this.sizeBytes,
    required this.cachedAt,
    required this.cachePath,
  });

  /// Validate this cached file
  void validate() {
    if (lockboxId.isEmpty || !_isValidUuid(lockboxId)) {
      throw ArgumentError('Invalid UUID format for lockbox ID: $lockboxId');
    }
    if (fileHash.length != 64 || !_isHexString(fileHash)) {
      throw ArgumentError('File hash must be valid SHA-256 hex (64 characters)');
    }
    if (fileName.isEmpty) {
      throw ArgumentError('File name cannot be empty');
    }
    if (sizeBytes <= 0) {
      throw ArgumentError('File size must be greater than 0');
    }
    if (cachedAt.isAfter(DateTime.now())) {
      throw ArgumentError('Cached time cannot be in the future');
    }
    if (cachePath.isEmpty) {
      throw ArgumentError('Cache path cannot be empty');
    }
    // Note: We don't check if file exists here as it may have been evicted by OS
  }

  bool _isValidUuid(String str) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(str);
  }

  bool _isHexString(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
  }

  /// Check if the cached file still exists on disk
  Future<bool> existsOnDisk() async {
    try {
      final file = File(cachePath);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'lockboxId': lockboxId,
      'fileHash': fileHash,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'cachedAt': cachedAt.toIso8601String(),
      'cachePath': cachePath,
    };
  }

  /// Create from JSON
  factory CachedFile.fromJson(Map<String, dynamic> json) {
    final cachedFile = CachedFile(
      lockboxId: json['lockboxId'] as String,
      fileHash: json['fileHash'] as String,
      fileName: json['fileName'] as String,
      sizeBytes: json['sizeBytes'] as int,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      cachePath: json['cachePath'] as String,
    );
    cachedFile.validate();
    return cachedFile;
  }

  /// Create a copy with updated fields
  CachedFile copyWith({
    String? lockboxId,
    String? fileHash,
    String? fileName,
    int? sizeBytes,
    DateTime? cachedAt,
    String? cachePath,
  }) {
    return CachedFile(
      lockboxId: lockboxId ?? this.lockboxId,
      fileHash: fileHash ?? this.fileHash,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      cachedAt: cachedAt ?? this.cachedAt,
      cachePath: cachePath ?? this.cachePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedFile &&
          runtimeType == other.runtimeType &&
          lockboxId == other.lockboxId &&
          fileHash == other.fileHash;

  @override
  int get hashCode => Object.hash(lockboxId, fileHash);

  @override
  String toString() {
    return 'CachedFile{lockboxId: $lockboxId, fileName: $fileName, fileHash: ${fileHash.substring(0, 8)}...}';
  }
}

