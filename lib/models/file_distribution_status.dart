/// Distribution state enum for tracking file distribution to key holders
enum DistributionState {
  pending, // Key holder hasn't downloaded yet (within 48hr window)
  downloaded, // Key holder successfully downloaded and cached
  missedWindow, // 48 hours elapsed without download
}

/// Extension for DistributionState
extension DistributionStateExtension on DistributionState {
  String get displayName {
    switch (this) {
      case DistributionState.pending:
        return 'Pending';
      case DistributionState.downloaded:
        return 'Downloaded';
      case DistributionState.missedWindow:
        return 'Missed Window';
    }
  }

  bool get isActive => this == DistributionState.pending;
  bool get isComplete => this == DistributionState.downloaded;
  bool get isFailed => this == DistributionState.missedWindow;
}

/// Tracks whether key holders have downloaded files during distribution window
class FileDistributionStatus {
  final String lockboxId; // UUID
  final String keyHolderPubkey; // Hex format (64 chars)
  final DistributionState state; // pending, downloaded, missed_window
  final DateTime? downloadedAt; // When key holder confirmed download
  final DateTime uploadedAt; // When owner uploaded to Blossom

  FileDistributionStatus({
    required this.lockboxId,
    required this.keyHolderPubkey,
    required this.state,
    this.downloadedAt,
    required this.uploadedAt,
  }) {
    _validate();
  }

  void _validate() {
    if (lockboxId.isEmpty) {
      throw ArgumentError('Lockbox ID cannot be empty');
    }
    if (keyHolderPubkey.length != 64 || !_isHexString(keyHolderPubkey)) {
      throw ArgumentError('Key holder pubkey must be valid hex (64 characters)');
    }
    if (state == DistributionState.downloaded && downloadedAt == null) {
      throw ArgumentError('downloadedAt is required when state is downloaded');
    }
    if (uploadedAt.isAfter(DateTime.now())) {
      throw ArgumentError('Upload date cannot be in the future');
    }
  }

  static bool _isHexString(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'lockboxId': lockboxId,
      'keyHolderPubkey': keyHolderPubkey,
      'state': state.name,
      if (downloadedAt != null) 'downloadedAt': downloadedAt!.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FileDistributionStatus.fromJson(Map<String, dynamic> json) {
    return FileDistributionStatus(
      lockboxId: json['lockboxId'] as String,
      keyHolderPubkey: json['keyHolderPubkey'] as String,
      state: DistributionState.values.firstWhere((e) => e.name == json['state']),
      downloadedAt:
          json['downloadedAt'] != null ? DateTime.parse(json['downloadedAt'] as String) : null,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  FileDistributionStatus copyWith({
    String? lockboxId,
    String? keyHolderPubkey,
    DistributionState? state,
    DateTime? downloadedAt,
    DateTime? uploadedAt,
  }) {
    return FileDistributionStatus(
      lockboxId: lockboxId ?? this.lockboxId,
      keyHolderPubkey: keyHolderPubkey ?? this.keyHolderPubkey,
      state: state ?? this.state,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileDistributionStatus &&
          runtimeType == other.runtimeType &&
          lockboxId == other.lockboxId &&
          keyHolderPubkey == other.keyHolderPubkey;

  @override
  int get hashCode => Object.hash(lockboxId, keyHolderPubkey);

  @override
  String toString() {
    return 'FileDistributionStatus{lockbox: $lockboxId, keyHolder: ${keyHolderPubkey.substring(0, 8)}..., state: ${state.name}}';
  }
}

/// Extension methods for lists of FileDistributionStatus
extension FileDistributionTracking on List<FileDistributionStatus> {
  /// Check if all key holders have downloaded
  bool allDownloaded() => every((status) => status.state == DistributionState.downloaded);

  /// Check if any key holder missed the window
  bool anyMissedWindow() => any((status) => status.state == DistributionState.missedWindow);

  /// Get count of downloaded statuses
  int get downloadedCount => where((s) => s.state == DistributionState.downloaded).length;

  /// Get download percentage
  double get downloadPercentage => isEmpty ? 0.0 : downloadedCount / length;

  /// Check if ready to delete from Blossom
  bool canDeleteFromBlossom(DateTime uploadedAt) {
    final windowExpired = DateTime.now().difference(uploadedAt) > const Duration(hours: 48);
    return allDownloaded() || windowExpired;
  }
}

