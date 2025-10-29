# Service Interfaces: Invitation Links for Key Holders

**Feature**: 004-invitation-links  
**Date**: 2025-01-27

## Overview

This document defines the service interfaces for the invitation links feature. Services follow the existing Keydex pattern of abstracting business logic behind providers and using repositories for data persistence.

## InvitationService

Primary service for managing invitation links and processing invitation-related events.

### Location
`lib/services/invitation_service.dart`

### Dependencies
- `LockboxRepository` - For accessing lockbox and backup config data
- `SharedPreferences` - For storing invitation codes and tracking
- `NdkService` - For publishing Nostr events
- `KeyService` - For encryption/decryption operations

### Methods

#### generateInvitationLink

Generates a new invitation link for a given invitee.

```dart
Future<InvitationLink> generateInvitationLink({
  required String lockboxId,
  required String inviteeName,
  required List<String> relayUrls,
}) async {
  // Validates lockbox exists and user is owner
  // Generates cryptographically secure invite code
  // Creates InvitationLink and InvitationCode records
  // Stores in SharedPreferences
  // Returns invitation link with URL
}
```

**Preconditions**:
- Lockbox must exist
- Current user must be lockbox owner
- `inviteeName` must not be empty
- `relayUrls` must be valid WebSocket URLs (1-3)

**Postconditions**:
- Invitation link created and stored
- Invitation code lookup entry created
- Returns InvitationLink with generated URL

**Error Cases**:
- `LockboxNotFoundException` - Lockbox doesn't exist
- `UnauthorizedException` - User is not lockbox owner
- `InvalidArgumentException` - Invalid invitee name or relay URLs

#### getPendingInvitations

Retrieves all pending invitations for a lockbox.

```dart
Future<List<InvitationLink>> getPendingInvitations(String lockboxId) async {
  // Loads invitations from SharedPreferences
  // Filters to pending status
  // Returns sorted by creation date
}
```

**Returns**: List of pending InvitationLink records

#### lookupInvitationCode

Looks up invitation details by invite code.

```dart
Future<InvitationCode?> lookupInvitationCode(String inviteCode) async {
  // Looks up invitation code in SharedPreferences
  // Returns InvitationCode if found, null otherwise
}
```

**Returns**: InvitationCode if found, null otherwise

#### redeemInvitation

Processes invitation redemption when invitee accepts.

```dart
Future<void> redeemInvitation({
  required String inviteCode,
  required String inviteePubkey, // Hex format
}) async {
  // Validates invite code exists and is pending
  // Checks if already redeemed
  // Updates invitation status to redeemed
  // Adds invitee to backup config as key holder
  // Publishes RSVP event to lockbox owner
  // Updates invitation tracking
}
```

**Preconditions**:
- Invite code must exist
- Invite code must be in pending status
- Invitee pubkey must be valid hex format

**Postconditions**:
- Invitation status updated to redeemed
- Invitee added to backup config key holders
- RSVP event published to Nostr relays
- Key holder status set to "awaiting key"

**Error Cases**:
- `InvitationNotFoundException` - Invite code not found
- `InvitationAlreadyRedeemedException` - Code already used
- `InvitationInvalidatedException` - Code invalidated
- `InvalidPubkeyException` - Invalid invitee pubkey format

#### denyInvitation

Processes invitation denial when invitee declines.

```dart
Future<void> denyInvitation({
  required String inviteCode,
  String? reason,
}) async {
  // Validates invite code exists and is pending
  // Updates invitation status to denied
  // Publishes denial event to lockbox owner
  // Invalidates invitation code
}
```

**Preconditions**:
- Invite code must exist
- Invite code must be in pending status

**Postconditions**:
- Invitation status updated to denied
- Denial event published to Nostr relays
- Invitation code invalidated

#### invalidateInvitation

Invalidates an invitation (e.g., when invitee removed from backup config).

```dart
Future<void> invalidateInvitation({
  required String inviteCode,
  required String reason,
}) async {
  // Updates invitation status to invalidated
  // Publishes invalid event to invitee if already redeemed
  // Removes invitation from tracking
}
```

**Preconditions**:
- Invite code must exist
- Invitation must not be already redeemed

**Postconditions**:
- Invitation status updated to invalidated
- Invalid event published if invitee already accepted
- Invitation removed from active tracking

#### processRsvpEvent

Processes RSVP event received from invitee.

```dart
Future<void> processRsvpEvent({
  required Nip01Event event,
}) async {
  // Decrypts event content using NIP-44
  // Validates invite code and invitee pubkey
  // Updates invitation status to redeemed
  // Adds invitee to backup config if not already present
  // Updates key holder status to "awaiting key"
}
```

**Preconditions**:
- Event must be kind 1340 (invitationRsvp)
- Event must be properly encrypted
- Current user must be lockbox owner

**Postconditions**:
- Invitation marked as redeemed
- Invitee added to backup config
- Key holder status updated

#### processDenialEvent

Processes denial event received from invitee.

```dart
Future<void> processDenialEvent({
  required Nip01Event event,
}) async {
  // Decrypts event content using NIP-44
  // Validates invite code
  // Updates invitation status to denied
  // Invalidates invitation code
}
```

**Preconditions**:
- Event must be kind 1341 (invitationDenial)
- Event must be properly encrypted
- Current user must be lockbox owner

**Postconditions**:
- Invitation marked as denied
- Invitation code invalidated

#### processShardConfirmationEvent

Processes shard confirmation event received from key holder.

```dart
Future<void> processShardConfirmationEvent({
  required Nip01Event event,
}) async {
  // Decrypts event content using NIP-44
  // Validates lockbox ID and shard index
  // Updates key holder status to "holding key"
  // Updates last acknowledgment timestamp
}
```

**Preconditions**:
- Event must be kind 1342 (shardConfirmation)
- Event must be properly encrypted
- Current user must be lockbox owner

**Postconditions**:
- Key holder status updated to "holding key"
- Acknowledgment timestamp updated

#### processShardErrorEvent

Processes shard error event received from key holder.

```dart
Future<void> processShardErrorEvent({
  required Nip01Event event,
}) async {
  // Decrypts event content using NIP-44
  // Validates lockbox ID and shard index
  // Updates key holder status to "error"
  // Logs error details
}
```

**Preconditions**:
- Event must be kind 1343 (shardError)
- Event must be properly encrypted
- Current user must be lockbox owner

**Postconditions**:
- Key holder status updated to "error"
- Error details logged

## DeepLinkService

Service for handling deep links, Universal Links, and custom URL schemes.

### Location
`lib/services/deep_link_service.dart`

### Dependencies
- `app_links` package - For handling deep links (supports both Universal Links and custom schemes)
- `InvitationService` - For processing invitation links

### Methods

#### initializeDeepLinking

Initializes deep link handling when app starts. Handles both Universal Links (`https://keydex.app/...`) and custom URL scheme (`keydex://...`).

```dart
Future<void> initializeDeepLinking() async {
  // Sets up app_links listeners
  // Handles initial link (app opened via link)
  // Sets up stream listener for subsequent links
  // Supports both Universal Links and custom URL scheme
}
```

**Postconditions**:
- Deep link listeners active
- Ready to handle incoming links (both Universal Links and custom scheme)
- Listens for: `https://keydex.app/...` and `keydex://...`

#### handleInitialLink

Handles link that opened the app (cold start).

```dart
Future<void> handleInitialLink() async {
  // Retrieves initial link from app_links
  // Parses and validates link format
  // Routes to appropriate handler
}
```

#### handleIncomingLink

Handles link received while app is running (warm start).

```dart
void handleIncomingLink(AppLink link) {
  // Parses link URL
  // Validates link format
  // Routes to invitation acceptance flow
}
```

**Parameters**:
- `link`: AppLink from app_links package

#### parseInvitationLink

Parses invitation link URL and extracts parameters. Handles both Universal Links (`https://keydex.app/invite/{code}`) and custom URL scheme (`keydex://keydex.app/invite/{code}`) formats.

```dart
InvitationLinkData? parseInvitationLink(Uri uri) {
  // Validates URL format:
  //   - Universal Link: https://keydex.app/invite/{code}?owner={pubkey}&relays={urls}
  //   - Custom scheme: keydex://keydex.app/invite/{code}?owner={pubkey}&relays={urls}
  // Extracts invite code from path (same path structure for both)
  // Extracts owner pubkey and relay URLs from query params
  // Returns parsed data or null if invalid
}
```

**Returns**: InvitationLinkData with invite code, owner pubkey, relay URLs

**Supported Schemes**:
- `https://` (Universal Links - production)
- `keydex://` (Custom scheme - development/testing)

**Error Cases**:
- Returns null if URL format invalid
- Returns null if missing required parameters
- Returns null if scheme not supported

## InvitationEventService

Service for creating and publishing invitation-related Nostr events.

### Location
`lib/services/invitation_event_service.dart`

### Dependencies
- `NdkService` - For Nostr event publishing
- `KeyService` - For encryption/decryption

### Methods

#### publishRsvpEvent

Creates and publishes RSVP event to accept invitation.

```dart
Future<String?> publishRsvpEvent({
  required String inviteCode,
  required String ownerPubkey, // Hex format
  required List<String> relayUrls,
}) async {
  // Creates RSVP event payload
  // Encrypts using NIP-44
  // Creates Nostr event (kind 1340)
  // Signs with invitee's private key
  // Publishes to relays
  // Returns event ID
}
```

**Returns**: Event ID if successful, null otherwise

#### publishDenialEvent

Creates and publishes denial event to decline invitation.

```dart
Future<String?> publishDenialEvent({
  required String inviteCode,
  required String ownerPubkey, // Hex format
  required List<String> relayUrls,
  String? reason,
}) async {
  // Creates denial event payload
  // Encrypts using NIP-44
  // Creates Nostr event (kind 1341)
  // Signs with invitee's private key
  // Publishes to relays
  // Returns event ID
}
```

**Returns**: Event ID if successful, null otherwise

#### publishShardConfirmationEvent

Creates and publishes shard confirmation event.

```dart
Future<String?> publishShardConfirmationEvent({
  required String lockboxId,
  required int shardIndex,
  required String ownerPubkey, // Hex format
  required List<String> relayUrls,
}) async {
  // Creates confirmation event payload
  // Encrypts using NIP-44
  // Creates Nostr event (kind 1342)
  // Signs with key holder's private key
  // Publishes to relays
  // Returns event ID
}
```

**Returns**: Event ID if successful, null otherwise

#### publishShardErrorEvent

Creates and publishes shard error event.

```dart
Future<String?> publishShardErrorEvent({
  required String lockboxId,
  required int shardIndex,
  required String ownerPubkey, // Hex format
  required List<String> relayUrls,
  required String error,
}) async {
  // Creates error event payload
  // Encrypts using NIP-44
  // Creates Nostr event (kind 1343)
  // Signs with key holder's private key
  // Publishes to relays
  // Returns event ID
}
```

**Returns**: Event ID if successful, null otherwise

#### publishInvitationInvalidEvent

Creates and publishes invitation invalid event.

```dart
Future<String?> publishInvitationInvalidEvent({
  required String inviteCode,
  required String inviteePubkey, // Hex format
  required List<String> relayUrls,
  required String reason,
}) async {
  // Creates invalid event payload
  // Encrypts using NIP-44
  // Creates Nostr event (kind 1344)
  // Signs with lockbox owner's private key
  // Publishes to relays
  // Returns event ID
}
```

**Returns**: Event ID if successful, null otherwise

## Provider Definitions

### Invitation Service Provider

```dart
final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService(
    ref.read(lockboxRepositoryProvider),
    ref.read(ndkServiceProvider),
    ref.read(keyServiceProvider),
  );
});
```

### Deep Link Service Provider

```dart
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(
    ref.read(invitationServiceProvider),
  );
});
```

### Pending Invitations Provider

```dart
final pendingInvitationsProvider = FutureProvider.family<List<InvitationLink>, String>(
  (ref, lockboxId) async {
    final service = ref.read(invitationServiceProvider);
    return await service.getPendingInvitations(lockboxId);
  },
);
```

### Invitation Code Provider

```dart
final invitationCodeProvider = FutureProvider.family<InvitationCode?, String>(
  (ref, inviteCode) async {
    final service = ref.read(invitationServiceProvider);
    return await service.lookupInvitationCode(inviteCode);
  },
);
```

## Error Types

### InvitationNotFoundException

Thrown when invite code not found in storage.

```dart
class InvitationNotFoundException implements Exception {
  final String inviteCode;
  InvitationNotFoundException(this.inviteCode);
}
```

### InvitationAlreadyRedeemedException

Thrown when invite code already redeemed.

```dart
class InvitationAlreadyRedeemedException implements Exception {
  final String inviteCode;
  InvitationAlreadyRedeemedException(this.inviteCode);
}
```

### InvitationInvalidatedException

Thrown when invite code has been invalidated.

```dart
class InvitationInvalidatedException implements Exception {
  final String inviteCode;
  final String reason;
  InvitationInvalidatedException(this.inviteCode, this.reason);
}
```

### InvalidInvitationLinkException

Thrown when invitation link URL is malformed or invalid.

```dart
class InvalidInvitationLinkException implements Exception {
  final String url;
  final String reason;
  InvalidInvitationLinkException(this.url, this.reason);
}
```

## Testing Strategy

### Unit Tests

- Test invitation code generation (cryptographic randomness)
- Test invitation link URL generation and parsing
- Test invitation status transitions
- Test event encryption/decryption
- Test error handling for invalid codes

### Integration Tests

- Test complete invitation flow (generate → share → redeem)
- Test invitation denial flow
- Test deep link handling (cold start and warm start)
- Test RSVP event processing
- Test shard confirmation event processing
- Test error event handling

### Widget Tests

- Test invitation link generation UI
- Test invitation acceptance screen
- Test key holder status display
- Test error message display

### Golden Tests

- Test invitation link generation screen
- Test invitation acceptance screen
- Test key holder list with invitation statuses
- Test error states

