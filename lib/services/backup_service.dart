import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntcdcrypto/ntcdcrypto.dart';
import '../models/backup_config.dart';
import '../models/key_holder.dart';
import '../models/shard_data.dart';
import '../models/backup_status.dart';
import '../models/key_holder_status.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'shard_distribution_service.dart';
import 'relay_scan_service.dart';
import '../services/logger.dart';

/// Provider for BackupService
final Provider<BackupService> backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.read(lockboxRepositoryProvider),
    ref.read(shardDistributionServiceProvider),
    ref.read(loginServiceProvider),
    ref.read(relayScanServiceProvider),
  );
});

/// Service for managing distributed backup using Shamir's Secret Sharing
class BackupService {
  final LockboxRepository _repository;
  final ShardDistributionService _shardDistributionService;
  final LoginService _loginService;
  final RelayScanService _relayScanService;

  BackupService(
    this._repository,
    this._shardDistributionService,
    this._loginService,
    this._relayScanService,
  );

  /// Create a new backup configuration
  Future<BackupConfig> createBackupConfiguration({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
    String? instructions,
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
      instructions: instructions,
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
    required List<Map<String, String>> peers,
    String? ownerName,
    String? instructions,
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
          ownerName: ownerName,
          instructions: instructions,
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
      if (holder.pubkey != null && holder.pubkey == pubkey) {
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

  /// Merge backup configuration changes with existing config
  ///
  /// This method intelligently merges new configuration data with existing data:
  /// - Key holders: Adds new ones, updates existing ones, preserves status/acknowledgments
  /// - Threshold/relays/instructions: Updates if provided
  /// - Increments distributionVersion if config params changed
  /// - Preserves lastRedistribution timestamp
  Future<BackupConfig> mergeBackupConfig({
    required String lockboxId,
    int? threshold,
    List<KeyHolder>? keyHolders,
    List<String>? relays,
    String? instructions,
  }) async {
    // Load existing config
    final existingConfig = await _repository.getBackupConfig(lockboxId);

    if (existingConfig == null) {
      throw ArgumentError('No existing backup configuration found for lockbox $lockboxId');
    }

    // Track if config parameters changed (requires redistribution)
    bool configParamsChanged = false;

    // Merge threshold
    final newThreshold = threshold ?? existingConfig.threshold;
    if (newThreshold != existingConfig.threshold) {
      configParamsChanged = true;
    }

    // Merge relays
    final newRelays = relays ?? existingConfig.relays;
    if (relays != null && !_areRelaysEqual(relays, existingConfig.relays)) {
      configParamsChanged = true;
    }

    // Merge instructions
    final newInstructions = instructions ?? existingConfig.instructions;
    if (instructions != null && instructions != existingConfig.instructions) {
      configParamsChanged = true;
    }

    // Merge key holders (more complex)
    List<KeyHolder> mergedKeyHolders;
    if (keyHolders != null) {
      mergedKeyHolders = _mergeKeyHolders(existingConfig.keyHolders, keyHolders);
      // If key holder list changed, it requires redistribution
      if (mergedKeyHolders.length != existingConfig.keyHolders.length) {
        configParamsChanged = true;
      }
    } else {
      mergedKeyHolders = existingConfig.keyHolders;
    }

    // Calculate new total keys based on merged key holders
    final newTotalKeys = mergedKeyHolders.length;

    // Increment distribution version if config changed
    final newDistributionVersion = configParamsChanged
        ? existingConfig.distributionVersion + 1
        : existingConfig.distributionVersion;

    // If distribution version incremented, reset all key holders with pubkeys to awaitingNewKey
    // (preserve invited key holders without pubkeys)
    final finalKeyHolders = newDistributionVersion > existingConfig.distributionVersion
        ? mergedKeyHolders.map((holder) {
            // Reset to awaitingNewKey if they have a pubkey and were holding a key
            // Keep as awaitingKey if they were already awaiting (never received a key)
            if (holder.pubkey != null && holder.status != KeyHolderStatus.invited) {
              final newStatus = holder.status == KeyHolderStatus.holdingKey
                  ? KeyHolderStatus.awaitingNewKey
                  : KeyHolderStatus.awaitingKey;
              return copyKeyHolder(
                holder,
                status: newStatus,
                acknowledgedAt: null,
                acknowledgmentEventId: null,
                acknowledgedDistributionVersion: null,
                keyShare: null,
                giftWrapEventId: null,
              );
            }
            return holder;
          }).toList()
        : mergedKeyHolders;

    // Create merged config
    final mergedConfig = copyBackupConfig(
      existingConfig,
      threshold: newThreshold,
      totalKeys: newTotalKeys,
      keyHolders: finalKeyHolders,
      relays: newRelays,
      instructions: newInstructions,
      lastUpdated: DateTime.now(),
      distributionVersion: newDistributionVersion,
      // Preserve lastRedistribution - only updated when distribution succeeds
    );

    // Save merged config
    await _repository.updateBackupConfig(lockboxId, mergedConfig);

    // Sync relays to RelayScanService
    try {
      await _relayScanService.syncRelaysFromUrls(newRelays);
      await _relayScanService.ensureScanningStarted();
      Log.info('Synced ${newRelays.length} relay(s) to RelayScanService');
    } catch (e) {
      Log.error('Error syncing relays to RelayScanService', e);
    }

    Log.info(
        'Merged backup configuration for lockbox $lockboxId (version: $newDistributionVersion)');
    return mergedConfig;
  }

  /// Handle lockbox content change by incrementing distributionVersion
  ///
  /// When vault contents change, we need to increment the distribution version
  /// and reset all key holders with pubkeys to awaitingKey status.
  /// This ensures that new shards will be distributed on the next distribution.
  Future<void> handleContentChange(String lockboxId) async {
    final config = await _repository.getBackupConfig(lockboxId);
    if (config == null) {
      // No backup config exists, nothing to do
      return;
    }

    // Increment distribution version
    final newDistributionVersion = config.distributionVersion + 1;

    // Reset all key holders with pubkeys to awaitingNewKey (if they were holding) or awaitingKey
    final updatedKeyHolders = config.keyHolders.map((holder) {
      // Reset to awaitingNewKey if they have a pubkey and were holding a key
      // Keep as awaitingKey if they were already awaiting (never received a key)
      if (holder.pubkey != null && holder.status != KeyHolderStatus.invited) {
        final newStatus = holder.status == KeyHolderStatus.holdingKey
            ? KeyHolderStatus.awaitingNewKey
            : KeyHolderStatus.awaitingKey;
        return copyKeyHolder(
          holder,
          status: newStatus,
          acknowledgedAt: null,
          acknowledgmentEventId: null,
          acknowledgedDistributionVersion: null,
          keyShare: null,
          giftWrapEventId: null,
        );
      }
      return holder;
    }).toList();

    // Update config with new version and reset key holders
    final updatedConfig = copyBackupConfig(
      config,
      keyHolders: updatedKeyHolders,
      distributionVersion: newDistributionVersion,
      lastUpdated: DateTime.now(),
      lastContentChange: DateTime.now(),
    );

    await _repository.updateBackupConfig(lockboxId, updatedConfig);
    Log.info(
        'Incremented distributionVersion to $newDistributionVersion for lockbox $lockboxId due to content change');
  }

  /// Helper to merge key holder lists
  List<KeyHolder> _mergeKeyHolders(List<KeyHolder> existing, List<KeyHolder> updated) {
    final merged = <KeyHolder>[];

    // Add all updated key holders, preserving acknowledgments from existing
    for (final updatedHolder in updated) {
      // Find matching holder in existing list by id
      final existingHolder = existing.where((h) => h.id == updatedHolder.id).firstOrNull;

      if (existingHolder != null) {
        // Preserve important fields from existing (status, acknowledgments, etc)
        merged.add(copyKeyHolder(
          updatedHolder,
          status: existingHolder.status,
          acknowledgedAt: existingHolder.acknowledgedAt,
          acknowledgmentEventId: existingHolder.acknowledgmentEventId,
          acknowledgedDistributionVersion: existingHolder.acknowledgedDistributionVersion,
        ));
      } else {
        // New key holder
        merged.add(updatedHolder);
      }
    }

    return merged;
  }

  /// Helper to compare relay lists
  bool _areRelaysEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    final set1 = Set<String>.from(list1);
    final set2 = Set<String>.from(list2);
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  /// Create or update backup configuration without distributing shares
  ///
  /// This allows saving the backup configuration before all key holders
  /// have accepted their invitations. Shares can be distributed later
  /// using createAndDistributeBackup or a separate distribution method.
  Future<BackupConfig> saveBackupConfig({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
    String? instructions,
  }) async {
    // Delete existing config if present (allows overwrite)
    final existingConfig = await _repository.getBackupConfig(lockboxId);
    if (existingConfig != null) {
      await deleteBackupConfig(lockboxId);
      Log.info('Deleted existing backup configuration for overwrite');
    }

    // Create backup configuration
    final config = await createBackupConfiguration(
      lockboxId: lockboxId,
      threshold: threshold,
      totalKeys: totalKeys,
      keyHolders: keyHolders,
      relays: relays,
      instructions: instructions,
    );

    // Sync relays to RelayScanService and ensure scanning is started
    try {
      await _relayScanService.syncRelaysFromUrls(relays);
      await _relayScanService.ensureScanningStarted();
      Log.info('Synced ${relays.length} relay(s) to RelayScanService');
    } catch (e) {
      Log.error('Error syncing relays to RelayScanService', e);
      // Don't fail backup config save if relay sync fails
    }

    Log.info('Created backup configuration for lockbox $lockboxId');
    return config;
  }

  /// High-level method to create and distribute a backup
  ///
  /// This orchestrates the entire backup creation flow:
  /// 1. Loads lockbox and backup configuration
  /// 2. Generates Shamir shares
  /// 3. Distributes shares to key holders via Nostr
  ///
  /// Throws exception if any step fails
  Future<BackupConfig> createAndDistributeBackup({
    required String lockboxId,
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

      // Step 2: Load backup configuration
      final config = await _repository.getBackupConfig(lockboxId);
      if (config == null) {
        throw Exception('Backup configuration not found for lockbox: $lockboxId');
      }
      if (config.keyHolders.isEmpty) {
        throw Exception('No stewards configured in backup configuration');
      }
      Log.info('Loaded backup configuration');

      // Step 3: Get creator's Nostr key pair
      final creatorKeyPair = await _loginService.getStoredNostrKey();
      final creatorPubkey = creatorKeyPair?.publicKey;
      final creatorPrivkey = creatorKeyPair?.privateKey;
      if (creatorPubkey == null || creatorPrivkey == null) {
        throw Exception('No Nostr key available for backup creation');
      }
      Log.info('Retrieved creator key pair');

      // Step 4: Validate all key holders are ready for distribution
      if (!config.canDistribute) {
        final names = config.keyHolders
            .where((kh) => kh.pubkey == null)
            .map((kh) => kh.name ?? kh.id)
            .join(', ');
        throw StateError(
          'Cannot distribute: ${config.pendingInvitationsCount} steward(s) '
          'haven\'t accepted invitations yet: $names',
        );
      }

      // Step 5: Generate Shamir shares
      // Note: peers list excludes the creator - recipients need to know OTHER key holders
      // Build peers list with name and pubkey maps
      final peers = config.keyHolders
          .where((kh) => kh.pubkey != null && kh.pubkey != creatorPubkey)
          .map((kh) => {
                'name': kh.name ?? 'Unknown',
                'pubkey': kh.pubkey!,
              })
          .toList();
      final shards = await generateShamirShares(
        content: content,
        threshold: config.threshold,
        totalShards: config.totalKeys,
        creatorPubkey: creatorPubkey,
        lockboxId: lockbox.id,
        lockboxName: lockbox.name,
        peers: peers,
        ownerName: lockbox.ownerName,
        instructions: config.instructions,
      );
      Log.info('Generated ${shards.length} Shamir shares');

      // Step 6: Distribute shards using injected service
      await _shardDistributionService.distributeShards(
        ownerPubkey: creatorPubkey,
        config: config,
        shards: shards,
      );
      Log.info('Successfully distributed all shards');

      // Step 7: Update backup config with distribution timestamp and status
      final now = DateTime.now();
      final updatedConfig = copyBackupConfig(
        config,
        lastRedistribution: now,
        lastUpdated: now,
        status: BackupStatus.active,
      );
      await _repository.updateBackupConfig(lockboxId, updatedConfig);
      Log.info('Updated backup config with redistribution timestamp');

      return updatedConfig;
    } catch (e) {
      Log.error('Failed to create and distribute backup', e);
      rethrow;
    }
  }
}
