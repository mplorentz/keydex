import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_distribution_status.dart';
import '../models/shard_data.dart';
import 'logger.dart';

/// Manages 48-hour file distribution window from owner to key holders
class FileDistributionService {
  static const String _distributionStatusKey = 'file_distribution_statuses';
  static const Duration _distributionWindow = Duration(hours: 48);

  /// Starts the distribution process after files uploaded to Blossom
  Future<List<FileDistributionStatus>> startDistribution({
    required String lockboxId,
    required List<String> keyHolderPubkeys,
  }) async {
    try {
      Log.info('Starting file distribution for lockbox: $lockboxId to ${keyHolderPubkeys.length} key holders');

      final uploadedAt = DateTime.now();
      final statuses = keyHolderPubkeys.map((pubkey) {
        return FileDistributionStatus(
          lockboxId: lockboxId,
          keyHolderPubkey: pubkey,
          state: DistributionState.pending,
          uploadedAt: uploadedAt,
        );
      }).toList();

      await _saveDistributionStatuses(statuses);
      Log.info('Distribution started for ${statuses.length} key holders');

      return statuses;
    } catch (e) {
      Log.error('Failed to start distribution for lockbox: $lockboxId', e);
      rethrow;
    }
  }

  /// Automatically triggered when key holder receives shard with file references
  /// 
  /// Note: This is a stub implementation. Full auto-download with retry will be added in Phase 3.5+
  Future<bool> autoDownloadFiles({
    required ShardData shardData,
    required String lockboxId,
  }) async {
    try {
      Log.info('Auto-downloading files for lockbox: $lockboxId');

      // Validate shard has file data
      if (shardData.blossomUrls == null || 
          shardData.fileHashes == null || 
          shardData.fileNames == null) {
        Log.warning('Shard data has no file references');
        return false;
      }

      // TODO: Actual download and cache logic with FileStorageService
      // Simulate download
      await Future.delayed(const Duration(milliseconds: 500));

      // TODO: Send confirmation to owner (kind 2442)

      Log.info('Auto-download completed for ${shardData.fileNames!.length} files');
      return true;
    } catch (e) {
      Log.error('Failed to auto-download files for lockbox: $lockboxId', e);
      // Will trigger retry
      return false;
    }
  }

  /// Gets distribution status for all key holders of a lockbox
  Future<List<FileDistributionStatus>> getDistributionStatus(String lockboxId) async {
    try {
      final allStatuses = await _loadAllDistributionStatuses();
      return allStatuses.where((s) => s.lockboxId == lockboxId).toList();
    } catch (e) {
      Log.error('Failed to get distribution status for lockbox: $lockboxId', e);
      return [];
    }
  }

  /// Checks if distribution is complete (ready to delete from Blossom)
  Future<bool> isDistributionComplete(String lockboxId) async {
    try {
      final statuses = await getDistributionStatus(lockboxId);
      
      if (statuses.isEmpty) {
        return false;
      }

      // Check if all downloaded
      if (statuses.allDownloaded()) {
        return true;
      }

      // Check if 48 hour window expired
      final uploadedAt = statuses.first.uploadedAt;
      final elapsed = DateTime.now().difference(uploadedAt);
      if (elapsed >= _distributionWindow) {
        return true;
      }

      return false;
    } catch (e) {
      Log.error('Failed to check distribution complete for lockbox: $lockboxId', e);
      return false;
    }
  }

  /// Deletes files from Blossom after successful distribution
  Future<bool> cleanupBlossom(String lockboxId) async {
    try {
      Log.info('Cleaning up Blossom files for lockbox: $lockboxId');

      // Check if distribution complete
      if (!await isDistributionComplete(lockboxId)) {
        Log.warning('Distribution not complete, cannot cleanup yet');
        return false;
      }

      // TODO: Get lockbox file hashes and delete from Blossom via FileStorageService
      // Simulate cleanup
      await Future.delayed(const Duration(milliseconds: 200));

      // Clear distribution statuses
      await _clearDistributionStatuses(lockboxId);

      Log.info('Blossom cleanup completed for lockbox: $lockboxId');
      return true;
    } catch (e) {
      Log.error('Failed to cleanup Blossom for lockbox: $lockboxId', e);
      return false;
    }
  }

  /// Manually triggers re-upload for key holders who missed the window
  Future<List<FileDistributionStatus>> reuploadForKeyHolders({
    required String lockboxId,
    List<String>? keyHolderPubkeys,
  }) async {
    try {
      Log.info('Re-uploading files for lockbox: $lockboxId');

      // Get current statuses
      final currentStatuses = await getDistributionStatus(lockboxId);
      
      // Determine which key holders to re-upload to
      List<String> targetPubkeys;
      if (keyHolderPubkeys != null) {
        targetPubkeys = keyHolderPubkeys;
      } else {
        // Default to missed window key holders
        targetPubkeys = currentStatuses
            .where((s) => s.state == DistributionState.missedWindow)
            .map((s) => s.keyHolderPubkey)
            .toList();
      }

      if (targetPubkeys.isEmpty) {
        Log.info('No key holders to re-upload to');
        return [];
      }

      // TODO: Re-upload files to Blossom and send new shard events

      // Create new distribution statuses
      final newStatuses = await startDistribution(
        lockboxId: lockboxId,
        keyHolderPubkeys: targetPubkeys,
      );

      Log.info('Re-upload started for ${targetPubkeys.length} key holders');
      return newStatuses;
    } catch (e) {
      Log.error('Failed to re-upload for lockbox: $lockboxId', e);
      rethrow;
    }
  }

  /// Called when key holder successfully downloads and caches files
  Future<void> confirmDownload({
    required String lockboxId,
    required String ownerPubkey,
  }) async {
    try {
      Log.info('Confirming download for lockbox: $lockboxId to owner: ${ownerPubkey.substring(0, 8)}...');

      // TODO: Create and publish Nostr event kind 2442 (download confirmation)
      // Simulate confirmation
      await Future.delayed(const Duration(milliseconds: 100));

      Log.info('Download confirmation sent');
    } catch (e) {
      Log.error('Failed to confirm download for lockbox: $lockboxId', e);
    }
  }

  /// Updates distribution status when receiving download confirmation
  Future<void> updateStatusFromConfirmation({
    required String lockboxId,
    required String keyHolderPubkey,
  }) async {
    try {
      Log.info('Updating status from confirmation: lockbox=$lockboxId, keyHolder=${keyHolderPubkey.substring(0, 8)}...');

      final allStatuses = await _loadAllDistributionStatuses();
      final index = allStatuses.indexWhere(
        (s) => s.lockboxId == lockboxId && s.keyHolderPubkey == keyHolderPubkey,
      );

      if (index != -1) {
        allStatuses[index] = allStatuses[index].copyWith(
          state: DistributionState.downloaded,
          downloadedAt: DateTime.now(),
        );

        await _saveDistributionStatuses(allStatuses);
        Log.info('Distribution status updated to downloaded');
      }
    } catch (e) {
      Log.error('Failed to update status from confirmation', e);
    }
  }

  /// Background task: Updates missed window statuses
  Future<void> updateMissedWindows() async {
    try {
      final allStatuses = await _loadAllDistributionStatuses();
      bool hasChanges = false;

      for (var i = 0; i < allStatuses.length; i++) {
        final status = allStatuses[i];
        if (status.state == DistributionState.pending) {
          final elapsed = DateTime.now().difference(status.uploadedAt);
          if (elapsed >= _distributionWindow) {
            allStatuses[i] = status.copyWith(state: DistributionState.missedWindow);
            hasChanges = true;
            Log.info('Marked key holder as missed window: ${status.keyHolderPubkey.substring(0, 8)}...');
          }
        }
      }

      if (hasChanges) {
        await _saveDistributionStatuses(allStatuses);
      }
    } catch (e) {
      Log.error('Failed to update missed windows', e);
    }
  }

  /// Internal: Load all distribution statuses
  Future<List<FileDistributionStatus>> _loadAllDistributionStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_distributionStatusKey);
      
      if (jsonStr == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr) as List;
      return jsonList
          .map((json) => FileDistributionStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.error('Failed to load distribution statuses', e);
      return [];
    }
  }

  /// Internal: Save distribution statuses
  Future<void> _saveDistributionStatuses(List<FileDistributionStatus> statuses) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load existing and merge with new
    final existing = await _loadAllDistributionStatuses();
    
    // Remove old statuses for same lockbox/keyholder pairs
    for (final newStatus in statuses) {
      existing.removeWhere(
        (s) => s.lockboxId == newStatus.lockboxId && s.keyHolderPubkey == newStatus.keyHolderPubkey,
      );
    }
    
    // Add new statuses
    existing.addAll(statuses);
    
    // Save all
    final jsonList = existing.map((s) => s.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await prefs.setString(_distributionStatusKey, jsonStr);
  }

  /// Internal: Clear distribution statuses for a lockbox
  Future<void> _clearDistributionStatuses(String lockboxId) async {
    final allStatuses = await _loadAllDistributionStatuses();
    allStatuses.removeWhere((s) => s.lockboxId == lockboxId);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = allStatuses.map((s) => s.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await prefs.setString(_distributionStatusKey, jsonStr);
  }
}

