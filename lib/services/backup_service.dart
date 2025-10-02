import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ntcdcrypto/ntcdcrypto.dart';
import 'package:ndk/ndk.dart';
import '../models/backup_config.dart';
import '../models/key_holder.dart';
import '../models/shard_data.dart';
import '../models/backup_status.dart';
import '../models/key_holder_status.dart';
import 'key_service.dart';
import 'lockbox_service.dart';
import 'shard_distribution_service.dart';
import '../services/logger.dart';

/// Service for managing distributed backup using Shamir's Secret Sharing
class BackupService {
  static const _storage = FlutterSecureStorage();
  static const String _backupConfigsKey = 'backup_configs';
  static Map<String, BackupConfig>? _cachedConfigs;
  static bool _isInitialized = false;

  /// Initialize the backup service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadBackupConfigs();
      _isInitialized = true;
    } catch (e) {
      Log.error('Error initializing BackupService', e);
      _cachedConfigs = {};
      _isInitialized = true;
    }
  }

  /// Load backup configurations from secure storage
  static Future<void> _loadBackupConfigs() async {
    try {
      final encryptedData = await _storage.read(key: _backupConfigsKey);

      if (encryptedData == null || encryptedData.isEmpty) {
        _cachedConfigs = {};
        Log.info('No backup configurations found');
        return;
      }

      // Decrypt the data using our Nostr key
      final decryptedJson = await KeyService.decryptText(encryptedData);
      final Map<String, dynamic> jsonMap = json.decode(decryptedJson);

      _cachedConfigs = {};
      for (final entry in jsonMap.entries) {
        _cachedConfigs![entry.key] = backupConfigFromJson(entry.value as Map<String, dynamic>);
      }

      Log.info('Loaded ${_cachedConfigs!.length} backup configurations');
    } catch (e) {
      Log.error('Error loading backup configurations', e);
      _cachedConfigs = {};
    }
  }

  /// Save backup configurations to secure storage
  static Future<void> _saveBackupConfigs() async {
    if (_cachedConfigs == null) return;

    try {
      // Convert to JSON
      final jsonMap = <String, dynamic>{};
      for (final entry in _cachedConfigs!.entries) {
        jsonMap[entry.key] = backupConfigToJson(entry.value);
      }
      final jsonString = json.encode(jsonMap);

      // Encrypt the JSON data using our Nostr key
      final encryptedData = await KeyService.encryptText(jsonString);

      // Save to secure storage
      await _storage.write(key: _backupConfigsKey, value: encryptedData);
      Log.info('Saved ${_cachedConfigs!.length} backup configurations');
    } catch (e) {
      Log.error('Error saving backup configurations', e);
      throw Exception('Failed to save backup configurations: $e');
    }
  }

  /// Create a new backup configuration
  static Future<BackupConfig> createBackupConfiguration({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
    String? contentHash,
  }) async {
    await initialize();

    // Validate inputs
    if (threshold < 2 || threshold > totalKeys) {
      throw ArgumentError('Threshold must be >= 2 and <= totalKeys');
    }
    if (totalKeys < threshold || totalKeys > 10) {
      throw ArgumentError('TotalKeys must be >= threshold and <= 10');
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

    // Store the configuration
    _cachedConfigs![lockboxId] = config;
    await _saveBackupConfigs();

    Log.info('Created backup configuration for lockbox $lockboxId');
    return config;
  }

  /// Get backup configuration for a lockbox
  static Future<BackupConfig?> getBackupConfig(String lockboxId) async {
    await initialize();
    return _cachedConfigs![lockboxId];
  }

  /// Get all backup configurations
  static Future<List<BackupConfig>> getAllBackupConfigs() async {
    await initialize();
    return List.unmodifiable(_cachedConfigs!.values);
  }

  /// Update backup configuration
  static Future<void> updateBackupConfig(BackupConfig config) async {
    await initialize();

    if (!_cachedConfigs!.containsKey(config.lockboxId)) {
      throw ArgumentError('Backup configuration not found for lockbox ${config.lockboxId}');
    }

    _cachedConfigs![config.lockboxId] = config;
    await _saveBackupConfigs();

    Log.info('Updated backup configuration for lockbox ${config.lockboxId}');
  }

  /// Delete backup configuration
  static Future<void> deleteBackupConfig(String lockboxId) async {
    await initialize();

    if (_cachedConfigs!.containsKey(lockboxId)) {
      _cachedConfigs!.remove(lockboxId);
      await _saveBackupConfigs();
      Log.info('Deleted backup configuration for lockbox $lockboxId');
    }
  }

  /// Generate Shamir shares for lockbox content
  static Future<List<ShardData>> generateShamirShares({
    required String content,
    required int threshold,
    required int totalShards,
    required String creatorPubkey,
  }) async {
    try {
      // Validate inputs
      if (threshold < 2) {
        throw ArgumentError('Threshold must be at least 2');
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
        );
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
  static Future<String> reconstructFromShares({required List<ShardData> shares}) async {
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
  static Future<void> updateBackupStatus(String lockboxId, BackupStatus status) async {
    await initialize();

    final config = _cachedConfigs![lockboxId];
    if (config == null) {
      throw ArgumentError('Backup configuration not found for lockbox $lockboxId');
    }

    final updatedConfig = copyBackupConfig(config, status: status, lastUpdated: DateTime.now());

    _cachedConfigs![lockboxId] = updatedConfig;
    await _saveBackupConfigs();

    Log.info('Updated backup status for lockbox $lockboxId to $status');
  }

  /// Update key holder status
  static Future<void> updateKeyHolderStatus({
    required String lockboxId,
    required String pubkey, // Hex format
    required KeyHolderStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
  }) async {
    await initialize();

    final config = _cachedConfigs![lockboxId];
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

    _cachedConfigs![lockboxId] = updatedConfig;
    await _saveBackupConfigs();

    Log.info('Updated key holder $pubkey status to $status');
  }

  /// Check if backup is ready (all required key holders have acknowledged)
  static Future<bool> isBackupReady(String lockboxId) async {
    await initialize();

    final config = _cachedConfigs![lockboxId];
    if (config == null) return false;

    return config.acknowledgedKeyHoldersCount >= config.threshold;
  }

  /// Clear all backup configurations (for testing)
  static Future<void> clearAll() async {
    _cachedConfigs = {};
    await _storage.delete(key: _backupConfigsKey);
    _isInitialized = false;
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
  static Future<BackupConfig> createAndDistributeBackup({
    required String lockboxId,
    required int threshold,
    required int totalKeys,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
  }) async {
    try {
      // Step 1: Load lockbox content
      final lockbox = await LockboxService.getLockbox(lockboxId);
      if (lockbox == null) {
        throw Exception('Lockbox not found: $lockboxId');
      }
      final content = lockbox.content;
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
      await initialize();
      if (_cachedConfigs!.containsKey(lockboxId)) {
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
      final shards = await generateShamirShares(
        content: content,
        threshold: threshold,
        totalShards: totalKeys,
        creatorPubkey: creatorPubkey,
      );
      Log.info('Generated ${shards.length} Shamir shares');

      // Step 6: Initialize NDK and distribute shards
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: creatorPubkey, privkey: creatorPrivkey);
      Log.info('Initialized NDK for shard distribution');

      await ShardDistributionService.distributeShards(
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
