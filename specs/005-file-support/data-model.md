# Phase 1: Data Model Design

**Feature**: File Storage in Lockboxes  
**Date**: 2025-11-14

## Overview

This document defines the data models required for file storage support in lockboxes. The design extends existing models and introduces new entities for file metadata, Blossom storage configuration, and file status tracking.

## Core Entities

### 1. LockboxFile

Represents a single file stored in a lockbox.

```dart
class LockboxFile {
  final String id;              // UUID for this file
  final String name;            // Original filename (e.g., "passport.pdf")
  final int sizeBytes;          // File size in bytes
  final String mimeType;        // MIME type (e.g., "application/pdf")
  final String blossomHash;     // SHA-256 hash of encrypted file on Blossom
  final String blossomUrl;      // Full Blossom URL for retrieval
  final DateTime uploadedAt;    // When file was uploaded
  final String encryptionSalt;  // Salt used for this file's encryption
}
```

**Validation Rules**:
- `id` must be valid UUID v4
- `name` must not be empty, max 255 characters
- `sizeBytes` must be > 0 and <= 1GB
- `mimeType` must be valid MIME format
- `blossomHash` must be valid SHA-256 hex (64 characters)
- `blossomUrl` must be valid HTTP/HTTPS URL
- `uploadedAt` must not be in the future

**Relationships**:
- Belongs to one `Lockbox` (many-to-one)
- Referenced in `FileDownloadStatus` (one-to-many)

### 2. Lockbox (Modified)

Extended lockbox model to support file storage.

```dart
class Lockbox {
  final String id;
  final String name;
  final List<LockboxFile> files;        // NEW: Replaces `content` field
  final DateTime createdAt;
  final String ownerPubkey;
  final String? ownerName;
  final List<ShardData> shards;
  final List<RecoveryRequest> recoveryRequests;
  final BackupConfig? backupConfig;
  
  // Computed property
  int get totalSizeBytes => files.fold(0, (sum, file) => sum + file.sizeBytes);
}
```

**Breaking Changes**:
- **REMOVED**: `String? content` field
- **ADDED**: `List<LockboxFile> files` field

**Validation Rules**:
- `files` can be empty (lockbox without files yet)
- `totalSizeBytes` must not exceed 1GB (1,073,741,824 bytes)
- All files must have unique `id` within the lockbox

**State Transitions**:
- `LockboxState.owned`: Has files (decrypted) and is owner
- `LockboxState.keyHolder`: Has shards but no files locally
- Other states remain unchanged

### 3. BlossomServerConfig

Configuration for a Blossom file storage server.

```dart
class BlossomServerConfig {
  final String id;              // UUID for this config
  final String url;             // HTTP/HTTPS URL (e.g., "https://blossom.example.com")
  final String name;            // User-friendly name
  final bool isEnabled;         // Whether to use this server
  final DateTime? lastUsed;     // Last successful upload/download
  final bool isDefault;         // Default server for new lockboxes
}
```

**Validation Rules**:
- `id` must be valid UUID v4
- `url` must be valid HTTP or HTTPS URL (not WebSocket)
- `url` must not end with trailing slash
- `name` must not be empty, max 100 characters
- Only one server can have `isDefault = true`

**Storage**:
- Persisted in SharedPreferences as JSON array
- Key: `blossom_server_configs`

### 4. CachedFile

Tracks locally cached encrypted files for key holders.

```dart
class CachedFile {
  final String lockboxId;          // UUID
  final String fileHash;           // SHA-256 hash
  final String fileName;           // Original filename for display
  final int sizeBytes;            // File size
  final DateTime cachedAt;        // When file was downloaded and cached
  final String cachePath;         // Local file path
}
```

**Validation Rules**:
- `lockboxId` must be valid UUID v4
- `fileHash` must be valid SHA-256 hex (64 characters)
- `fileName` must not be empty
- `sizeBytes` must be > 0
- `cachedAt` must not be in the future
- `cachePath` must exist on filesystem

**Storage**:
- Encrypted files stored in app cache directory
- File path format: `{cacheDir}/{lockboxId}/{fileHash}.enc`
- Metadata tracked in SharedPreferences

### 5. FileDistributionStatus

Tracks whether key holders have downloaded files during distribution window.

```dart
class FileDistributionStatus {
  final String lockboxId;          // UUID
  final String keyHolderPubkey;    // Hex format (64 chars)
  final DistributionState state;   // pending, downloaded, missed_window
  final DateTime? downloadedAt;    // When key holder confirmed download
  final DateTime uploadedAt;       // When owner uploaded to Blossom
}

enum DistributionState {
  pending,        // Key holder hasn't downloaded yet (within 48hr window)
  downloaded,     // Key holder successfully downloaded and cached
  missed_window,  // 48 hours elapsed without download
}
```

**Validation Rules**:
- `keyHolderPubkey` must be valid hex (64 characters)
- `lockboxId` must be valid UUID v4
- `downloadedAt` required if `state == downloaded`
- `uploadedAt` must not be in the future

**Lifecycle**:
- Created when owner distributes files
- Updated when key holder downloads
- Used to determine when to delete from Blossom (all downloaded)
- Cleared after successful Blossom cleanup

### 6. ShardData (Extended)

Extended to include file references and Blossom expiration for key holders.

```dart
typedef ShardData = ({
  // Existing fields...
  String shard,
  int threshold,
  int shardIndex,
  int totalShards,
  String primeMod,
  String creatorPubkey,
  int createdAt,
  String? lockboxId,
  String? lockboxName,
  List<Map<String, String>>? peers,
  String? ownerName,
  String? instructions,
  String? recipientPubkey,
  bool? isReceived,
  DateTime? receivedAt,
  String? nostrEventId,
  List<String>? relayUrls,
  
  // NEW fields for file support:
  List<String>? blossomUrls,        // List of Blossom URLs for file retrieval (temporary)
  List<String>? fileHashes,         // List of SHA-256 hashes (matches blossomUrls)
  List<String>? fileNames,          // List of original filenames for display
  DateTime? blossomExpiresAt,       // When files will be deleted from Blossom (~48hrs)
});
```

**New Fields**:
- `blossomUrls`: Temporary URLs to retrieve encrypted files from Blossom
- `fileHashes`: SHA-256 hashes for verification and cache lookup
- `fileNames`: Original filenames for key holder to see what they're backing up
- `blossomExpiresAt`: Expected expiration (owner will delete after this time)

**Validation Rules**:
- If any file field is present, all must be present
- All three lists must have the same length
- Each hash must be valid SHA-256 hex (64 characters)
- Each URL must be valid HTTP/HTTPS
- `blossomExpiresAt` should be 48 hours after creation (if present)

## Model Relationships

```
Lockbox (1) ──────────> (N) LockboxFile
   │
   │ (1)
   │
   └───────> (N) ShardData
                 │
                 └──> (includes) File References (blossomUrls, fileHashes, expiresAt)

KeyHolder (N) ──────────> (N) CachedFile
                               │
                               └──> (cached locally) Encrypted file

Lockbox (1) ──────────> (N) FileDistributionStatus (per key holder)

BlossomServerConfig (independent, global config)
```

**Key Differences from Permanent Storage Model**:
- `CachedFile`: Key holders cache encrypted files locally, not just track download status
- `FileDistributionStatus`: Simpler tracking (pending/downloaded/missed_window) vs complex per-file status
- Files distributed to key holders within 48 hours, then deleted from Blossom

## Data Storage

### Local Storage (SharedPreferences)

```json
{
  "lockboxes": [
    {
      "id": "uuid",
      "name": "My Passport",
      "files": [
        {
          "id": "file-uuid",
          "name": "passport.pdf",
          "sizeBytes": 1048576,
          "mimeType": "application/pdf",
          "blossomHash": "sha256-hash",
          "blossomUrl": "https://blossom.server/sha256-hash",
          "uploadedAt": "2025-11-14T12:00:00Z",
          "encryptionSalt": "base64-salt"
        }
      ],
      "createdAt": "2025-11-14T10:00:00Z",
      "ownerPubkey": "hex-pubkey",
      "shards": [],
      "recoveryRequests": [],
      "backupConfig": null
    }
  ],
  "blossom_server_configs": [
    {
      "id": "uuid",
      "url": "https://blossom.example.com",
      "name": "Example Blossom",
      "isEnabled": true,
      "lastUsed": "2025-11-14T12:00:00Z",
      "isDefault": true
    }
  ],
  "cached_files": [
    {
      "lockboxId": "uuid",
      "fileHash": "sha256-hash",
      "fileName": "passport.pdf",
      "sizeBytes": 1048576,
      "cachedAt": "2025-11-14T12:05:00Z",
      "cachePath": "/cache/uuid/sha256-hash.enc"
    }
  ],
  "file_distribution_statuses": [
    {
      "lockboxId": "uuid",
      "keyHolderPubkey": "hex-pubkey",
      "state": "downloaded",
      "downloadedAt": "2025-11-14T12:05:00Z",
      "uploadedAt": "2025-11-14T12:00:00Z"
    }
  ]
}
```

### File System (Cache Directory)

**Location**: `{appCacheDirectory}/encrypted_files/`

**Structure**:
```
{cacheDir}/
  encrypted_files/
    {lockboxId}/
      {fileHash1}.enc
      {fileHash2}.enc
```

**Characteristics**:
- Files are encrypted at rest
- OS may clear cache if storage pressure
- Survives app restarts
- Not backed up to cloud (device-only)

### Secure Storage (FlutterSecureStorage)

```json
{
  "lockbox_keys": {
    "lockbox-uuid": "base64-encoded-32-byte-aes-key"
  }
}
```

**Key Management**:
- Each lockbox has one symmetric AES-256 key (32 bytes)
- Key stored in secure storage only for owned lockboxes
- Key reconstructed from Shamir shares during recovery
- Key used to decrypt all files in the lockbox

## Migration Strategy

### From Old Lockbox Format

```dart
// Old format (text content)
Lockbox(
  id: "uuid",
  name: "My Secrets",
  content: "sensitive text here",  // REMOVED
  // ...
)

// New format (file-based)
Lockbox(
  id: "uuid",
  name: "My Secrets",
  files: [],                        // ADDED (initially empty)
  // ...
)
```

**Migration Rules**:
- No backward compatibility needed (no existing users per spec)
- Old `content` field ignored on load
- New installs start with file-based model only
- Serialization/deserialization handles missing `content` gracefully

## Computed Properties & Business Logic

### Total Lockbox Size

```dart
extension LockboxFileSupport on Lockbox {
  int get totalSizeBytes => files.fold(0, (sum, file) => sum + file.sizeBytes);
  bool get isWithinSizeLimit => totalSizeBytes <= 1073741824; // 1GB
  int get remainingBytes => 1073741824 - totalSizeBytes;
  bool canAddFile(int fileSizeBytes) => totalSizeBytes + fileSizeBytes <= 1073741824;
}
```

### File Distribution Tracking

```dart
extension FileDistributionTracking on List<FileDistributionStatus> {
  bool allDownloaded() => every((status) => status.state == DistributionState.downloaded);
  bool anyMissedWindow() => any((status) => status.state == DistributionState.missed_window);
  int get downloadedCount => where((s) => s.state == DistributionState.downloaded).length;
  double get downloadPercentage => downloadedCount / length;
  
  // Check if ready to delete from Blossom
  bool canDeleteFromBlossom(DateTime uploadedAt) {
    final windowExpired = DateTime.now().difference(uploadedAt) > Duration(hours: 48);
    return allDownloaded() || windowExpired;
  }
}
```

### Cached File Management

```dart
extension CachedFileOps on List<CachedFile> {
  int get totalCacheSize => fold(0, (sum, file) => sum + file.sizeBytes);
  bool hasFile(String fileHash) => any((file) => file.fileHash == fileHash);
  CachedFile? getByHash(String fileHash) {
    try {
      return firstWhere((file) => file.fileHash == fileHash);
    } catch (_) {
      return null;
    }
  }
}
```

## Validation Summary

| Entity | Key Validations |
|--------|----------------|
| LockboxFile | Size <= 1GB, valid hash, valid URL, non-empty name |
| Lockbox | Total files size <= 1GB, unique file IDs |
| BlossomServerConfig | Valid HTTP/HTTPS URL, non-empty name, single default |
| CachedFile | Valid hash, file exists on disk, lockbox UUID valid |
| FileDistributionStatus | Valid pubkey, downloadedAt if downloaded state |
| ShardData | File arrays same length, blossomExpiresAt ~48hrs from creation |

## Testing Considerations

- **Unit Tests**: Validation rules for each entity, cache file operations
- **Integration Tests**: 
  - File upload → distribution → key holder download → cache locally
  - Distribution window → Blossom cleanup flow
  - Recovery → key holder provides file → temporary Blossom → download
- **Golden Tests**: UI for file list, distribution status indicators
- **Edge Cases**: 
  - 1GB limit enforcement
  - Multiple file handling
  - Distribution window expiration (missed downloads)
  - Cache eviction by OS
  - Key holder offline during distribution
  - Recovery when key holder cache cleared

---
**Ready for Service Interface Design**

