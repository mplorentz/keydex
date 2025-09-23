# Data Model: Encrypted Text Lockbox

## Entities

### LockboxMetadata
**Purpose**: Represents metadata for an encrypted container (immutable record)

**Fields**:
- `id`: String (UUID) - Unique identifier for the lockbox
- `name`: String - User-provided name for identification (max 100 chars)
- `createdAt`: DateTime - When the lockbox was created
- `size`: int - Character count of original text (for validation)

**Validation Rules**:
- `name`: Required, non-empty, max 100 characters
- `size`: Must be <= 4000 characters

### LockboxContent
**Purpose**: Represents the decrypted content of a lockbox (immutable record)

**Fields**:
- `id`: String (UUID) - Unique identifier for the lockbox
- `name`: String - User-provided name for identification (max 100 chars)
- `content`: String - The decrypted text content (max 4000 chars)
- `createdAt`: DateTime - When the lockbox was created

**Validation Rules**:
- `content`: Max 4000 characters
- `name`: Required, non-empty, max 100 characters

**State Transitions**:
- Created → Active (when first saved)
- Active → Modified (when content updated)
- Active/Modified → Deleted (permanent removal)

### TextContent
**Purpose**: Represents the plaintext content before encryption

**Fields**:
- `content`: String - The actual sensitive text (max 4000 chars)
- `lockboxId`: String - Reference to parent lockbox

**Validation Rules**:
- `content`: Max 4000 characters
- `lockboxId`: Must reference existing lockbox

### EncryptionKey (NDK KeyPair)
**Purpose**: Represents the Nostr key used for encryption/decryption using NDK's KeyPair

**Fields** (from NDK KeyPair):
- `privateKey`: String? - Nostr private key (32-bytes hex-encoded string)
- `publicKey`: String - Nostr public key (32-bytes hex-encoded string)
- `privateKeyBech32`: String? - Human readable private key (nsec format)
- `publicKeyBech32`: String? - Human readable public key (npub format)

**Validation Rules**:
- `privateKey`: Valid hex string, 64 characters (when present)
- `publicKey`: Valid hex string, 64 characters
- Keys must be cryptographically valid pair
- NDK KeyPair handles equality comparison by publicKey only

## Relationships

- **LockboxMetadata** 1:1 **LockboxContent** (metadata and content are separate records)
- **LockboxMetadata** 1:1 **EncryptionKey** (uses NDK KeyPair for encryption/decryption)
- **User** 1:N **LockboxMetadata** (user can have multiple lockboxes)

## Storage Strategy

**Local Storage** (shared_preferences):
- `lockboxes`: JSON array of LockboxMetadata objects
- `lockbox_contents`: JSON object mapping lockbox IDs to encrypted content strings
- `encryption_key`: Single NDK KeyPair object
- `user_preferences`: App settings and preferences

**Encryption Flow**:
1. User enters text content
2. Text validated (size, format)
3. Text encrypted using NIP-44 with Nostr key
4. Encrypted content stored as base64 string
5. Lockbox metadata stored in shared_preferences

**Decryption Flow**:
1. User selects lockbox
2. Authenticate with biometric/password
3. Retrieve encrypted content from storage
4. Decrypt using NIP-44 with Nostr key
5. Display plaintext to user

## Data Integrity

**Validation**:
- All text content validated before encryption
- Encrypted content validated before storage
- Key validation on app startup
- Size limits enforced at multiple levels

**Error Handling**:
- Invalid encryption → Show error, don't save
- Corrupted data → Show error, offer recovery
- Key mismatch → Show error, require re-authentication
- Storage full → Show error, suggest cleanup
