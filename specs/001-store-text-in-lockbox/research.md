# Research: Encrypted Text Vault

## NIP-44 Encryption Implementation

**Decision**: Use NIP-44 (Nostr Encrypted Direct Message) for text encryption  
**Rationale**: 
- Standardized encryption method within the Nostr ecosystem
- Uses ChaCha20-Poly1305 AEAD encryption (industry standard)
- Provides authenticated encryption with associated data
- Compatible with existing Nostr infrastructure
- Well-documented and widely adopted

**Alternatives considered**:
- AES-GCM: More common but not Nostr-native
- Custom encryption: Would require security audit and standardization
- NIP-04: Older Nostr encryption standard, less secure than NIP-44

## Flutter Local Storage

**Decision**: Use shared_preferences for encrypted data storage  
**Rationale**:
- Simple key-value storage suitable for vault metadata
- Cross-platform compatibility across all 5 target platforms
- Encrypted data stored as base64-encoded strings
- No external database dependencies
- Automatic platform-specific storage handling

**Alternatives considered**:
- SQLite: Overkill for simple key-value storage
- Hive: More complex, not needed for simple storage
- File system: More complex, shared_preferences handles this

## Biometric Authentication

**Decision**: Use local_auth package for biometric authentication  
**Rationale**:
- Native biometric support across all platforms
- Handles platform differences (Touch ID, Face ID, Fingerprint, etc.)
- Secure authentication without storing biometric data
- Fallback to PIN/password when biometrics unavailable
- Well-maintained Flutter package

**Alternatives considered**:
- Custom biometric implementation: Platform-specific complexity
- Password-only: Less convenient for users
- No authentication: Security risk

## Nostr Key Management

**Decision**: Use NDK (Dart Nostr Development Kit) for key generation and management  
**Rationale**:
- Most comprehensive and actively maintained Nostr implementation for Dart/Flutter
- Mobile-optimized with automatic relay discovery and intelligent caching
- Handles key generation, signing, and encryption with extensive NIP support
- Compatible with NIP-44 encryption standard and many other NIPs
- Plugin architecture for custom databases, event verifiers, and signers
- Well-tested, maintained, and production-ready
- Integrates seamlessly with Nostr ecosystem

**Alternatives considered**:
- dart_nostr: Good but less advanced features and mobile optimization
- nostr_dart: Basic functionality, limited NIP support
- nostr (anasfik): Good scalability but lacks advanced features
- Custom key management: Security risk, reinventing the wheel
- External key storage: Complexity, security concerns
- Hardcoded keys: Security vulnerability

## Error Handling Strategy

**Decision**: Graceful error handling with user-friendly messages  
**Rationale**:
- Non-technical users need clear, actionable error messages
- Error codes for support debugging
- Graceful degradation when encryption fails
- No sensitive data exposed in error messages

**Alternatives considered**:
- Technical error messages: Confusing for non-technical users
- Silent failures: Poor user experience
- Crash on errors: Unreliable app

## Performance Considerations

**Decision**: Optimize for <200ms encryption/decryption operations  
**Rationale**:
- 4k character limit keeps operations fast
- NIP-44 is designed for efficiency
- Local storage avoids network latency
- Good user experience with responsive UI

**Alternatives considered**:
- Larger text limits: Would impact performance
- Network storage: Latency and reliability issues
- Synchronous operations: Could block UI
