import 'key_holder.dart';
import 'key_holder_status.dart';
import 'backup_status.dart';
import 'lockbox.dart';

/// Represents the backup configuration for a lockbox
///
/// This model contains all the settings and metadata needed to configure
/// distributed backup using Shamir's Secret Sharing and Nostr protocol.
typedef BackupConfig = ({
  String lockboxId,
  String specVersion,
  int threshold,
  int totalKeys,
  List<KeyHolder> keyHolders,
  List<String> relays,
  String? ownerName,
  DateTime createdAt,
  DateTime lastUpdated,
  DateTime? lastContentChange,
  DateTime? lastRedistribution,
  String? contentHash,
  BackupStatus status,
});

/// Create a new BackupConfig with validation
BackupConfig createBackupConfig({
  required String lockboxId,
  required int threshold,
  required int totalKeys,
  required List<KeyHolder> keyHolders,
  required List<String> relays,
  String? ownerName,
  String? contentHash,
}) {
  // Validate inputs
  if (threshold < LockboxBackupConstraints.minThreshold || threshold > totalKeys) {
    throw ArgumentError(
        'Threshold must be >= ${LockboxBackupConstraints.minThreshold} and <= totalKeys');
  }
  if (totalKeys < threshold || totalKeys > LockboxBackupConstraints.maxTotalKeys) {
    throw ArgumentError(
        'TotalKeys must be >= threshold and <= ${LockboxBackupConstraints.maxTotalKeys}');
  }
  if (keyHolders.length != totalKeys) {
    throw ArgumentError('KeyHolders length must equal totalKeys');
  }
  if (relays.isEmpty) {
    throw ArgumentError('At least one relay must be provided');
  }

  // Validate key holders have unique IDs
  final ids = keyHolders.map((h) => h.id).toSet();
  if (ids.length != keyHolders.length) {
    throw ArgumentError('All key holders must have unique IDs');
  }

  // Validate key holders with pubkeys have unique npubs
  final keyHoldersWithPubkeys = keyHolders.where((h) => h.pubkey != null).toList();
  final npubs = keyHoldersWithPubkeys.map((h) => h.npub).where((n) => n != null).toSet();
  if (npubs.length != keyHoldersWithPubkeys.length) {
    throw ArgumentError('All key holders with pubkeys must have unique npubs');
  }

  // Validate relay URLs
  for (final relay in relays) {
    if (!_isValidRelayUrl(relay)) {
      throw ArgumentError('Invalid relay URL: $relay');
    }
  }

  final now = DateTime.now();
  return (
    lockboxId: lockboxId,
    specVersion: '1.0.0', // Current specification version
    threshold: threshold,
    totalKeys: totalKeys,
    keyHolders: keyHolders,
    relays: relays,
    ownerName: ownerName,
    createdAt: now,
    lastUpdated: now,
    lastContentChange: null,
    lastRedistribution: null,
    contentHash: contentHash,
    status: BackupStatus.pending,
  );
}

/// Create a copy of this BackupConfig with updated fields
BackupConfig copyBackupConfig(
  BackupConfig config, {
  String? lockboxId,
  String? specVersion,
  int? threshold,
  int? totalKeys,
  List<KeyHolder>? keyHolders,
  List<String>? relays,
  String? ownerName,
  DateTime? createdAt,
  DateTime? lastUpdated,
  DateTime? lastContentChange,
  DateTime? lastRedistribution,
  String? contentHash,
  BackupStatus? status,
}) {
  return (
    lockboxId: lockboxId ?? config.lockboxId,
    specVersion: specVersion ?? config.specVersion,
    threshold: threshold ?? config.threshold,
    totalKeys: totalKeys ?? config.totalKeys,
    keyHolders: keyHolders ?? config.keyHolders,
    relays: relays ?? config.relays,
    ownerName: ownerName ?? config.ownerName,
    createdAt: createdAt ?? config.createdAt,
    lastUpdated: lastUpdated ?? config.lastUpdated,
    lastContentChange: lastContentChange ?? config.lastContentChange,
    lastRedistribution: lastRedistribution ?? config.lastRedistribution,
    contentHash: contentHash ?? config.contentHash,
    status: status ?? config.status,
  );
}

/// Extension methods for BackupConfig
extension BackupConfigExtension on BackupConfig {
  /// Check if this backup configuration is valid
  bool get isValid {
    try {
      if (threshold < LockboxBackupConstraints.minThreshold || threshold > totalKeys) return false;
      if (totalKeys < threshold || totalKeys > LockboxBackupConstraints.maxTotalKeys) return false;
      if (keyHolders.length != totalKeys) return false;
      if (relays.isEmpty) return false;

      // Check for unique IDs
      final ids = keyHolders.map((h) => h.id).toSet();
      if (ids.length != keyHolders.length) return false;

      // Check for unique npubs (only for key holders with pubkeys)
      final keyHoldersWithPubkeys = keyHolders.where((h) => h.pubkey != null).toList();
      final npubs = keyHoldersWithPubkeys.map((h) => h.npub).where((n) => n != null).toSet();
      if (npubs.length != keyHoldersWithPubkeys.length) return false;

      // Check relay URLs
      for (final relay in relays) {
        if (!_isValidRelayUrl(relay)) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if content has changed since last redistribution
  bool get hasContentChanged {
    if (lastContentChange == null || lastRedistribution == null) {
      return lastContentChange != null;
    }
    return lastContentChange!.isAfter(lastRedistribution!);
  }

  /// Get the number of active key holders
  int get activeKeyHoldersCount {
    return keyHolders.where((h) => h.isActive).length;
  }

  /// Get the number of acknowledged key holders
  int get acknowledgedKeyHoldersCount {
    return keyHolders.where((h) => h.status == KeyHolderStatus.holdingKey).length;
  }

  /// Check if backup is ready (all key holders acknowledged)
  bool get isReady {
    return status == BackupStatus.active && acknowledgedKeyHoldersCount >= threshold;
  }
}

/// Convert to JSON for storage
Map<String, dynamic> backupConfigToJson(BackupConfig config) {
  return {
    'lockboxId': config.lockboxId,
    'specVersion': config.specVersion,
    'threshold': config.threshold,
    'totalKeys': config.totalKeys,
    'keyHolders': config.keyHolders.map((h) => keyHolderToJson(h)).toList(),
    'relays': config.relays,
    if (config.ownerName != null) 'ownerName': config.ownerName,
    'createdAt': config.createdAt.toIso8601String(),
    'lastUpdated': config.lastUpdated.toIso8601String(),
    'lastContentChange': config.lastContentChange?.toIso8601String(),
    'lastRedistribution': config.lastRedistribution?.toIso8601String(),
    'contentHash': config.contentHash,
    'status': config.status.name,
  };
}

/// Create from JSON
BackupConfig backupConfigFromJson(Map<String, dynamic> json) {
  return (
    lockboxId: json['lockboxId'] as String,
    specVersion: json['specVersion'] as String,
    threshold: json['threshold'] as int,
    totalKeys: json['totalKeys'] as int,
    keyHolders: (json['keyHolders'] as List)
        .map((h) => keyHolderFromJson(h as Map<String, dynamic>))
        .toList(),
    relays: (json['relays'] as List).cast<String>(),
    ownerName: json['ownerName'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    lastContentChange: json['lastContentChange'] != null
        ? DateTime.parse(json['lastContentChange'] as String)
        : null,
    lastRedistribution: json['lastRedistribution'] != null
        ? DateTime.parse(json['lastRedistribution'] as String)
        : null,
    contentHash: json['contentHash'] as String?,
    status: BackupStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => BackupStatus.pending,
    ),
  );
}

/// String representation of BackupConfig
String backupConfigToString(BackupConfig config) {
  return 'BackupConfig(lockboxId: ${config.lockboxId}, threshold: ${config.threshold}/${config.totalKeys}, '
      'status: ${config.status}, keyHolders: ${config.keyHolders.length})';
}

/// Validate relay URL format
bool _isValidRelayUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.scheme == 'wss' || uri.scheme == 'ws';
  } catch (e) {
    return false;
  }
}
