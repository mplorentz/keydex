# Tasks: Encrypted Text Vault (UI-First Approach)

**Input**: Design documents from `/specs/001-store-text-in-vault/`
**Approach**: Start with working UI, expand incrementally, refactor as needed

## Development Philosophy
- ✅ **Build working code first** - Start with a single file that works
- ✅ **Expand incrementally** - Add one feature at a time
- ✅ **Refactor when patterns emerge** - Don't abstract too early
- ✅ **Test what you build** - Add tests after you understand what works
- ❌ **No premature abstraction** - Don't create interfaces until you need them

## Phase 1: Single-File Prototype 🚀
**Goal**: Get a working vault app in one file with fake data

- [x] T001 Create `lib/vault_app.dart` - Complete working app in single file
  - Basic Flutter MaterialApp with navigation
  - Hard-coded list of 3-4 fake vaults 
  - Simple screens: list, create, edit, view
  - No encryption, no auth, no persistence yet
  - Focus: Get the UI flow working end-to-end

- [x] T002 Test the prototype manually
  - Run `flutter run` and verify all screens work
  - Can navigate between screens
  - Can create/edit/delete vaults (in memory only)
  - UI looks reasonable on phone

## Phase 2: Add Real Data 💾
**Goal**: Make data persist and add basic functionality

- [x] T003.1 Generate a Nostr key for the user on app launch and store it in the keychain.

- [x] T003.2 Add SharedPreferences for persistence in `lib/vault_app.dart`
  - Replace hard-coded data with SharedPreferences
  - Encrypt vault data with nostr key before storing it in user preferences
  - Data survives app restarts

- [ ] T004 Add input validation and limits
  - 4k character limit for text content
  - Required name field
  - Basic error messages

## Phase 3: Extract and Organize 🏗️
**Goal**: Split single file into logical components as it grows

- [ ] T005 Extract data models to `lib/models/`
  - `vault.dart` - Simple class with toJson/fromJson
  - Keep it simple - just id, name, content, createdAt

- [ ] T006 Extract screens to `lib/screens/`
  - `vault_list_screen.dart`
  - `vault_detail_screen.dart` 
  - `create_vault_screen.dart`
  - Move screen widgets out of main file

- [ ] T007 Extract storage logic to `lib/services/storage_service.dart`
  - Simple class that wraps SharedPreferences
  - Methods: saveVault, getVaults, deleteVault
  - No interfaces yet - just a concrete class

## Phase 4: Add Security 🔒
**Goal**: Add encryption and authentication to working app

- [ ] T008 Add basic encryption using NDK
  - Generate/store Nostr keypair in SharedPreferences
  - Encrypt content before saving, decrypt when loading
  - Start with simple implementation in storage_service

- [ ] T009 Add biometric authentication
  - Use local_auth package
  - Require auth before viewing/editing content
  - Simple implementation - no complex auth flows

## Phase 5: Polish and Improve ✨
**Goal**: Make it production-ready

- [ ] T010 Improve error handling
  - Graceful handling of encryption failures
  - User-friendly error messages
  - Proper loading states

- [ ] T011 Add better UI/UX
  - Loading indicators
  - Confirmation dialogs for delete
  - Better visual design
  - Empty states

- [ ] T012 Performance optimization
  - Lazy loading for large lists
  - Efficient encryption/decryption
  - Memory management

## Phase 6: Add Tests 🧪
**Goal**: Test the working application

- [ ] T013 Add integration tests
  - Test complete user flows with real app
  - Create → Save → Retrieve → Edit → Delete
  - Authentication flow
  - Error scenarios

- [ ] T014 Add unit tests for key components
  - Storage service tests
  - Model serialization tests
  - Encryption/decryption tests

## Phase 7: Architecture Cleanup 🏛️
**Goal**: Refactor to clean architecture (only if needed)

- [ ] T015 Add service interfaces (if you have multiple implementations)
- [ ] T016 Implement dependency injection (if complexity warrants it)
- [ ] T017 Add repository pattern (if you add cloud sync later)

## Notes for AI Collaboration
- **Start simple**: Don't create abstractions until you need them
- **Build working code**: Always have a runnable app
- **One feature at a time**: Complete each task before moving to next
- **Refactor incrementally**: Improve code as you understand the problem better
- **Test real behavior**: Focus on integration tests over unit tests initially

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
Task: "Contract test VaultService in test/contract/test_vault_service.dart"
Task: "Integration test vault creation flow in integration_test/test_vault_creation.dart"
Task: "Integration test authentication flow in integration_test/test_authentication.dart"
Task: "Integration test encryption/decryption flow in integration_test/test_encryption.dart"

# Launch T010-T018 together (Models and Services):
Task: "Vault model in lib/models/vault.dart"
Task: "TextContent model in lib/models/text_content.dart"
Task: "EncryptionKey model in lib/models/encryption_key.dart"
Task: "NostrKeyPair model in lib/models/nostr_key_pair.dart"
Task: "AuthService implementation in lib/services/auth_service.dart"
Task: "EncryptionService implementation in lib/services/encryption_service.dart"
Task: "VaultService implementation in lib/services/vault_service.dart"
Task: "StorageService implementation in lib/services/storage_service.dart"
Task: "KeyService implementation in lib/services/key_service.dart"

# Launch T019-T028 together (UI Components):
Task: "Main app widget in lib/main.dart"
Task: "Vault list screen in lib/screens/vault_list_screen.dart"
Task: "Vault detail screen in lib/screens/vault_detail_screen.dart"
Task: "Create vault screen in lib/screens/create_vault_screen.dart"
Task: "Edit vault screen in lib/screens/edit_vault_screen.dart"
Task: "Authentication screen in lib/screens/authentication_screen.dart"
Task: "Settings screen in lib/screens/settings_screen.dart"
Task: "Vault list widget in lib/widgets/vault_list_widget.dart"
Task: "Vault card widget in lib/widgets/vault_card_widget.dart"
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


