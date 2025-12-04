# Tasks: Distributed Backup of Vaultes

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
- [x] T001 Add ntc_dcrypto dependency to pubspec.yaml for Shamir's Secret Sharing

## Phase 3.2: UI Stubs & Manual Verification (Outside-In Approach)
**Start with user-facing components for rapid feedback**
- [x] T002 [P] Stub BackupConfigScreen with placeholder content in lib/screens/backup_config_screen.dart
- [x] T003 [P] Stub KeyHolderList widget with placeholder content in lib/widgets/steward_list.dart
- [x] T004 [P] Stub BackupSummary widget with placeholder content in lib/widgets/backup_summary.dart
- [x] T005 [P] Stub RecoveryScreen with placeholder content in lib/screens/recovery_screen.dart
- [x] T006 [P] Integrate backup config into existing vault creation flow in lib/screens/
- [x] T007 Manual verification: Navigate through stubbed backup UI flow

## Phase 3.3: Core Implementation - Data Models (Behind UI Components)
- [x] T008 [P] Create BackupConfig model in lib/models/backup_config.dart
- [x] T009 [P] Create KeyHolder model in lib/models/steward.dart
- [x] T010 [P] Create ShardEvent model in lib/models/shard_event.dart
- [x] T011 [P] Create ShardData model in lib/models/shard_data.dart
- [x] T012 [P] Create BackupStatus enum in lib/models/backup_status.dart
- [x] T013 [P] Create KeyHolderStatus enum in lib/models/steward_status.dart
- [x] T014 [P] Create EventStatus enum in lib/models/event_status.dart

## Phase 3.4: Core Implementation - Services
- [x] T015 [P] Create BackupService with Shamir's Secret Sharing in lib/services/backup_service.dart
- [x] T016 [P] Extend NostrService for gift wrap events in lib/services/nostr_service.dart
- [x] T017 [P] Create ShardDistributionService in lib/services/shard_distribution_service.dart
- [x] T018 [P] Create RecoveryService for key reconstruction in lib/services/recovery_service.dart
- [x] T019 [P] Extend existing KeyService for backup key management in lib/services/key_service.dart

## Phase 3.5: Core Implementation - UI Components
- [x] T020 Implement BackupConfigScreen functionality in lib/screens/backup_config_screen.dart
- [x] T021 Implement KeyHolderList widget functionality in lib/widgets/steward_list.dart
- [x] T022 Implement BackupSummary widget functionality in lib/widgets/backup_summary.dart
- [x] T023 Implement RecoveryScreen functionality in lib/screens/recovery_screen.dart
- [x] T024 Integrate backup configuration into vault creation workflow

## Phase 3.6: Refactoring Pass 1 (Post-Implementation)
**Clean up implementation before adding complexity**
- [x] T025 Remove code duplication from core implementation
- [x] T026 Extract common patterns into reusable functions
- [x] T027 Improve naming and code clarity
- [x] T028 Consolidate error handling patterns

## Phase 3.7: Edge Cases & Error Handling
- [ ] T029 Handle invalid threshold and key count scenarios
- [ ] T030 Add error messages and user feedback for backup failures
- [ ] T031 Handle Nostr relay failures and network timeouts
- [ ] T032 Add loading states and progress indicators for backup operations
- [ ] T033 Handle steward acknowledgment timeouts
- [ ] T034 Handle specification version migration scenarios

## Phase 3.8: Refactoring Pass 2 (Post-Edge Cases)
**Final cleanup before testing**
- [ ] T035 Consolidate error handling patterns across services
- [ ] T036 Refactor complex conditional logic in backup flows
- [ ] T037 Extract configuration and constants for backup settings
- [ ] T038 Optimize Shamir's Secret Sharing performance
- [ ] T039 Optimize Nostr event publishing and retrieval

## Phase 3.9: Unit Tests (After Implementation)
- [ ] T040 [P] Unit tests for BackupConfig model in test/models/backup_config_test.dart
- [ ] T041 [P] Unit tests for KeyHolder model in test/models/steward_test.dart
- [ ] T042 [P] Unit tests for ShardEvent model in test/models/shard_event_test.dart
- [ ] T043 [P] Unit tests for BackupService in test/services/backup_service_test.dart
- [ ] T044 [P] Unit tests for Shamir's Secret Sharing algorithm in test/services/shamir_test.dart
- [ ] T045 [P] Unit tests for NostrService gift wrap events in test/services/nostr_service_test.dart
- [ ] T046 [P] Unit tests for ShardDistributionService in test/services/shard_distribution_service_test.dart
- [ ] T047 [P] Unit tests for RecoveryService in test/services/recovery_service_test.dart
- [ ] T048 [P] Unit tests for validation logic in test/validation/backup_validation_test.dart

## Phase 3.10: Integration Tests (Final Validation)
- [ ] T049 [P] Integration test complete backup setup workflow in test/integration/backup_setup_test.dart
- [ ] T050 [P] Integration test recovery process in test/integration/recovery_test.dart
- [ ] T051 [P] Integration test configuration update scenarios in test/integration/config_update_test.dart
- [ ] T052 [P] Security test Shamir's Secret Sharing in test/security/shamir_security_test.dart
- [ ] T053 [P] Integration test cross-platform backup functionality in test/integration/cross_platform_test.dart
- [ ] T054 [P] Widget test backup configuration screen in test/widget/backup_config_screen_test.dart
- [ ] T055 [P] Widget test steward list widget in test/widget/steward_list_test.dart
- [ ] T056 [P] Widget test backup summary widget in test/widget/backup_summary_test.dart

## Dependencies
- UI stubs (T002-T007) before implementation (T008-T024)
- Data models (T008-T014) before services (T015-T019)
- Services (T015-T019) before UI implementation (T020-T024)
- Core implementation (T008-T024) before refactoring pass 1 (T025-T028)
- Refactoring pass 1 (T025-T028) before edge cases (T029-T034)
- Edge cases (T029-T034) before refactoring pass 2 (T035-T039)
- Refactoring pass 2 (T035-T039) before unit tests (T040-T048)
- Unit tests (T040-T048) before integration tests (T049-T056)
- T008 blocks T015, T020
- T009 blocks T015, T021
- T015 blocks T020, T021, T022, T023

## Parallel Execution Examples
```
# Launch T002-T006 together (UI stubs):
Task: "Stub BackupConfigScreen with placeholder content in lib/screens/backup_config_screen.dart"
Task: "Stub KeyHolderList widget with placeholder content in lib/widgets/steward_list.dart"
Task: "Stub BackupSummary widget with placeholder content in lib/widgets/backup_summary.dart"
Task: "Stub RecoveryScreen with placeholder content in lib/screens/recovery_screen.dart"
Task: "Integrate backup config into existing vault creation flow in lib/screens/"

# Launch T008-T014 together (data models):
Task: "Create BackupConfig model in lib/models/backup_config.dart"
Task: "Create KeyHolder model in lib/models/steward.dart"
Task: "Create ShardEvent model in lib/models/shard_event.dart"
Task: "Create ShardData model in lib/models/shard_data.dart"
Task: "Create BackupStatus enum in lib/models/backup_status.dart"
Task: "Create KeyHolderStatus enum in lib/models/steward_status.dart"
Task: "Create EventStatus enum in lib/models/event_status.dart"

# Launch T015-T019 together (services):
Task: "Create BackupService with Shamir's Secret Sharing in lib/services/backup_service.dart"
Task: "Extend NostrService for gift wrap events in lib/services/nostr_service.dart"
Task: "Create ShardDistributionService in lib/services/shard_distribution_service.dart"
Task: "Create RecoveryService for key reconstruction in lib/services/recovery_service.dart"
Task: "Extend existing KeyService for backup key management in lib/services/key_service.dart"

# Launch T040-T048 together (unit tests):
Task: "Unit tests for BackupConfig model in test/models/backup_config_test.dart"
Task: "Unit tests for KeyHolder model in test/models/steward_test.dart"
Task: "Unit tests for ShardEvent model in test/models/shard_event_test.dart"
Task: "Unit tests for BackupService in test/services/backup_service_test.dart"
Task: "Unit tests for Shamir's Secret Sharing algorithm in test/services/shamir_test.dart"
Task: "Unit tests for NostrService gift wrap events in test/services/nostr_service_test.dart"
Task: "Unit tests for ShardDistributionService in test/services/shard_distribution_service_test.dart"
Task: "Unit tests for RecoveryService in test/services/recovery_service_test.dart"
Task: "Unit tests for validation logic in test/validation/backup_validation_test.dart"

# Launch T049-T056 together (integration tests):
Task: "Integration test complete backup setup workflow in test/integration/backup_setup_test.dart"
Task: "Integration test recovery process in test/integration/recovery_test.dart"
Task: "Integration test configuration update scenarios in test/integration/config_update_test.dart"
Task: "Security test Shamir's Secret Sharing in test/security/shamir_security_test.dart"
Task: "Integration test cross-platform backup functionality in test/integration/cross_platform_test.dart"
Task: "Widget test backup configuration screen in test/widget/backup_config_screen_test.dart"
Task: "Widget test steward list widget in test/widget/steward_list_test.dart"
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
