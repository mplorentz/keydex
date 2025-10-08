import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/backup_config.dart';
import '../models/key_holder.dart';
import '../models/shard_data.dart';
import '../models/backup_status.dart';
import '../models/key_holder_status.dart';
import '../services/backup_service.dart';

/// FutureProvider family for getting backup config by lockbox ID
final backupConfigProvider = FutureProvider.family<BackupConfig?, String>((ref, lockboxId) async {
  return await BackupService.getBackupConfig(lockboxId);
});

/// FutureProvider for all backup configurations
final allBackupConfigsProvider = FutureProvider<List<BackupConfig>>((ref) async {
  return await BackupService.getAllBackupConfigs();
});

/// FutureProvider family for checking if backup is ready
final isBackupReadyProvider = FutureProvider.family<bool, String>((ref, lockboxId) async {
  return await BackupService.isBackupReady(lockboxId);
});

/// Provider for backup repository operations
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(ref);
});

/// Repository class to handle backup operations
class BackupRepository {
  final Ref _ref;

  BackupRepository(this._ref);

  /// Create a new backup configuration
  Future<BackupConfig> createBackupConfiguration({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
    String? contentHash,
  }) async {
    final config = await BackupService.createBackupConfiguration(
      lockboxId: lockboxId,
      threshold: threshold,
      totalKeys: totalKeys,
      keyHolders: keyHolders,
      relays: relays,
      contentHash: contentHash,
    );
    _refreshProviders(lockboxId);
    return config;
  }

  /// Update backup configuration
  Future<void> updateBackupConfig(BackupConfig config) async {
    await BackupService.updateBackupConfig(config);
    _refreshProviders(config.lockboxId);
  }

  /// Delete backup configuration
  Future<void> deleteBackupConfig(String lockboxId) async {
    await BackupService.deleteBackupConfig(lockboxId);
    _refreshProviders(lockboxId);
  }

  /// Create and distribute backup with shard distribution
  Future<BackupConfig> createAndDistributeBackup({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
  }) async {
    final config = await BackupService.createAndDistributeBackup(
      lockboxId: lockboxId,
      threshold: threshold,
      totalKeys: totalKeys,
      keyHolders: keyHolders,
      relays: relays,
    );
    _refreshProviders(lockboxId);
    return config;
  }

  /// Update backup status
  Future<void> updateBackupStatus(String lockboxId, BackupStatus status) async {
    await BackupService.updateBackupStatus(lockboxId, status);
    _refreshProviders(lockboxId);
  }

  /// Update key holder status
  Future<void> updateKeyHolderStatus({
    required String lockboxId,
    required String pubkey,
    required KeyHolderStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
  }) async {
    await BackupService.updateKeyHolderStatus(
      lockboxId: lockboxId,
      pubkey: pubkey,
      status: status,
      acknowledgedAt: acknowledgedAt,
      acknowledgmentEventId: acknowledgmentEventId,
    );
    _refreshProviders(lockboxId);
  }

  /// Generate Shamir shares for lockbox content
  Future<List<ShardData>> generateShamirShares({
    required String content,
    required int threshold,
    required int totalShards,
    required String creatorPubkey,
    required String lockboxId,
    required String lockboxName,
    required List<String> peers,
  }) async {
    return await BackupService.generateShamirShares(
      content: content,
      threshold: threshold,
      totalShards: totalShards,
      creatorPubkey: creatorPubkey,
      lockboxId: lockboxId,
      lockboxName: lockboxName,
      peers: peers,
    );
  }

  /// Reconstruct content from Shamir shares
  Future<String> reconstructFromShares({required List<ShardData> shares}) async {
    return await BackupService.reconstructFromShares(shares: shares);
  }

  /// Clear all backup data (for testing/debugging)
  Future<void> clearAll() async {
    await BackupService.clearAll();
    _ref.invalidate(allBackupConfigsProvider);
  }

  /// Refresh all providers after an operation
  void _refreshProviders(String lockboxId) {
    _ref.invalidate(backupConfigProvider(lockboxId));
    _ref.invalidate(allBackupConfigsProvider);
    _ref.invalidate(isBackupReadyProvider(lockboxId));
  }
}
