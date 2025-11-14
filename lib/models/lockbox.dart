import 'shard_data.dart';
import 'recovery_request.dart';
import 'backup_config.dart';
import 'lockbox_file.dart';

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

/// Lockbox state enum indicating the current state of a lockbox
enum LockboxState {
  recovery, // Active recovery in progress
  owned, // Has decrypted content
  keyHolder, // Has shard but no content
  awaitingKey, // Invitee has accepted invitation but hasn't received shard yet
}

/// Data model for a secure lockbox containing encrypted files
class Lockbox {
  final String id;
  final String name;
  final String? content; // Deprecated - kept for backward compatibility
  final List<LockboxFile> files; // NEW: Replaces content field
  final DateTime createdAt;
  final String ownerPubkey; // Hex format, 64 characters
  final String? ownerName; // Name of the vault owner
  final List<ShardData> shards; // List of shards (single as key holder, multiple during recovery)
  final List<RecoveryRequest> recoveryRequests; // Embedded recovery requests
  final BackupConfig? backupConfig; // Optional backup configuration

  Lockbox({
    required this.id,
    required this.name,
    this.content, // Deprecated
    this.files = const [],
    required this.createdAt,
    required this.ownerPubkey,
    this.ownerName,
    this.shards = const [],
    this.recoveryRequests = const [],
    this.backupConfig,
  }) {
    _validate();
  }

  void _validate() {
    // Validate file size limit (1GB total)
    if (totalSizeBytes > 1073741824) {
      throw ArgumentError('Total file size cannot exceed 1GB');
    }
    // Validate unique file IDs
    final fileIds = files.map((f) => f.id).toSet();
    if (fileIds.length != files.length) {
      throw ArgumentError('All files must have unique IDs within the lockbox');
    }
  }

  /// Computed property: total size of all files in bytes
  int get totalSizeBytes => files.fold(0, (sum, file) => sum + file.sizeBytes);

  /// Check if within size limit
  bool get isWithinSizeLimit => totalSizeBytes <= 1073741824; // 1GB

  /// Get remaining bytes before hitting limit
  int get remainingBytes => 1073741824 - totalSizeBytes;

  /// Check if a file can be added without exceeding limit
  bool canAddFile(int fileSizeBytes) => totalSizeBytes + fileSizeBytes <= 1073741824;

  /// Get the state of this lockbox based on priority:
  /// 1. Recovery (if has active recovery request)
  /// 2. Owned (if has decrypted content)
  /// 3. Key holder (if has shards but no content)
  /// 4. Awaiting key (if no content and no shards - invitee waiting for shard)
  LockboxState get state {
    if (hasActiveRecovery) {
      return LockboxState.recovery;
    }
    if (content != null) {
      return LockboxState.owned;
    }
    if (shards.isNotEmpty) {
      return LockboxState.keyHolder;
    }
    // No content and no shards - invitee is awaiting key distribution
    return LockboxState.awaitingKey;
  }

  /// Check if the given hex key is the owner of this lockbox
  bool isOwned(String hexKey) => ownerPubkey == hexKey;

  /// Check if we are a key holder for this lockbox (have shards)
  bool get isKeyHolder => shards.isNotEmpty;

  /// Check if this lockbox has an active recovery request
  bool get hasActiveRecovery {
    return recoveryRequests.any((request) => request.status.isActive);
  }

  /// Get the active recovery request if one exists
  RecoveryRequest? get activeRecoveryRequest {
    try {
      return recoveryRequests.firstWhere((request) => request.status.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (content != null) 'content': content, // Deprecated but kept for compatibility
      'files': files.map((file) => file.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'ownerPubkey': ownerPubkey,
      if (ownerName != null) 'ownerName': ownerName,
      'shards': shards.map((shard) => shardDataToJson(shard)).toList(),
      'recoveryRequests': recoveryRequests.map((request) => request.toJson()).toList(),
      'backupConfig': backupConfig != null ? backupConfigToJson(backupConfig!) : null,
    };
  }

  /// Create from JSON
  factory Lockbox.fromJson(Map<String, dynamic> json) {
    return Lockbox(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String?, // Deprecated
      files: json['files'] != null
          ? (json['files'] as List)
              .map((fileJson) => LockboxFile.fromJson(fileJson as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      ownerPubkey: json['ownerPubkey'] as String,
      ownerName: json['ownerName'] as String?,
      shards: json['shards'] != null
          ? (json['shards'] as List)
              .map((shardJson) => shardDataFromJson(shardJson as Map<String, dynamic>))
              .toList()
          : [],
      recoveryRequests: json['recoveryRequests'] != null
          ? (json['recoveryRequests'] as List)
              .map((reqJson) => RecoveryRequest.fromJson(reqJson as Map<String, dynamic>))
              .toList()
          : [],
      backupConfig: json['backupConfig'] != null
          ? backupConfigFromJson(json['backupConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Create a copy with updated fields
  Lockbox copyWith({
    String? id,
    String? name,
    String? content,
    List<LockboxFile>? files,
    DateTime? createdAt,
    String? ownerPubkey,
    String? ownerName,
    List<ShardData>? shards,
    List<RecoveryRequest>? recoveryRequests,
    BackupConfig? backupConfig,
  }) {
    return Lockbox(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
      ownerPubkey: ownerPubkey ?? this.ownerPubkey,
      ownerName: ownerName ?? this.ownerName,
      shards: shards ?? this.shards,
      recoveryRequests: recoveryRequests ?? this.recoveryRequests,
      backupConfig: backupConfig ?? this.backupConfig,
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
    return 'Lockbox{id: $id, name: $name, state: ${state.name}, createdAt: $createdAt}';
  }
}
