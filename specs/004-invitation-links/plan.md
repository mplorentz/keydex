
# Implementation Plan: Invitation Links for Key Holders

**Branch**: `004-invitation-links` | **Date**: 2025-01-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-invitation-links/spec.md`

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
Allow lockbox owners to invite others to become key holders by sending invitation links. Links use Universal Links (iOS) and appropriate deep link mechanisms on other platforms via keydex.app domain. Invitees can be existing or new Keydex users. The system handles invitation acceptance via encrypted RSVP events, tracks invitation status, and supports key distribution after acceptance. Technical approach: Add deep linking support to Flutter app, create invitation link generation service, implement invitation code tracking, add new Nostr event kinds for RSVP and confirmation, and integrate with existing backup configuration flow.

## Technical Context
**Language/Version**: Dart 3.5.3, Flutter 3.35.0  
**Primary Dependencies**: flutter_riverpod 2.6.1, ndk 0.5.0 (Nostr), flutter_secure_storage 9.2.2, shared_preferences 2.5.3, ntcdcrypto 0.4.0 (NIP-44 encryption), app_links (NEEDS CLARIFICATION: deep linking package)  
**Storage**: SharedPreferences for invitation code tracking, FlutterSecureStorage for sensitive data  
**Testing**: flutter_test (unit/widget), golden_toolkit 0.15.0 (golden tests), integration_test  
**Target Platform**: Flutter app targeting iOS, Android, macOS, Windows, Web (all 5 platforms)  
**Project Type**: mobile (single Flutter app codebase)  
**Performance Goals**: <500ms invitation link generation, <2s deep link processing, 60fps UI  
**Constraints**: Must work offline for invitation link generation, requires network for RSVP events, cross-platform deep linking consistency  
**Scale/Scope**: Typical user has 3-10 lockboxes, each with 3-10 key holders, invitation links valid until redeemed or denied

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Outside-In Development
- [x] Feature starts from user scenarios and acceptance criteria
- [x] UI components stubbed out first for manual verification
- [x] Implementation proceeds from UI toward internal components
- [x] Unit tests planned after implementation of isolated classes
- [x] Integration tests planned last to validate complete workflows

### Security-First Development
- [x] All cryptographic operations use industry-standard libraries (NIP-44 via ntcdcrypto)
- [x] Shamir's Secret Sharing implementation is mathematically verified (existing, reused)
- [x] No sensitive data stored in plaintext (invitation codes stored securely)
- [x] Security review planned for cryptographic code (invitation code generation and validation)

### Cross-Platform Consistency
- [x] Flutter app targets all 5 platforms (iOS, Android, macOS, Windows, Linux)
- [x] Platform-specific features justified if needed (Universal Links on iOS, App Links on Android)
- [x] UI follows platform conventions while maintaining core consistency

### Nostr Protocol Integration
- [x] Data transmission uses Nostr protocol (RSVP, denial, confirmation events)
- [x] NIP documentation planned for backup/restore processes (existing NIPs reused, new event kinds added)
- [x] Relay selection and failover mechanisms designed (uses existing relay configuration)

### Riverpod State Management Architecture
- [x] App wrapped with ProviderScope at root level (existing)
- [x] Provider types used correctly (Provider, FutureProvider, StreamProvider, StateProvider)
- [x] Widgets consuming providers use ConsumerWidget or ConsumerStatefulWidget (existing pattern)
- [x] Repository pattern used to abstract service layer behind providers (existing pattern)
- [x] Resources properly disposed using ref.onDispose()
- [x] Provider composition uses ref.watch() for reactive dependencies
- [x] Cache invalidation uses ref.invalidate() or ref.refresh() when data changes
- [x] Auto-dispose providers preferred for temporary or screen-scoped data
- [x] Provider families used for parameterized providers (e.g., invitation by lockboxId)

### Non-Technical User Focus
- [x] UI designed for non-technical users (simple invitation flow, clear status indicators)
- [x] Complex concepts abstracted behind simple language (no mention of Nostr events to users)
- [x] Error messages written in plain English

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

**Structure Decision**: Option 1 (single Flutter app codebase)

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
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (service-interfaces, data model, quickstart)
- Each service interface method → unit test task [P]
- Each entity model → model creation task [P]
- Each UI component → widget stub task, then implementation task
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- Outside-In order: UI stubs first (invitation generation screen, acceptance screen), then implementation behind components
- Dependency order: 
  1. Data models (InvitationLink, InvitationCode, event types)
  2. Service interfaces (InvitationService, DeepLinkService, InvitationEventService)
  3. UI stubs (backup config screen updates, invitation acceptance screen, key holder status updates)
  4. Service implementations (make tests pass)
  5. UI implementations (connect to services)
  6. Deep linking integration (app_links setup, link handling)
  7. Event processing (RSVP, denial, confirmation event handlers)
  8. Integration tests (end-to-end flows)
- Mark [P] for parallel execution (independent files, models, service methods)
- Follow constitutional principles: UI-first, then implementation

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
- [x] Complexity deviations documented

---
*Based on Constitution v1.2.0 - See `/memory/constitution.md`*
