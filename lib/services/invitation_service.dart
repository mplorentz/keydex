import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invitation_link.dart';
import '../models/invitation_status.dart';
import '../models/invitation_exceptions.dart';
import '../models/key_holder.dart';
import '../models/key_holder_status.dart';
import '../models/backup_config.dart';
import '../models/lockbox.dart';
import '../models/nostr_kinds.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../services/login_service.dart';
import '../services/logger.dart';
import '../utils/invite_code_utils.dart';
import '../utils/validators.dart';
import 'invitation_sending_service.dart';
import 'ndk_service.dart';

/// Provider for InvitationService
final invitationServiceProvider = Provider<InvitationService>((ref) {
  final service = InvitationService(
    ref.read(lockboxRepositoryProvider),
    ref.read(invitationSendingServiceProvider),
    ref.read(loginServiceProvider),
    () => ref.read(ndkServiceProvider),
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
  final LoginService _loginService;
  final NdkService Function() _getNdkService;

  // Stream controller for notifying listeners when invitations change
  final StreamController<void> _invitationsChangedController = StreamController<void>.broadcast();

  // SharedPreferences keys
  static String _invitationKey(String inviteCode) => 'invitation_$inviteCode';
  static String _lockboxInvitationsKey(String lockboxId) => 'lockbox_invitations_$lockboxId';

  InvitationService(
    this.repository,
    this.invitationSendingService,
    this._loginService,
    this._getNdkService,
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
    final ownerPubkey = await _loginService.getCurrentPublicKey();
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
    final inviteCode = generateSecureID();

    // Create invitation link
    final invitation = createInvitationLink(
      inviteCode: inviteCode,
      lockboxId: lockboxId,
      lockboxName: lockbox.name,
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

    // Ensure relay URLs are added to NDK service so we can receive RSVP events
    // Add relays asynchronously - don't fail invitation generation if relay addition fails
    _addRelaysToNdk(relayUrls);

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

  /// Creates an invitation record when received via deep link
  ///
  /// This is called when an invitee opens an invitation link.
  /// Creates a local invitation record so it can be displayed and processed.
  /// If the invitation already exists, updates it with the latest data.
  Future<void> createReceivedInvitation({
    required String inviteCode,
    required String lockboxId,
    required String ownerPubkey,
    required List<String> relayUrls,
    String? lockboxName,
  }) async {
    // Check if invitation already exists
    final existing = await _loadInvitation(inviteCode);
    if (existing != null) {
      Log.debug('Invitation $inviteCode already exists, skipping creation');
      return;
    }

    // Create invitation record from received link data
    // Note: inviteeName is not known on the receiving side, so we pass null
    final invitation = createInvitationLink(
      inviteCode: inviteCode,
      lockboxId: lockboxId,
      lockboxName: lockboxName,
      ownerPubkey: ownerPubkey,
      relayUrls: relayUrls,
      inviteeName: null, // Not available on receiving side
    );

    // Set status to pending (awaiting acceptance)
    final pendingInvitation = invitation.updateStatus(InvitationStatus.pending);

    // Validate the invitation
    validateInvitationLink(pendingInvitation);

    // Store invitation locally
    await _saveInvitation(pendingInvitation);

    // Note: We don't add to lockbox invitations index on the receiving side
    // because the invitee doesn't own the lockbox - that index is owner-only

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Created received invitation record for inviteCode=$inviteCode, lockboxId=$lockboxId');
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
    // Note: On the invitee side, the lockbox may not exist yet, so we check if it exists first
    final lockbox = await repository.getLockbox(invitation.lockboxId);
    if (lockbox != null) {
      final backupConfig = lockbox.backupConfig;
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

      // Lockbox exists - add invitee to backup config
      // This happens on the owner's side when they accept their own invitation
      await _addKeyHolderToBackupConfig(
        invitation.lockboxId,
        inviteePubkey,
        invitation.inviteeName, // Can be null for received invitations
        invitation.relayUrls,
      );
    } else {
      // Lockbox doesn't exist yet - this is the invitee side
      // Create a lockbox stub so invitee can see it in their list
      final lockboxStub = Lockbox(
        id: invitation.lockboxId,
        name: invitation.lockboxName,
        content: null, // No content yet - waiting for shard
        createdAt: invitation.createdAt,
        ownerPubkey: invitation.ownerPubkey,
        shards: [], // No shards yet - awaiting key distribution
        backupConfig: null,
      );

      await repository.addLockbox(lockboxStub);
      Log.info(
          'Created lockbox stub for invitee: ${invitation.lockboxId} (${invitation.lockboxName})');
    }

    // Update invitation status to redeemed
    final redeemedInvitation = invitation.updateStatus(
      InvitationStatus.redeemed,
      redeemedBy: inviteePubkey,
      redeemedAt: DateTime.now(),
    );
    await _saveInvitation(redeemedInvitation);

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
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process RSVP event.');
    }

    // Parse the RSVP data from the unwrapped content (already decrypted by NDK)
    Map<String, dynamic> payload;
    try {
      Log.debug('RSVP event content: ${event.content}');
      payload = json.decode(event.content) as Map<String, dynamic>;
      Log.debug('RSVP event payload keys: ${payload.keys.toList()}');
    } catch (e) {
      Log.error('Error parsing RSVP event JSON', e);
      throw Exception('Invalid JSON in RSVP event content: $e');
    }

    // Extract invite code from payload
    final inviteCode = payload['invite_code'] as String?;
    if (inviteCode == null) {
      throw ArgumentError('Missing invite_code in RSVP event payload');
    }

    // Extract invitee pubkey from payload
    final inviteePubkey = payload['invitee_pubkey'] as String?;
    if (inviteePubkey == null || !isValidHexPubkey(inviteePubkey)) {
      throw ArgumentError('Invalid invitee_pubkey in RSVP event payload');
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
    // This will update invited key holders or add new ones
    await _addKeyHolderToBackupConfig(
      invitation.lockboxId,
      inviteePubkey,
      invitation.inviteeName, // Can be null for received invitations
      invitation.relayUrls, // Pass relay URLs from invitation
      inviteCode: inviteCode, // Pass invite code for matching
    );

    // Also update status to awaitingKey if key holder already exists with invited status
    // This handles the case where the key holder was added to the backup config
    // but the UI hasn't saved yet
    try {
      final backupConfig = await repository.getBackupConfig(invitation.lockboxId);
      if (backupConfig != null) {
        final keyHolderIndex = backupConfig.keyHolders.indexWhere(
          (holder) => holder.pubkey == inviteePubkey,
        );
        if (keyHolderIndex != -1) {
          final holder = backupConfig.keyHolders[keyHolderIndex];
          if (holder.status == KeyHolderStatus.invited) {
            // Update status to awaitingKey
            final updatedKeyHolders = List<KeyHolder>.from(backupConfig.keyHolders);
            updatedKeyHolders[keyHolderIndex] = copyKeyHolder(
              holder,
              status: KeyHolderStatus.awaitingKey,
            );
            final updatedConfig = copyBackupConfig(
              backupConfig,
              keyHolders: updatedKeyHolders,
              lastUpdated: DateTime.now(),
            );
            await repository.updateBackupConfig(invitation.lockboxId, updatedConfig);
            Log.info('Updated key holder $inviteePubkey status from invited to awaitingKey');
          }
        }
      }
    } catch (e) {
      Log.warning('Error updating key holder status after RSVP: $e');
      // Don't fail RSVP processing if status update fails
    }

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
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process denial event.');
    }

    // Parse the denial data from the unwrapped content (already decrypted by NDK)
    Map<String, dynamic> payload;
    try {
      Log.debug('Denial event content: ${event.content}');
      payload = json.decode(event.content) as Map<String, dynamic>;
      Log.debug('Denial event payload keys: ${payload.keys.toList()}');
    } catch (e) {
      Log.error('Error parsing denial event JSON', e);
      throw Exception('Invalid JSON in denial event content: $e');
    }

    // Extract invite code from payload
    final inviteCode = payload['invite_code'] as String?;
    if (inviteCode == null) {
      throw ArgumentError('Missing invite_code in denial event payload');
    }

    // Extract invitee pubkey from payload (optional for denial)
    final inviteePubkey = payload['invitee_pubkey'] as String?;
    if (inviteePubkey != null && !isValidHexPubkey(inviteePubkey)) {
      throw ArgumentError('Invalid invitee_pubkey in denial event payload');
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
  ///
  /// When an RSVP is received:
  /// - If a key holder with this pubkey already exists, do nothing
  /// - If a key holder with matching inviteCode exists but no pubkey (invited status),
  ///   update it with the pubkey and change status to awaitingKey
  /// - Otherwise, add a new key holder
  Future<void> _addKeyHolderToBackupConfig(
    String lockboxId,
    String pubkey,
    String? name, // Can be null for received invitations
    List<String> relayUrls, {
    String? inviteCode, // Invite code for matching invited key holders
  }) async {
    var backupConfig = await repository.getBackupConfig(lockboxId);

    if (backupConfig == null) {
      // Create new backup config with this key holder
      // We'll use default values - owner can adjust later
      final newKeyHolder = createKeyHolder(pubkey: pubkey, name: name);
      backupConfig = createBackupConfig(
        lockboxId: lockboxId,
        threshold: 1, // Start with 1-of-1, will be updated when more key holders are added
        totalKeys: 1, // Will be updated when more key holders are added
        keyHolders: [newKeyHolder],
        relays: relayUrls, // Use relay URLs from invitation
      );
      await repository.updateBackupConfig(lockboxId, backupConfig);
      Log.info('Created new backup config for lockbox $lockboxId with key holder $pubkey');
    } else {
      // FIRST: Check if there's an invited key holder (no pubkey) with matching invite code
      // This must be checked BEFORE checking for existing pubkey, otherwise we'll miss
      // updating invited key holders when RSVP comes in
      if (inviteCode != null) {
        Log.debug('Looking for invited key holder with invite code: "$inviteCode"');

        final invitedHolderIndex = backupConfig.keyHolders.indexWhere(
          (holder) =>
              holder.inviteCode == inviteCode &&
              holder.pubkey == null &&
              holder.status == KeyHolderStatus.invited,
        );

        if (invitedHolderIndex != -1) {
          // Update the invited key holder with pubkey and change status to awaitingKey
          final updatedKeyHolders = List<KeyHolder>.from(backupConfig.keyHolders);
          updatedKeyHolders[invitedHolderIndex] = copyKeyHolder(
            updatedKeyHolders[invitedHolderIndex],
            pubkey: pubkey,
            status: KeyHolderStatus.awaitingKey,
            // Keep inviteCode for reference, but it's no longer needed after acceptance
          );

          final updatedConfig = copyBackupConfig(
            backupConfig,
            keyHolders: updatedKeyHolders,
            lastUpdated: DateTime.now(),
          );
          await repository.updateBackupConfig(lockboxId, updatedConfig);
          Log.info(
              'Updated invited key holder with invite code "$inviteCode" - added pubkey $pubkey and changed status to awaitingKey');
          return;
        } else {
          Log.debug('No invited key holder found with invite code "$inviteCode"');
        }
      } else {
        Log.debug('No invite code provided, skipping invited key holder check');
      }

      // SECOND: Check if key holder with this pubkey already exists
      final existingByPubkey =
          backupConfig.keyHolders.where((holder) => holder.pubkey == pubkey).toList();
      if (existingByPubkey.isNotEmpty) {
        // Check if this key holder needs status update (e.g., was invited, now accepting)
        final existingHolder = existingByPubkey.first;
        if (existingHolder.status == KeyHolderStatus.invited ||
            existingHolder.status == KeyHolderStatus.awaitingKey) {
          // Status is already appropriate or will be updated elsewhere
          Log.debug(
              'Key holder $pubkey already exists in backup config with status ${existingHolder.status}');
        } else {
          Log.debug('Key holder $pubkey already exists in backup config');
        }
        return;
      }

      // THIRD: Add new key holder and update totalKeys
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

  /// Add relay URLs to NDK service so we can receive RSVP events
  ///
  /// This is called when an invitation is generated to ensure the owner
  /// is listening on the relays where the invitee will send RSVP events.
  Future<void> _addRelaysToNdk(List<String> relayUrls) async {
    try {
      final ndkService = _getNdkService();
      for (final relayUrl in relayUrls) {
        try {
          await ndkService.addRelay(relayUrl);
          Log.info('Added relay to NDK for invitation listening: $relayUrl');
        } catch (e) {
          Log.warning('Failed to add relay $relayUrl to NDK: $e');
          // Continue with other relays even if one fails
        }
      }
    } catch (e) {
      Log.error('Error accessing NDK service to add relays', e);
      // Don't fail invitation generation if relay addition fails
    }
  }
}
