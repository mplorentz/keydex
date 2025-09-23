# Tasks: Encrypted Text Lockbox

**Input**: Design documents from `/specs/001-store-text-in-lockbox/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Mobile**: `lib/`, `test/` at repository root (Flutter app structure)
- Paths shown below assume Flutter mobile app structure

## Phase 3.1: Setup
- [ ] T001 Create Flutter project structure with lib/, test/, integration_test/ directories
- [ ] T002 Initialize Flutter project with dependencies: dart_nostr, local_auth, shared_preferences
- [ ] T003 [P] Configure linting and formatting tools (analysis_options.yaml, dart format)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T004 [P] Contract test AuthService in test/contract/test_auth_service.dart
- [ ] T005 [P] Contract test EncryptionService in test/contract/test_encryption_service.dart
- [ ] T006 [P] Contract test LockboxService in test/contract/test_lockbox_service.dart
- [ ] T007 [P] Integration test lockbox creation flow in integration_test/test_lockbox_creation.dart
- [ ] T008 [P] Integration test authentication flow in integration_test/test_authentication.dart
- [ ] T009 [P] Integration test encryption/decryption flow in integration_test/test_encryption.dart

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T010 [P] Lockbox model in lib/models/lockbox.dart
- [ ] T011 [P] TextContent model in lib/models/text_content.dart
- [ ] T012 [P] EncryptionKey model in lib/models/encryption_key.dart
- [ ] T013 [P] NostrKeyPair model in lib/models/nostr_key_pair.dart
- [ ] T014 [P] AuthService implementation in lib/services/auth_service.dart
- [ ] T015 [P] EncryptionService implementation in lib/services/encryption_service.dart
- [ ] T016 [P] LockboxService implementation in lib/services/lockbox_service.dart
- [ ] T017 [P] StorageService implementation in lib/services/storage_service.dart
- [ ] T018 [P] KeyService implementation in lib/services/key_service.dart

## Phase 3.4: UI Implementation
- [ ] T019 [P] Main app widget in lib/main.dart
- [ ] T020 [P] Lockbox list screen in lib/screens/lockbox_list_screen.dart
- [ ] T021 [P] Lockbox detail screen in lib/screens/lockbox_detail_screen.dart
- [ ] T022 [P] Create lockbox screen in lib/screens/create_lockbox_screen.dart
- [ ] T023 [P] Edit lockbox screen in lib/screens/edit_lockbox_screen.dart
- [ ] T024 [P] Authentication screen in lib/screens/authentication_screen.dart
- [ ] T025 [P] Settings screen in lib/screens/settings_screen.dart
- [ ] T026 [P] Lockbox list widget in lib/widgets/lockbox_list_widget.dart
- [ ] T027 [P] Lockbox card widget in lib/widgets/lockbox_card_widget.dart
- [ ] T028 [P] Authentication widget in lib/widgets/authentication_widget.dart

## Phase 3.5: Integration
- [ ] T029 Connect services to shared_preferences storage
- [ ] T030 Implement biometric authentication with local_auth
- [ ] T031 Implement NIP-44 encryption with dart_nostr
- [ ] T032 Add error handling and user-friendly messages
- [ ] T033 Add input validation and size limits
- [ ] T034 Implement navigation between screens

## Phase 3.6: Polish
- [ ] T035 [P] Unit tests for models in test/unit/test_models.dart
- [ ] T036 [P] Unit tests for services in test/unit/test_services.dart
- [ ] T037 [P] Unit tests for widgets in test/unit/test_widgets.dart
- [ ] T038 Performance tests (<200ms encryption/decryption)
- [ ] T039 [P] Update README.md with setup instructions
- [ ] T040 [P] Add error code documentation
- [ ] T041 Remove code duplication and optimize
- [ ] T042 Run quickstart.md validation scenarios

## Dependencies
- Tests (T004-T009) before implementation (T010-T018)
- Models (T010-T013) before services (T014-T018)
- Services (T014-T018) before UI (T019-T028)
- UI (T019-T028) before integration (T029-T034)
- Integration (T029-T034) before polish (T035-T042)

## Parallel Example
```
# Launch T004-T009 together (Contract and Integration Tests):
Task: "Contract test AuthService in test/contract/test_auth_service.dart"
Task: "Contract test EncryptionService in test/contract/test_encryption_service.dart"
Task: "Contract test LockboxService in test/contract/test_lockbox_service.dart"
Task: "Integration test lockbox creation flow in integration_test/test_lockbox_creation.dart"
Task: "Integration test authentication flow in integration_test/test_authentication.dart"
Task: "Integration test encryption/decryption flow in integration_test/test_encryption.dart"

# Launch T010-T018 together (Models and Services):
Task: "Lockbox model in lib/models/lockbox.dart"
Task: "TextContent model in lib/models/text_content.dart"
Task: "EncryptionKey model in lib/models/encryption_key.dart"
Task: "NostrKeyPair model in lib/models/nostr_key_pair.dart"
Task: "AuthService implementation in lib/services/auth_service.dart"
Task: "EncryptionService implementation in lib/services/encryption_service.dart"
Task: "LockboxService implementation in lib/services/lockbox_service.dart"
Task: "StorageService implementation in lib/services/storage_service.dart"
Task: "KeyService implementation in lib/services/key_service.dart"

# Launch T019-T028 together (UI Components):
Task: "Main app widget in lib/main.dart"
Task: "Lockbox list screen in lib/screens/lockbox_list_screen.dart"
Task: "Lockbox detail screen in lib/screens/lockbox_detail_screen.dart"
Task: "Create lockbox screen in lib/screens/create_lockbox_screen.dart"
Task: "Edit lockbox screen in lib/screens/edit_lockbox_screen.dart"
Task: "Authentication screen in lib/screens/authentication_screen.dart"
Task: "Settings screen in lib/screens/settings_screen.dart"
Task: "Lockbox list widget in lib/widgets/lockbox_list_widget.dart"
Task: "Lockbox card widget in lib/widgets/lockbox_card_widget.dart"
Task: "Authentication widget in lib/widgets/authentication_widget.dart"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts
- Flutter app structure: lib/ for source, test/ for unit tests, integration_test/ for integration tests

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each service interface → implementation task [P]
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → UI → Integration → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All contracts have corresponding tests
- [x] All entities have model tasks
- [x] All tests come before implementation
- [x] Parallel tasks truly independent
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task


