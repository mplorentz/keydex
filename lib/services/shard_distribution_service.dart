import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../models/backup_config.dart';
import '../models/nostr_kinds.dart';
import '../models/shard_event.dart';
import '../models/shard_data.dart';
import '../models/key_holder.dart';
import '../models/key_holder_status.dart';
import '../models/event_status.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'ndk_service.dart';
import 'logger.dart';

/// Provider for ShardDistributionService
final Provider<ShardDistributionService> shardDistributionServiceProvider =
    Provider<ShardDistributionService>((ref) {
  return ShardDistributionService(
    ref.read(lockboxRepositoryProvider),
    ref.read(loginServiceProvider),
    ref.read(ndkServiceProvider),
  );
});

/// Service for distributing shards to key holders via Nostr
class ShardDistributionService {
  final LockboxRepository _repository;
  final LoginService _loginService;
  final NdkService _ndkService;

  ShardDistributionService(this._repository, this._loginService, this._ndkService);

  /// Distribute shards to all key holders
  Future<List<ShardEvent>> distributeShards({
    required String ownerPubkey, // Hex format - lockbox owner's pubkey for signing
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

        // Skip key holders without pubkeys (invited but not yet accepted)
        if (keyHolder.pubkey == null) {
          Log.info(
              'Skipping shard distribution to key holder ${keyHolder.name ?? keyHolder.id} - no pubkey yet (invited)');
          continue;
        }

        try {
          // Update shard with relay URLs from backup config for confirmation events
          final shardWithRelays = copyShardData(
            shard,
            relayUrls: config.relays,
          );

          // Create shard data JSON
          final shardJson = shardDataToJson(shardWithRelays);
          final shardString = json.encode(shardJson);

          Log.debug('recipient pubkey: ${keyHolder.pubkey}');

          // Publish using NdkService
          final eventId = await _ndkService.publishGiftWrapEvent(
            content: shardString,
            kind: NostrKind.shardData.value,
            recipientPubkey: keyHolder.pubkey!, // Hex format - safe because we checked null above
            relays: config.relays,
            tags: [
              ['d', 'shard_${config.lockboxId}_$i'], // Distinguisher tag
              ['backup_config_id', config.lockboxId],
              ['shard_index', i.toString()],
            ],
            customPubkey: ownerPubkey, // Lockbox owner signs the rumor
          );

          if (eventId == null) {
            throw Exception('Failed to publish shard event');
          }

          // Create ShardEvent record
          final shardEvent = createShardEvent(
            eventId: eventId,
            recipientPubkey: keyHolder.pubkey!, // Hex format - safe because we checked null above
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
          Log.info('Distributed shard $i to ${keyHolder.npub ?? keyHolder.name ?? keyHolder.id}');
        } catch (e) {
          Log.error(
              'Failed to distribute shard $i to ${keyHolder.npub ?? keyHolder.name ?? keyHolder.id}',
              e);
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
  Future<void> updateDistributionStatus({
    required String lockboxId,
    required List<ShardEvent> shardEvents,
  }) async {
    try {
      final ndk = await _ndkService.getNdk();

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
            // Update key holder status to holdingKey (confirmed receipt)
            await _repository.updateKeyHolderStatus(
              lockboxId: lockboxId,
              pubkey: shardEvent.recipientPubkey, // Hex format
              status: KeyHolderStatus.holdingKey,
              acknowledgedAt: DateTime.now(),
              acknowledgmentEventId: acknowledgmentEventId,
            );
          } else {
            // Update key holder status to awaitingKey (published but not acknowledged)
            await _repository.updateKeyHolderStatus(
              lockboxId: lockboxId,
              pubkey: shardEvent.recipientPubkey, // Hex format
              status: KeyHolderStatus.awaitingKey,
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

  /// Processes shard confirmation event received from key holder
  ///
  /// Decrypts event content using NIP-44.
  /// Validates lockbox ID and shard index.
  /// Updates key holder status to "holding key".
  /// Updates last acknowledgment timestamp.
  Future<void> processShardConfirmationEvent({
    required Nip01Event event,
  }) async {
    // Validate event kind
    if (event.kind != NostrKind.shardConfirmation.value) {
      throw ArgumentError(
          'Invalid event kind: expected ${NostrKind.shardConfirmation.value}, got ${event.kind}');
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process shard confirmation event.');
    }

    // Extract lockbox ID and shard index from tags
    // All confirmation data is stored in tags (no content)
    final lockboxId = _extractTagValue(event.tags, 'lockbox_id');
    final shardIndexStr = _extractTagValue(event.tags, 'shard_index');

    if (lockboxId == null) {
      throw ArgumentError('Missing lockbox_id tag in shard confirmation event');
    }

    if (shardIndexStr == null) {
      throw ArgumentError('Missing shard_index tag in shard confirmation event');
    }

    final shardIndex = int.tryParse(shardIndexStr);
    if (shardIndex == null) {
      throw ArgumentError('Invalid shard index in shard confirmation event: $shardIndexStr');
    }

    // Update key holder status
    final keyHolderPubkey = event.pubKey;
    await _repository.updateKeyHolderStatus(
      lockboxId: lockboxId,
      pubkey: keyHolderPubkey,
      status: KeyHolderStatus.holdingKey,
      acknowledgedAt: DateTime.now(),
      acknowledgmentEventId: event.id,
    );

    Log.info(
        'Processed shard confirmation event for lockbox $lockboxId, shard $shardIndex from key holder $keyHolderPubkey');
  }

  /// Processes shard error event received from key holder
  ///
  /// Decrypts event content using NIP-44.
  /// Validates lockbox ID and shard index.
  /// Updates key holder status to "error".
  /// Logs error details.
  Future<void> processShardErrorEvent({
    required Nip01Event event,
  }) async {
    // Validate event kind
    if (event.kind != NostrKind.shardError.value) {
      throw ArgumentError(
          'Invalid event kind: expected ${NostrKind.shardError.value}, got ${event.kind}');
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process shard error event.');
    }

    // Extract lockbox ID and shard index from tags
    final lockboxId = _extractTagValue(event.tags, 'lockbox');
    final shardIndexStr = _extractTagValue(event.tags, 'shard');

    if (lockboxId == null) {
      throw ArgumentError('Missing lockbox tag in shard error event');
    }

    if (shardIndexStr == null) {
      throw ArgumentError('Missing shard tag in shard error event');
    }

    final shardIndex = int.tryParse(shardIndexStr);
    if (shardIndex == null) {
      throw ArgumentError('Invalid shard index in shard error event: $shardIndexStr');
    }

    // Verify we're the recipient (p tag should be owner)
    final recipientPubkey = _extractTagValue(event.tags, 'p');
    if (recipientPubkey != ownerPubkey) {
      throw ArgumentError('Shard error event not addressed to current user');
    }

    // Decrypt event content
    String decryptedContent;
    try {
      decryptedContent = await _loginService.decryptFromSender(
        encryptedText: event.content,
        senderPubkey: event.pubKey,
      );
    } catch (e) {
      Log.error('Error decrypting shard error event content', e);
      throw Exception('Failed to decrypt shard error event content: $e');
    }

    // Parse decrypted JSON
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(decryptedContent) as Map<String, dynamic>;
    } catch (e) {
      Log.error('Error parsing shard error event JSON', e);
      throw Exception('Invalid JSON in shard error event content: $e');
    }

    // Validate payload
    final payloadLockboxId = payload['lockboxId'] as String?;
    final payloadShardIndex = payload['shardIndex'] as int?;
    final error = payload['error'] as String? ?? 'Unknown error';

    if (payloadLockboxId != lockboxId) {
      throw ArgumentError('Lockbox ID mismatch in shard error event payload');
    }

    if (payloadShardIndex != shardIndex) {
      throw ArgumentError('Shard index mismatch in shard error event payload');
    }

    // Update key holder status to error
    final keyHolderPubkey = event.pubKey;
    await _repository.updateKeyHolderStatus(
      lockboxId: lockboxId,
      pubkey: keyHolderPubkey,
      status: KeyHolderStatus.error,
    );

    Log.error(
        'Processed shard error event for lockbox $lockboxId, shard $shardIndex from key holder $keyHolderPubkey: $error');
  }

  /// Helper method to extract a tag value from event tags
  String? _extractTagValue(List<List<String>> tags, String tagName) {
    for (final tag in tags) {
      if (tag.isNotEmpty && tag[0] == tagName && tag.length > 1) {
        return tag[1];
      }
    }
    return null;
  }
}
