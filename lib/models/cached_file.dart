/// Tracks locally cached encrypted files for key holders
class CachedFile {
  final String lockboxId; // UUID
  final String fileHash; // SHA-256 hash
  final String fileName; // Original filename for display
  final int sizeBytes; // File size
  final DateTime cachedAt; // When file was downloaded and cached
  final String cachePath; // Local file path

  CachedFile({
    required this.lockboxId,
    required this.fileHash,
    required this.fileName,
    required this.sizeBytes,
    required this.cachedAt,
    required this.cachePath,
  }) {
    _validate();
  }

  void _validate() {
    if (lockboxId.isEmpty) {
      throw ArgumentError('Lockbox ID cannot be empty');
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
      throw ArgumentError('Cache date cannot be in the future');
    }
    if (cachePath.isEmpty) {
      throw ArgumentError('Cache path cannot be empty');
    }
  }

  static bool _isHexString(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
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
    return CachedFile(
      lockboxId: json['lockboxId'] as String,
      fileHash: json['fileHash'] as String,
      fileName: json['fileName'] as String,
      sizeBytes: json['sizeBytes'] as int,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      cachePath: json['cachePath'] as String,
    );
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
    return 'CachedFile{lockboxId: $lockboxId, fileName: $fileName, hash: ${fileHash.substring(0, 8)}...}';
  }
}

/// Extension methods for lists of cached files
extension CachedFileOps on List<CachedFile> {
  /// Get total size of all cached files
  int get totalCacheSize => fold(0, (sum, file) => sum + file.sizeBytes);

  /// Check if a file with given hash exists
  bool hasFile(String fileHash) => any((file) => file.fileHash == fileHash);

  /// Get file by hash
  CachedFile? getByHash(String fileHash) {
    try {
      return firstWhere((file) => file.fileHash == fileHash);
    } catch (_) {
      return null;
    }
  }
}

