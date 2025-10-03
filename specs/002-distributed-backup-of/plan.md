# Implementation Plan: Distributed Backup of Lockboxes

**Branch**: `002-distributed-backup-of` | **Date**: 2025-01-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-distributed-backup-of/spec.md`

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
Implement distributed backup functionality for Keydex lockboxes using Shamir's Secret Sharing and Nostr protocol. Users can configure backup settings during lockbox creation, specifying threshold and total key holders, then distribute encrypted keys to trusted contacts via Nostr gift wrap events.

## Technical Context
**Language/Version**: Dart 3.0+ / Flutter 3.16+  
**Primary Dependencies**: Flutter, ndk (Nostr protocol), ntcdcrypto (Shamir's Secret Sharing)  
**Storage**: FlutterSecureStorage (local), Nostr relays (distributed)  
**Testing**: Flutter test framework, widget tests, integration tests  
**Target Platform**: iOS, Android, macOS, Windows, Web (Flutter cross-platform)  
**Project Type**: mobile (Flutter app)  
**Performance Goals**: <2s backup configuration, <5s key distribution, <10s recovery process  
**Constraints**: Offline-capable, secure key storage, Nostr protocol compliance  
**Scale/Scope**: Individual users with 3-10 key holders per lockbox

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Outside-In Development
- [x] Feature starts from user scenarios and acceptance criteria
- [x] UI components stubbed out first for manual verification
- [x] Implementation proceeds from UI toward internal components
- [x] Unit tests planned after implementation of isolated classes
- [x] Integration tests planned last to validate complete workflows

### Security-First Development
- [x] All cryptographic operations use industry-standard libraries
- [x] Shamir's Secret Sharing implementation is mathematically verified
- [x] No sensitive data stored in plaintext
- [x] Security review planned for cryptographic code

### Cross-Platform Consistency
- [x] Flutter app targets all 5 platforms (iOS, Android, macOS, Windows, Linux)
- [x] Platform-specific features justified if needed
- [x] UI follows platform conventions while maintaining core consistency

### Nostr Protocol Integration
- [x] Data transmission uses Nostr protocol
- [x] NIP documentation planned for backup/restore processes
- [x] Relay selection and failover mechanisms designed

### Non-Technical User Focus
- [x] UI designed for non-technical users
- [x] Complex concepts abstracted behind simple language
- [x] Error messages written in plain English

## Project Structure

### Documentation (this feature)
```
specs/002-distributed-backup-of/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── service-interfaces/  # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
lib/
├── models/
│   ├── lockbox.dart
│   ├── backup_config.dart
│   ├── key_holder.dart
│   └── gift_wrap_event.dart
├── services/
│   ├── lockbox_service.dart
│   ├── backup_service.dart
│   └── nostr_service.dart
├── screens/
│   ├── backup_config_screen.dart
│   └── recovery_screen.dart
└── widgets/
    ├── key_holder_list.dart
    └── backup_summary.dart

test/
├── contract/
├── integration/
└── unit/
```

**Structure Decision**: Option 1 (Single project) - Flutter mobile app with integrated services

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - Research Shamir's Secret Sharing implementation for Dart/Flutter
   - Research Nostr protocol integration patterns for Flutter
   - Research NIP-44 encryption and NIP-59 gift wrap event standards
   - Research FlutterSecureStorage best practices for key management

2. **Generate and dispatch research agents**:
   ```
   Task: "Research Shamir's Secret Sharing libraries for Dart/Flutter"
   Task: "Research Nostr protocol integration patterns for mobile apps"
   Task: "Research NIP-44 and NIP-59 implementation requirements"
   Task: "Research FlutterSecureStorage security best practices"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - BackupConfig entity (threshold, total_keys, key_holders)
   - KeyHolder entity (npub, status, last_updated)
   - GiftWrapEvent entity (encrypted_key, recipient_npub, timestamp)
   - Validation rules from requirements
   - State transitions if applicable

2. **Design service interfaces** from functional requirements:
   - BackupService interface for configuration and key management
   - NostrService extension for gift wrap events
   - Service method signatures and return types
   - No HTTP contracts needed (Nostr client architecture)

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

**Output**: data-model.md, service interfaces, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Specific Task Categories**:
1. **Data Models** (Parallel execution):
   - BackupConfig model with validation
   - KeyHolder model with Nostr key validation
   - GiftWrapEvent model with encryption handling
   - BackupStatus and KeyHolderStatus enums

2. **Services** (Sequential execution):
   - BackupService with integrated Shamir's Secret Sharing using ntc_dcrypto library
   - NostrService extension for gift wrap events
   - Integration with existing KeyService

3. **UI Components** (Outside-In approach):
   - BackupConfigScreen stub for manual verification
   - KeyHolderList widget for managing contacts
   - BackupSummary widget for status display
   - Integration with existing lockbox creation flow

4. **Unit Tests** (Parallel execution):
   - Data model constraint tests
   - Service method tests
   - Shamir's Secret Sharing algorithm tests

5. **Integration Tests**:
   - Complete backup setup workflow
   - Recovery process validation
   - Configuration update scenarios

**Ordering Strategy**:
- Outside-In order: UI stubs first, then implementation behind components
- Dependency order: UI, Models, Services 
- Mark [P] for parallel execution (independent files)
- Security-first: Shamir's Secret Sharing implementation before UI integration

**Estimated Output**: 30-35 numbered, ordered tasks in tasks.md

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
| None | All constitutional requirements met | N/A |

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
- [x] Complexity deviations documented

---
*Based on Constitution v1.1.0 - See `/memory/constitution.md`*