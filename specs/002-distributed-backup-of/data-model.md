# Data Model: Distributed Backup of Vaults

## Core Entities

### BackupConfig
Represents the backup configuration for a vault.

**Fields**:
- `vaultId: String` - Unique identifier for the vault
- `specVersion: String` - Specification version for backup protocol (e.g., "1.0.0") for compatibility tracking
- `threshold: int` - Number of keys required to reconstruct the vault (minimum 2, maximum 10)
- `totalKeys: int` - Total number of keys created (must be >= threshold)
- `keyHolders: List<KeyHolder>` - List of trusted contacts who hold keys
- `relays: List<String>` - List of Nostr relay URLs used for communication
- `createdAt: DateTime` - When backup was configured
- `lastUpdated: DateTime` - When backup was last modified
- `lastContentChange: DateTime?` - When vault contents were last modified
- `lastRedistribution: DateTime?` - When shares were last redistributed
- `contentHash: String?` - Hash of current vault contents for change detection
- `status: BackupStatus` - Current status of the backup

**Validation Rules**:
- `specVersion` must be valid semantic version (e.g., "1.0.0", "2.1.3")
- `threshold` must be >= 2 and <= `totalKeys`
- `totalKeys` must be >= `threshold` and <= 10
- `keyHolders.length` must equal `totalKeys`
- All stewards must have valid Nostr public keys
- `relays` must contain at least one valid Nostr relay URL
- All relay URLs must be valid and accessible
- `contentHash` must be valid SHA-256 hash if present
- `lastRedistribution` must be >= `lastContentChange` if both present

**State Transitions**:
- `PENDING` → `ACTIVE` (when all keys distributed successfully and acknowledged)
- `ACTIVE` → `PENDING` (when configuration changes or content changes detected)
- `ACTIVE` → `INACTIVE` (when backup is disabled)
- `PENDING` → `FAILED` (when key distribution fails)

### KeyHolder
Represents a trusted contact who holds a backup key.

**Fields**:
- `npub: String` - Nostr public key in bech32 format (npub1...)
- `name: String?` - Optional display name for the contact
- `status: KeyHolderStatus` - Current status of this steward
- `lastSeen: DateTime?` - When this steward was last active
- `keyShare: String?` - Encrypted Shamir share (Base64Url encoded, stored locally for recovery)
- `giftWrapEventId: String?` - Nostr event ID of the gift wrap event
- `acknowledgedAt: DateTime?` - When this steward last acknowledged receipt
- `acknowledgmentEventId: String?` - Nostr event ID of the acknowledgment

**Validation Rules**:
- `npub` must be valid bech32 format starting with "npub1"
- `npub` must be unique within a backup configuration
- `name` is optional but recommended for user experience

**State Transitions**:
- `PENDING` → `ACTIVE` (when gift wrap event published successfully)
- `ACTIVE` → `ACKNOWLEDGED` (when steward acknowledges receipt)
- `ACKNOWLEDGED` → `ACTIVE` (when new gift wrap event sent)
- `ACTIVE` → `INACTIVE` (when steward becomes unresponsive)
- `ACKNOWLEDGED` → `INACTIVE` (when steward becomes unresponsive)
- `ACTIVE` → `REVOKED` (when steward is removed from backup)
- `ACKNOWLEDGED` → `REVOKED` (when steward is removed from backup)

### ShardEvent
Represents a Nostr gift wrap event (kind 1059) containing an encrypted shard.

**Fields**:
- `eventId: String` - Unique Nostr event identifier
- `recipientNpub: String` - Nostr public key of the recipient (in p tag)
- `encryptedContent: String` - NIP-59 gift wrap containing encrypted shard data
- `backupConfigId: String` - Reference to the backup configuration
- `shardIndex: int` - Index of this shard in the Shamir scheme
- `createdAt: DateTime` - When the event was created
- `publishedAt: DateTime?` - When the event was published to relays
- `status: EventStatus` - Current status of the event

**Validation Rules**:
- `eventId` must be valid Nostr event ID format
- `encryptedContent` must be valid NIP-59 gift wrap format
- `shardIndex` must be >= 0 and < totalKeys
- Event must be kind 1059 (gift wrap)

**State Transitions**:
- `CREATED` → `PUBLISHED` (when successfully published to relays)
- `PUBLISHED` → `CONFIRMED` (when recipient acknowledges receipt)
- `PUBLISHED` → `FAILED` (when publishing fails)

### ShardData
Represents the decrypted shard data contained within a ShardEvent.

**Fields**:
- `shard: String` - Base64-encoded Shamir shard bytes
- `threshold: int` - Number of shards required for reconstruction
- `shardIndex: int` - Index of this shard in the Shamir scheme
- `totalShards: int` - Total number of shards created
- `primeMod: String` - Base64-encoded prime modulus for Shamir reconstruction
- `creatorPubkey: String` - Public key of the vault creator (for verification)
- `createdAt: int` - Unix timestamp when shard was created

**Validation Rules**:
- `shard` must be valid Base64-encoded bytes
- `threshold` must be >= 2 and <= `totalShards`
- `shardIndex` must be >= 0 and < `totalShards`
- `primeMod` must be valid Base64-encoded bytes

### BackupStatus (Enum)
- `PENDING` - Backup configuration created but keys not yet distributed or need redistribution
- `ACTIVE` - All keys successfully distributed and backup is functional
- `INACTIVE` - Backup is disabled or configuration is invalid
- `FAILED` - Key distribution failed and backup is not functional

### KeyHolderStatus (Enum)
- `PENDING` - Key holder added but gift wrap event not yet published
- `ACTIVE` - Gift wrap event published and steward is responsive
- `ACKNOWLEDGED` - Key holder has acknowledged receipt of their key share
- `INACTIVE` - Key holder is unresponsive or offline
- `REVOKED` - Key holder removed from backup configuration

### EventStatus (Enum)
- `CREATED` - Gift wrap event created but not yet published
- `PUBLISHED` - Event published to Nostr relays
- `CONFIRMED` - Recipient has acknowledged receipt
- `FAILED` - Publishing failed or event was rejected

## Relationships

### BackupConfig → KeyHolder (1:N)
- One backup configuration has many stewards
- Each steward belongs to exactly one backup configuration
- Cascade delete: removing backup config removes all stewards

### BackupConfig → ShardEvent (1:N)
- One backup configuration generates many shard events
- Each shard event belongs to exactly one backup configuration
- Cascade delete: removing backup config removes all shard events

### KeyHolder → ShardEvent (1:1)
- Each steward has exactly one shard event
- Each shard event is for exactly one steward
- Relationship maintained through `recipientNpub` field

### ShardEvent → ShardData (1:1)
- Each shard event contains exactly one shard data when decrypted
- Shard data is encrypted within the shard event's content

## Data Flow

### Backup Creation Flow
1. User creates `BackupConfig` with threshold, totalKeys, and relay URLs
2. System sets `specVersion` to current specification version (e.g., "1.0.0")
3. User adds `KeyHolder` entities with Nostr public keys
4. System validates configuration, stewards, and relay connectivity
5. System generates Shamir shares for the vault
6. System creates `GiftWrapEvent` entities for each steward
7. System publishes gift wrap events to specified Nostr relays
8. System waits for acknowledgment events from stewards
9. System updates statuses based on publishing and acknowledgment results
10. System sets `contentHash` and `lastRedistribution` timestamps

### Recovery Flow
1. User initiates recovery process
2. System retrieves `BackupConfig` for the vault
3. System checks `specVersion` field for compatibility
4. System collects `GiftWrapEvent` entities from Nostr relays
5. System decrypts Shamir shares using recipient's private key
6. System reconstructs original vault data using Shamir's algorithm
7. System validates reconstructed data integrity

### Configuration Update Flow
1. User modifies `BackupConfig` (threshold, stewards, relays)
2. System invalidates existing `GiftWrapEvent` entities
3. System generates new Shamir shares
4. System creates new `GiftWrapEvent` entities
5. System publishes new gift wrap events to updated relay list
6. System waits for acknowledgment events from stewards
7. System updates all statuses based on results
8. System updates `lastRedistribution` timestamp

### Specification Version Migration Flow
1. System detects `BackupConfig` with older `specVersion` during recovery
2. System checks compatibility with current specification version
3. If compatible: System proceeds with recovery using current algorithms
4. If incompatible: System triggers migration process
5. System updates `specVersion` field to current specification version
6. System redistributes shares using new format
7. System updates all related entities with new specification version

### Content Change Detection Flow
1. User modifies vault contents
2. System calculates new `contentHash` of vault data
3. System compares new hash with stored `contentHash`
4. If different: System sets `lastContentChange` and changes status to `PENDING`
5. System triggers redistribution process (same as Configuration Update Flow)
6. System updates `lastRedistribution` and `contentHash` after successful redistribution

## Security Considerations

### Data Encryption
- All Shamir shares encrypted using NIP-44 before storage/transmission
- Gift wrap events provide additional encryption layer
- No plaintext sensitive data stored anywhere in the system

### Key Management
- Shamir shares generated using cryptographically secure random numbers
- Each share encrypted with recipient's public key
- Original vault data never stored in distributed form

### Access Control
- Only vault owner can modify backup configuration
- Key holders can only access their own encrypted shares
- No central authority controls backup or recovery process
