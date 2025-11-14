# Quickstart Guide: File Storage in Lockboxes (P2P Ephemeral Model)

**Feature**: File Storage Support with P2P Distribution  
**Purpose**: End-to-end validation guide for manual testing and integration test scenarios

## Overview

This guide walks through the complete file storage workflow using a P2P ephemeral distribution model. Files are temporarily uploaded to Blossom servers (48-hour window) for distribution to key holders, who cache them locally. After distribution, files are deleted from Blossom. During recovery, key holders provide files via temporary Blossom uploads. Use this for manual verification during development and as a basis for automated integration tests.

## Prerequisites

- Flutter development environment set up
- Test Nostr keys generated (owner + 3 key holders)
- Local Blossom server running on `localhost:10548` (or configure alternative)
- Sample test files prepared:
  - Small text file (~1KB): `test_document.txt`
  - Medium PDF (~1MB): `test_passport.pdf`
  - Large file (~100MB): `test_large.zip`

**Note**: Default Blossom server is `http://localhost:10548` for development. You can run a local Blossom server or configure a different server in settings.

## Test Scenario 1: First-Time Setup

### 1.1 Configure Blossom Server (Owner)

**Steps**:
1. Launch Keydex app
2. Navigate to Settings
3. Tap "Blossom Servers" section
4. Verify default localhost server is pre-configured:
   - Name: "Local Blossom Server"
   - URL: `http://localhost:10548`
   - Status: Default (orange indicator)
5. (Optional) Add custom/production server
6. Tap "Test Connection" for each server
7. Verify green checkmark for reachable servers

**Expected**:
- Localhost server pre-configured and marked as default
- Connection test shows success if local Blossom server is running
- If server not reachable, shows warning with instructions
- Can add additional servers via "Add Server" button

**Validation**:
```dart
test('Default localhost Blossom server is initialized', () async {
  final service = BlossomConfigService();
  final servers = await service.getAllConfigs();
  expect(servers, hasLength(1));
  
  final defaultServer = await service.getDefaultServer();
  expect(defaultServer, isNotNull);
  expect(defaultServer!.url, 'http://localhost:10548');
  expect(defaultServer.name, 'Local Blossom Server');
  expect(defaultServer.isDefault, true);
  expect(defaultServer.isEnabled, true);
});
```

## Test Scenario 2: Create Lockbox with Files (Owner)

### 2.1 Create New Lockbox

**Steps**:
1. From lockbox list screen, tap "Create New Lockbox" (orange button)
2. Enter lockbox name: "My Important Documents"
3. Tap "Add Files" button (replaces old content text area)
4. Native file picker opens
5. Select `test_document.txt` and `test_passport.pdf`
6. Files appear in list with names and sizes
7. Tap "Continue" to proceed to backup configuration

**Expected**:
- File picker opens with native UI
- Multiple selection works
- Files listed with correct names and sizes
- Total size displayed: "1.01 MB of 1 GB used"
- Cannot proceed if total exceeds 1GB

**Validation**:
```dart
testWidgets('Create lockbox with files', (tester) async {
  // Mock file picker
  when(mockFilePicker.pickFiles(allowMultiple: true))
    .thenAnswer((_) async => FilePickerResult([
      PlatformFile(name: 'test.txt', size: 1024, ...),
    ]));
  
  await tester.pumpWidget(LockboxCreateScreen());
  await tester.tap(find.text('Add Files'));
  await tester.pumpAndSettle();
  
  expect(find.text('test.txt'), findsOneWidget);
  expect(find.text('1.00 KB'), findsOneWidget);
});
```

### 2.2 Configure Backup with Key Holders

**Steps**:
1. Set threshold: 2
2. Set total keys: 3
3. Add 3 key holder pubkeys (hex format)
4. Tap "Distribute Keys"
5. Progress dialog shows:
   - "Encrypting files..."
   - "Uploading to Blossom..."
   - "Distributing keys..."
6. Success screen appears

**Expected**:
- Files encrypted with generated AES-256 key
- Encrypted files uploaded to default Blossom server
- Shard events include Blossom URLs and hashes
- Key holders receive shards via Nostr
- Owner sees lockbox in "Owned" state

**Validation**:
```dart
test('Files encrypted and uploaded during backup', () async {
  final service = FileStorageService(...);
  final file = PlatformFile(name: 'test.txt', bytes: utf8.encode('secret'));
  final key = generateRandomBytes(32);
  
  final lockboxFile = await service.encryptAndUploadFile(
    file: file,
    encryptionKey: key,
    serverUrl: 'https://test.blossom.server',
  );
  
  expect(lockboxFile.name, 'test.txt');
  expect(lockboxFile.blossomHash, hasLength(64)); // SHA-256
  expect(lockboxFile.blossomUrl, startsWith('https://'));
});
```

## Test Scenario 3: Key Holder Receives Files

### 3.1 Automatic File Download & Local Caching

**Steps** (Key Holder Device):
1. Launch Keydex on key holder device
2. Relay scan detects new shard event with file references
3. App automatically begins downloading files from Blossom
4. Notification: "Downloading files for lockbox: My Important Documents"
5. Files downloaded and cached to local storage
6. Download confirmation sent to owner (Nostr event kind 2442)
7. Navigate to lockbox detail screen
8. Shows: "Files downloaded and cached locally (2 of 2)"

**Expected**:
- Files downloaded automatically in background within 48hr window
- Encrypted files cached to `{appCache}/encrypted_files/{lockboxId}/`
- Cache metadata saved to SharedPreferences
- Download confirmation sent to owner
- Owner sees "1 of 3 key holders have downloaded files"
- If download fails, retry schedule: 1min, 5min, 15min, 1hr, 6hr, 24hr

**Validation**:
```dart
test('Key holder auto-downloads and caches files on shard receipt', () async {
  final shardData = createShardData(
    blossomUrls: ['https://blossom.test/hash1'],
    fileHashes: ['abc123...'],
    fileNames: ['test.txt'],
    blossomExpiresAt: DateTime.now().add(Duration(hours: 48)),
    ...
  );
  
  final distributionService = FileDistributionService(...);
  final success = await distributionService.autoDownloadFiles(
    shardData: shardData,
    lockboxId: 'test-lockbox-id',
  );
  
  expect(success, true);
  
  // Verify file cached locally
  final cachedFile = await fileStorageService.getCachedFile(
    lockboxId: 'test-lockbox-id',
    fileHash: 'abc123...',
  );
  expect(cachedFile, isNotNull);
  
  // Verify confirmation sent
  verify(ndkService.publishEvent(
    argThat(isA<NostrEvent>().having((e) => e.kind, 'kind', equals(2442)))
  )).called(1);
});
```

### 3.2 View Cached Files

**Steps** (Key Holder):
1. Tap on lockbox "My Important Documents"
2. Lockbox detail screen shows:
   - "You are a key holder for this lockbox"
   - Files section lists: `test_document.txt`, `test_passport.pdf`
   - Each file shows green checkmark (cached locally)
   - Shows cache date: "Cached 2 hours ago"
3. Tap on file to view details (name, size, cache location)

**Expected**:
- All files show cached status with local paths
- Can see file metadata but cannot view contents (encrypted, needs recovery key)
- Shows owner name and other key holders
- Shows storage usage: "Using 1.01 MB of cache"

## Test Scenario 4: Owner Views Distribution Status

### 4.1 Check Distribution Progress

**Steps** (Owner Device):
1. Navigate to lockbox "My Important Documents"
2. Tap "View Distribution Status"
3. List shows 3 key holders with status:
   - Alice: ✓ Files downloaded (2 hours ago)
   - Bob: ⏳ Downloading... (Retry in 5 minutes)
   - Carol: ⚠ Not responding (24 hours, retrying)
4. Shows Blossom status: "Files will be deleted in 24 hours"

**Expected**:
- Real-time distribution state for each key holder
- Visual indicators (checkmark, spinner, warning)
- Retry countdown for failed downloads
- Time until Blossom expiration shown
- Manual "Resend to Carol" button for missed downloads

**Validation**:
```dart
test('Owner can view distribution status per key holder', () async {
  final service = FileDistributionService(...);
  final statuses = await service.getDistributionStatus(
    lockboxId: 'test-lockbox-id',
  );
  
  expect(statuses, hasLength(3)); // 3 key holders
  expect(statuses.where((s) => s.state == DistributionState.downloaded), hasLength(1));
  expect(statuses.where((s) => s.state == DistributionState.pending), hasLength(2));
  
  // Check if ready to delete from Blossom
  final complete = await service.isDistributionComplete('test-lockbox-id');
  expect(complete, false); // Still pending
});
```

### 4.2 Blossom Cleanup After Distribution

**Steps** (Background Task):
1. All 3 key holders have downloaded files
2. Owner's app receives all download confirmations (kind 2442)
3. Background task detects distribution complete
4. Files deleted from Blossom server
5. Distribution statuses cleared from storage

**Expected**:
- Files deleted from Blossom within 1 hour of all confirmations
- OR automatically deleted after 48 hours if some key holders missed window
- Owner sees: "Files distributed successfully. Blossom storage cleared."
- Key holders retain cached files indefinitely

**Validation**:
```dart
test('Blossom files deleted after all key holders download', () async {
  final service = FileDistributionService(...);
  
  // Simulate all key holders downloading
  await service.updateStatusFromConfirmation(
    lockboxId: 'test-id',
    keyHolderPubkey: 'alice-pubkey',
  );
  await service.updateStatusFromConfirmation(
    lockboxId: 'test-id',
    keyHolderPubkey: 'bob-pubkey',
  );
  await service.updateStatusFromConfirmation(
    lockboxId: 'test-id',
    keyHolderPubkey: 'carol-pubkey',
  );
  
  // Should trigger cleanup
  final deleted = await service.cleanupBlossom('test-id');
  expect(deleted, true);
  
  // Verify files deleted from Blossom
  verify(fileStorageService.deleteFile(any, any)).called(2); // 2 files
});
```

## Test Scenario 5: Update Lockbox Files

### 5.1 Replace File

**Steps** (Owner):
1. Open lockbox "My Important Documents"
2. Tap on `test_document.txt`
3. Tap "Replace File"
4. Select new file: `test_document_v2.txt`
5. Confirmation: "Replace test_document.txt with test_document_v2.txt?"
6. Tap "Replace"
7. Progress: "Encrypting... Uploading to Blossom... Distributing..."
8. Success: "File updated. Distribution started (expires in 48 hours)."

**Expected**:
- Old file deleted from Blossom immediately
- New file encrypted and uploaded to Blossom (new 48hr window)
- New shard events sent to all key holders
- Key holders auto-download new file version and replace cache
- Old cached files on key holder devices overwritten
- New distribution status created for tracking

**Validation**:
```dart
test('Replacing file triggers re-upload and new distribution', () async {
  final lockbox = await repository.getLockbox('test-id');
  final oldFile = lockbox.files.first;
  
  // Replace file
  final newFile = await fileStorageService.encryptAndUploadFile(...);
  final updatedLockbox = lockbox.copyWith(
    files: [newFile, ...lockbox.files.skip(1)],
  );
  await repository.updateLockbox(updatedLockbox);
  
  // Old file should be deleted from Blossom immediately
  verify(fileStorageService.deleteFile(
    blossomHash: oldFile.blossomHash,
    serverUrl: oldFile.blossomUrl,
  )).called(1);
  
  // New distribution should start
  final statuses = await distributionService.getDistributionStatus('test-id');
  expect(statuses.every((s) => s.state == DistributionState.pending), true);
  expect(statuses.first.uploadedAt.isAfter(oldFile.uploadedAt), true);
});
```

### 5.2 Add More Files

**Steps** (Owner):
1. In lockbox detail, tap "Add More Files"
2. Select 2 more files
3. Verify total size doesn't exceed 1GB
4. Tap "Add"
5. Files uploaded and keys redistributed

**Expected**:
- Size validation before upload
- All files encrypted with same lockbox key
- Single redistribution event for all new files
- Key holders download new files automatically

## Test Scenario 6: Recovery Flow (P2P File Sharing)

### 6.1 Initiate Recovery and Request Files (Key Holder)

**Steps** (Bob's Device - initiating recovery):
1. In lockbox "My Important Documents", tap "Request Recovery"
2. Recovery request sent to other key holders (Alice and Carol)
3. Alice and Carol accept recovery request and provide shards
4. Bob's device collects shards (2 of 3 threshold met)
5. Key reconstructed automatically
6. Bob's app sends file request (Nostr kind 2440) to Alice and Carol
7. Alice uploads her cached encrypted files to temporary Blossom location
8. Alice responds with file URLs (Nostr kind 2441, expires in 1 hour)
9. Bob downloads encrypted files from temporary Blossom
10. Bob decrypts files with reconstructed key
11. Recovery success screen with file list

**Expected**:
- Threshold met (2 shards collected)
- Key reconstruction successful
- File request events sent to key holders
- At least one key holder provides files (from their local cache)
- Files downloaded from temporary Blossom location
- Files decrypted but not yet saved
- Temporary Blossom files deleted after download (1 hour max)

**Validation**:
```dart
test('Recovery requests files from key holders via Nostr', () async {
  final recoveryService = RecoveryService(...);
  
  // Collect 2 shards (threshold)
  await recoveryService.submitShard(shard1);
  await recoveryService.submitShard(shard2);
  
  final result = await recoveryService.attemptRecovery('lockbox-id');
  expect(result.success, true);
  expect(result.reconstructedKey, hasLength(32));
  
  // File request should be sent (kind 2440)
  verify(ndkService.publishEvent(
    argThat(isA<NostrEvent>()
      .having((e) => e.kind, 'kind', equals(2440))
      .having((e) => e.content, 'content', contains('lockbox-id'))
    )
  )).called(greaterThan(0));
  
  // Simulate key holder response (kind 2441)
  final fileResponse = NostrEvent(
    kind: 2441,
    content: jsonEncode({
      'blossom_url': 'https://temp.blossom/abc123',
      'expires_at': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
    }),
    tags: [['p', 'bob-pubkey']],
  );
  
  // Bob downloads and decrypts
  final decryptedBytes = await fileStorageService.downloadAndDecryptFile(
    blossomUrl: 'https://temp.blossom/abc123',
    blossomHash: 'abc123...',
    encryptionKey: result.reconstructedKey,
  );
  expect(decryptedBytes.isNotEmpty, true);
});
```

### 6.2 Save Recovered Files

**Steps** (Bob's Device - continuing from 6.1):
1. Recovery success screen lists files:
   - test_document_v2.txt
   - test_passport.pdf
2. Tap "Save All Files"
3. For each file, native save dialog appears
4. Choose save location for `test_document_v2.txt`
5. Choose save location for `test_passport.pdf`
6. Success: "All files saved successfully"

**Expected**:
- Native save dialog for each file
- Original filenames suggested
- Files saved to chosen locations
- User can verify file contents externally
- Decrypted files cleared from memory

**Validation**:
```dart
test('Recovered files can be saved to disk', () async {
  final fileService = FileStorageService(...);
  final decryptedBytes = Uint8List.fromList([1, 2, 3]);
  
  final saved = await fileService.saveFile(
    fileBytes: decryptedBytes,
    suggestedName: 'recovered_file.txt',
    mimeType: 'text/plain',
  );
  
  expect(saved, true); // User didn't cancel
});
```

## Test Scenario 7: Distribution Window Management

### 7.1 Missed Distribution Window

**Steps** (Owner Device - 48 hours after distribution):
1. Owner checks lockbox "My Important Documents"
2. Distribution status shows:
   - Alice: ✓ Downloaded (2 days ago)
   - Bob: ✓ Downloaded (2 days ago)
   - Carol: ⚠ Missed window (no response for 48 hours)
3. Background task detects 48 hours elapsed
4. Files automatically deleted from Blossom
5. Owner sees notification: "Carol missed distribution window"
6. Manual "Resend Files to Carol" button available

**Expected**:
- Files deleted from Blossom after 48 hours regardless of Carol's status
- Alice and Bob have cached files (safe)
- Carol marked as `missed_window` state
- Owner can manually re-upload for Carol (new 48hr window)
- No data loss: 2 of 3 key holders have files (recovery still possible)

**Validation**:
```dart
test('Files deleted from Blossom after 48-hour window', () async {
  final distributionService = FileDistributionService(...);
  
  // Simulate 48 hours passing with one key holder not responding
  final lockbox = await repository.getLockbox('test-id');
  final uploadTime = DateTime.now().subtract(Duration(hours: 49));
  
  // Check if distribution complete (by timeout)
  final complete = await distributionService.isDistributionComplete('test-id');
  expect(complete, true); // Window expired
  
  // Should trigger cleanup
  final deleted = await distributionService.cleanupBlossom('test-id');
  expect(deleted, true);
  
  // Verify files deleted from Blossom
  verify(fileStorageService.deleteFile(any, any)).called(greaterThan(0));
  
  // Verify Carol marked as missed_window
  final statuses = await distributionService.getDistributionStatus('test-id');
  final carolStatus = statuses.firstWhere((s) => s.keyHolderPubkey == 'carol-pubkey');
  expect(carolStatus.state, DistributionState.missed_window);
});
```

### 7.2 Manual Re-Upload for Missed Window

**Steps** (Owner Device):
1. Owner taps "Resend Files to Carol"
2. Files re-uploaded to Blossom (new URLs, new 48hr window)
3. New shard event sent to Carol only
4. Carol receives event and downloads files
5. Carol's status updated to `downloaded`
6. After confirmation, files deleted from Blossom again

**Expected**:
- Only targeted key holder receives new distribution
- Other key holders unaffected (keep existing cache)
- New 48-hour window starts for Carol
- Success rate improves with targeted retry

**Validation**:
```dart
test('Manual re-upload creates new distribution for specific key holder', () async {
  final distributionService = FileDistributionService(...);
  
  final statuses = await distributionService.reuploadForKeyHolders(
    lockboxId: 'test-id',
    keyHolderPubkeys: ['carol-pubkey'],
  );
  
  expect(statuses, hasLength(1));
  expect(statuses.first.keyHolderPubkey, 'carol-pubkey');
  expect(statuses.first.state, DistributionState.pending);
  expect(statuses.first.uploadedAt.isAfter(DateTime.now().subtract(Duration(minutes: 1))), true);
});
```

## Test Scenario 8: Error Handling

### 8.1 File Too Large

**Steps**:
1. Try to add 2GB file to lockbox
2. Error: "File too large. Maximum total size is 1 GB."
3. Try to add 600MB when lockbox already has 500MB
4. Error: "Not enough space. 400 MB available."

**Expected**:
- Clear size limits communicated
- No upload attempted if over limit
- Shows remaining space

### 8.2 Network Failure During Upload

**Steps**:
1. Start adding file to lockbox
2. Disconnect network during upload
3. Error: "Upload failed. Check connection and try again."
4. Reconnect network
5. Tap "Retry"
6. Upload succeeds

**Expected**:
- Upload progress saved (resume from where it left off - future)
- Clear retry button
- Success after retry

### 8.3 Key Holder Download Failure with Retry

**Steps** (Key Holder Device):
1. Receive shard for new lockbox
2. Auto-download fails (server unreachable)
3. Status shows: "Download failed. Retrying in 1 minute..."
4. Automatic retries: 1min, 5min, 15min, 1hr, 6hr, 24hr
5. After successful retry, files cached locally
6. Confirmation sent to owner

**Expected**:
- Failed status persisted temporarily
- Aggressive automatic retry schedule
- Manual "Retry Now" button available
- Owner sees "Pending (retrying)" status
- After 48 hours of failures: marked as `missed_window`
- Owner notified if key holder misses window

### 8.4 Cache Cleared by OS

**Steps** (Key Holder Device):
1. OS clears app cache due to storage pressure
2. Cached encrypted files deleted
3. Key holder still has shard (in SharedPreferences/secure storage)
4. During recovery, key holder sees: "Cached files missing"
5. Key holder cannot provide files for recovery

**Expected**:
- Graceful degradation: shard still available
- Warning shown to key holder: "Cache was cleared, recovery may be affected"
- Recovery initiator requests files from other key holders
- If enough key holders have files, recovery succeeds
- If not enough files available, recovery fails with clear error

### 8.5 Recovery with Missing Cached Files

**Steps** (Recovery Scenario):
1. Bob initiates recovery
2. Sends file request (kind 2440) to Alice and Carol
3. Alice has cached files, Carol's cache was cleared
4. Alice provides files via temporary Blossom
5. Recovery succeeds with Alice's files only

**Expected**:
- At least one key holder with cached files sufficient
- Clear error if NO key holders have cached files
- Owner can re-upload files on demand for key holders with cleared cache

## Integration Test Checklist

Use this checklist for complete feature validation:

**Configuration & Setup**:
- [ ] Blossom server configuration (add/edit/delete/test connection)
- [ ] Default Blossom servers initialized on first launch
- [ ] File picker opens on all platforms with native UI
- [ ] Multiple file selection works

**File Upload & Distribution**:
- [ ] Size validation (1GB total limit enforced)
- [ ] File encryption before Blossom upload
- [ ] Blossom upload with progress indicator
- [ ] Files uploaded with 48-hour expiration expectation
- [ ] Shard events include file metadata (blossomUrls, fileHashes, fileNames, expiresAt)
- [ ] Distribution status created for all key holders (pending state)

**Key Holder Download & Caching**:
- [ ] Key holder auto-download triggered on shard receipt
- [ ] Files downloaded from Blossom within 48-hour window
- [ ] Aggressive retry schedule: 1min, 5min, 15min, 1hr, 6hr, 24hr
- [ ] Encrypted files cached to local directory
- [ ] Cache metadata saved to SharedPreferences
- [ ] Download confirmation (kind 2442) sent to owner
- [ ] Owner receives and processes download confirmations

**Distribution Management**:
- [ ] Owner views distribution status per key holder
- [ ] Distribution states: pending, downloaded, missed_window
- [ ] Time until Blossom expiration displayed
- [ ] Blossom cleanup after all key holders download
- [ ] Blossom cleanup after 48-hour window (forced)
- [ ] Manual re-upload for missed key holders

**File Updates**:
- [ ] File replacement creates new distribution
- [ ] Old file deleted from Blossom immediately
- [ ] New distribution window starts (48 hours)
- [ ] Key holders re-download and update cache
- [ ] Add more files to existing lockbox

**Recovery Flow (P2P)**:
- [ ] Recovery reconstructs key from shards
- [ ] File request (kind 2440) sent to key holders
- [ ] Key holder uploads cached file to temporary Blossom
- [ ] Key holder responds with file URL (kind 2441)
- [ ] Recovery initiator downloads from temporary Blossom
- [ ] Files decrypted with reconstructed key
- [ ] Save recovered files with native dialog
- [ ] Temporary Blossom files deleted after recovery (1 hour)

**Error Handling**:
- [ ] Network errors during upload/download (with retry)
- [ ] Blossom server unreachable (clear error message)
- [ ] File size limit exceeded (validation before upload)
- [ ] Key holder misses 48-hour window (marked, owner notified)
- [ ] OS clears cache (graceful degradation, warning shown)
- [ ] Recovery with missing cached files (try multiple key holders)
- [ ] No key holders have cached files (recovery fails with clear error)

**Background Tasks**:
- [ ] Retry failed downloads automatically
- [ ] Blossom cleanup runs hourly
- [ ] Distribution health check runs daily
- [ ] Notifications for missed windows

**Cross-Platform**:
- [ ] File picker native UI on iOS, Android, macOS, Windows, Linux, Web
- [ ] Cache directory access on all platforms
- [ ] Blossom upload/download on all platforms
- [ ] Background tasks scheduled on all platforms

## Performance Benchmarks

- **File Selection**: < 1 second for picker to open
- **Encryption**: 1MB in < 100ms, 100MB in < 5 seconds
- **Upload**: 1MB in < 2 seconds on good connection
- **Download**: Same as upload
- **Decryption**: Same as encryption
- **UI Responsiveness**: 60fps during all operations

## Cleanup

After testing, clean up test data:
```bash
# Delete test lockbox (also deletes from Blossom)
flutter test integration_test/cleanup_test_lockboxes.dart

# Reset Blossom server config to defaults
flutter test integration_test/reset_blossom_config.dart
```

---
**Status**: Ready for implementation and automated test generation

