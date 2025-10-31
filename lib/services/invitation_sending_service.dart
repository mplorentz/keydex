import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../services/ndk_service.dart';
import '../services/login_service.dart';
import '../providers/key_provider.dart';
import '../services/logger.dart';
import '../models/nostr_kinds.dart';

/// Provider for InvitationSendingService
final invitationSendingServiceProvider = Provider<InvitationSendingService>((ref) {
  return InvitationSendingService(
    ref.read(ndkServiceProvider),
    ref.read(loginServiceProvider),
  );
});

/// Stateless utility service for creating and publishing outgoing invitation-related Nostr events
///
/// This service handles only outgoing event creation and publishing, with no local state or storage.
/// All methods are pure functions that create and publish events.
class InvitationSendingService {
  final NdkService ndkService;
  final LoginService loginService;

  InvitationSendingService(this.ndkService, this.loginService);

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
      // Get current user's keys
      final keyPair = await loginService.getStoredNostrKey();
      final currentPubkey = keyPair?.publicKey;
      final currentPrivkey = keyPair?.privateKey;

      if (currentPubkey == null || currentPrivkey == null) {
        Log.error('No key pair available for sending RSVP event');
        return null;
      }

      // Initialize NDK
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: currentPubkey, privkey: currentPrivkey);

      // Create RSVP event payload
      final rsvpData = {
        'type': 'invitation_rsvp',
        'invite_code': inviteCode,
        'invitee_pubkey': currentPubkey,
        'responded_at': DateTime.now().toIso8601String(),
      };

      final rsvpJson = json.encode(rsvpData);

      Log.info('Sending RSVP event for invite code: ${inviteCode.substring(0, 8)}...');

      // Create rumor event with RSVP data
      final rumor = await ndk.giftWrap.createRumor(
        customPubkey: currentPubkey,
        content: rsvpJson,
        kind: NostrKind.invitationRsvp.value,
        tags: [
          ['d', 'invitation_rsvp_$inviteCode'],
          ['invite_code', inviteCode],
        ],
      );

      // Wrap the rumor in a gift wrap for the owner
      final giftWrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: ownerPubkey,
      );

      // Broadcast the gift wrap event
      ndk.broadcast.broadcast(
        nostrEvent: giftWrap,
        specificRelays: relayUrls,
      );

      Log.info('Sent RSVP event (event: ${giftWrap.id.substring(0, 8)}...)');
      return giftWrap.id;
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
      // Get current user's keys
      final keyPair = await loginService.getStoredNostrKey();
      final currentPubkey = keyPair?.publicKey;
      final currentPrivkey = keyPair?.privateKey;

      if (currentPubkey == null || currentPrivkey == null) {
        Log.error('No key pair available for sending denial event');
        return null;
      }

      // Initialize NDK
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: currentPubkey, privkey: currentPrivkey);

      // Create denial event payload
      final denialData = {
        'type': 'invitation_denial',
        'invite_code': inviteCode,
        'invitee_pubkey': currentPubkey,
        'responded_at': DateTime.now().toIso8601String(),
      };

      if (reason != null && reason.isNotEmpty) {
        denialData['reason'] = reason;
      }

      final denialJson = json.encode(denialData);

      Log.info('Sending denial event for invite code: ${inviteCode.substring(0, 8)}...');

      // Create rumor event with denial data
      final rumor = await ndk.giftWrap.createRumor(
        customPubkey: currentPubkey,
        content: denialJson,
        kind: NostrKind.invitationDenial.value,
        tags: [
          ['d', 'invitation_denial_$inviteCode'],
          ['invite_code', inviteCode],
        ],
      );

      // Wrap the rumor in a gift wrap for the owner
      final giftWrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: ownerPubkey,
      );

      // Broadcast the gift wrap event
      ndk.broadcast.broadcast(
        nostrEvent: giftWrap,
        specificRelays: relayUrls,
      );

      Log.info('Sent denial event (event: ${giftWrap.id.substring(0, 8)}...)');
      return giftWrap.id;
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
      // Get current user's keys
      final keyPair = await loginService.getStoredNostrKey();
      final currentPubkey = keyPair?.publicKey;
      final currentPrivkey = keyPair?.privateKey;

      if (currentPubkey == null || currentPrivkey == null) {
        Log.error('No key pair available for sending shard confirmation event');
        return null;
      }

      // Initialize NDK
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: currentPubkey, privkey: currentPrivkey);

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

      // Create rumor event with confirmation data
      final rumor = await ndk.giftWrap.createRumor(
        customPubkey: currentPubkey,
        content: confirmationJson,
        kind: NostrKind.shardConfirmation.value,
        tags: [
          ['d', 'shard_confirmation_${lockboxId}_$shardIndex'],
          ['lockbox_id', lockboxId],
          ['shard_index', shardIndex.toString()],
        ],
      );

      // Wrap the rumor in a gift wrap for the owner
      final giftWrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: ownerPubkey,
      );

      // Broadcast the gift wrap event
      ndk.broadcast.broadcast(
        nostrEvent: giftWrap,
        specificRelays: relayUrls,
      );

      Log.info('Sent shard confirmation event (event: ${giftWrap.id.substring(0, 8)}...)');
      return giftWrap.id;
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
      // Get current user's keys
      final keyPair = await loginService.getStoredNostrKey();
      final currentPubkey = keyPair?.publicKey;
      final currentPrivkey = keyPair?.privateKey;

      if (currentPubkey == null || currentPrivkey == null) {
        Log.error('No key pair available for sending shard error event');
        return null;
      }

      // Initialize NDK
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: currentPubkey, privkey: currentPrivkey);

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

      // Create rumor event with error data
      final rumor = await ndk.giftWrap.createRumor(
        customPubkey: currentPubkey,
        content: errorJson,
        kind: NostrKind.shardError.value,
        tags: [
          ['d', 'shard_error_${lockboxId}_$shardIndex'],
          ['lockbox_id', lockboxId],
          ['shard_index', shardIndex.toString()],
        ],
      );

      // Wrap the rumor in a gift wrap for the owner
      final giftWrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: ownerPubkey,
      );

      // Broadcast the gift wrap event
      ndk.broadcast.broadcast(
        nostrEvent: giftWrap,
        specificRelays: relayUrls,
      );

      Log.info('Sent shard error event (event: ${giftWrap.id.substring(0, 8)}...)');
      return giftWrap.id;
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
      // Get current user's keys (lockbox owner)
      final keyPair = await loginService.getStoredNostrKey();
      final currentPubkey = keyPair?.publicKey;
      final currentPrivkey = keyPair?.privateKey;

      if (currentPubkey == null || currentPrivkey == null) {
        Log.error('No key pair available for sending invitation invalid event');
        return null;
      }

      // Initialize NDK
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(pubkey: currentPubkey, privkey: currentPrivkey);

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

      // Create rumor event with invalid data
      final rumor = await ndk.giftWrap.createRumor(
        customPubkey: currentPubkey,
        content: invalidJson,
        kind: NostrKind.invitationInvalid.value,
        tags: [
          ['d', 'invitation_invalid_$inviteCode'],
          ['invite_code', inviteCode],
        ],
      );

      // Wrap the rumor in a gift wrap for the invitee
      final giftWrap = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: inviteePubkey,
      );

      // Broadcast the gift wrap event
      ndk.broadcast.broadcast(
        nostrEvent: giftWrap,
        specificRelays: relayUrls,
      );

      Log.info('Sent invitation invalid event (event: ${giftWrap.id.substring(0, 8)}...)');
      return giftWrap.id;
    } catch (e) {
      Log.error('Error sending invitation invalid event', e);
      return null;
    }
  }
}
