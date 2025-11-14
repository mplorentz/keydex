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
  final List<LockboxFile> files; // Files stored in this lockbox (replaces content)
  final DateTime createdAt;
  final String ownerPubkey; // Hex format, 64 characters
  final String? ownerName; // Name of the vault owner
  final List<ShardData> shards; // List of shards (single as key holder, multiple during recovery)
  final List<RecoveryRequest> recoveryRequests; // Embedded recovery requests
  final BackupConfig? backupConfig; // Optional backup configuration

  Lockbox({
    required this.id,
    required this.name,
    this.files = const [],
    required this.createdAt,
    required this.ownerPubkey,
    this.ownerName,
    this.shards = const [],
    this.recoveryRequests = const [],
    this.backupConfig,
  });

  /// Get the state of this lockbox based on priority:
  /// 1. Recovery (if has active recovery request)
  /// 2. Owned (if has files - owner has decrypted access)
  /// 3. Key holder (if has shards but no files locally)
  /// 4. Awaiting key (if no files and no shards - invitee waiting for shard)
  LockboxState get state {
    if (hasActiveRecovery) {
      return LockboxState.recovery;
    }
    if (files.isNotEmpty) {
      return LockboxState.owned;
    }
    if (shards.isNotEmpty) {
      return LockboxState.keyHolder;
    }
    // No files and no shards - invitee is awaiting key distribution
    return LockboxState.awaitingKey;
  }

  /// Get total size of all files in bytes
  int get totalSizeBytes => files.fold(0, (sum, file) => sum + file.sizeBytes);

  /// Check if lockbox is within size limit (1GB)
  bool get isWithinSizeLimit => totalSizeBytes <= 1073741824;

  /// Get remaining bytes before hitting size limit
  int get remainingBytes => 1073741824 - totalSizeBytes;

  /// Check if a file of given size can be added
  bool canAddFile(int fileSizeBytes) => totalSizeBytes + fileSizeBytes <= 1073741824;

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
