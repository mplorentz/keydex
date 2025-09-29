# Tasks: Distributed Backup of Lockboxes

**Input**: Design documents from `/specs/002-distributed-backup-of/`
**Prerequisites**: plan.md, research.md, data-model.md

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Extract: Dart/Flutter tech stack, ntc_dcrypto, NDK dependencies
2. Load design documents:
   → data-model.md: Extract entities → model tasks
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, UI components
   → Integration: Nostr service, backup service
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → UI stubs before implementation (Outside-In)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Phase 3.1: Setup
- [ ] T001 Add ntc_dcrypto dependency to pubspec.yaml for Shamir's Secret Sharing

## Phase 3.2: UI Stubs & Manual Verification (Outside-In Approach)
**Start with user-facing components for rapid feedback**
- [ ] T004 [P] Stub BackupConfigScreen with placeholder content in lib/screens/backup_config_screen.dart
- [ ] T005 [P] Stub KeyHolderList widget with placeholder content in lib/widgets/key_holder_list.dart
- [ ] T006 [P] Stub BackupSummary widget with placeholder content in lib/widgets/backup_summary.dart
- [ ] T007 [P] Stub RecoveryScreen with placeholder content in lib/screens/recovery_screen.dart
- [ ] T008 [P] Integrate backup config into existing lockbox creation flow in lib/screens/
- [ ] T009 Manual verification: Navigate through stubbed backup UI flow

## Phase 3.3: Core Implementation - Data Models (Behind UI Components)
- [ ] T010 [P] Create BackupConfig model in lib/models/backup_config.dart
- [ ] T011 [P] Create KeyHolder model in lib/models/key_holder.dart
- [ ] T012 [P] Create ShardEvent model in lib/models/shard_event.dart
- [ ] T013 [P] Create ShardData model in lib/models/shard_data.dart
- [ ] T014 [P] Create BackupStatus enum in lib/models/backup_status.dart
- [ ] T015 [P] Create KeyHolderStatus enum in lib/models/key_holder_status.dart
- [ ] T016 [P] Create EventStatus enum in lib/models/event_status.dart

## Phase 3.4: Core Implementation - Services
- [ ] T017 [P] Create BackupService with Shamir's Secret Sharing in lib/services/backup_service.dart
- [ ] T018 [P] Extend NostrService for gift wrap events in lib/services/nostr_service.dart
- [ ] T019 [P] Create ShardDistributionService in lib/services/shard_distribution_service.dart
- [ ] T020 [P] Create RecoveryService for key reconstruction in lib/services/recovery_service.dart
- [ ] T021 [P] Extend existing KeyService for backup key management in lib/services/key_service.dart

## Phase 3.5: Core Implementation - UI Components
- [ ] T022 Implement BackupConfigScreen functionality in lib/screens/backup_config_screen.dart
- [ ] T023 Implement KeyHolderList widget functionality in lib/widgets/key_holder_list.dart
- [ ] T024 Implement BackupSummary widget functionality in lib/widgets/backup_summary.dart
- [ ] T025 Implement RecoveryScreen functionality in lib/screens/recovery_screen.dart
- [ ] T026 Integrate backup configuration into lockbox creation workflow

## Phase 3.6: Refactoring Pass 1 (Post-Implementation)
**Clean up implementation before adding complexity**
- [ ] T027 Remove code duplication from core implementation
- [ ] T028 Extract common patterns into reusable functions
- [ ] T029 Improve naming and code clarity
- [ ] T030 Consolidate error handling patterns

## Phase 3.7: Edge Cases & Error Handling
- [ ] T031 Handle invalid threshold and key count scenarios
- [ ] T032 Add error messages and user feedback for backup failures
- [ ] T033 Handle Nostr relay failures and network timeouts
- [ ] T034 Add loading states and progress indicators for backup operations
- [ ] T035 Handle key holder acknowledgment timeouts
- [ ] T036 Handle specification version migration scenarios

## Phase 3.8: Refactoring Pass 2 (Post-Edge Cases)
**Final cleanup before testing**
- [ ] T037 Consolidate error handling patterns across services
- [ ] T038 Refactor complex conditional logic in backup flows
- [ ] T039 Extract configuration and constants for backup settings
- [ ] T040 Optimize Shamir's Secret Sharing performance
- [ ] T041 Optimize Nostr event publishing and retrieval

## Phase 3.9: Unit Tests (After Implementation)
- [ ] T042 [P] Unit tests for BackupConfig model in test/models/backup_config_test.dart
- [ ] T043 [P] Unit tests for KeyHolder model in test/models/key_holder_test.dart
- [ ] T044 [P] Unit tests for ShardEvent model in test/models/shard_event_test.dart
- [ ] T045 [P] Unit tests for BackupService in test/services/backup_service_test.dart
- [ ] T046 [P] Unit tests for Shamir's Secret Sharing algorithm in test/services/shamir_test.dart
- [ ] T047 [P] Unit tests for NostrService gift wrap events in test/services/nostr_service_test.dart
- [ ] T048 [P] Unit tests for ShardDistributionService in test/services/shard_distribution_service_test.dart
- [ ] T049 [P] Unit tests for RecoveryService in test/services/recovery_service_test.dart
- [ ] T050 [P] Unit tests for validation logic in test/validation/backup_validation_test.dart

## Phase 3.10: Integration Tests (Final Validation)
- [ ] T051 [P] Integration test complete backup setup workflow in test/integration/backup_setup_test.dart
- [ ] T052 [P] Integration test recovery process in test/integration/recovery_test.dart
- [ ] T053 [P] Integration test configuration update scenarios in test/integration/config_update_test.dart
- [ ] T054 [P] Security test Shamir's Secret Sharing in test/security/shamir_security_test.dart
- [ ] T055 [P] Integration test cross-platform backup functionality in test/integration/cross_platform_test.dart
- [ ] T056 [P] Widget test backup configuration screen in test/widget/backup_config_screen_test.dart
- [ ] T057 [P] Widget test key holder list widget in test/widget/key_holder_list_test.dart
- [ ] T058 [P] Widget test backup summary widget in test/widget/backup_summary_test.dart

## Dependencies
- UI stubs (T004-T009) before implementation (T010-T026)
- Data models (T010-T016) before services (T017-T021)
- Services (T017-T021) before UI implementation (T022-T026)
- Core implementation (T010-T026) before refactoring pass 1 (T027-T030)
- Refactoring pass 1 (T027-T030) before edge cases (T031-T036)
- Edge cases (T031-T036) before refactoring pass 2 (T037-T041)
- Refactoring pass 2 (T037-T041) before unit tests (T042-T050)
- Unit tests (T042-T050) before integration tests (T051-T058)
- T010 blocks T017, T022
- T011 blocks T017, T023
- T017 blocks T022, T023, T024, T025

## Parallel Execution Examples
```
# Launch T004-T008 together (UI stubs):
Task: "Stub BackupConfigScreen with placeholder content in lib/screens/backup_config_screen.dart"
Task: "Stub KeyHolderList widget with placeholder content in lib/widgets/key_holder_list.dart"
Task: "Stub BackupSummary widget with placeholder content in lib/widgets/backup_summary.dart"
Task: "Stub RecoveryScreen with placeholder content in lib/screens/recovery_screen.dart"
Task: "Integrate backup config into existing lockbox creation flow in lib/screens/"

# Launch T010-T016 together (data models):
Task: "Create BackupConfig model in lib/models/backup_config.dart"
Task: "Create KeyHolder model in lib/models/key_holder.dart"
Task: "Create ShardEvent model in lib/models/shard_event.dart"
Task: "Create ShardData model in lib/models/shard_data.dart"
Task: "Create BackupStatus enum in lib/models/backup_status.dart"
Task: "Create KeyHolderStatus enum in lib/models/key_holder_status.dart"
Task: "Create EventStatus enum in lib/models/event_status.dart"

# Launch T017-T021 together (services):
Task: "Create BackupService with Shamir's Secret Sharing in lib/services/backup_service.dart"
Task: "Extend NostrService for gift wrap events in lib/services/nostr_service.dart"
Task: "Create ShardDistributionService in lib/services/shard_distribution_service.dart"
Task: "Create RecoveryService for key reconstruction in lib/services/recovery_service.dart"
Task: "Extend existing KeyService for backup key management in lib/services/key_service.dart"

# Launch T042-T050 together (unit tests):
Task: "Unit tests for BackupConfig model in test/models/backup_config_test.dart"
Task: "Unit tests for KeyHolder model in test/models/key_holder_test.dart"
Task: "Unit tests for ShardEvent model in test/models/shard_event_test.dart"
Task: "Unit tests for BackupService in test/services/backup_service_test.dart"
Task: "Unit tests for Shamir's Secret Sharing algorithm in test/services/shamir_test.dart"
Task: "Unit tests for NostrService gift wrap events in test/services/nostr_service_test.dart"
Task: "Unit tests for ShardDistributionService in test/services/shard_distribution_service_test.dart"
Task: "Unit tests for RecoveryService in test/services/recovery_service_test.dart"
Task: "Unit tests for validation logic in test/validation/backup_validation_test.dart"

# Launch T051-T058 together (integration tests):
Task: "Integration test complete backup setup workflow in test/integration/backup_setup_test.dart"
Task: "Integration test recovery process in test/integration/recovery_test.dart"
Task: "Integration test configuration update scenarios in test/integration/config_update_test.dart"
Task: "Security test Shamir's Secret Sharing in test/security/shamir_security_test.dart"
Task: "Integration test cross-platform backup functionality in test/integration/cross_platform_test.dart"
Task: "Widget test backup configuration screen in test/widget/backup_config_screen_test.dart"
Task: "Widget test key holder list widget in test/widget/key_holder_list_test.dart"
Task: "Widget test backup summary widget in test/widget/backup_summary_test.dart"
```

## Notes
- [P] tasks = different files, no dependencies
- Manual verification of UI stubs before implementing functionality
- Refactoring passes clean up code before adding complexity
- Unit tests written after implementation and refactoring
- Integration tests written last for complete workflow validation
- Commit after each task
- Security-first approach: Shamir's Secret Sharing implementation before UI integration
- Outside-In development: UI stubs first, then implementation behind components
- Cross-platform testing on all 5 Flutter target platforms
- Nostr protocol compliance for gift wrap events (kind 1059)
- NIP-44 encryption for all sensitive data transmission

## Task Generation Rules Applied
1. **From Data Model**:
   - Each entity (BackupConfig, KeyHolder, ShardEvent, ShardData) → model creation task [P]
   - Each enum (BackupStatus, KeyHolderStatus, EventStatus) → enum creation task [P]
   
2. **From Research**:
   - ntc_dcrypto library → dependency setup task
   - NDK extension → service extension task
   - NIP-44/NIP-59 → encryption implementation tasks
   
3. **From Plan**:
   - UI components → stub tasks first, then implementation
   - Services → parallel creation tasks [P]
   - Integration → test tasks after implementation
   
4. **Ordering**:
   - Setup → UI Stubs → Models → Services → UI Implementation → Refactoring → Edge Cases → Tests
   - Dependencies block parallel execution where files are shared

## Validation Checklist
- [x] All UI components have stub tasks
- [x] All entities have model tasks
- [x] All enums have creation tasks
- [x] All services have implementation tasks
- [x] Refactoring passes included after implementation and edge cases
- [x] Unit tests come after implementation and refactoring
- [x] Integration tests come last
- [x] Parallel tasks truly independent (different files)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Security-first approach maintained
- [x] Outside-In development approach followed
- [x] Cross-platform considerations included
- [x] Nostr protocol compliance ensured
