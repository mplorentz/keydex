import 'dart:convert';
import 'package:ndk/ndk.dart';
import '../models/backup_config.dart';
import '../models/nostr_kinds.dart';
import '../models/shard_event.dart';
import '../models/shard_data.dart';
import '../models/key_holder.dart';
import '../models/key_holder_status.dart';
import '../models/event_status.dart';
import '../providers/lockbox_provider.dart';
import 'backup_service.dart';
import 'logger.dart';

/// Service for distributing shards to key holders via Nostr
class ShardDistributionService {
  /// Distribute shards to all key holders
  static Future<List<ShardEvent>> distributeShards({
    required String ownerPubkey, // Hex format - lockbox owner's pubkey for signing
    required BackupConfig config,
    required List<ShardData> shards,
    required Ndk ndk,
    required LockboxRepository repository,
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
          // Create rumor event with shard data
          final shardJson = shardDataToJson(shard);
          final shardString = json.encode(shardJson);

          final rumor = await ndk.giftWrap.createRumor(
            customPubkey: ownerPubkey, // Lockbox owner signs the rumor
            content: shardString,
            kind: NostrKind.shardData.value, // Keydex custom kind for shard data
            tags: [
              ['d', 'shard_${config.lockboxId}_$i'], // Distinguisher tag
              ['backup_config_id', config.lockboxId],
              ['shard_index', i.toString()],
            ],
          );

          Log.debug('recipient pubkey: ${keyHolder.pubkey}');
          // Wrap the rumor in a gift wrap for the recipient
          final giftWrap = await ndk.giftWrap.toGiftWrap(
            rumor: rumor,
            recipientPubkey: keyHolder.pubkey, // Hex format
          );

          // Broadcast the gift wrap event
          ndk.broadcast.broadcast(
            nostrEvent: giftWrap,
            specificRelays: config.relays,
          );

          // Create ShardEvent record
          final shardEvent = createShardEvent(
            eventId: giftWrap.id,
            recipientPubkey: keyHolder.pubkey, // Hex format
            encryptedContent: shardString, // Store original content for reference
            backupConfigId: config.lockboxId,
            shardIndex: i,
          );

          // Update status to published
          final publishedShardEvent = copyShardEvent(
            shardEvent,
            publishedAt: DateTime.now(),
            status: EventStatus.published,
          );

          shardEvents.add(publishedShardEvent);
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
    required Ndk ndk,
    required LockboxRepository repository,
  }) async {
    try {
      for (final shardEvent in shardEvents) {
        try {
          // Query for acknowledgment events (kind 1059) from the recipient
          final filter = Filter(
            kinds: [1059], // Gift wrap events
            authors: [shardEvent.recipientPubkey], // Hex format
            since: shardEvent.createdAt.millisecondsSinceEpoch ~/ 1000,
          );

          final acknowledgmentResponse = ndk.requests.query(
            filters: [filter],
          );

          // Get the events from the response
          final acknowledgmentEvents = await acknowledgmentResponse.future;

          // Check if any acknowledgment event references our gift wrap
          bool isAcknowledged = false;
          String? acknowledgmentEventId;

          for (final event in acknowledgmentEvents) {
            // Look for 'p' tag referencing the original sender
            final pTags = event.pTags;
            if (pTags.isNotEmpty) {
              // This is a simplified check - in practice you'd want to verify
              // that this acknowledgment is specifically for our gift wrap
              isAcknowledged = true;
              acknowledgmentEventId = event.id;
              break;
            }
          }

          if (isAcknowledged) {
            // Update key holder status to acknowledged
            await BackupService.updateKeyHolderStatus(
              lockboxId: lockboxId,
              pubkey: shardEvent.recipientPubkey, // Hex format
              status: KeyHolderStatus.acknowledged,
              repository: repository,
              acknowledgedAt: DateTime.now(),
              acknowledgmentEventId: acknowledgmentEventId,
            );
          } else {
            // Update key holder status to active (published but not acknowledged)
            await BackupService.updateKeyHolderStatus(
              lockboxId: lockboxId,
              pubkey: shardEvent.recipientPubkey, // Hex format
              status: KeyHolderStatus.active,
              repository: repository,
            );
          }
        } catch (e) {
          Log.error('Failed to check acknowledgment for shard ${shardEvent.shardIndex}', e);
          // Continue with other shards even if one fails
        }
      }
    } catch (e) {
      Log.error('Error updating distribution status', e);
      throw Exception('Failed to update distribution status: $e');
    }
  }
}
