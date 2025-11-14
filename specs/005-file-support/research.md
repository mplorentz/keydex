# Phase 0: Research & Technical Decisions

**Feature**: File Storage in Lockboxes  
**Date**: 2025-11-14

## Research Overview

This document captures technical research and decisions for implementing file storage support in Keydex lockboxes. The feature replaces direct text editing with file-based storage using native file pickers and Blossom storage servers.

## Key Technical Decisions

### 1. Cross-Platform File Picker

**Decision**: Use `file_picker` package (^8.0.0)

**Rationale**:
- Provides native file picker UI on all platforms (iOS, Android, macOS, Windows, Linux, Web)
- Supports multiple file selection out of the box
- Returns file paths and bytes, enabling both desktop and mobile workflows
- Active maintenance and wide adoption in Flutter ecosystem
- Handles platform permissions automatically

**Alternatives Considered**:
- `image_picker`: Limited to images/videos only
- Platform channels: Too much custom code per platform
- `file_selector`: Desktop-only, no mobile support

**Implementation Notes**:
- Use `FilePicker.platform.pickFiles(allowMultiple: true)` for multi-file selection
- Handle `PlatformFile` objects for cross-platform compatibility
- Web platform returns bytes directly, other platforms return file paths

### 2. Blossom Server Integration (Ephemeral Relay Model)

**Decision**: Use NDK's built-in Blossom support as **temporary file relay**, not permanent storage

**Rationale**:
- Blossom servers used to relay files between owner and key holders (24-48 hour window)
- True P2P model: Files distributed to key holder devices, not stored long-term on servers
- Privacy: Files only on third-party servers during distribution, then deleted
- Cost-effective: Minimal Blossom storage usage
- Aligns with Nostr philosophy: Ephemeral relay, distributed storage
- NDK 0.5.1 provides upload/download/delete operations

**File Lifecycle**:
1. Owner uploads encrypted files to Blossom (temporary)
2. Key holders auto-download within 48 hours (aggressive retry)
3. After all key holders download → Delete from Blossom
4. Files now live only on key holder devices (encrypted, local cache)
5. During recovery: Key holder re-uploads to temporary Blossom location

**Alternatives Considered**:
- Permanent Blossom storage: Privacy concerns, ongoing costs, not P2P
- Direct P2P transfer: Complex NAT traversal, requires both online simultaneously
- IPFS/similar: Additional dependencies, complexity not justified

**Implementation Notes**:
- Use `ndk.blossom.upload()` with 7-day maximum lifetime expectation
- Use `ndk.blossom.download()` for key holder retrieval (aggressive retry schedule)
- Use `ndk.blossom.delete()` after successful distribution
- Track upload timestamp, auto-cleanup after 7 days even if some key holders missed window
- Blossom server URLs follow HTTP/HTTPS format (not WebSocket like relays)

### 3. File Encryption Strategy

**Decision**: Use symmetric AES-256-GCM encryption via ntcdcrypto

**Rationale**:
- Files can be large (up to 1GB), symmetric encryption is efficient
- AES-256-GCM provides both confidentiality and authenticity
- ntcdcrypto package already used in project, supports AES-GCM
- Encryption key becomes the lockbox secret that is Shamir-shared
- Key holders can decrypt files during recovery with reassembled key

**Alternatives Considered**:
- NIP-44 encryption: Designed for small messages, not large files
- Public key encryption: Too slow for large files
- Stream encryption: Complexity not justified for current needs

**Implementation Notes**:
- Generate 32-byte (256-bit) random key for each lockbox
- Encrypt file bytes before upload: `encrypt_aes_gcm(fileBytes, symmetricKey)`
- Store encryption key using existing Shamir's Secret Sharing
- Include Blossom blob hash in shard metadata for retrieval
- Decrypt during recovery: `decrypt_aes_gcm(encryptedBytes, reassembledKey)`

### 4. Multiple File Support in Lockbox Model

**Decision**: Store list of file metadata in lockbox, single encryption key for all files

**Rationale**:
- User clarified that multiple files should be supported
- Simplifies key management: one Shamir share set per lockbox, not per file
- Files are logically grouped in a lockbox container
- Reduces complexity of shard distribution

**Alternatives Considered**:
- One key per file: Explosion of shard events, complex tracking
- Zip files: User loses visibility of individual files, harder to manage

**Implementation Notes**:
- Replace `Lockbox.content` field with `List<LockboxFile>` field
- Each `LockboxFile` contains: name, size, mimeType, blossomHash, uploadedAt
- All files in a lockbox encrypted with same symmetric key
- Maximum total size across all files: 1GB

### 5. Blossom Server Configuration

**Decision**: Create `BlossomServerConfig` model similar to `RelayConfiguration`

**Rationale**:
- Consistent UX with existing relay configuration
- Users need to configure their preferred Blossom servers
- Multiple servers support for redundancy
- Similar validation and storage patterns

**Alternatives Considered**:
- Hardcoded servers: Not flexible for user needs
- Combined with relay config: Different protocols, cleaner separation

**Implementation Notes**:
- Store in SharedPreferences like relay configs
- Validation: Must be valid HTTP or HTTPS URL
- UI similar to relay configuration screen
- Default server: `http://localhost:10548` (local Blossom server for development)
- Production servers can be added later via settings UI

### 6. Local Encrypted File Cache (Key Holders)

**Decision**: Key holders store encrypted files locally in app cache directory

**Rationale**:
- P2P model: Files distributed across key holder devices, not centralized
- Cache survives app restarts but can be cleared by OS if needed
- Files remain encrypted at rest (safe for local storage)
- Enables recovery without requiring Blossom (key holder provides file directly)
- Simpler than re-downloading from Blossom each time

**Alternatives Considered**:
- Keep in memory only: Lost on app restart, not viable
- Store in secure storage: Overkill, files are encrypted anyway
- Always re-download: Wastes bandwidth, requires Blossom availability

**Implementation Notes**:
- Use app cache directory: `getApplicationCacheDirectory()`
- File naming: `{lockboxId}/{fileHash}.enc`
- Track which files are cached in SharedPreferences
- Automatic cache eviction if storage space low (OS handles)
- Owner doesn't cache files (has originals or can decrypt from key)

### 7. Aggressive Download Window

**Decision**: 48-hour window for key holders to download files from Blossom

**Rationale**:
- Keeps files on Blossom servers for minimal time
- Aggressive retry schedule ensures high success rate
- Owner alerted if key holder misses window
- Can re-upload on demand if needed

**Retry Schedule**:
- Immediate on shard receipt
- 1 minute later if failed
- 5 minutes later
- 15 minutes later
- 1 hour later
- 6 hours later
- 24 hours later

**Implementation Notes**:
- Background task manages retry schedule
- Push notification after 24 hours if not downloaded
- Owner dashboard shows "Alice hasn't downloaded files" warning
- Owner can manually trigger re-upload to reset window

### 8. Recovery File Sharing via Nostr + Temporary Blossom

**Decision**: During recovery, key holders upload cached files to temporary Blossom location

**Rationale**:
- Files already on key holder devices (cached locally)
- Recovery initiator requests via Nostr event
- Key holder uploads to Blossom temporarily (1 hour lifetime)
- Simpler than custom P2P protocol
- Reuses existing Blossom infrastructure

**New Nostr Event Kinds**:
- **Kind 2440**: File request (recovery initiator → key holders)
- **Kind 2441**: File response (key holder → recovery initiator with Blossom URL)

**Alternatives Considered**:
- Custom P2P transfer: Complex, NAT issues
- Keep files on Blossom forever: Not P2P, privacy issues
- Use Nostr event content directly: 64KB limit, too small for files

**Implementation Notes**:
- Recovery initiator sends kind 2440 to key holders
- Key holder uploads cached encrypted file to Blossom
- Key holder responds with kind 2441 containing temporary URL
- Recovery initiator downloads, decrypts, saves
- Delete from Blossom after recovery completes (1 hour max)

### 9. File Save/Recovery UI

**Decision**: Use `file_picker` saveFile() for recovered file export

**Rationale**:
- Consistent with file selection UX
- Native save dialogs on all platforms
- User chooses destination, avoiding permission issues
- Supports original filename suggestion

**Alternatives Considered**:
- Auto-save to downloads: Permission and discovery issues
- Share sheet: Not all platforms, harder to find files

**Implementation Notes**:
- During recovery, decrypt files to memory (Uint8List)
- Call `FilePicker.platform.saveFile()` with suggested filename
- Handle cancellation gracefully (user may not want all files)

## Dependencies to Add

```yaml
dependencies:
  file_picker: ^8.0.0        # Cross-platform file picker
  path_provider: ^2.1.0      # Access cache directory for local file storage

# Existing dependencies (no changes needed):
# - ndk: ^0.5.1         # Already has Blossom support
# - ntcdcrypto: ^0.4.0  # Already has AES-GCM
```

## Open Questions / Future Considerations

1. **Production Blossom Servers**: Localhost default for development; need to identify reliable public servers for production
2. **Cache Size Management**: Limit on total encrypted file cache size? (Let OS manage for MVP)
3. **Offline Key Holders**: How to handle key holders who are offline for weeks? (Manual re-upload by owner)
4. **File Compression**: Should we compress before encrypt for larger files? (Future optimization)
5. **Multiple Recovery Scenarios**: If multiple key holders initiate recovery simultaneously, how to coordinate? (First wins, others use their cached files)
6. **Blossom Server Availability During Recovery**: What if no Blossom server available? (Key holders could use alternative relay method - future)
7. **Local Blossom Setup**: Should we document how to run a local Blossom server for development? (Yes, add to README)

## Research Validation

- [x] All technical decisions documented with rationale
- [x] No NEEDS CLARIFICATION markers remain
- [x] Dependencies identified and compatibility verified
- [x] Cross-platform considerations addressed
- [x] Security implications reviewed
- [x] Performance constraints considered (1GB file size)
- [x] Integration with existing architecture validated

---
**Ready for Phase 1: Design & Contracts**

