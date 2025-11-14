
/// Tracks whether key holders have downloaded files during distribution window
enum DistributionState {
  pending, // Key holder hasn't downloaded yet (within 48hr window)
  downloaded, // Key holder successfully downloaded and cached
  missedWindow, // 48 hours elapsed without download
}

/// Represents the distribution status for a key holder
class FileDistributionStatus {
  final String lockboxId;
  final String keyHolderPubkey;
  final DistributionState state;
  final DateTime? downloadedAt;
  final DateTime uploadedAt;

  FileDistributionStatus({
    required this.lockboxId,
    required this.keyHolderPubkey,
    required this.state,
    this.downloadedAt,
    required this.uploadedAt,
  });

  /// Create a new FileDistributionStatus in pending state
  factory FileDistributionStatus.createPending({
    required String lockboxId,
    required String keyHolderPubkey,
  }) {
    return FileDistributionStatus(
      lockboxId: lockboxId,
      keyHolderPubkey: keyHolderPubkey,
      state: DistributionState.pending,
      uploadedAt: DateTime.now(),
    );
  }

  /// Validate this distribution status
  void validate() {
    if (lockboxId.isEmpty || !_isValidUuid(lockboxId)) {
      throw ArgumentError('Invalid UUID format for lockbox ID: $lockboxId');
    }
    if (keyHolderPubkey.length != 64 || !_isHexString(keyHolderPubkey)) {
      throw ArgumentError('Key holder pubkey must be valid hex format (64 characters)');
    }
    if (state == DistributionState.downloaded && downloadedAt == null) {
      throw ArgumentError('DownloadedAt is required when state is downloaded');
    }
    if (uploadedAt.isAfter(DateTime.now())) {
      throw ArgumentError('Upload time cannot be in the future');
    }
    if (downloadedAt != null && downloadedAt!.isBefore(uploadedAt)) {
      throw ArgumentError('Download time cannot be before upload time');
    }
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

  /// Check if the distribution window has expired (48 hours)
  bool get isWindowExpired {
    final now = DateTime.now();
    final difference = now.difference(uploadedAt);
    return difference.inHours >= 48;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'lockboxId': lockboxId,
      'keyHolderPubkey': keyHolderPubkey,
      'state': state.name,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FileDistributionStatus.fromJson(Map<String, dynamic> json) {
    final status = FileDistributionStatus(
      lockboxId: json['lockboxId'] as String,
      keyHolderPubkey: json['keyHolderPubkey'] as String,
      state: DistributionState.values.firstWhere(
        (e) => e.name == json['state'] as String,
        orElse: () => DistributionState.pending,
      ),
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
    status.validate();
    return status;
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
    return 'FileDistributionStatus{lockboxId: $lockboxId, keyHolderPubkey: ${keyHolderPubkey.substring(0, 8)}..., state: ${state.name}}';
  }
}

