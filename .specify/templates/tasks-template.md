# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
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
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup
- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

## Phase 3.2: UI Stubs & Manual Verification (Outside-In Approach)
**Start with user-facing components for rapid feedback**
- [ ] T004 [P] Stub main UI screens with placeholder content
- [ ] T005 [P] Stub navigation between screens
- [ ] T006 [P] Stub form inputs and buttons (non-functional)
- [ ] T007 Manual verification: Navigate through stubbed UI flow

## Phase 3.3: Core Implementation (Behind UI Components)
- [ ] T008 [P] User model in src/models/user.py
- [ ] T009 [P] UserService CRUD in src/services/user_service.py
- [ ] T010 [P] CLI --create-user in src/cli/user_commands.py
- [ ] T011 POST /api/users endpoint
- [ ] T012 GET /api/users/{id} endpoint
- [ ] T013 Input validation
- [ ] T014 Error handling and logging

## Phase 3.4: Refactoring Pass 1 (Post-Implementation)
**Clean up implementation before adding complexity**
- [ ] T015 Remove code duplication from core implementation
- [ ] T016 Extract common patterns into reusable functions
- [ ] T017 Improve naming and code clarity

## Phase 3.5: Edge Cases & Error Handling
- [ ] T018 Handle invalid input scenarios
- [ ] T019 Add error messages and user feedback
- [ ] T020 Handle network failures and timeouts
- [ ] T021 Add loading states and progress indicators

## Phase 3.6: Refactoring Pass 2 (Post-Edge Cases)
**Final cleanup before testing**
- [ ] T022 Consolidate error handling patterns
- [ ] T023 Refactor complex conditional logic
- [ ] T024 Extract configuration and constants
- [ ] T025 Optimize data structures and algorithms
- [ ] T026 Optimize performance bottlenecks

## Phase 3.7: Unit Tests (After Implementation)
- [ ] T027 [P] Unit tests for models in tests/unit/test_models.py
- [ ] T028 [P] Unit tests for services in tests/unit/test_services.py
- [ ] T029 [P] Unit tests for validation in tests/unit/test_validation.py
- [ ] T030 [P] Unit tests for utilities in tests/unit/test_utils.py

## Phase 3.8: Integration Tests (Final Validation)
- [ ] T031 [P] Integration test complete user workflow in tests/integration/test_user_flow.py
- [ ] T032 [P] Integration test cross-platform UI in tests/integration/test_cross_platform.py
- [ ] T033 [P] Security test Shamir's Secret Sharing in tests/security/test_shamir.py
- [ ] T034 [P] Screenshot test backup flow in tests/screenshot/test_backup_flow.dart

## Dependencies
- UI stubs (T004-T007) before implementation (T008-T014)
- Core implementation (T008-T014) before refactoring pass 1 (T015-T017)
- Refactoring pass 1 (T015-T017) before edge cases (T018-T021)
- Edge cases (T018-T021) before refactoring pass 2 (T022-T026)
- Refactoring pass 2 (T022-T026) before unit tests (T027-T030)
- Unit tests (T027-T030) before integration tests (T031-T034)
- T008 blocks T009, T015
- T018 blocks T019, T020
- T022 blocks T023, T024

## Parallel Example
```
# Launch T004-T006 together (UI stubs):
Task: "Stub main UI screens with placeholder content in lib/screens/"
Task: "Stub navigation between screens in lib/navigation/"
Task: "Stub form inputs and buttons (non-functional) in lib/widgets/"

# Launch T015-T017 together (refactoring pass 1):
Task: "Remove code duplication from core implementation"
Task: "Extract common patterns into reusable functions"
Task: "Improve naming and code clarity"

# Later, launch T027-T030 together (unit tests):
Task: "Unit tests for models in tests/unit/test_models.py"
Task: "Unit tests for services in tests/unit/test_services.py"
Task: "Unit tests for validation in tests/unit/test_validation.py"
```

## Notes
- [P] tasks = different files, no dependencies
- Manual verification of UI stubs before implementing functionality
- Refactoring passes clean up code before adding complexity
- Unit tests written after implementation and refactoring
- Integration tests written last for complete workflow validation
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → UI Stubs → Implementation → Refactoring Pass 1 → Edge Cases → Refactoring Pass 2 → Unit Tests → Integration Tests
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All UI components have stub tasks
- [ ] All entities have model tasks
- [ ] Refactoring passes included after implementation and edge cases
- [ ] Unit tests come after implementation and refactoring
- [ ] Integration tests come last
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task