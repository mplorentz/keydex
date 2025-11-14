# Implementation Plan: File Storage in Lockboxes

**Branch**: `005-file-support` | **Date**: 2025-11-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-file-support/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
This feature replaces text-based lockbox content with file storage using a P2P ephemeral distribution model. Users select files (PDFs, text documents) via native file pickers. Files are encrypted with symmetric keys and uploaded to Blossom servers as a temporary relay (48-hour distribution window). Key holders automatically download and cache encrypted files locally within this window. After all key holders confirm download (or 48 hours elapsed), files are deleted from Blossom. During recovery, key holders provide their cached files via temporary Blossom uploads. This architecture ensures true P2P distribution, minimal third-party storage, and enhanced privacy.

## Technical Context
**Language/Version**: Dart 3.5.3+ with Flutter 3.35.0  
**Primary Dependencies**: flutter_riverpod (2.6.1), ndk (0.5.1 with Blossom support), ntcdcrypto (0.4.0), flutter_secure_storage (9.2.2), shared_preferences (2.5.3), file_picker (8.0.0), path_provider (2.1.0)  
**Storage**: SharedPreferences for metadata, FlutterSecureStorage for encryption keys, Blossom servers as temporary file relay (48hr-7day TTL), local cache directory for encrypted files (key holders)  
**Testing**: flutter_test with golden_toolkit (0.15.0) for UI regression tests, mockito (5.4.4) for unit tests, integration_test for workflows  
**Target Platform**: Cross-platform Flutter app (iOS, Android, macOS, Windows, Linux, Web)
**Project Type**: Mobile app with P2P file distribution architecture  
**Performance Goals**: File uploads must handle up to 1GB total vault size, smooth UI at 60fps during file operations, aggressive 48hr distribution window  
**Constraints**: Cross-platform file picker support, ephemeral Blossom storage (not permanent), local cache management, background retry tasks  
**Scale/Scope**: 12 existing screens to update, 3 new services (FileStorage, BlossomConfig, FileDistribution), updates to lockbox/shard data models, Blossom configuration UI, new Nostr event kinds (2440, 2441, 2442)

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Outside-In Development
- [x] Feature starts from user scenarios and acceptance criteria (9 acceptance scenarios defined)
- [x] UI components stubbed out first for manual verification (file picker, status display)
- [x] Implementation proceeds from UI toward internal components (UI → file service → storage)
- [x] Unit tests planned after implementation of isolated classes (file service, encryption)
- [x] Integration tests planned last to validate complete workflows (end-to-end file upload/recovery)

### Security-First Development
- [x] All cryptographic operations use industry-standard libraries (ntcdcrypto for encryption)
- [x] Shamir's Secret Sharing implementation is mathematically verified (existing implementation)
- [x] No sensitive data stored in plaintext (files encrypted before upload, keys in secure storage)
- [x] Security review planned for cryptographic code (file encryption and key management)

### Cross-Platform Consistency
- [x] Flutter app targets all 5 platforms (iOS, Android, macOS, Windows, Linux)
- [x] Platform-specific features justified if needed (native file pickers per platform)
- [x] UI follows platform conventions while maintaining core consistency (native dialogs)

### Nostr Protocol Integration
- [x] Data transmission uses Nostr protocol (shard distribution includes file location)
- [x] NIP documentation planned for backup/restore processes (update existing NIP for file support)
- [x] Relay selection and failover mechanisms designed (uses existing relay infrastructure)

### Riverpod State Management Architecture
- [x] App wrapped with ProviderScope at root level (existing architecture)
- [x] Provider types used correctly (Provider, FutureProvider, StreamProvider, StateProvider)
- [x] Widgets consuming providers use ConsumerWidget or ConsumerStatefulWidget
- [x] Resources properly disposed using ref.onDispose()
- [x] Provider composition uses ref.watch() for reactive dependencies
- [x] Cache invalidation uses ref.invalidate() or ref.refresh() when data changes
- [x] Auto-dispose providers preferred for temporary or screen-scoped data
- [x] Provider families used for parameterized providers

### Service and Repository Architecture
- [x] Services are instance classes with Riverpod dependency injection (FileStorageService)
- [x] Each service has a Provider that injects dependencies (fileStorageServiceProvider)
- [x] Repositories used for complex data access (caching, streams, 100+ lines) (existing LockboxRepository)
- [x] Services used for business logic (validation, workflows, orchestration) (file validation, upload)
- [x] No thin repository wrappers (under 100 lines that just delegate) (service-only for file operations)
- [x] Circular dependencies broken with explicit Provider types

### Non-Technical User Focus
- [x] UI designed for non-technical users (simple file picker, clear status indicators)
- [x] Complex concepts abstracted behind simple language ("Add files" not "Upload encrypted blobs")
- [x] Error messages written in plain English (clear file upload/retrieval errors)

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command) - web services only
├── service-interfaces/  # Phase 1 output (/plan command) - client apps only
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: [DEFAULT to Option 1 unless Technical Context indicates web/mobile app]

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable
   - Entities should be value types unless they have a specific need to be reference types.

2. **Design service interfaces** from functional requirements:
   - For web services: Generate API contracts (REST/GraphQL) → `/contracts/`
   - For client apps: Design service method signatures and return types
   - For mobile apps: Focus on local service interfaces and data models
   - Adapt approach based on project type from Technical Context

3. **Generate appropriate tests** based on project type:
   - Web services: Contract tests for API endpoints
   - Client apps: Unit tests for service methods and data models
   - All projects: Integration tests for complete workflows

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh cursor`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, service interfaces (or contracts/), failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
Based on the Phase 1 artifacts (data-model.md, service-interfaces/, quickstart.md), generate tasks in this order:

1. **UI Stubs First** (Outside-In):
   - File picker integration screen stub
   - Blossom server configuration screen stub
   - Lockbox file list widget stub
   - File download status indicator stub
   - File replacement dialog stub

2. **Data Models** (Foundation):
   - Create `LockboxFile` model with validation [P]
   - Modify `Lockbox` model to use `List<LockboxFile>` [P]
   - Create `BlossomServerConfig` model [P]
   - Create `CachedFile` model [P]
   - Create `FileDistributionStatus` model [P]
   - Extend `ShardData` with file fields and blossomExpiresAt [P]

3. **Service Interfaces** (Business Logic):
   - Implement `BlossomConfigService` (CRUD for server configs)
   - Implement `FileStorageService` (encrypt, upload, download, decrypt, cache)
   - Implement `FileDistributionService` (48hr distribution window, cleanup)
   - Update `BackupService` to include file metadata in shards
   - Update `ShardDistributionService` to trigger auto-downloads
   - Update `RecoveryService` for file request/response via Nostr (kinds 2440/2441)

4. **UI Implementation** (Connect to Services):
   - Implement file picker integration
   - Implement Blossom server configuration UI
   - Update lockbox create screen to use files instead of content
   - Update lockbox detail screen to show files and status
   - Implement file replacement flow
   - Implement recovery file save flow

5. **Integration Tests**:
   - End-to-end: Create lockbox with files → backup → key holder download
   - File replacement → redistribution → cleanup flow
   - Recovery → file decryption → save flow
   - Error handling scenarios from quickstart.md

6. **Golden Tests**:
   - Lockbox file list display
   - Blossom server configuration screens
   - File download status indicators
   - File replacement dialogs

**Ordering Strategy**:
- Outside-In: UI stubs → Models → Services → UI implementation → Tests
- Parallel markers [P] for independent files (models, service unit tests)
- Dependencies: Models before services, services before UI implementation
- Tests last to validate complete flows

**Estimated Output**: 38-45 numbered, ordered tasks in tasks.md

**Key Task Categories**:
- UI stubs: 5 tasks
- Data models: 6 tasks (parallel) - includes CachedFile, FileDistributionStatus
- Services: 6 tasks - FileStorageService, BlossomConfigService, FileDistributionService + updates
- UI implementation: 6 tasks
- Integration tests: 7 tasks - includes P2P distribution and recovery flows
- Golden tests: 4 tasks
- Documentation updates: 3 tasks (NIP spec, README, DESIGN_GUIDE if needed)
- Migration/cleanup: 3 tasks
- Background tasks: 3 tasks (retry, cleanup, notifications)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none - design aligns with constitution)

**Artifacts Generated**:
- [x] research.md (Phase 0) - Updated for P2P ephemeral model
- [x] data-model.md (Phase 1) - CachedFile, FileDistributionStatus models
- [x] service-interfaces/file_storage_service.md (Phase 1) - Includes local cache ops
- [x] service-interfaces/blossom_config_service.md (Phase 1)
- [x] service-interfaces/file_distribution_service.md (Phase 1) - Replaces download tracking
- [x] quickstart.md (Phase 1) - Needs update for P2P model
- [x] .cursor/rules/specify-rules.mdc updated (Phase 1)

---
*Based on Constitution v1.3.0 - See `.specify/memory/constitution.md`*
