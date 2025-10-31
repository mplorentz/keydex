# Tasks: Invitation Links for Key Holders

**Feature**: 004-invitation-links  
**Branch**: `004-invitation-links`  
**Input**: Design documents from `/specs/004-invitation-links/`  
**Prerequisites**: plan.md, research.md, data-model.md, service-interfaces.md, quickstart.md

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Extract: tech stack, libraries, structure
2. Load design documents:
   → data-model.md: Extract entities → model tasks
   → service-interfaces.md: Extract services → service tasks
   → quickstart.md: Extract scenarios → integration test tasks
3. Generate tasks by category:
   → Setup: dependencies, deep linking config
   → UI Stubs: screens for manual verification
   → Models: InvitationLink, InvitationStatus, event types
   → Services: InvitationService, DeepLinkService, InvitationSendingService
   → UI Implementation: connect stubs to services
   → Deep Linking: app_links integration
   → Event Processing: RSVP, denial, confirmation handlers
   → Tests: unit, widget, integration, golden
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

## Phase 3.1: Setup & Dependencies
- [X] T001 Add `app_links: ^5.0.0` dependency to `pubspec.yaml`
- [X] T002 [P] Configure custom URL scheme `keydex://` in iOS Info.plist (`ios/Runner/Info.plist`)
- [X] T003 [P] Configure custom URL scheme `keydex://` in Android manifest (`android/app/src/main/AndroidManifest.xml`)
- [X] T004 [P] Configure custom URL scheme for macOS (`macos/Runner/Info.plist`)
- [X] T005 [P] Configure custom URL scheme for Windows (`windows/runner/main.cpp` if needed)
- [X] T006 Update `lib/models/nostr_kinds.dart` to add new event kinds: 1340 (invitationRsvp), 1341 (invitationDenial), 1342 (shardConfirmation), 1343 (shardError), 1344 (invitationInvalid)

## Phase 3.2: UI Stubs & Manual Verification (Outside-In Approach)
**Start with user-facing components for rapid feedback**
- [X] T007 [P] Stub invitation link generation section in `lib/screens/backup_config_screen.dart` (add "Invite by Link" UI with name input and generate button, non-functional)
- [X] T008 [P] Stub invitation acceptance screen `lib/screens/invitation_acceptance_screen.dart` (placeholder UI showing invitation details and accept/deny buttons)
- [X] T009 [P] Stub key holder status badges in `lib/widgets/key_holder_list.dart` (add invitation status indicators: invited, awaiting key, holding key, error)
- [X] T010 [P] Stub "Generate and Distribute Keys" button in `lib/screens/lockbox_detail_screen.dart` (show button when all invited key holders have accepted)
- [x] T011 Manual verification: Navigate through stubbed UI flow and verify layout/look

## Phase 3.3: Core Models (Foundation)
- [X] T012 [P] Create `InvitationStatus` enum in `lib/models/invitation_status.dart` (created, pending, redeemed, denied, invalidated, error)
- [X] T013 [P] Create `InvitationLink` model in `lib/models/invitation_link.dart` (typedef with inviteCode, lockboxId, ownerPubkey, relayUrls, inviteeName, createdAt, status, redeemedBy, redeemedAt)
- [X] T014 [P] Create error exception classes in `lib/models/invitation_exceptions.dart` (InvitationNotFoundException, InvitationAlreadyRedeemedException, InvitationInvalidatedException, InvalidInvitationLinkException)
- [X] T015 [P] Add invitation status extension to `KeyHolderStatus` or create `InvitationKeyHolderStatus` enum in `lib/models/key_holder_status.dart` (invited, awaitingKey, holdingKey, error)

## Phase 3.4: Service Interfaces & Providers
- [X] T016 Create `InvitationService` class stub in `lib/services/invitation_service.dart` (empty methods matching service-interfaces.md)
- [X] T017 Create `DeepLinkService` class stub in `lib/services/deep_link_service.dart` (empty methods matching service-interfaces.md)
- [X] T018 Create `InvitationSendingService` class stub in `lib/services/invitation_sending_service.dart` (stateless utility class with empty methods matching service-interfaces.md)
- [X] T019 [P] Create providers in `lib/providers/invitation_provider.dart` (invitationServiceProvider, pendingInvitationsProvider, invitationByCodeProvider)

## Phase 3.5: Refactoring Pass 1 (Model Validation & Helpers)
**Clean up models before service implementation**
- [X] T020 Add validation functions to `lib/models/invitation_link.dart` (validate invite code format, validate hex pubkey, validate relay URLs)
- [X] T021 Add helper functions to `lib/models/invitation_link.dart` (createInvitationLink, updateInvitationStatus, invitationLinkToJson, invitationLinkFromJson, invitationLinkToUrl)
- [X] T022 Add Base64URL encoding/decoding utilities for invite codes in `lib/utils/invite_code_utils.dart` (generate secure invite code, validate invite code format)

## Phase 3.6: Service Implementation - InvitationService
- [X] T023 Implement `generateInvitationLink` in `lib/services/invitation_service.dart` (validates lockbox ownership, generates secure invite code, creates InvitationLink, stores in SharedPreferences)
- [X] T024 Implement `getPendingInvitations` in `lib/services/invitation_service.dart` (loads from SharedPreferences using lockbox_invitations index, filters by status)
- [X] T025 Implement `lookupInvitationByCode` in `lib/services/invitation_service.dart` (looks up InvitationLink by invite code from SharedPreferences)
- [X] T026 Implement `redeemInvitation` in `lib/services/invitation_service.dart` (validates code, updates status, adds to backup config, publishes RSVP event)
- [X] T027 Implement `denyInvitation` in `lib/services/invitation_service.dart` (validates code, updates status, publishes denial event, invalidates code)
- [X] T028 Implement `invalidateInvitation` in `lib/services/invitation_service.dart` (updates status, publishes invalid event if needed, removes from tracking)
- [X] T029 Implement `processRsvpEvent` in `lib/services/invitation_service.dart` (decrypts event, validates, updates invitation, adds to backup config)
- [X] T030 Implement `processDenialEvent` in `lib/services/invitation_service.dart` (decrypts event, validates, updates invitation status)
- [~] T031 ~~Implement `processShardConfirmationEvent` in `lib/services/invitation_service.dart`~~ **MOVED to ShardDistributionService (see Phase 3.6.1)**
- [~] T032 ~~Implement `processShardErrorEvent` in `lib/services/invitation_service.dart`~~ **MOVED to ShardDistributionService (see Phase 3.6.1)**

## Phase 3.6.1: Architectural Refactoring - Separate Invitation and Shard Lifecycles
**Rationale**: Shard confirmation/error events are part of the shard distribution lifecycle (after invitation acceptance), not the invitation lifecycle. Moving them to ShardDistributionService provides better separation of concerns.

- [X] T031a Move `processShardConfirmationEvent` from `lib/services/invitation_service.dart` to `lib/services/shard_distribution_service.dart` (decrypts event, validates, updates key holder status to holdingKey)
- [X] T032a Move `processShardErrorEvent` from `lib/services/invitation_service.dart` to `lib/services/shard_distribution_service.dart` (decrypts event, validates, updates key holder status to error)
- [X] T083 Update any references to these methods (if called from other services or screens) - No references found

## Phase 3.7: Service Implementation - DeepLinkService
- [ ] T033 Implement `initializeDeepLinking` in `lib/services/deep_link_service.dart` (sets up app_links listeners for Universal Links and custom scheme)
- [ ] T034 Implement `handleInitialLink` in `lib/services/deep_link_service.dart` (handles link that opened app on cold start)
- [ ] T035 Implement `handleIncomingLink` in `lib/services/deep_link_service.dart` (handles link received while app running)
- [ ] T036 Implement `parseInvitationLink` in `lib/services/deep_link_service.dart` (parses both https://keydex.app/invite/{code} and keydex://keydex.app/invite/{code} formats)

## Phase 3.8: Service Implementation - InvitationSendingService
- [ ] T037 Implement `sendRsvpEvent` in `lib/services/invitation_sending_service.dart` (creates kind 1340 event, encrypts with NIP-44, publishes to relays)
- [ ] T038 Implement `sendDenialEvent` in `lib/services/invitation_sending_service.dart` (creates kind 1341 event, encrypts with NIP-44, publishes to relays)
- [ ] T039 Implement `sendShardConfirmationEvent` in `lib/services/invitation_sending_service.dart` (creates kind 1342 event, encrypts with NIP-44, publishes to relays)
- [ ] T040 Implement `sendShardErrorEvent` in `lib/services/invitation_sending_service.dart` (creates kind 1343 event, encrypts with NIP-44, publishes to relays)
- [ ] T041 Implement `sendInvitationInvalidEvent` in `lib/services/invitation_sending_service.dart` (creates kind 1344 event, encrypts with NIP-44, publishes to relays)

## Phase 3.9: UI Implementation - Connect Stubs to Services
- [ ] T042 Implement invitation link generation UI in `lib/screens/backup_config_screen.dart` (connect to InvitationService.generateInvitationLink, display link, copy functionality)
- [ ] T043 Implement invitation acceptance screen in `lib/screens/invitation_acceptance_screen.dart` (connect to DeepLinkService, InvitationService.redeemInvitation or denyInvitation)
- [ ] T044 Implement key holder status display in `lib/widgets/key_holder_list.dart` (show invitation status badges, fetch from pendingInvitationsProvider)
- [ ] T045 Implement "Generate and Distribute Keys" button in `lib/screens/lockbox_detail_screen.dart` (show when all invited key holders accepted, trigger backup service)
- [ ] T046 Add deep link initialization in `lib/main.dart` (call DeepLinkService.initializeDeepLinking on app start)

## Phase 3.10: Edge Cases & Error Handling
- [ ] T047 Handle invalid invitation codes (already redeemed, invalidated, format errors) in `lib/services/invitation_service.dart`
- [ ] T048 Handle malformed invitation links (invalid URL format, missing parameters) in `lib/services/deep_link_service.dart`
- [ ] T049 Handle duplicate invitation redemption (user already key holder) in `lib/services/invitation_service.dart`
- [ ] T050 Handle network failures during event publishing (retry logic, user feedback) in `lib/services/invitation_sending_service.dart`
- [ ] T051 Handle decryption failures when processing events in `lib/services/invitation_service.dart`
- [ ] T052 Add error messages and user feedback for all error cases in UI screens

## Phase 3.11: Refactoring Pass 2 (Post-Edge Cases)
**Final cleanup before testing**
- [ ] T053 Consolidate error handling patterns across services
- [ ] T054 Extract invitation URL generation logic into reusable utility
- [ ] T055 Optimize SharedPreferences storage access patterns
- [ ] T056 Add logging for invitation operations (debug/info levels)

## Phase 3.12: Unit Tests (After Implementation)
- [ ] T057 [P] Unit tests for `InvitationLink` model in `test/models/invitation_link_test.dart` (validation, JSON serialization, URL generation)
- [ ] T058 [P] Unit tests for `InvitationStatus` enum in `test/models/invitation_status_test.dart` (state transitions)
- [ ] T059 [P] Unit tests for invite code utilities in `test/utils/invite_code_utils_test.dart` (generation, validation, encoding)
- [ ] T060 [P] Unit tests for `InvitationService` methods in `test/services/invitation_service_test.dart` (mock dependencies, test each method)
- [ ] T061 [P] Unit tests for `DeepLinkService` parsing in `test/services/deep_link_service_test.dart` (parseInvitationLink with various URL formats)
- [ ] T062 [P] Unit tests for `InvitationSendingService` event creation in `test/services/invitation_sending_service_test.dart` (verify event structure, encryption)

## Phase 3.13: Widget Tests
- [ ] T063 [P] Widget tests for invitation link generation UI in `test/widgets/invitation_generation_widget_test.dart` (form input, button interactions, error display)
- [ ] T064 [P] Widget tests for invitation acceptance screen in `test/widgets/invitation_acceptance_screen_test.dart` (accept/deny buttons, status display)
- [ ] T065 [P] Widget tests for key holder status badges in `test/widgets/key_holder_status_badge_test.dart` (status display, colors, icons)

## Phase 3.14: Golden Tests (Screenshot Tests)
- [ ] T066 [P] Golden test for invitation link generation screen in `test/widgets/invitation_generation_golden_test.dart` (all states: empty, with invitation, error)
- [ ] T067 [P] Golden test for invitation acceptance screen in `test/widgets/invitation_acceptance_golden_test.dart` (pending, accepted, denied states)
- [ ] T068 [P] Golden test for key holder list with invitation statuses in `test/widgets/key_holder_list_invitation_golden_test.dart` (invited, awaiting key, holding key, error badges)

## Phase 3.15: Integration Tests (Final Validation)
- [ ] T069 [P] Integration test: Generate invitation link flow in `test/integration/invitation_generation_test.dart` (full flow from UI to storage)
- [ ] T070 [P] Integration test: Accept invitation flow (existing user) in `test/integration/invitation_acceptance_existing_user_test.dart` (deep link → acceptance → RSVP event)
- [ ] T071 [P] Integration test: Accept invitation flow (new user) in `test/integration/invitation_acceptance_new_user_test.dart` (deep link → account setup → acceptance)
- [ ] T072 [P] Integration test: Deny invitation flow in `test/integration/invitation_denial_test.dart` (deep link → denial → denial event)
- [ ] T073 [P] Integration test: Generate and distribute keys flow in `test/integration/invitation_key_distribution_test.dart` (all accept → generate keys → distribute → confirmations)
- [ ] T074 [P] Integration test: Shard confirmation event processing in `test/integration/shard_confirmation_test.dart` (receive event → update status)
- [ ] T075 [P] Integration test: Invalid invitation code handling in `test/integration/invitation_invalid_test.dart` (already redeemed, invalidated, malformed)
- [ ] T076 [P] Integration test: Duplicate invitation handling in `test/integration/invitation_duplicate_test.dart` (user already key holder)

## Dependencies
- Setup (T001-T006) before everything
- UI Stubs (T007-T011) before implementation (T012-T046)
- Models (T012-T015) before services (T016-T041)
- Service interfaces (T016-T019) before service implementations (T023-T041)
- Refactoring pass 1 (T020-T022) before service implementations
- Service implementations (T023-T030, T031a-T032a, T033-T041) before UI implementation (T042-T046)
- Phase 3.6.1 refactoring (T031a-T032a, T083) can happen anytime after T023-T030 complete
- UI implementation (T042-T046) before edge cases (T047-T052)
- Edge cases (T047-T052) before refactoring pass 2 (T053-T056)
- Refactoring pass 2 (T053-T056) before unit tests (T057-T062)
- Unit tests (T057-T062) before widget tests (T063-T065)
- Widget tests (T063-T065) before golden tests (T066-T068)
- Golden tests (T066-T068) before integration tests (T069-T076)
- T012 blocks T013 (InvitationStatus needed for InvitationLink)
- T013 blocks T023-T030 (InvitationLink needed for InvitationService)
- T016-T018 block T023-T041 (service stubs needed before implementation)
- T037-T041 are stateless utility methods (can be parallel if no shared state)
- T033 blocks T042-T046 (DeepLinkService needed for UI)
- T023-T030 block T042-T045 (InvitationService needed for UI)
- T031a-T032a are shard distribution methods (part of ShardDistributionService)

## Parallel Execution Examples
```
# Launch T002-T005 together (URL scheme configuration):
Task: "Configure custom URL scheme keydex:// in iOS Info.plist"
Task: "Configure custom URL scheme keydex:// in Android manifest"
Task: "Configure custom URL scheme for macOS"
Task: "Configure custom URL scheme for Windows"

# Launch T007-T010 together (UI stubs):
Task: "Stub invitation link generation section in backup_config_screen.dart"
Task: "Stub invitation acceptance screen"
Task: "Stub key holder status badges in key_holder_list.dart"
Task: "Stub Generate and Distribute Keys button in lockbox_detail_screen.dart"

# Launch T012-T015 together (models):
Task: "Create InvitationStatus enum"
Task: "Create InvitationLink model"
Task: "Create error exception classes"
Task: "Add invitation status extension to KeyHolderStatus"

# Launch T057-T062 together (unit tests):
Task: "Unit tests for InvitationLink model"
Task: "Unit tests for InvitationStatus enum"
Task: "Unit tests for invite code utilities"
Task: "Unit tests for InvitationService methods"
Task: "Unit tests for DeepLinkService parsing"
Task: "Unit tests for InvitationSendingService event creation"

# Launch T066-T068 together (golden tests):
Task: "Golden test for invitation link generation screen"
Task: "Golden test for invitation acceptance screen"
Task: "Golden test for key holder list with invitation statuses"

# Launch T069-T076 together (integration tests):
Task: "Integration test: Generate invitation link flow"
Task: "Integration test: Accept invitation flow (existing user)"
Task: "Integration test: Accept invitation flow (new user)"
Task: "Integration test: Deny invitation flow"
Task: "Integration test: Generate and distribute keys flow"
Task: "Integration test: Shard confirmation event processing"
Task: "Integration test: Invalid invitation code handling"
Task: "Integration test: Duplicate invitation handling"
```

## Notes
- [P] tasks = different files, no dependencies
- Manual verification of UI stubs (T011) before implementing functionality
- Refactoring passes clean up code before adding complexity
- Unit tests written after implementation and refactoring
- Integration tests written last for complete workflow validation
- Follow Outside-In development: UI stubs first, then implementation behind components
- Commit after each task
- Golden tests run on macOS only (as per constitution)
- Custom URL scheme (`keydex://`) supports local testing before Universal Links setup
- **Architectural Decision**: Shard confirmation/error events moved to ShardDistributionService (Phase 3.6.1) to separate invitation lifecycle from shard distribution lifecycle

## Task Generation Rules Applied
1. **From Data Model**:
   - InvitationLink → model task (T013)
   - InvitationStatus → enum task (T012)
   - Event types → referenced in service tasks

2. **From Service Interfaces**:
   - InvitationService methods → service implementation tasks (T023-T032)
   - DeepLinkService methods → service implementation tasks (T033-T036)
   - InvitationSendingService methods → service implementation tasks (T037-T041)

3. **From User Stories (Quickstart)**:
   - Each scenario → integration test task (T069-T076)

4. **Ordering**:
   - Setup → UI Stubs → Models → Services → UI Implementation → Edge Cases → Refactoring → Tests
   - Outside-In: UI stubs before implementation
   - Dependencies block parallel execution

## Validation Checklist
- [x] All UI components have stub tasks
- [x] All entities have model tasks
- [x] Refactoring passes included after implementation and edge cases
- [x] Unit tests come after implementation and refactoring
- [x] Integration tests come last
- [x] Golden tests included for UI components
- [x] Parallel tasks truly independent
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Deep linking setup tasks included
- [x] Event processing tasks included
- [x] Error handling tasks included

