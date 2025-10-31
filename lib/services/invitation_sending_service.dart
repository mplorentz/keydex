import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ndk_service.dart';

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
    // Stub: Non-functional for now
    throw UnimplementedError('sendRsvpEvent not yet implemented');
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
    // Stub: Non-functional for now
    throw UnimplementedError('sendDenialEvent not yet implemented');
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
    // Stub: Non-functional for now
    throw UnimplementedError('sendShardConfirmationEvent not yet implemented');
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
    // Stub: Non-functional for now
    throw UnimplementedError('sendShardErrorEvent not yet implemented');
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
    // Stub: Non-functional for now
    throw UnimplementedError('sendInvitationInvalidEvent not yet implemented');
  }
}
