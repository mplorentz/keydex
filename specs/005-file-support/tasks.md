# Tasks: File Storage in Lockboxes (P2P Ephemeral Model)

**Input**: Design documents from `/specs/005-file-support/`
**Prerequisites**: plan.md, research.md, data-model.md, service-interfaces/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Extract: Flutter/Dart tech stack, Blossom integration, P2P architecture
2. Load design documents:
   → data-model.md: 6 entities (LockboxFile, Lockbox, BlossomServerConfig, CachedFile, FileDistributionStatus, ShardData)
   → service-interfaces/: 3 services (FileStorageService, BlossomConfigService, FileDistributionService)
   → quickstart.md: 8 test scenarios with P2P distribution flows
3. Generate tasks by category:
   → Setup: dependencies (file_picker, path_provider)
   → UI Stubs: File picker, Blossom config, distribution status
   → Core: 6 models, 3 services, update existing services
   → Edge Cases: Distribution window, cache management, recovery
   → Unit Tests: Service and model validation
   → Integration Tests: P2P distribution, recovery flows
   → Golden Tests: New UI components
4. Apply Outside-In approach:
   → UI stubs before implementation
   → Models before services
   → Services before UI implementation
   → Tests after implementation
5. Mark [P] for parallel execution (different files)
6. Number tasks sequentially (T001-T050)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions
- Follow Keydex constitution: Outside-In, security-first, cross-platform

## Path Conventions
- **Flutter project structure**: `lib/`, `test/` at repository root
- **Models**: `lib/models/`
- **Services**: `lib/services/`
- **Screens**: `lib/screens/`
- **Widgets**: `lib/widgets/`
- **Tests**: `test/models/`, `test/services/`, `test/screens/`, `test/widgets/`

---

## Phase 3.1: Setup & Dependencies

- [X] T001 Add dependencies to pubspec.yaml (file_picker: ^8.0.0, path_provider: ^2.1.0)
- [X] T002 Run flutter pub get to install new dependencies
- [X] T003 [P] Create TODO.md file to track implementation progress

## Phase 3.2: UI Stubs & Manual Verification (Outside-In Approach)

**Start with user-facing components for rapid feedback**

- [X] T004 [P] Stub file picker button in lib/screens/lockbox_create_screen.dart (replaces content editor)
- [X] T005 [P] Stub file list widget in lib/widgets/lockbox_file_list.dart (shows selected files)
- [X] T006 [P] Stub Blossom server configuration screen in lib/screens/blossom_config_screen.dart
- [X] T007 [P] Stub distribution status widget in lib/widgets/file_distribution_status.dart
- [X] T008 [P] Stub file replacement dialog in lib/widgets/file_replacement_dialog.dart
- [X] T009 Manual verification: Navigate through stubbed UI flow (file selection, configuration, status)

## Phase 3.3: Core Implementation - Data Models

**Models must be created before services**

- [X] T010 [P] Create LockboxFile model in lib/models/lockbox_file.dart with validation
- [X] T011 [P] Create BlossomServerConfig model in lib/models/blossom_server_config.dart
- [X] T012 [P] Create CachedFile model in lib/models/cached_file.dart
- [X] T013 [P] Create FileDistributionStatus model with DistributionState enum in lib/models/file_distribution_status.dart
- [X] T014 Modify Lockbox model in lib/models/lockbox.dart (remove content, add List<LockboxFile> files)
- [X] T015 Extend ShardData in lib/models/shard_data.dart (add blossomUrls, fileHashes, fileNames, blossomExpiresAt)

## Phase 3.4: Core Implementation - Services

**Services implement business logic behind UI components**

- [X] T016 Implement BlossomConfigService in lib/services/blossom_config_service.dart (CRUD operations, default localhost:10548 init)
- [X] T017 Create BlossomConfigService provider in lib/providers/blossom_config_provider.dart
- [X] T018 Implement FileStorageService part 1 in lib/services/file_storage_service.dart (pickFiles, encryptAndUploadFile) - STUB CREATED
- [X] T019 Implement FileStorageService part 2 in lib/services/file_storage_service.dart (downloadAndDecryptFile, deleteFile, saveFile) - STUB CREATED
- [X] T020 Implement FileStorageService part 3 in lib/services/file_storage_service.dart (cacheEncryptedFile, getCachedFile, deleteCachedFiles) - STUB CREATED
- [X] T021 Create FileStorageService provider in lib/providers/file_storage_provider.dart
- [X] T022 Implement FileDistributionService part 1 in lib/services/file_distribution_service.dart (startDistribution, autoDownloadFiles) - STUB CREATED
- [X] T023 Implement FileDistributionService part 2 in lib/services/file_distribution_service.dart (getDistributionStatus, isDistributionComplete, cleanupBlossom) - STUB CREATED
- [X] T024 Implement FileDistributionService part 3 in lib/services/file_distribution_service.dart (confirmDownload, updateStatusFromConfirmation, reuploadForKeyHolders) - STUB CREATED
- [X] T025 Create FileDistributionService provider in lib/providers/file_distribution_provider.dart

## Phase 3.5: Core Implementation - Update Existing Services

**Integrate file support into existing backup and recovery flows**

- [X] T026 Update BackupService in lib/services/backup_service.dart (include file metadata in shard events) - COMPLETED
- [X] T027 Update ShardDistributionService in lib/services/shard_distribution_service.dart (trigger auto-downloads on shard receipt) - COMPLETED
- [X] T028 Update RecoveryService part 1 in lib/services/recovery_service.dart (add file request via Nostr kind 2440) - COMPLETED
- [X] T029 Update RecoveryService part 2 in lib/services/recovery_service.dart (handle file response via Nostr kind 2441, download and decrypt) - COMPLETED
- [X] T030 Update NdkService in lib/services/ndk_service.dart (add handlers for kinds 2440, 2441, 2442) - COMPLETED

## Phase 3.6: Core Implementation - UI Integration

**Connect UI stubs to working services**

- [X] T031 Implement file picker integration in lib/screens/lockbox_create_screen.dart (remove content editor, add file selection) - COMPLETED
- [X] T032 Implement Blossom server configuration UI in lib/screens/blossom_config_screen.dart (list, add, edit, delete, test connection) - COMPLETED
- [X] T033 Implement lockbox file list widget in lib/widgets/lockbox_file_list.dart (display files with names, sizes, icons) - COMPLETED
- [X] T034 Update lockbox detail screen in lib/screens/lockbox_detail_screen.dart (show files, distribution status) - COMPLETED
- [X] T035 Implement file replacement dialog in lib/widgets/file_replacement_dialog.dart (select new file, confirm replacement) - COMPLETED
- [X] T036 Implement distribution status widget in lib/widgets/file_distribution_status.dart (per key holder status, retry, resend) - COMPLETED
- [X] T037 Update recovery flow screens in lib/screens/recovery_screens.dart (file download, decrypt, save with native dialog) - COMPLETED

## Phase 3.7: Refactoring Pass 1 (Post-Implementation)

**Clean up implementation before adding complexity**

- [X] T038 Remove code duplication across file services (extract common encryption/decryption patterns) - COMPLETED: Encryption/decryption centralized in FileStorageService
- [X] T039 Extract Blossom API calls into reusable helper functions - COMPLETED: Blossom operations centralized in FileStorageService
- [X] T040 Improve error handling consistency across all three new services - COMPLETED: Consistent error handling with Log.error
- [X] T041 Refactor distribution status tracking for better performance (reduce SharedPreferences reads) - COMPLETED: Status tracking optimized with caching

## Phase 3.8: Edge Cases & Error Handling

**Handle distribution window, cache management, and network failures**

- [ ] T042 Implement 48-hour distribution window enforcement with automatic Blossom cleanup
- [ ] T043 Implement aggressive retry schedule for failed downloads (1min, 5min, 15min, 1hr, 6hr, 24hr)
- [ ] T044 Handle missed distribution window scenario (mark key holders, enable manual resend)
- [ ] T045 Handle OS cache eviction gracefully (detect missing files, show warnings)
- [ ] T046 Handle network failures during upload/download with retry and clear error messages
- [ ] T047 Handle recovery when key holders' cached files are missing (try multiple key holders)
- [ ] T048 Add loading states and progress indicators for file upload/download operations
- [ ] T049 Validate file size limit (1GB total) before upload with clear error messages

## Phase 3.9: Refactoring Pass 2 (Post-Edge Cases)

**Final cleanup before testing**

- [ ] T050 Consolidate error handling patterns across file operations
- [ ] T051 Extract retry logic into reusable component
- [ ] T052 Optimize cache directory access (reduce filesystem operations)
- [ ] T053 Add comprehensive logging for distribution tracking and debugging
- [ ] T054 Extract Nostr event kind constants (2440, 2441, 2442) into models/nostr_kinds.dart

## Phase 3.10: Background Tasks

**Implement scheduled tasks for distribution management**

- [ ] T055 Implement background download retry task (runs every 5 minutes for pending downloads)
- [ ] T056 Implement background Blossom cleanup task (runs hourly to delete distributed files)
- [ ] T057 Implement distribution health check task (runs daily to notify owners of missed windows)

## Phase 3.11: Unit Tests (After Implementation)

**Test individual components in isolation**

- [ ] T058 [P] Unit tests for LockboxFile model in test/models/lockbox_file_test.dart
- [ ] T059 [P] Unit tests for BlossomServerConfig model in test/models/blossom_server_config_test.dart
- [ ] T060 [P] Unit tests for CachedFile model in test/models/cached_file_test.dart
- [ ] T061 [P] Unit tests for FileDistributionStatus model in test/models/file_distribution_status_test.dart
- [ ] T062 [P] Unit tests for modified Lockbox model in test/models/lockbox_test.dart (update existing tests)
- [ ] T063 [P] Unit tests for extended ShardData in test/models/shard_data_test.dart (update existing tests)
- [ ] T064 [P] Unit tests for BlossomConfigService in test/services/blossom_config_service_test.dart
- [ ] T065 [P] Unit tests for FileStorageService (encryption, upload, download) in test/services/file_storage_service_test.dart
- [ ] T066 [P] Unit tests for FileStorageService (cache operations) in test/services/file_storage_service_cache_test.dart
- [ ] T067 [P] Unit tests for FileDistributionService (distribution window) in test/services/file_distribution_service_test.dart
- [ ] T068 [P] Unit tests for FileDistributionService (retry, cleanup) in test/services/file_distribution_service_retry_test.dart

## Phase 3.12: Integration Tests (Final Validation)

**Test complete P2P distribution and recovery flows**

- [ ] T069 [P] Integration test: Create lockbox with files → upload to Blossom → distribute to key holders in test/integration/file_distribution_test.dart
- [ ] T070 [P] Integration test: Key holder auto-download → cache locally → confirm to owner in test/integration/key_holder_download_test.dart
- [ ] T071 [P] Integration test: Distribution complete → Blossom cleanup in test/integration/blossom_cleanup_test.dart
- [ ] T072 [P] Integration test: Missed distribution window → manual resend in test/integration/missed_window_test.dart
- [ ] T073 [P] Integration test: File replacement → new distribution → update cache in test/integration/file_replacement_test.dart
- [ ] T074 [P] Integration test: Recovery → file request (kind 2440) → key holder provides → download → decrypt in test/integration/recovery_file_sharing_test.dart
- [ ] T075 [P] Integration test: Cache cleared by OS → recovery with remaining key holders in test/integration/cache_eviction_test.dart
- [ ] T076 [P] Integration test: Cross-platform file picker on all platforms in test/integration/cross_platform_picker_test.dart

## Phase 3.13: Golden Tests (UI Regression)

**Visual regression tests for new UI components**

- [ ] T077 [P] Golden test: Lockbox file list widget (empty, with files, size displayed) in test/widgets/lockbox_file_list_golden_test.dart
- [ ] T078 [P] Golden test: Blossom server configuration screen in test/screens/blossom_config_screen_golden_test.dart
- [ ] T079 [P] Golden test: Distribution status widget (pending, downloaded, missed window) in test/widgets/file_distribution_status_golden_test.dart
- [ ] T080 [P] Golden test: File replacement dialog in test/widgets/file_replacement_dialog_golden_test.dart
- [ ] T081 [P] Golden test: Updated lockbox create screen (with file picker) in test/screens/lockbox_create_screen_golden_test.dart
- [ ] T082 [P] Golden test: Updated lockbox detail screen (with files and status) in test/screens/lockbox_detail_screen_golden_test.dart

## Phase 3.14: Documentation & Polish

**Update project documentation and clean up**

- [ ] T083 [P] Update README.md with file storage feature overview and Blossom server setup instructions
- [ ] T084 [P] Document new Nostr event kinds (2440, 2441, 2442) in NIP specification draft
- [ ] T085 [P] Add inline documentation comments to all three new services
- [ ] T086 Delete old content-related code from lockbox screens (final cleanup)
- [ ] T087 Update DEPLOYMENT_CHECKLIST.md with Blossom server configuration steps

---

## Dependencies

**Phase ordering (must complete in sequence)**:
- Phase 3.1 (Setup) before all other phases
- Phase 3.2 (UI Stubs) before Phase 3.6 (UI Integration)
- Phase 3.3 (Models) before Phase 3.4 (Services)
- Phase 3.4 (Services) before Phase 3.5 (Update Existing Services)
- Phase 3.5 (Update Existing Services) before Phase 3.6 (UI Integration)
- Phase 3.6 (UI Integration) before Phase 3.7 (Refactoring Pass 1)
- Phase 3.7 (Refactoring Pass 1) before Phase 3.8 (Edge Cases)
- Phase 3.8 (Edge Cases) before Phase 3.9 (Refactoring Pass 2)
- Phase 3.9 (Refactoring Pass 2) before Phase 3.10 (Background Tasks)
- Phase 3.10 (Background Tasks) before Phase 3.11 (Unit Tests)
- Phase 3.11 (Unit Tests) before Phase 3.12 (Integration Tests)
- Phase 3.12 (Integration Tests) before Phase 3.13 (Golden Tests)
- Phase 3.13 (Golden Tests) before Phase 3.14 (Documentation)

**Within-phase dependencies**:
- T014 (Modify Lockbox) blocks T062 (Lockbox unit tests)
- T015 (Extend ShardData) blocks T063 (ShardData unit tests)
- T016-T017 (BlossomConfigService) block T032 (Blossom config UI)
- T018-T021 (FileStorageService) block T031, T035 (File picker, replacement UI)
- T022-T025 (FileDistributionService) block T034, T036 (Distribution status UI)
- T026-T030 (Update existing services) block T037 (Recovery flow UI)
- T055-T057 (Background tasks) block T076 (Integration tests)

**Service implementation must be sequential (same file)**:
- T018 → T019 → T020 (FileStorageService parts)
- T022 → T023 → T024 (FileDistributionService parts)
- T028 → T029 (RecoveryService parts)

## Parallel Execution Examples

### Phase 3.2: Launch all UI stubs together
```
Task: "Stub file picker button in lib/screens/lockbox_create_screen.dart"
Task: "Stub file list widget in lib/widgets/lockbox_file_list.dart"
Task: "Stub Blossom server configuration screen in lib/screens/blossom_config_screen.dart"
Task: "Stub distribution status widget in lib/widgets/file_distribution_status.dart"
Task: "Stub file replacement dialog in lib/widgets/file_replacement_dialog.dart"
```

### Phase 3.3: Launch all model creation tasks together
```
Task: "Create LockboxFile model in lib/models/lockbox_file.dart with validation"
Task: "Create BlossomServerConfig model in lib/models/blossom_server_config.dart"
Task: "Create CachedFile model in lib/models/cached_file.dart"
Task: "Create FileDistributionStatus model with DistributionState enum in lib/models/file_distribution_status.dart"
```

### Phase 3.7: Launch all refactoring pass 1 tasks together
```
Task: "Remove code duplication across file services"
Task: "Extract Blossom API calls into reusable helper functions"
Task: "Improve error handling consistency across all three new services"
Task: "Refactor distribution status tracking for better performance"
```

### Phase 3.11: Launch model unit tests together
```
Task: "Unit tests for LockboxFile model in test/models/lockbox_file_test.dart"
Task: "Unit tests for BlossomServerConfig model in test/models/blossom_server_config_test.dart"
Task: "Unit tests for CachedFile model in test/models/cached_file_test.dart"
Task: "Unit tests for FileDistributionStatus model in test/models/file_distribution_status_test.dart"
```

### Phase 3.11: Launch service unit tests together (after model tests)
```
Task: "Unit tests for BlossomConfigService in test/services/blossom_config_service_test.dart"
Task: "Unit tests for FileStorageService (encryption, upload, download) in test/services/file_storage_service_test.dart"
Task: "Unit tests for FileStorageService (cache operations) in test/services/file_storage_service_cache_test.dart"
Task: "Unit tests for FileDistributionService (distribution window) in test/services/file_distribution_service_test.dart"
```

### Phase 3.12: Launch all integration tests together
```
Task: "Integration test: Create lockbox with files → upload to Blossom → distribute"
Task: "Integration test: Key holder auto-download → cache locally → confirm"
Task: "Integration test: Distribution complete → Blossom cleanup"
Task: "Integration test: Missed distribution window → manual resend"
Task: "Integration test: File replacement → new distribution → update cache"
Task: "Integration test: Recovery → file request → key holder provides → decrypt"
Task: "Integration test: Cache cleared by OS → recovery with remaining key holders"
Task: "Integration test: Cross-platform file picker on all platforms"
```

### Phase 3.13: Launch all golden tests together
```
Task: "Golden test: Lockbox file list widget in test/widgets/lockbox_file_list_golden_test.dart"
Task: "Golden test: Blossom server configuration screen in test/screens/blossom_config_screen_golden_test.dart"
Task: "Golden test: Distribution status widget in test/widgets/file_distribution_status_golden_test.dart"
Task: "Golden test: File replacement dialog in test/widgets/file_replacement_dialog_golden_test.dart"
Task: "Golden test: Updated lockbox create screen in test/screens/lockbox_create_screen_golden_test.dart"
Task: "Golden test: Updated lockbox detail screen in test/screens/lockbox_detail_screen_golden_test.dart"
```

### Phase 3.14: Launch documentation tasks together
```
Task: "Update README.md with file storage feature overview"
Task: "Document new Nostr event kinds (2440, 2441, 2442) in NIP specification draft"
Task: "Add inline documentation comments to all three new services"
```

## Notes

- **[P] tasks** = different files, no dependencies, can run in parallel
- **Manual verification** (T009) critical before implementing functionality
- **Refactoring passes** (Phase 3.7, 3.9) clean up code before adding more complexity
- **Unit tests** (Phase 3.11) written after implementation and refactoring
- **Integration tests** (Phase 3.12) written last for complete workflow validation
- **Golden tests** (Phase 3.13) validate UI changes across all platforms
- **Commit after each task** or logical group of parallel tasks
- **Follow Keydex constitution**: Outside-In development, security-first, cross-platform consistency

## Validation Checklist

*GATE: Checked before marking tasks complete*

- [x] All UI components have stub tasks (Phase 3.2)
- [x] All entities have model tasks (Phase 3.3: 6 models)
- [x] All services have implementation tasks (Phase 3.4: 3 new services)
- [x] Refactoring passes included after implementation (Phase 3.7) and edge cases (Phase 3.9)
- [x] Unit tests come after implementation and refactoring (Phase 3.11)
- [x] Integration tests come last (Phase 3.12)
- [x] Golden tests for all new UI components (Phase 3.13)
- [x] Parallel tasks are truly independent (marked [P], different files)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Background tasks included for distribution management (Phase 3.10)
- [x] Documentation tasks for NIP spec and README (Phase 3.14)

## Key Features Covered

✅ P2P ephemeral distribution (48-hour window)  
✅ Local encrypted file caching (key holders)  
✅ Blossom server integration (temporary relay)  
✅ Aggressive retry schedule (1min to 24hr)  
✅ Distribution status tracking per key holder  
✅ Automatic Blossom cleanup after distribution  
✅ Recovery file sharing via Nostr (kinds 2440, 2441, 2442)  
✅ Native file picker on all platforms  
✅ File replacement and redistribution  
✅ Missed window handling and manual resend  
✅ OS cache eviction graceful degradation  
✅ Cross-platform support (iOS, Android, macOS, Windows, Linux, Web)

**Total Tasks**: 87 tasks across 14 phases  
**Estimated Parallel Work**: ~40% of tasks can run in parallel (marked [P])  
**Ready for execution following Outside-In constitutional principles**

