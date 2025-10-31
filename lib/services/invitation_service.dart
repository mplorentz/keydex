import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invitation_link.dart';
import '../models/invitation_status.dart';
import '../models/invitation_exceptions.dart';
import '../models/key_holder.dart';
import '../models/backup_config.dart';
import '../models/nostr_kinds.dart';
import '../providers/lockbox_provider.dart';
import '../services/key_service.dart';
import '../services/logger.dart';
import '../utils/invite_code_utils.dart';
import '../utils/validators.dart';
import 'invitation_sending_service.dart';

/// Provider for InvitationService
final invitationServiceProvider = Provider<InvitationService>((ref) {
  final service = InvitationService(
    ref.read(lockboxRepositoryProvider),
    ref.read(invitationSendingServiceProvider),
  );

  // Properly clean up when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Service for managing invitation links and processing invitation-related events
class InvitationService {
  final LockboxRepository repository;
  final InvitationSendingService invitationSendingService;

  // Stream controller for notifying listeners when invitations change
  final StreamController<void> _invitationsChangedController = StreamController<void>.broadcast();

  // SharedPreferences keys
  static String _invitationKey(String inviteCode) => 'invitation_$inviteCode';
  static String _lockboxInvitationsKey(String lockboxId) => 'lockbox_invitations_$lockboxId';

  InvitationService(
    this.repository,
    this.invitationSendingService,
  );

  /// Stream that emits whenever invitations change
  /// UI providers listen to this to automatically update
  Stream<void> get invitationsChangedStream => _invitationsChangedController.stream;

  /// Notify listeners that invitations have changed
  void _notifyInvitationsChanged() {
    _invitationsChangedController.add(null);
  }

  /// Dispose of resources
  void dispose() {
    _invitationsChangedController.close();
  }

  /// Generates a new invitation link for a given invitee
  ///
  /// Validates lockbox exists and user is owner.
  /// Generates cryptographically secure invite code.
  /// Creates InvitationLink and stores in SharedPreferences.
  /// Returns invitation link with URL.
  Future<InvitationLink> generateInvitationLink({
    required String lockboxId,
    required String inviteeName,
    required List<String> relayUrls,
  }) async {
    // Validate inputs
    if (inviteeName.trim().isEmpty) {
      throw ArgumentError('Invitee name cannot be empty');
    }

    if (!areValidRelayUrls(relayUrls)) {
      throw ArgumentError('Invalid relay URLs: must be 1-3 valid WebSocket URLs');
    }

    // Get current user's pubkey
    final ownerPubkey = await KeyService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot generate invitation.');
    }

    // Validate lockbox exists and user is owner
    final lockbox = await repository.getLockbox(lockboxId);
    if (lockbox == null) {
      throw ArgumentError('Lockbox not found: $lockboxId');
    }

    if (lockbox.ownerPubkey != ownerPubkey) {
      throw ArgumentError('User is not the owner of this lockbox');
    }

    // Generate secure invite code
    final inviteCode = generateSecureInviteCode();

    // Create invitation link
    final invitation = createInvitationLink(
      inviteCode: inviteCode,
      lockboxId: lockboxId,
      ownerPubkey: ownerPubkey,
      relayUrls: relayUrls,
      inviteeName: inviteeName.trim(),
    );

    // Update status to pending (ready to be sent)
    final pendingInvitation = invitation.updateStatus(InvitationStatus.pending);

    // Validate the invitation
    validateInvitationLink(pendingInvitation);

    // Store invitation
    await _saveInvitation(pendingInvitation);

    // Add to lockbox invitations index
    await _addToLockboxIndex(lockboxId, inviteCode);

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Generated invitation link for lockbox $lockboxId, invitee: $inviteeName');

    return pendingInvitation;
  }

  /// Retrieves all pending invitations for a lockbox
  ///
  /// Loads invitations from SharedPreferences.
  /// Filters to pending status.
  /// Returns sorted by creation date.
  Future<List<InvitationLink>> getPendingInvitations(String lockboxId) async {
    // Get all invite codes for this lockbox
    final inviteCodes = await _getLockboxInviteCodes(lockboxId);

    // Load all invitations
    final invitations = <InvitationLink>[];
    for (final code in inviteCodes) {
      final invitation = await _loadInvitation(code);
      if (invitation != null) {
        invitations.add(invitation);
      }
    }

    // Filter to pending status and sort by creation date
    final pending = invitations.where((inv) => inv.status == InvitationStatus.pending).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return pending;
  }

  /// Looks up invitation details by invite code
  ///
  /// Looks up invitation code in SharedPreferences.
  /// Returns InvitationLink if found, null otherwise.
  Future<InvitationLink?> lookupInvitationByCode(String inviteCode) async {
    return await _loadInvitation(inviteCode);
  }

  /// Processes invitation redemption when invitee accepts
  ///
  /// Validates invite code exists and is pending.
  /// Checks if already redeemed.
  /// Updates invitation status to redeemed.
  /// Adds invitee to backup config as key holder.
  /// Sends RSVP event via InvitationSendingService.
  /// Updates invitation tracking.
  Future<void> redeemInvitation({
    required String inviteCode,
    required String inviteePubkey, // Hex format
  }) async {
    // Validate invitee pubkey format
    if (!isValidHexPubkey(inviteePubkey)) {
      throw ArgumentError('Invalid invitee pubkey format: must be 64 hex characters');
    }

    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      throw InvitationNotFoundException(inviteCode);
    }

    // Validate invitation status
    if (invitation.status == InvitationStatus.redeemed) {
      throw InvitationAlreadyRedeemedException(inviteCode);
    }

    if (invitation.status == InvitationStatus.invalidated) {
      throw InvitationInvalidatedException(inviteCode, 'Invitation has been invalidated');
    }

    if (!invitation.status.canRedeem) {
      throw ArgumentError('Invitation cannot be redeemed in current status: ${invitation.status}');
    }

    // Check if user is already a key holder
    final backupConfig = await repository.getBackupConfig(invitation.lockboxId);
    final isAlreadyKeyHolder =
        backupConfig?.keyHolders.any((holder) => holder.pubkey == inviteePubkey) ?? false;

    if (isAlreadyKeyHolder) {
      Log.warning(
          'Invitee $inviteePubkey is already a key holder for lockbox ${invitation.lockboxId}');
      // Still mark invitation as redeemed to prevent duplicate processing
      final redeemedInvitation = invitation.updateStatus(
        InvitationStatus.redeemed,
        redeemedBy: inviteePubkey,
        redeemedAt: DateTime.now(),
      );
      await _saveInvitation(redeemedInvitation);
      _notifyInvitationsChanged();
      return;
    }

    // Update invitation status to redeemed
    final redeemedInvitation = invitation.updateStatus(
      InvitationStatus.redeemed,
      redeemedBy: inviteePubkey,
      redeemedAt: DateTime.now(),
    );
    await _saveInvitation(redeemedInvitation);

    // Add invitee to backup config as key holder
    await _addKeyHolderToBackupConfig(
      invitation.lockboxId,
      inviteePubkey,
      invitation.inviteeName,
    );

    // Send RSVP event
    try {
      await invitationSendingService.sendRsvpEvent(
        inviteCode: inviteCode,
        ownerPubkey: invitation.ownerPubkey,
        relayUrls: invitation.relayUrls,
      );
    } catch (e) {
      Log.error('Error sending RSVP event for invitation $inviteCode', e);
      // Don't fail the redemption if event sending fails - invitation is already redeemed
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Redeemed invitation $inviteCode by invitee $inviteePubkey');
  }

  /// Processes invitation denial when invitee declines
  ///
  /// Validates invite code exists and is pending.
  /// Updates invitation status to denied.
  /// Sends denial event via InvitationSendingService.
  /// Invalidates invitation code.
  Future<void> denyInvitation({
    required String inviteCode,
    String? reason,
  }) async {
    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      throw InvitationNotFoundException(inviteCode);
    }

    // Validate invitation status
    if (!invitation.status.canRedeem) {
      throw ArgumentError('Invitation cannot be denied in current status: ${invitation.status}');
    }

    // Update invitation status to denied
    final deniedInvitation = invitation.updateStatus(InvitationStatus.denied);
    await _saveInvitation(deniedInvitation);

    // Send denial event
    try {
      await invitationSendingService.sendDenialEvent(
        inviteCode: inviteCode,
        ownerPubkey: invitation.ownerPubkey,
        relayUrls: invitation.relayUrls,
        reason: reason,
      );
    } catch (e) {
      Log.error('Error sending denial event for invitation $inviteCode', e);
      // Don't fail if event sending fails - invitation is already denied
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Denied invitation $inviteCode${reason != null ? ", reason: $reason" : ""}');
  }

  /// Invalidates an invitation (e.g., when invitee removed from backup config)
  ///
  /// Updates invitation status to invalidated.
  /// Sends invalid event via InvitationSendingService if invitee already accepted.
  /// Removes invitation from tracking.
  Future<void> invalidateInvitation({
    required String inviteCode,
    required String reason,
  }) async {
    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      throw InvitationNotFoundException(inviteCode);
    }

    // Update invitation status to invalidated
    final invalidatedInvitation = invitation.updateStatus(InvitationStatus.invalidated);
    await _saveInvitation(invalidatedInvitation);

    // If invitation was already redeemed, send invalid event to notify invitee
    if (invitation.status == InvitationStatus.redeemed && invitation.redeemedBy != null) {
      try {
        await invitationSendingService.sendInvitationInvalidEvent(
          inviteCode: inviteCode,
          inviteePubkey: invitation.redeemedBy!,
          relayUrls: invitation.relayUrls,
          reason: reason,
        );
      } catch (e) {
        Log.error('Error sending invalid event for invitation $inviteCode', e);
        // Don't fail if event sending fails
      }
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Invalidated invitation $inviteCode, reason: $reason');
  }

  /// Processes RSVP event received from invitee
  ///
  /// Decrypts event content using NIP-44.
  /// Validates invite code and invitee pubkey.
  /// Updates invitation status to redeemed.
  /// Adds invitee to backup config if not already present.
  /// Updates key holder status to "awaiting key".
  Future<void> processRsvpEvent({
    required Nip01Event event,
  }) async {
    // Validate event kind
    if (event.kind != NostrKind.invitationRsvp.value) {
      throw ArgumentError(
          'Invalid event kind: expected ${NostrKind.invitationRsvp.value}, got ${event.kind}');
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await KeyService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process RSVP event.');
    }

    // Extract invite code from tags
    final inviteCode = _extractTagValue(event.tags, 'invite');
    if (inviteCode == null) {
      throw ArgumentError('Missing invite tag in RSVP event');
    }

    // Verify we're the recipient (p tag should be owner)
    final recipientPubkey = _extractTagValue(event.tags, 'p');
    if (recipientPubkey != ownerPubkey) {
      throw ArgumentError('RSVP event not addressed to current user');
    }

    // Decrypt event content
    String decryptedContent;
    try {
      decryptedContent = await KeyService.decryptFromSender(
        encryptedText: event.content,
        senderPubkey: event.pubKey,
      );
    } catch (e) {
      Log.error('Error decrypting RSVP event content', e);
      throw Exception('Failed to decrypt RSVP event content: $e');
    }

    // Parse decrypted JSON
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(decryptedContent) as Map<String, dynamic>;
    } catch (e) {
      Log.error('Error parsing RSVP event JSON', e);
      throw Exception('Invalid JSON in RSVP event content: $e');
    }

    // Validate payload
    final payloadInviteCode = payload['inviteCode'] as String?;
    final inviteePubkey = payload['pubkey'] as String?;

    if (payloadInviteCode != inviteCode) {
      throw ArgumentError('Invite code mismatch in RSVP event payload');
    }

    if (inviteePubkey == null || !isValidHexPubkey(inviteePubkey)) {
      throw ArgumentError('Invalid invitee pubkey in RSVP event payload');
    }

    if (inviteePubkey != event.pubKey) {
      throw ArgumentError('Invitee pubkey mismatch: event pubkey != payload pubkey');
    }

    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      Log.warning('RSVP event received for unknown invitation: $inviteCode');
      return; // Silently ignore if invitation not found
    }

    // Update invitation status to redeemed
    final redeemedInvitation = invitation.updateStatus(
      InvitationStatus.redeemed,
      redeemedBy: inviteePubkey,
      redeemedAt: DateTime.now(),
    );
    await _saveInvitation(redeemedInvitation);

    // Add invitee to backup config if not already present
    await _addKeyHolderToBackupConfig(
      invitation.lockboxId,
      inviteePubkey,
      invitation.inviteeName,
    );

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Processed RSVP event for invitation $inviteCode from invitee $inviteePubkey');
  }

  /// Processes denial event received from invitee
  ///
  /// Decrypts event content using NIP-44.
  /// Validates invite code.
  /// Updates invitation status to denied.
  /// Invalidates invitation code.
  Future<void> processDenialEvent({
    required Nip01Event event,
  }) async {
    // Validate event kind
    if (event.kind != NostrKind.invitationDenial.value) {
      throw ArgumentError(
          'Invalid event kind: expected ${NostrKind.invitationDenial.value}, got ${event.kind}');
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await KeyService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process denial event.');
    }

    // Extract invite code from tags
    final inviteCode = _extractTagValue(event.tags, 'invite');
    if (inviteCode == null) {
      throw ArgumentError('Missing invite tag in denial event');
    }

    // Verify we're the recipient (p tag should be owner)
    final recipientPubkey = _extractTagValue(event.tags, 'p');
    if (recipientPubkey != ownerPubkey) {
      throw ArgumentError('Denial event not addressed to current user');
    }

    // Decrypt event content
    String decryptedContent;
    try {
      decryptedContent = await KeyService.decryptFromSender(
        encryptedText: event.content,
        senderPubkey: event.pubKey,
      );
    } catch (e) {
      Log.error('Error decrypting denial event content', e);
      throw Exception('Failed to decrypt denial event content: $e');
    }

    // Parse decrypted JSON
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(decryptedContent) as Map<String, dynamic>;
    } catch (e) {
      Log.error('Error parsing denial event JSON', e);
      throw Exception('Invalid JSON in denial event content: $e');
    }

    // Validate payload
    final payloadInviteCode = payload['inviteCode'] as String?;
    if (payloadInviteCode != inviteCode) {
      throw ArgumentError('Invite code mismatch in denial event payload');
    }

    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      Log.warning('Denial event received for unknown invitation: $inviteCode');
      return; // Silently ignore if invitation not found
    }

    // Update invitation status to denied
    final deniedInvitation = invitation.updateStatus(InvitationStatus.denied);
    await _saveInvitation(deniedInvitation);

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Processed denial event for invitation $inviteCode');
  }

  // ========== Storage Helper Methods ==========

  /// Save an invitation to SharedPreferences
  Future<void> _saveInvitation(InvitationLink invitation) async {
    final prefs = await SharedPreferences.getInstance();
    final json = invitationLinkToJson(invitation);
    final jsonString = jsonEncode(json);

    await prefs.setString(_invitationKey(invitation.inviteCode), jsonString);
    Log.debug('Saved invitation ${invitation.inviteCode} to SharedPreferences');
  }

  /// Load an invitation from SharedPreferences
  Future<InvitationLink?> _loadInvitation(String inviteCode) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_invitationKey(inviteCode));

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return invitationLinkFromJson(json);
    } catch (e) {
      Log.error('Error loading invitation $inviteCode', e);
      return null;
    }
  }

  /// Add invite code to lockbox invitations index
  Future<void> _addToLockboxIndex(String lockboxId, String inviteCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _lockboxInvitationsKey(lockboxId);

    final existingCodes = prefs.getStringList(key) ?? [];
    if (!existingCodes.contains(inviteCode)) {
      existingCodes.add(inviteCode);
      await prefs.setStringList(key, existingCodes);
      Log.debug('Added invite code $inviteCode to lockbox $lockboxId index');
    }
  }

  /// Get all invite codes for a lockbox
  Future<List<String>> _getLockboxInviteCodes(String lockboxId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _lockboxInvitationsKey(lockboxId);
    return prefs.getStringList(key) ?? [];
  }

  /// Add a key holder to backup config (or create config if it doesn't exist)
  Future<void> _addKeyHolderToBackupConfig(
    String lockboxId,
    String pubkey,
    String name,
  ) async {
    var backupConfig = await repository.getBackupConfig(lockboxId);

    if (backupConfig == null) {
      // Create new backup config with this key holder
      // We'll use default values - owner can adjust later
      final newKeyHolder = createKeyHolder(pubkey: pubkey, name: name);
      backupConfig = createBackupConfig(
        lockboxId: lockboxId,
        threshold: 2, // Default threshold
        totalKeys: 1, // Will be updated when more key holders are added
        keyHolders: [newKeyHolder],
        relays: [], // Will be populated from invitation relayUrls if needed
      );
      await repository.updateBackupConfig(lockboxId, backupConfig);
      Log.info('Created new backup config for lockbox $lockboxId with key holder $pubkey');
    } else {
      // Check if key holder already exists
      final exists = backupConfig.keyHolders.any((holder) => holder.pubkey == pubkey);
      if (exists) {
        Log.debug('Key holder $pubkey already exists in backup config');
        return;
      }

      // Add new key holder and update totalKeys
      final newKeyHolder = createKeyHolder(pubkey: pubkey, name: name);
      final updatedKeyHolders = [...backupConfig.keyHolders, newKeyHolder];
      final updatedConfig = copyBackupConfig(
        backupConfig,
        keyHolders: updatedKeyHolders,
        totalKeys: updatedKeyHolders.length,
        lastUpdated: DateTime.now(),
      );
      await repository.updateBackupConfig(lockboxId, updatedConfig);
      Log.info('Added key holder $pubkey to backup config for lockbox $lockboxId');
    }
  }

  /// Extract a tag value from event tags
  ///
  /// Returns the value of the first tag matching the given name, or null if not found.
  /// Tags are formatted as [name, value] or [name, value, ...].
  String? _extractTagValue(List<List<String>> tags, String tagName) {
    for (final tag in tags) {
      if (tag.isNotEmpty && tag[0] == tagName) {
        return tag.length > 1 ? tag[1] : null;
      }
    }
    return null;
  }
}
