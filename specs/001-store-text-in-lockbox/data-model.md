# Data Model: Encrypted Text Lockbox

## Entities

### Lockbox
**Purpose**: Represents an encrypted container for storing sensitive text content

**Fields**:
- `id`: String (UUID) - Unique identifier for the lockbox
- `name`: String - User-provided name for identification (max 100 chars)
- `encryptedContent`: String - Base64-encoded encrypted text content
- `createdAt`: DateTime - When the lockbox was created
- `updatedAt`: DateTime - When the lockbox was last modified
- `size`: int - Character count of original text (for validation)

**Validation Rules**:
- `name`: Required, non-empty, max 100 characters
- `encryptedContent`: Required, valid base64 string
- `size`: Must be <= 4000 characters
- `createdAt`: Must be <= `updatedAt`

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

### EncryptionKey
**Purpose**: Represents the Nostr key used for encryption/decryption

**Fields**:
- `privateKey`: String - Nostr private key (hex format)
- `publicKey`: String - Nostr public key (hex format)
- `createdAt`: DateTime - When key was generated

**Validation Rules**:
- `privateKey`: Valid hex string, 64 characters
- `publicKey`: Valid hex string, 64 characters
- Keys must be cryptographically valid pair

## Relationships

- **Lockbox** 1:1 **TextContent** (encrypted version of content)
- **Lockbox** 1:1 **EncryptionKey** (uses key for encryption/decryption)
- **User** 1:N **Lockbox** (user can have multiple lockboxes)

## Storage Strategy

**Local Storage** (shared_preferences):
- `lockboxes`: JSON array of Lockbox objects
- `encryption_key`: Single EncryptionKey object
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
