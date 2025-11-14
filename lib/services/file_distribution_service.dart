import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/file_storage_provider.dart';
import '../providers/lockbox_provider.dart';
import '../services/file_storage_service.dart';
import '../models/file_distribution_status.dart';
import '../models/shard_data.dart';
import '../services/ndk_service.dart';
import '../providers/key_provider.dart';
import '../services/login_service.dart';
import '../models/nostr_kinds.dart';
import 'logger.dart';

/// Provider for FileDistributionService
final fileDistributionServiceProvider = Provider<FileDistributionService>((ref) {
  return FileDistributionService(
    ref.read(fileStorageServiceProvider),
    ref.read(lockboxRepositoryProvider),
    ref.read(ndkServiceProvider),
    ref.read(loginServiceProvider),
  );
});

/// Service for managing file distribution operations
class FileDistributionService {
  final FileStorageService _fileStorageService;
  final LockboxRepository _lockboxRepository;
  final NdkService _ndkService;
  final LoginService _loginService;

  FileDistributionService(
    this._fileStorageService,
    this._lockboxRepository,
    this._ndkService,
    this._loginService,
  );

  static const String _distributionStatusesKey = 'file_distribution_statuses';
  static const Duration _distributionWindow = Duration(hours: 48);

  /// Starts the distribution process after files uploaded to Blossom
  Future<List<FileDistributionStatus>> startDistribution({
    required String lockboxId,
    required List<String> keyHolderPubkeys,
  }) async {
    try {
      final statuses = <FileDistributionStatus>[];

      for (final pubkey in keyHolderPubkeys) {
        final status = FileDistributionStatus.createPending(
          lockboxId: lockboxId,
          keyHolderPubkey: pubkey,
        );
        status.validate();
        statuses.add(status);
      }

      await _saveDistributionStatuses(statuses);
      Log.info('Started distribution for lockbox $lockboxId with ${statuses.length} key holders');
      return statuses;
    } catch (e) {
      Log.error('Error starting distribution', e);
      rethrow;
    }
  }

  /// Automatically triggered when key holder receives shard with file references
  Future<bool> autoDownloadFiles({
    required ShardData shardData,
    required String lockboxId,
  }) async {
    try {
      // Extract file URLs and hashes from shardData
      if (shardData.blossomUrls == null ||
          shardData.fileHashes == null ||
          shardData.fileNames == null) {
        Log.warning('Shard data missing file metadata for lockbox $lockboxId');
        return false;
      }

      final blossomUrls = shardData.blossomUrls!;
      final fileHashes = shardData.fileHashes!;
      final fileNames = shardData.fileNames!;

      if (blossomUrls.length != fileHashes.length || blossomUrls.length != fileNames.length) {
        throw ArgumentError('File arrays must have the same length');
      }

      // Get encryption key from reconstructed secret
      // TODO: This requires reconstructing the secret from shards
      // For now, we'll need to get it from the lockbox or shard reconstruction
      // This is a placeholder - actual implementation needs secret reconstruction
      final encryptionKey = await _getEncryptionKeyForLockbox(lockboxId);
      if (encryptionKey == null) {
        Log.warning('Could not get encryption key for lockbox $lockboxId');
        return false;
      }

      // Download and cache each file (as encrypted bytes from Blossom)
      bool allSucceeded = true;
      for (int i = 0; i < blossomUrls.length; i++) {
        try {
          // Download encrypted bytes (don't decrypt - we cache encrypted)
          final encryptedBytes = await _fileStorageService.downloadEncryptedFile(
            blossomUrl: blossomUrls[i],
            blossomHash: fileHashes[i],
          );

          // Cache the encrypted file bytes
          // During recovery, we'll decrypt when needed using the reconstructed key
          await _fileStorageService.cacheEncryptedFile(
            lockboxId: lockboxId,
            fileHash: fileHashes[i],
            fileName: fileNames[i],
            encryptedBytes: encryptedBytes,
          );

          Log.info('Downloaded and cached file ${fileNames[i]} for lockbox $lockboxId');
        } catch (e) {
          Log.error('Error downloading file ${fileNames[i]}', e);
          allSucceeded = false;
        }
      }

      if (allSucceeded) {
        // Send confirmation to owner
        final lockbox = await _lockboxRepository.getLockbox(lockboxId);
        if (lockbox != null) {
          await confirmDownload(
            lockboxId: lockboxId,
            ownerPubkey: lockbox.ownerPubkey,
          );
        }
      }

      return allSucceeded;
    } catch (e) {
      Log.error('Error in auto-download files', e);
      rethrow;
    }
  }

  /// Gets distribution status for all key holders of a lockbox
  Future<List<FileDistributionStatus>> getDistributionStatus(String lockboxId) async {
    try {
      final allStatuses = await _loadAllDistributionStatuses();
      return allStatuses.where((s) => s.lockboxId == lockboxId).toList();
    } catch (e) {
      Log.error('Error getting distribution status', e);
      return [];
    }
  }

  /// Checks if distribution is complete
  Future<bool> isDistributionComplete(String lockboxId) async {
    try {
      final statuses = await getDistributionStatus(lockboxId);
      if (statuses.isEmpty) {
        return false;
      }

      // Check if all downloaded
      final allDownloaded = statuses.every((s) => s.state == DistributionState.downloaded);
      if (allDownloaded) {
        return true;
      }

      // Check if 48 hours elapsed
      final oldestUpload = statuses.map((s) => s.uploadedAt).reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );
      final now = DateTime.now();
      final difference = now.difference(oldestUpload);
      if (difference >= _distributionWindow) {
        // Mark expired ones as missed window
        for (final status in statuses) {
          if (status.state == DistributionState.pending && status.isWindowExpired) {
            await _updateDistributionStatus(
              status.copyWith(state: DistributionState.missedWindow),
            );
          }
        }
        return true;
      }

      return false;
    } catch (e) {
      Log.error('Error checking distribution complete', e);
      return false;
    }
  }

  /// Deletes files from Blossom after successful distribution
  Future<bool> cleanupBlossom(String lockboxId) async {
    try {
      if (!await isDistributionComplete(lockboxId)) {
        return false;
      }

      final lockbox = await _lockboxRepository.getLockbox(lockboxId);
      if (lockbox == null) {
        Log.warning('Lockbox not found for cleanup: $lockboxId');
        return false;
      }

      // Delete each file from Blossom
      // TODO: Extract server URL from file blossomUrl
      // For now, placeholder - needs proper Blossom server URL extraction
      for (final file in lockbox.files) {
        try {
          // Extract server URL from blossomUrl (e.g., "https://blossom.example.com/hash" -> "https://blossom.example.com")
          final uri = Uri.parse(file.blossomUrl);
          final serverUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';

          await _fileStorageService.deleteFile(
            blossomHash: file.blossomHash,
            serverUrl: serverUrl,
          );
          Log.info('Deleted file ${file.blossomHash} from Blossom');
        } catch (e) {
          Log.warning('Error deleting file ${file.blossomHash} from Blossom', e);
          // Continue with other files
        }
      }

      // Clear distribution statuses
      await _clearDistributionStatuses(lockboxId);
      Log.info('Cleaned up Blossom files for lockbox $lockboxId');
      return true;
    } catch (e) {
      Log.error('Error cleaning up Blossom', e);
      return false;
    }
  }

  /// Manually triggers re-upload for key holders who missed the window
  Future<List<FileDistributionStatus>> reuploadForKeyHolders({
    required String lockboxId,
    List<String>? keyHolderPubkeys,
  }) async {
    try {
      // Get current statuses
      final currentStatuses = await getDistributionStatus(lockboxId);

      // Determine which key holders to re-upload for
      final targetPubkeys = keyHolderPubkeys ??
          currentStatuses
              .where((s) => s.state == DistributionState.missedWindow)
              .map((s) => s.keyHolderPubkey)
              .toList();

      if (targetPubkeys.isEmpty) {
        return [];
      }

      // Clear old statuses for these key holders
      for (final pubkey in targetPubkeys) {
        await _removeDistributionStatus(lockboxId, pubkey);
      }

      // Create new distribution statuses
      final newStatuses = await startDistribution(
        lockboxId: lockboxId,
        keyHolderPubkeys: targetPubkeys,
      );

      Log.info('Re-uploaded files for ${newStatuses.length} key holders for lockbox $lockboxId');
      return newStatuses;
    } catch (e) {
      Log.error('Error re-uploading for key holders', e);
      rethrow;
    }
  }

  /// Called when key holder successfully downloads and caches files
  Future<void> confirmDownload({
    required String lockboxId,
    required String ownerPubkey,
  }) async {
    try {
      final currentPubkey = await _loginService.getCurrentPublicKey();
      if (currentPubkey == null) {
        throw Exception('No current pubkey available');
      }

      // Create Nostr event kind 2442 (download confirmation)
      final content = json.encode({
        'lockbox_id': lockboxId,
        'key_holder_pubkey': currentPubkey,
        'confirmed_at': DateTime.now().toIso8601String(),
      });

      // Get default relays from NDK service
      final relays = await _ndkService.getActiveRelays();
      await _ndkService.publishEncryptedEvent(
        content: content,
        kind: NostrKind.fileDownloadConfirmation.toInt(),
        recipientPubkey: ownerPubkey,
        relays: relays.isNotEmpty ? relays : ['wss://relay.damus.io'], // Fallback relay
        tags: [
          ['p', ownerPubkey],
        ],
      );
      Log.info('Sent download confirmation for lockbox $lockboxId to owner $ownerPubkey');
    } catch (e) {
      Log.error('Error confirming download', e);
      rethrow;
    }
  }

  /// Updates distribution status when receiving download confirmation
  Future<void> updateStatusFromConfirmation({
    required String lockboxId,
    required String keyHolderPubkey,
  }) async {
    try {
      final statuses = await getDistributionStatus(lockboxId);
      final status = statuses.firstWhere(
        (s) => s.keyHolderPubkey == keyHolderPubkey,
        orElse: () => throw Exception('Distribution status not found'),
      );

      final updatedStatus = status.copyWith(
        state: DistributionState.downloaded,
        downloadedAt: DateTime.now(),
      );
      updatedStatus.validate();

      await _updateDistributionStatus(updatedStatus);

      // Check if all key holders downloaded → trigger Blossom cleanup
      if (await isDistributionComplete(lockboxId)) {
      // Schedule cleanup (don't await - run in background)
      cleanupBlossom(lockboxId).catchError((e) {
        Log.error('Error in background Blossom cleanup', e);
        return false;
      });
      }

      Log.info('Updated distribution status for key holder $keyHolderPubkey');
    } catch (e) {
      Log.error('Error updating status from confirmation', e);
      rethrow;
    }
  }

  // Private helper methods

  Future<Uint8List?> _getEncryptionKeyForLockbox(String lockboxId) async {
    // TODO: This needs to reconstruct the secret from shards
    // For now, placeholder - actual implementation requires:
    // 1. Get all shards for this lockbox
    // 2. Reconstruct secret using BackupService.reconstructFromShares
    // 3. Convert secret to 32-byte key
    // This is a complex operation that requires integration with BackupService
    Log.warning('_getEncryptionKeyForLockbox not fully implemented for lockbox $lockboxId');
    return null;
  }

  Future<void> _saveDistributionStatuses(List<FileDistributionStatus> statuses) async {
    final prefs = await SharedPreferences.getInstance();
    final allStatuses = await _loadAllDistributionStatuses();

    // Remove existing statuses for these lockbox/key holder combinations
    for (final status in statuses) {
      allStatuses.removeWhere(
        (s) => s.lockboxId == status.lockboxId && s.keyHolderPubkey == status.keyHolderPubkey,
      );
    }

    // Add new statuses
    allStatuses.addAll(statuses);

    // Save to SharedPreferences
    final jsonList = allStatuses.map((s) => s.toJson()).toList();
    await prefs.setString(_distributionStatusesKey, json.encode(jsonList));
  }

  Future<List<FileDistributionStatus>> _loadAllDistributionStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_distributionStatusesKey);

      if (jsonData == null || jsonData.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonData);
      return jsonList
          .map((json) => FileDistributionStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.error('Error loading distribution statuses', e);
      return [];
    }
  }

  Future<void> _updateDistributionStatus(FileDistributionStatus status) async {
    final allStatuses = await _loadAllDistributionStatuses();
    final index = allStatuses.indexWhere(
      (s) => s.lockboxId == status.lockboxId && s.keyHolderPubkey == status.keyHolderPubkey,
    );

    if (index != -1) {
      allStatuses[index] = status;
    } else {
      allStatuses.add(status);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonList = allStatuses.map((s) => s.toJson()).toList();
    await prefs.setString(_distributionStatusesKey, json.encode(jsonList));
  }

  Future<void> _removeDistributionStatus(String lockboxId, String keyHolderPubkey) async {
    final allStatuses = await _loadAllDistributionStatuses();
    allStatuses.removeWhere(
      (s) => s.lockboxId == lockboxId && s.keyHolderPubkey == keyHolderPubkey,
    );

    final prefs = await SharedPreferences.getInstance();
    final jsonList = allStatuses.map((s) => s.toJson()).toList();
    await prefs.setString(_distributionStatusesKey, json.encode(jsonList));
  }

  Future<void> _clearDistributionStatuses(String lockboxId) async {
    final allStatuses = await _loadAllDistributionStatuses();
    allStatuses.removeWhere((s) => s.lockboxId == lockboxId);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = allStatuses.map((s) => s.toJson()).toList();
    await prefs.setString(_distributionStatusesKey, json.encode(jsonList));
  }
}
