# FileDistributionService Interface

**Purpose**: Manages the 48-hour file distribution window from owner to key holders. Handles automatic downloads with aggressive retries, tracks distribution status, and triggers Blossom cleanup after successful distribution.

## Service Architecture

```dart
final Provider<FileDistributionService> fileDistributionServiceProvider = 
  Provider<FileDistributionService>((ref) {
    return FileDistributionService(
      ref.read(fileStorageServiceProvider),
      ref.read(lockboxRepositoryProvider),
    );
  });
```

## Dependencies

- `FileStorageService`: For downloading and caching encrypted files
- `LockboxRepository`: For accessing lockbox and shard data

## Public Methods

### Start Distribution (Owner)

```dart
/// Starts the distribution process after files uploaded to Blossom
/// Creates distribution status tracking for each key holder
/// 
/// Parameters:
///   - lockboxId: Lockbox UUID
///   - keyHolderPubkeys: List of key holder hex pubkeys
/// 
/// Returns: List of FileDistributionStatus (all in pending state)
Future<List<FileDistributionStatus>> startDistribution({
  required String lockboxId,
  required List<String> keyHolderPubkeys,
}) async
```

**Implementation**:
1. Create `FileDistributionStatus` for each key holder (state: pending)
2. Set `uploadedAt` to now
3. Save statuses to SharedPreferences
4. Return created statuses

### Auto-Download Files (Key Holder)

```dart
/// Automatically triggered when key holder receives shard with file references
/// Downloads files from Blossom and caches locally
/// 
/// Parameters:
///   - shardData: Received shard with blossomUrls
///   - lockboxId: Associated lockbox ID
/// 
/// Returns: true if all files downloaded successfully
/// Throws: DownloadFailedException (will trigger retry)
Future<bool> autoDownloadFiles({
  required ShardData shardData,
  required String lockboxId,
}) async
```

**Implementation**:
1. Extract file URLs and hashes from shardData
2. For each file:
   - Download encrypted bytes from Blossom
   - Cache locally using FileStorageService
3. Send confirmation back to owner (kind 2442 Nostr event)
4. Return true if all succeeded

**Retry Schedule** (on failure):
- 1 minute later
- 5 minutes later
- 15 minutes later
- 1 hour later
- 6 hours later
- 24 hours later
- Background service continues retrying until 48 hours elapsed

**Error Handling**:
- Network errors: Schedule retry
- Server errors: Schedule retry
- Disk full: Clear old caches, retry
- After 48 hours: Mark as `missed_window`, stop retrying

### Get Distribution Status (Owner)

```dart
/// Gets distribution status for all key holders of a lockbox
/// 
/// Parameters:
///   - lockboxId: Lockbox to check
/// 
/// Returns: List of FileDistributionStatus
Future<List<FileDistributionStatus>> getDistributionStatus(String lockboxId) async
```

**Implementation**:
- Load from SharedPreferences
- Filter by lockboxId
- Return matching statuses

### Check Distribution Complete

```dart
/// Checks if distribution is complete (ready to delete from Blossom)
/// 
/// Parameters:
///   - lockboxId: Lockbox to check
/// 
/// Returns: true if all downloaded OR 48hr window expired
Future<bool> isDistributionComplete(String lockboxId) async
```

**Implementation**:
1. Get distribution statuses for lockbox
2. Check if all in `downloaded` state
3. OR check if 48 hours elapsed since uploadedAt
4. Return true if either condition met

### Delete from Blossom After Distribution

```dart
/// Deletes files from Blossom after successful distribution
/// Called automatically by background task or manually by owner
/// 
/// Parameters:
///   - lockboxId: Lockbox to cleanup
/// 
/// Returns: true if deleted, false if distribution not complete
Future<bool> cleanupBlossom(String lockboxId) async
```

**Implementation**:
1. Check if distribution complete
2. If not complete, return false
3. Get lockbox file hashes and Blossom URLs
4. Delete each file from Blossom
5. Clear distribution statuses from SharedPreferences
6. Return true

**Error Handling**:
- Blossom delete fails: Log but don't fail (server will eventually clean up)
- Network error: Retry later via background task

### Manual Re-Upload (Owner)

```dart
/// Manually triggers re-upload for key holders who missed the window
/// 
/// Parameters:
///   - lockboxId: Lockbox to re-upload
///   - keyHolderPubkeys: Specific key holders (or null for all missed)
/// 
/// Returns: List of new FileDistributionStatus
Future<List<FileDistributionStatus>> reuploadForKeyHolders({
  required String lockboxId,
  List<String>? keyHolderPubkeys,
}) async
```

**Implementation**:
1. Upload files to Blossom again (new URLs)
2. Send new shard events to specified key holders
3. Create new distribution statuses (reset to pending)
4. Old statuses cleared
5. Return new statuses

### Confirm Download (Key Holder → Owner)

```dart
/// Called when key holder successfully downloads and caches files
/// Sends confirmation event to owner
/// 
/// Parameters:
///   - lockboxId: Lockbox ID
///   - ownerPubkey: Owner's hex pubkey
Future<void> confirmDownload({
  required String lockboxId,
  required String ownerPubkey,
}) async
```

**Implementation**:
1. Create Nostr event kind 2442 (download confirmation)
2. Include lockboxId and current pubkey
3. Publish to owner's relays
4. Owner's app processes event and updates FileDistributionStatus

### Update Status from Confirmation (Owner)

```dart
/// Updates distribution status when receiving download confirmation
/// Called by relay scan service when kind 2442 event received
/// 
/// Parameters:
///   - lockboxId: Lockbox ID
///   - keyHolderPubkey: Key holder who confirmed
Future<void> updateStatusFromConfirmation({
  required String lockboxId,
  required String keyHolderPubkey,
}) async
```

**Implementation**:
1. Find FileDistributionStatus for this key holder and lockbox
2. Update state to `downloaded`
3. Set `downloadedAt` to now
4. Save to SharedPreferences
5. Check if all key holders now downloaded → trigger Blossom cleanup

## Background Tasks

### Retry Failed Downloads (Key Holder)

Runs every 5 minutes:
```dart
void scheduleDownloadRetry() {
  // Find pending distributions for current key holder
  // Check retry schedule
  // Attempt download if retry time reached
  // Stop after 48 hours (mark missed_window)
}
```

### Blossom Cleanup (Owner)

Runs hourly:
```dart
void scheduleBlossomCleanup() {
  // Find lockboxes with complete distribution
  // Delete files from Blossom
  // Clear distribution statuses
}
```

### Distribution Status Notifications (Owner)

Runs daily:
```dart
void checkDistributionHealth() {
  // Find distributions > 24 hours old with pending key holders
  // Show notification: "Alice hasn't downloaded files for lockbox X"
  // Suggest manual re-upload
}
```

## Nostr Event Kinds

### Kind 2442: Download Confirmation (Key Holder → Owner)

```dart
{
  "kind": 2442,
  "content": {
    "lockbox_id": "uuid",
    "key_holder_pubkey": "hex",
    "confirmed_at": "2025-11-14T12:00:00Z"
  },
  "tags": [
    ["p", "owner-pubkey"],
  ]
}
```

## State Management

Service maintains no internal state. All distribution status persisted in SharedPreferences. Background tasks scheduled via WorkManager (Android) / BackgroundTasks (iOS).

## Storage Format

```json
{
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

## Testing Strategy

### Unit Tests

- Distribution status CRUD operations
- Distribution complete logic (all downloaded OR 48hrs elapsed)
- Retry schedule enforcement
- Download confirmation processing

### Integration Tests

- Full distribution flow: upload → download → confirm → cleanup
- Missed window scenario (48hrs elapsed, some pending)
- Manual re-upload flow
- Background task execution

### Edge Cases

- Key holder offline entire 48-hour window
- Some key holders download, others don't
- Owner deletes lockbox during distribution
- Key holder receives shard but Blossom files already deleted
- Multiple lockboxes distributing simultaneously

## Error Handling

- **Download Failed**: "Could not download files. Retrying in 5 minutes..."
- **All Retries Failed**: "Download window expired. Contact lockbox owner to resend files."
- **Blossom Cleanup Failed**: Log error, retry later (silent to user)
- **Confirmation Failed**: Retry sending confirmation event

## Performance Considerations

- Downloads happen in background, don't block UI
- Aggressive retry schedule ensures high success rate (>95% expected)
- Blossom cleanup batched, not per-file
- Distribution status lightweight (< 1KB per lockbox)

## Security Considerations

- Files remain encrypted in transit and at rest
- Download confirmations signed with Nostr keys
- No sensitive data in distribution status (just pubkeys and timestamps)
- Automatic cleanup minimizes Blossom exposure window

---
**Related Services**: FileStorageService, BackupService, ShardDistributionService

