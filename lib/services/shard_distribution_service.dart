import 'dart:convert';
import '../models/backup_config.dart';
import '../models/shard_event.dart';
import '../models/shard_data.dart';
import '../models/key_holder.dart';
import '../models/key_holder_status.dart';
import 'backup_service.dart';
import 'nostr_service.dart';
import 'key_service.dart';
import 'logger.dart';

/// Service for distributing shards to key holders via Nostr
class ShardDistributionService {
  /// Distribute shards to all key holders
  static Future<List<ShardEvent>> distributeShards({
    required BackupConfig config,
    required List<ShardData> shards,
  }) async {
    try {
      if (shards.length != config.totalKeys) {
        throw ArgumentError('Number of shards must equal totalKeys');
      }

      final shardEvents = <ShardEvent>[];

      for (int i = 0; i < shards.length; i++) {
        final shard = shards[i];
        final keyHolder = config.keyHolders[i];

        try {
          // Encrypt shard data for this key holder
          final shardJson = shardDataToJson(shard);
          final shardString = json.encode(shardJson);
          final encryptedContent = await KeyService.encryptForRecipient(
            plaintext: shardString,
            recipientPubkey: keyHolder.pubkey, // Hex format
          );
          Log.debug(encryptedContent);

          // Publish gift wrap event
          final shardEvent = await NostrService.publishGiftWrapEvent(
            recipientPubkey: keyHolder.pubkey, // Hex format
            encryptedContent: encryptedContent,
            backupConfigId: config.lockboxId,
            shardIndex: i,
          );
          Log.debug('shardEvent: $shardEvent');

          shardEvents.add(shardEvent);
          Log.info('Distributed shard $i to ${keyHolder.npub}');
        } catch (e) {
          Log.error('Failed to distribute shard $i to ${keyHolder.npub}', e);
          // Continue with other shards even if one fails
        }
      }

      return shardEvents;
    } catch (e) {
      Log.error('Error distributing shards', e);
      throw Exception('Failed to distribute shards: $e');
    }
  }

  /// Check distribution status and update key holder statuses
  static Future<void> updateDistributionStatus({
    required String lockboxId,
    required List<ShardEvent> shardEvents,
  }) async {
    try {
      for (final shardEvent in shardEvents) {
        // Check if event has been acknowledged
        final isAcknowledged = await NostrService.checkEventAcknowledgment(
          shardEvent.eventId,
        );

        if (isAcknowledged) {
          // Update key holder status to acknowledged
          await BackupService.updateKeyHolderStatus(
            lockboxId: lockboxId,
            pubkey: shardEvent.recipientPubkey, // Hex format
            status: KeyHolderStatus.acknowledged,
            acknowledgedAt: DateTime.now(),
            acknowledgmentEventId: shardEvent.eventId,
          );
        } else {
          // Update key holder status to active (published but not acknowledged)
          await BackupService.updateKeyHolderStatus(
            lockboxId: lockboxId,
            pubkey: shardEvent.recipientPubkey, // Hex format
            status: KeyHolderStatus.active,
          );
        }
      }
    } catch (e) {
      Log.error('Error updating distribution status', e);
      throw Exception('Failed to update distribution status: $e');
    }
  }
}
