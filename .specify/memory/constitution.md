<!--
Sync Impact Report:
Version change: 1.0.0 → 1.1.0
Modified principles: Behavior-Driven Development → Outside-In Development
Added sections: N/A
Removed sections: N/A
Templates requiring updates:
  ✅ .specify/templates/plan-template.md (constitution check alignment)
    - Added Outside-In Development checklist section
    - Updated constitution version reference to v1.1.0
  ✅ .specify/templates/spec-template.md (constitution compliance)
    - No changes needed - already focuses on user scenarios
  ✅ .specify/templates/tasks-template.md (testing approach)
    - Updated Phase 3.2 from "Tests First (TDD)" to "UI Stubs & Manual Verification"
    - Reorganized phases: Setup → UI Stubs → Implementation → Refactoring Pass 1 → Edge Cases → Refactoring Pass 2 → Unit Tests → Integration Tests
    - Added two refactoring phases: after implementation and after edge cases
    - Updated dependencies, parallel examples, and task numbering
    - Updated validation checklist and task generation rules
Follow-up TODOs: None - all templates updated
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
- Manual verification of stubbed UI components comes first for rapid feedback
- Unit tests are added after implementation of isolated classes to verify behavior
- Widget tests validate UI behavior and user interactions
- Security tests validate cryptographic operations and sensitive data handling
- Nostr protocol tests ensure proper event handling and relay communication
- Platform-specific tests ensure native functionality
- Integration tests are written last to validate complete user workflows
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

**Version**: 1.1.0 | **Ratified**: 2025-01-27 | **Last Amended**: 2025-09-24