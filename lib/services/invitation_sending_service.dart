import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ndk_service.dart';
import '../services/logger.dart';
import '../models/nostr_kinds.dart';

/// Provider for InvitationSendingService
final invitationSendingServiceProvider = Provider<InvitationSendingService>((ref) {
  return InvitationSendingService(
    ref.read(ndkServiceProvider),
  );
});

/// Stateless utility service for creating and publishing outgoing invitation-related Nostr events
///
/// This service handles only outgoing event creation and publishing, with no local state or storage.
/// All methods are pure functions that create and publish events.
class InvitationSendingService {
  final NdkService ndkService;

  InvitationSendingService(this.ndkService);

  /// Creates and publishes RSVP event to accept invitation
  ///
  /// Creates RSVP event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1340).
  /// Signs with invitee's private key.
  /// Publishes to relays.
  /// Returns event ID.
  Future<String?> sendRsvpEvent({
    required String inviteCode,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
  }) async {
    try {
      final currentPubkey = await ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        Log.error('No key pair available for sending RSVP event');
        return null;
      }

      // Create RSVP event payload
      final rsvpData = {
        'invite_code': inviteCode,
        'invitee_pubkey': currentPubkey,
        'responded_at': DateTime.now().toIso8601String(),
      };

      final rsvpJson = json.encode(rsvpData);

      Log.info('Sending RSVP event for invite code: ${inviteCode.substring(0, 8)}...');

      // Publish using NdkService
      return await ndkService.publishGiftWrapEvent(
        content: rsvpJson,
        kind: NostrKind.invitationRsvp.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'invitation_rsvp_$inviteCode'],
          ['invite', inviteCode],
        ],
      );
    } catch (e) {
      Log.error('Error sending RSVP event', e);
      return null;
    }
  }

  /// Creates and publishes denial event to decline invitation
  ///
  /// Creates denial event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1341).
  /// Signs with invitee's private key.
  /// Publishes to relays.
  /// Returns event ID.
  Future<String?> sendDenialEvent({
    required String inviteCode,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
    String? reason,
  }) async {
    try {
      final currentPubkey = await ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        Log.error('No key pair available for sending denial event');
        return null;
      }

      // Create denial event payload
      final denialData = {
        'invite_code': inviteCode,
        'invitee_pubkey': currentPubkey,
        'responded_at': DateTime.now().toIso8601String(),
      };

      if (reason != null && reason.isNotEmpty) {
        denialData['reason'] = reason;
      }

      final denialJson = json.encode(denialData);

      Log.info('Sending denial event for invite code: ${inviteCode.substring(0, 8)}...');

      // Publish using NdkService
      return await ndkService.publishGiftWrapEvent(
        content: denialJson,
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'invitation_denial_$inviteCode'],
          ['invite', inviteCode],
        ],
      );
    } catch (e) {
      Log.error('Error sending denial event', e);
      return null;
    }
  }

  /// Creates and publishes shard confirmation event
  ///
  /// Creates confirmation event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1342).
  /// Signs with key holder's private key.
  /// Publishes to relays.
  /// Returns event ID.
  Future<String?> sendShardConfirmationEvent({
    required String lockboxId,
    required int shardIndex,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
  }) async {
    try {
      final currentPubkey = await ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        Log.error('No key pair available for sending shard confirmation event');
        return null;
      }

      // Create shard confirmation event payload
      final confirmationData = {
        'type': 'shard_confirmation',
        'lockbox_id': lockboxId,
        'shard_index': shardIndex,
        'key_holder_pubkey': currentPubkey,
        'confirmed_at': DateTime.now().toIso8601String(),
      };

      final confirmationJson = json.encode(confirmationData);

      Log.info(
          'Sending shard confirmation event for lockbox: ${lockboxId.substring(0, 8)}..., shard: $shardIndex');

      // Publish using NdkService
      return await ndkService.publishGiftWrapEvent(
        content: confirmationJson,
        kind: NostrKind.shardConfirmation.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'shard_confirmation_${lockboxId}_$shardIndex'],
          ['lockbox_id', lockboxId],
          ['shard_index', shardIndex.toString()],
        ],
      );
    } catch (e) {
      Log.error('Error sending shard confirmation event', e);
      return null;
    }
  }

  /// Creates and publishes shard error event
  ///
  /// Creates error event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1343).
  /// Signs with key holder's private key.
  /// Publishes to relays.
  /// Returns event ID.
  Future<String?> sendShardErrorEvent({
    required String lockboxId,
    required int shardIndex,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
    required String error,
  }) async {
    try {
      final currentPubkey = await ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        Log.error('No key pair available for sending shard error event');
        return null;
      }

      // Create shard error event payload
      final errorData = {
        'type': 'shard_error',
        'lockbox_id': lockboxId,
        'shard_index': shardIndex,
        'key_holder_pubkey': currentPubkey,
        'error': error,
        'reported_at': DateTime.now().toIso8601String(),
      };

      final errorJson = json.encode(errorData);

      Log.warning(
          'Sending shard error event for lockbox: ${lockboxId.substring(0, 8)}..., shard: $shardIndex');

      // Publish using NdkService
      return await ndkService.publishGiftWrapEvent(
        content: errorJson,
        kind: NostrKind.shardError.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'shard_error_${lockboxId}_$shardIndex'],
          ['lockbox_id', lockboxId],
          ['shard_index', shardIndex.toString()],
        ],
      );
    } catch (e) {
      Log.error('Error sending shard error event', e);
      return null;
    }
  }

  /// Creates and publishes invitation invalid event
  ///
  /// Creates invalid event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1344).
  /// Signs with lockbox owner's private key.
  /// Publishes to relays.
  /// Returns event ID.
  Future<String?> sendInvitationInvalidEvent({
    required String inviteCode,
    required String inviteePubkey, // Hex format
    required List<String> relayUrls,
    required String reason,
  }) async {
    try {
      final currentPubkey = await ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        Log.error('No key pair available for sending invitation invalid event');
        return null;
      }

      // Create invitation invalid event payload
      final invalidData = {
        'type': 'invitation_invalid',
        'invite_code': inviteCode,
        'owner_pubkey': currentPubkey,
        'reason': reason,
        'invalidated_at': DateTime.now().toIso8601String(),
      };

      final invalidJson = json.encode(invalidData);

      Log.warning(
          'Sending invitation invalid event for invite code: ${inviteCode.substring(0, 8)}...');

      // Publish using NdkService
      return await ndkService.publishGiftWrapEvent(
        content: invalidJson,
        kind: NostrKind.invitationInvalid.value,
        recipientPubkey: inviteePubkey,
        relays: relayUrls,
        tags: [
          ['d', 'invitation_invalid_$inviteCode'],
          ['invite_code', inviteCode],
        ],
      );
    } catch (e) {
      Log.error('Error sending invitation invalid event', e);
      return null;
    }
  }
}
