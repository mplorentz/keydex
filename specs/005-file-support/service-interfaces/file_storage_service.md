# FileStorageService Interface

**Purpose**: Manages file selection, encryption, upload to Blossom servers (temporary relay), local caching, and download/decryption during recovery. Treats Blossom as ephemeral file relay, not permanent storage.

## Service Architecture

```dart
final Provider<FileStorageService> fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService(
    ref.read(ndkServiceProvider),
    ref.read(loginServiceProvider),
    ref.read(blossomConfigServiceProvider),
  );
});
```

## Dependencies

- `NdkService`: For Blossom API access (upload, download, delete)
- `LoginService`: For current user pubkey and signing
- `BlossomConfigService`: For configured Blossom servers

## Public Methods

### File Selection

```dart
/// Opens native file picker and returns selected files
/// 
/// Returns: List of PlatformFile objects or empty list if cancelled
/// Throws: FilePickerException if platform picker fails
Future<List<PlatformFile>> pickFiles({
  bool allowMultiple = true,
  List<String>? allowedExtensions,
}) async
```

**Validation**:
- Check combined size doesn't exceed 1GB
- Validate file types if extensions specified
- Handle platform-specific picker behavior

### File Upload & Encryption

```dart
/// Encrypts file and uploads to Blossom server
/// 
/// Parameters:
///   - file: PlatformFile from picker
///   - encryptionKey: 32-byte AES-256 key
///   - serverUrl: Target Blossom server URL
///   - onProgress: Optional callback for upload progress (0.0 to 1.0)
/// 
/// Returns: LockboxFile metadata with Blossom hash and URL
/// Throws: EncryptionException, BlossomUploadException
Future<LockboxFile> encryptAndUploadFile({
  required PlatformFile file,
  required Uint8List encryptionKey,
  required String serverUrl,
  void Function(double progress)? onProgress,
}) async
```

**Implementation Steps**:
1. Read file bytes (handle both path and bytes depending on platform)
2. Generate encryption salt
3. Encrypt bytes using AES-256-GCM: `ntcdcrypto.encrypt()`
4. Upload encrypted bytes to Blossom: `ndk.blossom.upload()`
5. Create `LockboxFile` metadata with returned hash and URL
6. Call progress callback during upload if provided

**Error Handling**:
- File read failures: Clear error message with filename
- Encryption failures: Technical error with support code
- Network failures: Retry suggestion with server name
- Server errors: Display server response if available

### File Download & Decryption

```dart
/// Downloads encrypted file from Blossom and decrypts
/// 
/// Parameters:
///   - blossomUrl: Full URL to encrypted file
///   - blossomHash: SHA-256 hash for verification
///   - encryptionKey: 32-byte AES-256 key
///   - onProgress: Optional callback for download progress (0.0 to 1.0)
/// 
/// Returns: Decrypted file bytes
/// Throws: BlossomDownloadException, DecryptionException, HashMismatchException
Future<Uint8List> downloadAndDecryptFile({
  required String blossomUrl,
  required String blossomHash,
  required Uint8List encryptionKey,
  void Function(double progress)? onProgress,
}) async
```

**Implementation Steps**:
1. Download encrypted bytes from Blossom: `ndk.blossom.download()`
2. Verify SHA-256 hash matches expected hash
3. Decrypt bytes using AES-256-GCM: `ntcdcrypto.decrypt()`
4. Return decrypted bytes
5. Call progress callback during download if provided

**Error Handling**:
- Network failures: Retry suggestion
- Hash mismatch: "File corrupted, cannot decrypt"
- Decryption failures: "Invalid key or corrupted file"

### File Deletion

```dart
/// Deletes file from Blossom server
/// 
/// Parameters:
///   - blossomHash: SHA-256 hash of file to delete
///   - serverUrl: Blossom server URL
/// 
/// Returns: true if deleted, false if already gone
/// Throws: BlossomDeleteException
Future<bool> deleteFile({
  required String blossomHash,
  required String serverUrl,
}) async
```

**Implementation Steps**:
1. Call `ndk.blossom.delete()` with authentication
2. Handle 404 as success (already deleted)
3. Log deletion for audit trail

**Error Handling**:
- Authentication failures: Re-login prompt
- Server errors: Log but don't fail user operation

### File Export (Recovery)

```dart
/// Saves decrypted file to user-chosen location
/// 
/// Parameters:
///   - fileBytes: Decrypted file data
///   - suggestedName: Original filename
///   - mimeType: File MIME type
/// 
/// Returns: true if saved, false if cancelled
/// Throws: FileSaveException
Future<bool> saveFile({
  required Uint8List fileBytes,
  required String suggestedName,
  String? mimeType,
}) async
```

**Implementation Steps**:
1. Call `FilePicker.platform.saveFile()` with suggested name
2. Write bytes to chosen location
3. Show success confirmation

**Error Handling**:
- Permission denied: Clear message with platform instructions
- Disk full: "Not enough space" with size needed
- Cancellation: Return false silently

### Local Cache Operations (Key Holders)

```dart
/// Caches encrypted file locally for key holder
/// 
/// Parameters:
///   - lockboxId: Lockbox UUID
///   - fileHash: SHA-256 hash
///   - fileName: Original filename for display
///   - encryptedBytes: Encrypted file data
/// 
/// Returns: CachedFile metadata
/// Throws: CacheWriteException
Future<CachedFile> cacheEncryptedFile({
  required String lockboxId,
  required String fileHash,
  required String fileName,
  required Uint8List encryptedBytes,
}) async
```

**Implementation Steps**:
1. Get cache directory: `getApplicationCacheDirectory()`
2. Create lockbox subdirectory if not exists
3. Write encrypted bytes to `{cacheDir}/encrypted_files/{lockboxId}/{fileHash}.enc`
4. Create `CachedFile` metadata
5. Save metadata to SharedPreferences
6. Return `CachedFile`

**Error Handling**:
- Disk full: Delete oldest cached files, retry
- Permission denied: Fallback to temp directory
- IO errors: Retry once, then fail with clear message

```dart
/// Retrieves cached encrypted file
/// 
/// Parameters:
///   - lockboxId: Lockbox UUID
///   - fileHash: SHA-256 hash
/// 
/// Returns: Encrypted file bytes or null if not cached
/// Throws: CacheReadException
Future<Uint8List?> getCachedFile({
  required String lockboxId,
  required String fileHash,
}) async
```

**Implementation Steps**:
1. Load cached file metadata from SharedPreferences
2. Find entry matching lockboxId and fileHash
3. Read file from disk at cachePath
4. Return encrypted bytes or null if not found

**Error Handling**:
- File not found: Return null (cache evicted by OS)
- Corrupted file: Delete from cache, return null
- IO errors: Log and return null

```dart
/// Deletes cached files for a lockbox
/// 
/// Parameters:
///   - lockboxId: Lockbox UUID
/// 
/// Returns: Number of files deleted
Future<int> deleteCachedFiles(String lockboxId) async
```

**Implementation Steps**:
1. Load cached file metadata for lockbox
2. Delete directory `{cacheDir}/encrypted_files/{lockboxId}/`
3. Remove metadata from SharedPreferences
4. Return count of deleted files

```dart
/// Gets all cached files (for stats/management)
/// 
/// Returns: List of CachedFile metadata
Future<List<CachedFile>> getAllCachedFiles() async
```

**Implementation Steps**:
1. Load all cached file metadata from SharedPreferences
2. Filter out files that no longer exist on disk
3. Return list

## State Management

This service is stateless - no internal state beyond injected dependencies. All file operations are transactional. Cache metadata persisted in SharedPreferences, files on disk.

## Testing Strategy

### Unit Tests

- Mock `file_picker` responses
- Mock `NdkService` Blossom methods
- Test encryption/decryption round-trip
- Test size limit validation
- Test hash verification

### Integration Tests

- Full upload/download cycle with test Blossom server
- Progress callback behavior
- Error recovery flows
- Cross-platform file picker behavior

### Golden Tests

- File picker UI states (not applicable - native)
- Progress indicators during upload/download
- Error message displays

## Performance Considerations

- **Large Files**: Use streaming for files > 100MB (future optimization)
- **Progress Updates**: Throttle callbacks to ~100ms intervals
- **Memory**: Process files in chunks if > 50MB (future optimization)
- **Cancellation**: Support operation cancellation for long uploads (future)

## Security Considerations

- Encryption keys never leave secure storage or memory
- Encrypted bytes never cached to disk
- Original file bytes cleared from memory after encryption
- Blossom authentication uses Nostr signatures
- All HTTPS for Blossom communication

---
**Related Services**: BlossomConfigService, LockboxRepository

