<!--
Sync Impact Report:
Version change: 0.0.0 → 1.0.0
Modified principles: N/A (initial creation)
Added sections: Security-First Development, Cross-Platform UX, Open Source Principles, Interoperability & Standards
Removed sections: N/A
Templates requiring updates:
  ✅ .specify/templates/plan-template.md (constitution check alignment)
    - Added keydex-specific constitution check gates
    - Security-First Development validation
    - Cross-Platform Consistency checks
    - Nostr Protocol Integration requirements
    - Non-Technical User Focus validation
  ✅ .specify/templates/spec-template.md (constitution compliance)
    - Added Keydex-Specific Requirements section
    - Security requirements for sensitive data handling
    - Cross-platform functionality specification
    - Nostr protocol integration requirements
    - Shamir's Secret Sharing workflow documentation
  ✅ .specify/templates/tasks-template.md (TDD enforcement)
    - Updated test examples for keydex context
    - Security tests for Shamir's Secret Sharing
    - Contract tests for Nostr backup events
    - Cross-platform UI integration tests
    - Screenshot tests for backup flow
  ✅ .cursor/commands/constitution.md (self-reference)
Follow-up TODOs: None
-->

# Keydex Constitution

## Core Principles

### I. Security-First Development (NON-NEGOTIABLE)
Security is the primary concern for all design and implementation decisions. All cryptographic operations MUST use industry-standard libraries and algorithms. Shamir's Secret Sharing implementation must be mathematically correct and thoroughly tested. No security shortcuts or "good enough" solutions are permitted. Security reviews are mandatory for all cryptographic code.

### II. Behavior-Driven Development
All features MUST be defined through user stories and acceptance criteria before implementation begins. Tests are written in plain language that are easy to understand. The Red-Green-Refactor cycle is enforced, with tests written first and failing before implementation. Integration tests validate complete user workflows across all platforms. Screenshot tests should be used for validation of UI changes.

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

### Testing Strategy
- Unit tests cover all business logic and cryptographic functions
- Widget tests validate UI behavior across platforms
- Integration tests verify complete user workflows
- Platform-specific tests ensure native functionality
- Security tests validate cryptographic operations
- Nostr protocol tests ensure proper event handling and relay communication
- Screenshot tests validate UI changes across all platforms

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

## Governance

This constitution supersedes all other development practices and guidelines. Amendments require documentation of rationale, security review if security-related, and approval through the /constitution command. All PRs and reviews must verify compliance with constitutional principles. Security-related changes require additional review by cryptography experts. The project maintains its open-source nature and community-driven development approach.

**Version**: 1.0.0 | **Ratified**: 2025-01-27 | **Last Amended**: 2025-01-27