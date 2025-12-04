# Data Model: Invitation Links for Stewards

**Feature**: 004-invitation-links  
**Date**: 2025-01-27

## Overview

This document defines the data models for the invitation links feature. All models follow Flutter/Dart conventions using records (typedefs) for value types. Public keys are stored in hex format (64 characters) internally, and converted to bech32 format (npub/nsec) only for display and user input.

## Core Entities

### InvitationLink

Represents a generated invitation link that can be shared with an invitee.

```dart
typedef InvitationLink = ({
  String inviteCode,          // Base64URL encoded 32-byte random string
  String vaultId,           // ID of the vault being shared
  String ownerPubkey,        // Hex format (64 chars) - vault owner's public key
  List<String> relayUrls,    // Up to 3 relay URLs for communication
  String inviteeName,         // Name entered by vault owner
  DateTime createdAt,         // When invitation was generated
  InvitationStatus status,    // Current status of invitation
  String? redeemedBy,         // Hex pubkey of redeemer (null if not redeemed)
  DateTime? redeemedAt,      // When invitation was redeemed (null if not redeemed)
});
```

**Validation Rules**:
- `inviteCode`: Must be 43 characters (Base64URL encoded 32 bytes)
- `vaultId`: Must match existing vault
- `ownerPubkey`: Must be valid hex format (64 characters)
- `relayUrls`: Must have 1-3 URLs, all valid WebSocket URLs
- `inviteeName`: Must not be empty

**State Transitions**:
- `created` → `pending` (after generation)
- `pending` → `redeemed` (when invitee accepts)
- `pending` → `denied` (when invitee denies)
- `pending` → `invalidated` (when vault owner removes invitee from config)
- `pending` → `error` (when invalid code redemption attempted)

### InvitationCode

**DEPRECATED**: This model is redundant. Use `InvitationLink` directly and look it up by invite code.

The invite code is globally unique, so we can store `InvitationLink` directly indexed by invite code. For listing all invitations for a vault, we maintain a separate index mapping vaultId → list of invite codes.

### InvitationStatus

Enum representing the current state of an invitation.

```dart
enum InvitationStatus {
  created,      // Invitation just generated, not yet sent
  pending,       // Invitation sent, awaiting response
  redeemed,      // Invitation accepted by invitee
  denied,        // Invitation denied by invitee
  invalidated,   // Invitation invalidated by vault owner
  error,         // Error occurred during redemption
}
```

### InvitationRsvpEvent

Encrypted Nostr event (kind 1340) sent by invitee to accept invitation.

```dart
typedef InvitationRsvpEvent = ({
  String eventId,            // Nostr event ID (hex, 64 chars)
  String inviteCode,          // Invitation code being redeemed
  String inviteePubkey,       // Hex format - invitee's public key
  String vaultId,           // ID of vault
  String ownerPubkey,         // Hex format - vault owner's public key
  DateTime createdAt,         // When RSVP was sent
  String encryptedContent,     // NIP-44 encrypted content
});
```

**Encrypted Content** (JSON):
```json
{
  "inviteCode": "abc123...",
  "pubkey": "789abc...def",
  "timestamp": "2025-01-27T10:00:00Z"
}
```

**Event Tags**:
- `['p', ownerPubkey]` - Recipient (vault owner)
- `['invite', inviteCode]` - Invitation reference

### InvitationDenialEvent

Encrypted Nostr event (kind 1341) sent by invitee to deny invitation.

```dart
typedef InvitationDenialEvent = ({
  String eventId,            // Nostr event ID
  String inviteCode,          // Invitation code being denied
  String ownerPubkey,         // Hex format - vault owner's public key
  DateTime createdAt,         // When denial was sent
  String? reason,             // Optional reason for denial
  String encryptedContent,     // NIP-44 encrypted content
});
```

**Encrypted Content** (JSON):
```json
{
  "inviteCode": "abc123...",
  "timestamp": "2025-01-27T10:00:00Z",
  "reason": "Optional reason text"
}
```

**Event Tags**:
- `['p', ownerPubkey]` - Recipient (vault owner)
- `['invite', inviteCode]` - Invitation reference

### ShardConfirmationEvent

Encrypted Nostr event (kind 1342) sent by steward after successfully processing shard.

```dart
typedef ShardConfirmationEvent = ({
  String eventId,            // Nostr event ID
  String vaultId,           // ID of vault
  int shardIndex,             // Index of shard being confirmed
  String ownerPubkey,         // Hex format - vault owner's public key
  String keyHolderPubkey,      // Hex format - steward's public key
  DateTime createdAt,         // When confirmation was sent
  String encryptedContent,     // NIP-44 encrypted content
});
```

**Encrypted Content** (JSON):
```json
{
  "vaultId": "abc123...",
  "shardIndex": 0,
  "timestamp": "2025-01-27T10:00:00Z"
}
```

**Event Tags**:
- `['p', ownerPubkey]` - Recipient (vault owner)
- `['vault', vaultId]` - Vault reference
- `['shard', shardIndex.toString()]` - Shard index

### ShardErrorEvent

Encrypted Nostr event (kind 1343) sent by steward when shard processing fails.

```dart
typedef ShardErrorEvent = ({
  String eventId,            // Nostr event ID
  String vaultId,           // ID of vault
  int shardIndex,             // Index of shard that failed
  String ownerPubkey,         // Hex format - vault owner's public key
  String keyHolderPubkey,      // Hex format - steward's public key
  String error,                // Error message
  DateTime createdAt,         // When error was sent
  String encryptedContent,     // NIP-44 encrypted content
});
```

**Encrypted Content** (JSON):
```json
{
  "vaultId": "abc123...",
  "shardIndex": 0,
  "error": "Failed to decrypt shard",
  "timestamp": "2025-01-27T10:00:00Z"
}
```

**Event Tags**:
- `['p', ownerPubkey]` - Recipient (vault owner)
- `['vault', vaultId]` - Vault reference
- `['shard', shardIndex.toString()]` - Shard index

### InvitationInvalidEvent

Encrypted Nostr event (kind 1344) sent by vault owner to notify invitee of invalid code.

```dart
typedef InvitationInvalidEvent = ({
  String eventId,            // Nostr event ID
  String inviteCode,          // Invalid invitation code
  String inviteePubkey,       // Hex format - invitee's public key
  String reason,              // Reason for invalidation
  DateTime createdAt,         // When notification was sent
  String encryptedContent,     // NIP-44 encrypted content
});
```

**Encrypted Content** (JSON):
```json
{
  "inviteCode": "abc123...",
  "reason": "Code already redeemed",
  "timestamp": "2025-01-27T10:00:00Z"
}
```

**Event Tags**:
- `['p', inviteePubkey]` - Recipient (invitee)
- `['invite', inviteCode]` - Invitation reference

## Extended KeyHolder Status

The existing `KeyHolderStatus` enum should be extended or a new status tracking added for invitation-related states:

```dart
// Extend existing KeyHolderStatus or add invitation-specific tracking
enum InvitationKeyHolderStatus {
  invited,        // Invitation sent, awaiting acceptance
  awaitingKey,    // Invitation accepted, awaiting shard distribution
  holdingKey,     // Shard received and confirmed
  error,          // Error occurred during invitation or shard processing
}
```

## Storage Schema

### SharedPreferences Keys

**Invitation Lookup** (by invite code - primary storage):
```
invitation_{inviteCode}
```
Value: JSON InvitationLink data
- Invite codes are globally unique, so this is the primary storage
- Used for quick lookup when someone redeems an invitation

**Vault Invitations Index** (for listing all invitations per vault):
```
vault_invitations_{vaultId}
```
Value: List of invite codes (strings)
- Used to quickly get all invitation codes for a vault
- To get full invitation details, look up each code using `invitation_{inviteCode}`

### Data Relationships

```
Vault
  └── BackupConfig
      └── KeyHolder[]
          └── InvitationLink? (if invited via link)
              └── InvitationRsvpEvent? (when accepted)
              └── InvitationDenialEvent? (when denied)
                  └── KeyHolder (updated status)
                      └── ShardConfirmationEvent? (when shard received)
                      └── ShardErrorEvent? (if error)
```

## Model Conversion Functions

### InvitationLink

```dart
// Create new invitation link
InvitationLink createInvitationLink({
  required String inviteCode,
  required String vaultId,
  required String ownerPubkey,
  required List<String> relayUrls,
  required String inviteeName,
});

// Update invitation status
InvitationLink updateInvitationStatus(
  InvitationLink link,
  InvitationStatus status, {
  String? redeemedBy,
  DateTime? redeemedAt,
});

// Convert to/from JSON for storage
Map<String, dynamic> invitationLinkToJson(InvitationLink link);
InvitationLink invitationLinkFromJson(Map<String, dynamic> json);

// Generate invitation URL
String invitationLinkToUrl(InvitationLink link);
```

### InvitationCode (removed - use InvitationLink directly)

**Note**: The `InvitationCode` model has been removed. Use `InvitationLink` directly and look it up by invite code using the storage key `invitation_{inviteCode}`.

## Validation Rules

### Invite Code
- Must be exactly 43 characters (Base64URL encoded 32 bytes)
- Must contain only Base64URL characters: `A-Z`, `a-z`, `0-9`, `-`, `_`
- Must be cryptographically random (use `Random.secure()`)

### Invitation Link URL
- Format: `https://horcrux.app/invite/{inviteCode}?owner={ownerPubkey}&relays={relayUrls}`
- `ownerPubkey`: Hex format, URL-encoded
- `relayUrls`: Comma-separated, URL-encoded

### Relay URLs
- Must be valid WebSocket URLs: `wss://` or `ws://`
- Maximum 3 URLs per invitation
- Minimum 1 URL required

## State Management

### Provider Structure

```dart
// Provider for invitation service
final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService(ref.read(vaultRepositoryProvider));
});

// Provider for pending invitations by vault
final pendingInvitationsProvider = FutureProvider.family<List<InvitationLink>, String>(
  (ref, vaultId) async {
    final service = ref.read(invitationServiceProvider);
    return await service.getPendingInvitations(vaultId);
  },
);

// Provider for invitation lookup by code
final invitationByCodeProvider = FutureProvider.family<InvitationLink?, String>(
  (ref, inviteCode) async {
    final service = ref.read(invitationServiceProvider);
    return await service.lookupInvitationByCode(inviteCode);
  },
);
```

## Error Handling

### Invalid Invitation Code
- Code not found in storage
- Code already redeemed
- Code invalidated by vault owner
- Code format invalid

### Invalid Invitation Link
- Malformed URL
- Missing required parameters
- Invalid owner pubkey format
- Invalid relay URLs

### Event Processing Errors
- Failed to decrypt event
- Invalid event structure
- Missing required tags
- Event signature verification failed

