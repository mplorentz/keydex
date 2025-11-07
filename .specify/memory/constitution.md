<!--
Sync Impact Report:
Version change: 1.2.1 → 1.3.0
Modified principles: 
  - Principle VIII: Riverpod State Management Architecture (expanded with service/repository guidance)
Added sections: 
  - Principle IX: Service and Repository Architecture (new architectural guidance)
  - Cross-Platform Development → Service and Repository Architecture subsection
  - Code Quality → Service and repository naming and organization conventions
Removed sections: N/A
Templates requiring updates:
  ✅ .specify/memory/constitution.md (service/repository architecture principles added)
  ✅ .cursorrules (service/repository patterns and examples added)
  ⚠ .specify/templates/plan-template.md (constitution check updated to include IX)
  ⚠ .specify/templates/tasks-template.md (may benefit from service/repository task examples)
Follow-up TODOs: 
  - Consider adding service/repository architecture examples to plan template
  - Update task template with service implementation patterns
-->

# Keydex Constitution

## Core Principles

### I. Security-First Development (NON-NEGOTIABLE)
Security is the primary concern for all design and implementation decisions. All cryptographic operations MUST use industry-standard libraries and algorithms. Shamir's Secret Sharing implementation must be mathematically correct and thoroughly tested. No security shortcuts or "good enough" solutions are permitted. Security reviews are mandatory for all cryptographic code.

### II. Outside-In Development
All features MUST start from the user's perspective and work inward to implementation details. Development begins with user scenarios and acceptance criteria that define the complete user experience. Implementation proceeds by stubbing out UI components first for manual verification, then implementing functionality behind those components to achieve working behavior. Edge cases are handled after core functionality works. Unit tests are added after implementation of isolated classes to verify their behavior. Integration tests are written last to validate complete workflows. This approach ensures rapid feedback and working functionality before comprehensive test coverage.

### III. Cross-Platform Consistency
The Flutter app MUST provide identical functionality across iOS, Android, macOS, Windows, and Linux. Platform-specific features are only added when absolutely necessary. UI/UX follows platform conventions while maintaining consistency in core functionality. All platforms receive updates simultaneously.

### IV. Simplicity & Readability
Code MUST be written for human readability over writing speed. KISS (Keep It Simple, Stupid) principles apply to all design decisions. DRY (Don't Repeat Yourself) is enforced, but not at the cost of clarity. Convention over configuration reduces cognitive load. Unnecessary dependencies are avoided to maintain project nimbleness.

### V. Non-Technical User Focus
The user interface MUST be intuitive enough for non-technical users to safely backup and recover sensitive data. Complex cryptographic concepts are abstracted behind simple, clear language. Error messages are actionable and written in plain English. Onboarding guides users through security best practices without technical jargon.

### VI. Open Source Excellence
The project prioritizes simplicity and easy extensibility for contributors. Code is well-documented and follows consistent patterns. Architecture decisions are documented with clear rationale. The codebase remains nimble and avoids over-engineering. Community contributions are welcomed and properly reviewed.

### VII. Interoperability & Standards
The app uses the Nostr protocol for all data transmission, ensuring decentralized and censorship-resistant communication. Backup and restore processes are documented in a Nostr Implementation Possibility (NIP) to enable interoperability with competing applications. All protocol implementations must follow established Nostr standards and be compatible with the broader Nostr ecosystem.

### VIII. Riverpod State Management Architecture
All state management MUST use Riverpod following established best practices. The app MUST be wrapped with ProviderScope at the root to enable provider access throughout the widget tree. State providers MUST be categorized correctly: Provider for immutable dependencies, FutureProvider for async data loading, StreamProvider for reactive streams, and StateProvider only for simple mutable state. Widgets that consume providers MUST use ConsumerWidget or ConsumerStatefulWidget instead of accessing providers directly. All providers MUST properly dispose resources using ref.onDispose(). Provider composition MUST use ref.watch() for reactive dependencies and ref.read() for one-time access. Cache invalidation MUST use ref.invalidate() or ref.refresh() when data changes. Auto-dispose providers MUST be preferred for data that should be cleaned up when not in use. Provider families MUST be used for parameterized providers (e.g., by ID). These patterns ensure predictable state management, automatic cleanup, and testability.

### IX. Service and Repository Architecture
Services MUST be instance classes with dependencies injected via Riverpod providers, not static utility classes. Each service MUST have a corresponding Provider that injects its dependencies. Repositories are separate from services and follow the Repository Pattern for data access abstraction. Repositories MUST be used when data access is complex (caching, multiple sources, streams, 100+ lines) or when multiple services need the same data access logic. Services MUST be used for business logic, validation, and workflows. Services depend on repositories for data access. Repositories handle persistence (SharedPreferences, databases), in-memory caching, stream management for reactive updates, and specialized queries. Services handle business rules, cross-cutting workflows (e.g., Shamir's Secret Sharing), validation logic, and orchestration of multiple repositories or external services. Do NOT create thin repository wrappers (under 100 lines that just delegate to services); instead use services directly with providers. Service-only architecture (no repository layer) is acceptable for simple data access with minimal caching. Circular dependencies between services MUST be broken by adding explicit types to Provider declarations. This architecture ensures testability through dependency injection, clear separation of concerns, and maintainable code as the system grows.

## Security Standards

### Cryptographic Requirements
- Shamir's Secret Sharing implementation must be mathematically verified
- All cryptographic operations use established, audited libraries
- Key generation uses cryptographically secure random number generators
- No sensitive data is stored in plaintext anywhere in the system
- All data transmission is encrypted using industry-standard protocols

### Data Protection
- Sensitive data exists only in memory during processing
- No logs contain sensitive information
- Secure deletion of temporary data is enforced
- Recovery shares are encrypted before storage
- User consent is explicitly required for all data operations

### Nostr Protocol Integration
- All data transmission uses Nostr protocol for decentralized communication
- Backup and restore processes are documented in a formal NIP specification
- Protocol implementations must be compatible with existing Nostr clients
- Nostr events are properly encrypted and signed according to protocol standards
- Relay selection and failover mechanisms ensure reliable data transmission

## Cross-Platform Development

### Flutter Architecture
- Single codebase maintains feature parity across all platforms
- Platform-specific code is isolated and clearly documented
- UI follows Material Design on Android and Cupertino on iOS
- Desktop platforms maintain native look and feel
- Performance is optimized for each platform's capabilities

### Riverpod State Management
- ProviderScope wraps the entire app at the root level
- Provider types are used correctly: Provider for dependencies, FutureProvider for async data, StreamProvider for reactive streams, StateProvider only for simple mutable state
- All widgets that consume providers use ConsumerWidget or ConsumerStatefulWidget
- Resources are properly disposed using ref.onDispose()
- Provider composition uses ref.watch() for reactive dependencies and ref.read() for one-time access
- Cache invalidation uses ref.invalidate() or ref.refresh() when data changes
- Auto-dispose providers are preferred for temporary or screen-scoped data
- Provider families (Provider.family) are used for parameterized providers
- Provider dependencies are managed through ref.watch() to maintain reactive updates
- StreamProvider uses Stream.multi() for proper subscription management and cleanup

### Service and Repository Architecture
- Services are instance classes with Riverpod dependency injection, not static utility classes
- Each service has a Provider that injects its dependencies
- Repositories handle data access (persistence, caching, streams, queries)
- Services handle business logic (validation, workflows, orchestration)
- Use repositories when: data access is complex (100+ lines), multiple services need same data, or might swap storage
- Use service-only when: simple CRUD, single consumer, minimal caching
- No thin repository wrappers (under 100 lines that just delegate)
- Circular dependencies broken with explicit Provider type declarations

### Testing Strategy
- Manual verification of stubbed UI components comes first for rapid feedback
- Unit tests are added after implementation of isolated classes to verify behavior
- Widget tests validate UI behavior and user interactions
- Security tests validate cryptographic operations and sensitive data handling
- Nostr protocol tests ensure proper event handling and relay communication
- Platform-specific tests ensure native functionality
- Integration tests are written last to validate complete user workflows
- Golden tests (screenshot tests) validate UI changes across all platforms and detect layout regressions

### Golden Testing Conventions
- Golden test files MUST use the `*_golden_test.dart` naming convention
- Golden images are stored in `test/goldens/` directory
- Tests use `testGoldens()` from `golden_toolkit` package for consistent rendering
- Widget rendering uses `pumpWidgetBuilder()` with proper surface size constraints
- Helper functions handle edge cases (e.g., widgets with infinite animations using `screenMatchesGoldenWithoutSettle`)
- Global test configuration in `flutter_test_config.dart` loads app fonts and configures golden validation
- Golden validation runs on macOS only to ensure consistent font rendering across test runs
- Golden tests cover all UI states: loading, error, empty, and data-filled states
- Provider overrides use `ProviderContainer` with `UncontrolledProviderScope` for golden tests
- Golden tests serve as visual regression tests to quickly detect layout bugs and understand code changes

## Quality Gates

### Security Review
- All cryptographic code requires security review
- No sensitive data handling without proper encryption
- Security tests must pass before any release
- Third-party security audits are conducted regularly

### User Experience
- All user flows are tested by non-technical users
- Error messages are clear and actionable
- Onboarding process is intuitive and complete
- Accessibility standards are met across all platforms

### Code Quality
- All code follows established Flutter/Dart conventions
- Test files MUST use the `*_test.dart` naming convention for IDE compatibility
- Code reviews are required for all changes
- Documentation is updated with every feature
- Performance is measured and optimized
- Nostr protocol implementations are tested against multiple relay providers
- NIP documentation is maintained and updated with protocol changes
- Riverpod providers follow naming conventions: providers end with `Provider`, repositories end with `Repository`, services end with `Service`
- Provider files are organized in `lib/providers/` directory, service files in `lib/services/`
- Services are instance classes with dependency injection, not static utility classes
- Repository classes are used only for complex data access (caching, streams, multiple sources)
- Provider tests mock dependencies using OverrideProvider for testability
- Golden test files follow `*_golden_test.dart` naming convention
- Golden images are stored in `test/goldens/` directory

## Governance

This constitution supersedes all other development practices and guidelines. Amendments require documentation of rationale, security review if security-related, and approval through the /constitution command. All PRs and reviews must verify compliance with constitutional principles. Security-related changes require additional review by cryptography experts. The project maintains its open-source nature and community-driven development approach.

**Version**: 1.3.0 | **Ratified**: 2025-01-27 | **Last Amended**: 2025-10-31