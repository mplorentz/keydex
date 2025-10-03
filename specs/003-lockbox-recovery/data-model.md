# Data Model: Lockbox Recovery

**Feature**: 003-lockbox-recovery  
**Date**: 2024-12-19  
**Status**: Complete

## Entities

### RecoveryRequest
Represents a request to recover a lockbox, containing the lockbox ID, initiator's public key, timestamp, and current status.

**Fields**:
- `id`: String (unique identifier)
- `lockboxId`: String (reference to Lockbox)
- `initiatorPubkey`: String (hex format, 64 characters)
- `requestedAt`: DateTime (when request was created)
- `status`: RecoveryRequestStatus (current state)
- `nostrEventId`: String? (Nostr event ID if published)
- `expiresAt`: DateTime? (optional expiration)
- `keyHolderResponses`: Map<String, RecoveryResponse> (pubkey -> response)

**Validation Rules**:
- `id` must be non-empty
- `lockboxId` must reference existing Lockbox
- `initiatorPubkey` must be valid hex format (64 characters)
- `requestedAt` must be in the past
- `expiresAt` must be in the future if set

**State Transitions**:
- `pending` → `sent` (when Nostr event published)
- `sent` → `in_progress` (when first response received)
- `in_progress` → `completed` (when sufficient shares collected)
- `in_progress` → `failed` (when insufficient shares or timeout)
- `*` → `cancelled` (user-initiated cancellation)

### RecoveryResponse
Represents a key holder's response to a recovery request.

**Fields**:
- `pubkey`: String (hex format, 64 characters)
- `status`: RecoveryResponseStatus (approved, denied, pending)
- `respondedAt`: DateTime? (when response was received)
- `shardData`: ShardData? (complete shard data if approved)
- `nostrEventId`: String? (Nostr event ID of response)

**Validation Rules**:
- `pubkey` must be valid hex format (64 characters)
- `respondedAt` must be in the past if status is not pending
- `shardData` must be valid if status is approved

### RelayConfiguration
Represents a list of Nostr relays that the app monitors for incoming key shares and recovery requests.

**Fields**:
- `id`: String (unique identifier)
- `url`: String (relay URL)
- `name`: String (user-friendly name)
- `isEnabled`: bool (whether to scan this relay)
- `lastScanned`: DateTime? (last scan timestamp)
- `scanInterval`: Duration (how often to scan)
- `isTrusted`: bool (whether relay is trusted for sensitive operations)

**Validation Rules**:
- `id` must be non-empty
- `url` must be valid WebSocket URL
- `name` must be non-empty
- `scanInterval` must be positive

### RecoveryStatus
Represents the current state of a recovery process, including which key holders have responded and their decision.

**Fields**:
- `recoveryRequestId`: String (reference to RecoveryRequest)
- `totalKeyHolders`: int (total number of key holders)
- `respondedCount`: int (number of responses received)
- `approvedCount`: int (number of approvals)
- `deniedCount`: int (number of denials)
- `collectedShares`: List<ShardData> (shard data collected)
- `threshold`: int (minimum shares needed for recovery)
- `canRecover`: bool (whether recovery is possible)
- `lastUpdated`: DateTime (last status update)

**Validation Rules**:
- `totalKeyHolders` must be positive
- `respondedCount` must be <= `totalKeyHolders`
- `approvedCount` + `deniedCount` must be <= `respondedCount`
- `threshold` must be positive and <= `totalKeyHolders`
- `canRecover` must be true when `approvedCount` >= `threshold`

### ShardData (Extended)
Represents a Shamir share with optional metadata for lockbox recovery.

**Core Fields** (from existing ShardData):
- `shard`: String (the actual Shamir share)
- `threshold`: int (minimum shares needed for recovery)
- `shardIndex`: int (index of this share)
- `totalShards`: int (total number of shares)
- `primeMod`: String (prime modulus for Shamir's algorithm)
- `creatorPubkey`: String (hex format, 64 characters)
- `createdAt`: int (Unix timestamp when created)

**Recovery Metadata** (optional fields):
- `id`: String? (unique identifier for recovery tracking)
- `lockboxId`: String? (reference to Lockbox)
- `recipientPubkey`: String? (hex format, 64 characters)
- `isReceived`: bool? (whether share has been received)
- `receivedAt`: DateTime? (when share was received)
- `nostrEventId`: String? (Nostr event ID if published)

**Validation Rules**:
- Core ShardData validation rules apply
- `id` must be non-empty if provided
- `lockboxId` must reference existing Lockbox if provided
- `recipientPubkey` must be valid hex format (64 characters) if provided
- `receivedAt` must be in the past if `isReceived` is true

## Enums

### RecoveryRequestStatus
- `pending`: Request created but not yet sent
- `sent`: Request sent to key holders via Nostr
- `in_progress`: Responses being collected
- `completed`: Recovery successful, content reassembled
- `failed`: Recovery failed (insufficient shares or timeout)
- `cancelled`: Request cancelled by user

### RecoveryResponseStatus
- `pending`: No response yet
- `approved`: Key holder approved and shared key
- `denied`: Key holder denied the request
- `timeout`: No response within timeout period

## Relationships

- `RecoveryRequest` 1:1 `RecoveryStatus`
- `RecoveryRequest` 1:N `RecoveryResponse`
- `RecoveryRequest` N:1 `Lockbox`
- `ShardData` N:1 `Lockbox` (when lockboxId is provided)
- `RelayConfiguration` N:1 `User` (implicit)

## Data Flow

1. **Recovery Initiation**: User creates `RecoveryRequest` for a `Lockbox`
2. **Request Distribution**: `RecoveryRequest` sent to key holders via Nostr
3. **Response Collection**: Key holders respond with `RecoveryResponse`
4. **Status Tracking**: `RecoveryStatus` updated as responses arrive
5. **Content Recovery**: When threshold met, `ShardData` contents reassembled
6. **Storage**: Recovered content saved to local secure storage

## Security Considerations

- All sensitive data encrypted before storage
- Key shares never stored in plaintext
- Recovery requests include expiration timestamps
- State transitions validated to prevent unauthorized access
- Nostr event IDs tracked for audit purposes
