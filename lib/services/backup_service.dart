import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntcdcrypto/ntcdcrypto.dart';
import 'package:ndk/ndk.dart';
import '../models/backup_config.dart';
import '../models/key_holder.dart';
import '../models/shard_data.dart';
import '../models/backup_status.dart';
import '../models/key_holder_status.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import 'key_service.dart';
import 'shard_distribution_service.dart';
import '../services/logger.dart';

/// Provider for BackupService
/// Note: Uses ref.read() for shardDistributionServiceProvider to break circular dependency
final Provider<BackupService> backupServiceProvider = Provider<BackupService>((ref) {
  // Use ref.read() to break circular dependency with ShardDistributionService
  final ShardDistributionService shardService = ref.read(shardDistributionServiceProvider);
  return BackupService(
    ref.read(lockboxRepositoryProvider),
    shardService,
  );
});

/// Service for managing distributed backup using Shamir's Secret Sharing
class BackupService {
  final LockboxRepository _repository;
  final ShardDistributionService _shardDistributionService;

  BackupService(this._repository, this._shardDistributionService);

  /// Create a new backup configuration
  Future<BackupConfig> createBackupConfiguration({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
    String? contentHash,
  }) async {
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

    // Create backup configuration
    final config = createBackupConfig(
      lockboxId: lockboxId,
      threshold: threshold,
      totalKeys: totalKeys,
      keyHolders: keyHolders,
      relays: relays,
      contentHash: contentHash,
    );

    // Store the configuration in the lockbox via repository
    await _repository.updateBackupConfig(lockboxId, config);

    Log.info('Created backup configuration for lockbox $lockboxId');
    return config;
  }

  /// Get backup configuration for a lockbox
  Future<BackupConfig?> getBackupConfig(String lockboxId) async {
    return await _repository.getBackupConfig(lockboxId);
  }

  /// Get all backup configurations
  Future<List<BackupConfig>> getAllBackupConfigs() async {
    final lockboxes = await _repository.getAllLockboxes();
    return lockboxes
        .where((lockbox) => lockbox.backupConfig != null)
        .map((lockbox) => lockbox.backupConfig!)
        .toList();
  }

  /// Update backup configuration
  Future<void> updateBackupConfig(BackupConfig config) async {
    await _repository.updateBackupConfig(config.lockboxId, config);
    Log.info('Updated backup configuration for lockbox ${config.lockboxId}');
  }

  /// Delete backup configuration
  Future<void> deleteBackupConfig(String lockboxId) async {
    // Set backup config to null in the lockbox
    final lockbox = await _repository.getLockbox(lockboxId);
    if (lockbox != null) {
      await _repository.saveLockbox(lockbox.copyWith(backupConfig: null));
    }
    Log.info('Deleted backup configuration for lockbox $lockboxId');
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
    try {
      // Validate inputs
      if (threshold < LockboxBackupConstraints.minThreshold) {
        throw ArgumentError('Threshold must be at least ${LockboxBackupConstraints.minThreshold}');
      }
      if (threshold > totalShards) {
        throw ArgumentError('Threshold cannot exceed total shards');
      }
      if (content.isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }

      // Create SSS instance
      final sss = SSS();

      // Generate shares using Base64Url encoding (isBase64 = true)
      // The ntcdcrypto library returns shares as Base64Url-encoded strings
      final shareStrings = sss.create(threshold, totalShards, content, true);
      Log.debug('Share Strings: $shareStrings');

      // The prime modulus is fixed in ntcdcrypto, convert to base64url for storage
      // This matches the format expected by skb.py
      final primeModHex = sss.prime.toRadixString(16);
      final primeMod = base64Url.encode(utf8.encode(primeModHex));

      // Convert to ShardData objects
      final shardDataList = <ShardData>[];
      for (int i = 0; i < totalShards; i++) {
        final shardData = createShardData(
          shard: shareStrings[i],
          threshold: threshold,
          shardIndex: i,
          totalShards: totalShards,
          primeMod: primeMod,
          creatorPubkey: creatorPubkey,
          lockboxId: lockboxId,
          lockboxName: lockboxName,
          peers: peers,
        );
        Log.debug(shardData.toString());
        shardDataList.add(shardData);
      }

      Log.info('Generated $totalShards Shamir shares with threshold $threshold');
      return shardDataList;
    } catch (e) {
      Log.error('Error generating Shamir shares', e);
      throw Exception('Failed to generate Shamir shares: $e');
    }
  }

  /// Reconstruct content from Shamir shares
  Future<String> reconstructFromShares({required List<ShardData> shares}) async {
    try {
      if (shares.isEmpty) {
        throw ArgumentError('At least one share is required');
      }

      // Validate that all shares have the same threshold and totalShards
      final threshold = shares.first.threshold;
      final totalShards = shares.first.totalShards;
      final primeMod = shares.first.primeMod;
      final creatorPubkey = shares.first.creatorPubkey;

      for (final share in shares) {
        if (share.threshold != threshold ||
            share.totalShards != totalShards ||
            share.primeMod != primeMod ||
            share.creatorPubkey != creatorPubkey) {
          throw ArgumentError('All shares must have the same parameters');
        }
      }

      if (shares.length < threshold) {
        throw ArgumentError('At least $threshold shares are required, got ${shares.length}');
      }

      // Create SSS instance
      final sss = SSS();

      // Verify that the prime modulus matches the one ntcdcrypto uses
      final expectedPrimeModHex = sss.prime.toRadixString(16);
      final expectedPrimeMod = base64Url.encode(utf8.encode(expectedPrimeModHex));

      if (primeMod != expectedPrimeMod) {
        throw ArgumentError(
          'Invalid prime modulus: shares were created with a different prime than ntcdcrypto uses',
        );
      }

      // Extract the share strings from ShardData objects
      final shareStrings = shares.map((s) => s.shard).toList();

      // Combine shares using Base64Url encoding (isBase64 = true)
      // This will reconstruct the original secret
      final content = sss.combine(shareStrings, true);

      Log.info('Successfully reconstructed content from ${shares.length} shares');
      return content;
    } on ArgumentError catch (e) {
      Log.error('Error reconstructing from shares', e);
      rethrow;
    } catch (e) {
      Log.error('Error reconstructing from shares', e);
      throw Exception('Failed to reconstruct content from shares: $e');
    }
  }

  /// Update backup status
  Future<void> updateBackupStatus(String lockboxId, BackupStatus status) async {
    final config = await _repository.getBackupConfig(lockboxId);
    if (config == null) {
      throw ArgumentError('Backup configuration not found for lockbox $lockboxId');
    }

    final updatedConfig = copyBackupConfig(config, status: status, lastUpdated: DateTime.now());
    await _repository.updateBackupConfig(lockboxId, updatedConfig);

    Log.info('Updated backup status for lockbox $lockboxId to $status');
  }

  /// Update key holder status
  Future<void> updateKeyHolderStatus({
    required String lockboxId,
    required String pubkey, // Hex format
    required KeyHolderStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
  }) async {
    final config = await _repository.getBackupConfig(lockboxId);
    if (config == null) {
      throw ArgumentError('Backup configuration not found for lockbox $lockboxId');
    }

    // Find and update the key holder
    final updatedKeyHolders = config.keyHolders.map((holder) {
      if (holder.pubkey == pubkey) {
        return copyKeyHolder(
          holder,
          status: status,
          acknowledgedAt: acknowledgedAt,
          acknowledgmentEventId: acknowledgmentEventId,
        );
      }
      return holder;
    }).toList();

    final updatedConfig = copyBackupConfig(
      config,
      keyHolders: updatedKeyHolders,
      lastUpdated: DateTime.now(),
    );

    await _repository.updateBackupConfig(lockboxId, updatedConfig);

    Log.info('Updated key holder $pubkey status to $status');
  }

  /// Check if backup is ready (all required key holders have acknowledged)
  Future<bool> isBackupReady(String lockboxId) async {
    final config = await _repository.getBackupConfig(lockboxId);
    if (config == null) return false;

    return config.acknowledgedKeyHoldersCount >= config.threshold;
  }

  /// High-level method to create and distribute a backup
  ///
  /// This orchestrates the entire backup creation flow:
  /// 1. Loads lockbox content
  /// 2. Deletes existing backup configuration if one exists
  /// 3. Creates new backup configuration
  /// 4. Generates Shamir shares
  /// 5. Distributes shares to key holders via Nostr
  ///
  /// Throws exception if any step fails
  Future<BackupConfig> createAndDistributeBackup({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
  }) async {
    try {
      // Step 1: Load lockbox content
      final lockbox = await _repository.getLockbox(lockboxId);
      if (lockbox == null) {
        throw Exception('Lockbox not found: $lockboxId');
      }
      final content = lockbox.content;
      if (content == null) {
        throw Exception('Cannot backup encrypted lockbox - content is not available');
      }
      Log.info('Loaded lockbox content for backup: $lockboxId');

      // Step 2: Get creator's Nostr key pair
      final creatorKeyPair = await KeyService.getStoredNostrKey();
      final creatorPubkey = creatorKeyPair?.publicKey;
      final creatorPrivkey = creatorKeyPair?.privateKey;
      if (creatorPubkey == null || creatorPrivkey == null) {
        throw Exception('No Nostr key available for backup creation');
      }
      Log.info('Retrieved creator key pair');

      // Step 3: Delete existing config if present (allows overwrite)
      final existingConfig = await _repository.getBackupConfig(lockboxId);
      if (existingConfig != null) {
        await deleteBackupConfig(lockboxId);
        Log.info('Deleted existing backup configuration for overwrite');
      }

      // Step 4: Create backup configuration
      final config = await createBackupConfiguration(
        lockboxId: lockboxId,
        threshold: threshold,
        totalKeys: totalKeys,
        keyHolders: keyHolders,
        relays: relays,
      );
      Log.info('Created backup configuration');

      // Step 5: Generate Shamir shares
      // Note: peers list excludes the creator - recipients need to know OTHER key holders
      final peers =
          keyHolders.map((kh) => kh.pubkey).where((pubkey) => pubkey != creatorPubkey).toList();
      final shards = await generateShamirShares(
        content: content,
        threshold: threshold,
        totalShards: totalKeys,
        creatorPubkey: creatorPubkey,
        lockboxId: lockbox.id,
        lockboxName: lockbox.name,
        peers: peers,
      );
      Log.info('Generated ${shards.length} Shamir shares');

      // Step 6: Initialize NDK and distribute shards
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: creatorPubkey, privkey: creatorPrivkey);
      Log.info('Initialized NDK for shard distribution');

      // Distribute shards using injected service
      await _shardDistributionService.distributeShards(
        ownerPubkey: creatorPubkey,
        config: config,
        shards: shards,
        ndk: ndk,
      );
      Log.info('Successfully distributed all shards');

      return config;
    } catch (e) {
      Log.error('Failed to create and distribute backup', e);
      rethrow;
    }
  }
}
