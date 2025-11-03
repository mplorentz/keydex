import 'shard_data.dart';
import 'recovery_request.dart';
import 'backup_config.dart';

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

/// Data model for a secure lockbox containing encrypted text content
class Lockbox {
  final String id;
  final String name;
  final String? content; // Nullable - null when content is not decrypted
  final DateTime createdAt;
  final String ownerPubkey; // Hex format, 64 characters
  final List<ShardData> shards; // List of shards (single as key holder, multiple during recovery)
  final List<RecoveryRequest> recoveryRequests; // Embedded recovery requests
  final BackupConfig? backupConfig; // Optional backup configuration

  Lockbox({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.ownerPubkey,
    this.shards = const [],
    this.recoveryRequests = const [],
    this.backupConfig,
  });

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
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'ownerPubkey': ownerPubkey,
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
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ownerPubkey: json['ownerPubkey'] as String,
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
    DateTime? createdAt,
    String? ownerPubkey,
    List<ShardData>? shards,
    List<RecoveryRequest>? recoveryRequests,
    BackupConfig? backupConfig,
  }) {
    return Lockbox(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      ownerPubkey: ownerPubkey ?? this.ownerPubkey,
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
