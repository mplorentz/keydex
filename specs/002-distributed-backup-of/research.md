# Research: Distributed Backup of Lockboxes

## Shamir's Secret Sharing Implementation

**Decision**: Use ntc_dcrypto library for Shamir's Secret Sharing implementation  
**Rationale**: 
- [ntc_dcrypto](https://github.com/congnghia0609/ntc_dcrypto) provides a mature 256-bit implementation of Shamir's Secret Sharing Algorithm
- Apache 2.0 licensed with active maintenance and community support
- Supports both Base64Url and Hex encoding formats
- Well-tested with unit tests included in the repository
- Follows constitutional requirement for industry-standard cryptographic operations
- Reduces implementation complexity and security risk

**Alternatives considered**:
- Custom implementation: Would require extensive security review and mathematical verification
- `shamir_secret_sharing` package: Exists but unmaintained and not security-audited
- `crypto` package: Provides hash functions but not secret sharing
- External service: Would compromise decentralization and security
- Platform-specific implementations: Would violate cross-platform consistency

**Implementation approach**:
- Add `ntcdcrypto: ^0.4.0` to pubspec.yaml dependencies
- Use SSS class for creating and combining shares
- Support Base64Url encoding for better compatibility with Nostr protocol
- Validate threshold and share count parameters before calling library functions
- Include comprehensive tests using library's built-in test patterns

## Nostr Protocol Integration

**Decision**: Extend existing NDK (Dart Nostr Development Kit) usage for gift wrap events  
**Rationale**:
- Project already uses NDK v0.3.2 for NIP-44 encryption and key management
- NDK provides comprehensive Nostr protocol support including event publishing
- NIP-59 (Gift Wrap Events) is supported in NDK for kind 1059 events
- Maintains consistency with existing Nostr infrastructure
- NDK handles relay management and failover automatically

**Alternatives considered**:
- Custom Nostr implementation: Would duplicate existing functionality
- Different Nostr library: Would create inconsistency and maintenance burden
- Direct relay communication: Would bypass NDK's optimizations and error handling

**Implementation approach**:
- Use NDK's event publishing for gift wrap events (kind 1059)
- Leverage existing NIP-44 encryption for key encryption
- Utilize NDK's relay selection and failover mechanisms
- Extend existing KeyService for multi-recipient encryption

## NIP-44 and NIP-59 Standards

**Decision**: Implement NIP-44 encryption with NIP-59 gift wrap events  
**Rationale**:
- NIP-44 provides authenticated encryption using ChaCha20-Poly1305 AEAD
- NIP-59 enables encrypted content distribution to specific recipients
- Both standards are well-documented and widely adopted in Nostr ecosystem
- Compatible with existing KeyService NIP-44 implementation
- Provides end-to-end encryption for distributed backup keys

**Alternatives considered**:
- NIP-04: Older, less secure encryption standard
- Custom encryption: Would require security audit and standardization
- Unencrypted distribution: Security risk for sensitive backup keys

**Implementation approach**:
- Encrypt each Shamir share using NIP-44 with recipient's public key
- Wrap encrypted shares in NIP-59 gift wrap events (kind 1059)
- Include metadata for backup identification and recovery
- Validate recipient public keys before encryption

## FlutterSecureStorage Security

**Decision**: Continue using FlutterSecureStorage for local key management  
**Rationale**:
- Already implemented and tested in existing KeyService
- Provides platform-specific secure storage (Keychain on iOS, Keystore on Android)
- Handles encryption at the OS level for maximum security
- Cross-platform compatibility across all 5 target platforms
- No sensitive data stored in plaintext

**Alternatives considered**:
- SharedPreferences: Not secure enough for cryptographic keys
- Custom encryption: Would duplicate OS-level security features
- External secure storage: Would compromise offline capability

**Implementation approach**:
- Store backup configuration metadata in FlutterSecureStorage
- Use existing secure storage patterns from KeyService
- Implement secure deletion for revoked backup configurations
- Maintain separation between local keys and distributed shares

## Relay Selection and Failover

**Decision**: Leverage NDK's built-in relay management  
**Rationale**:
- NDK provides intelligent relay selection and failover mechanisms
- Handles network interruptions and relay unavailability automatically
- Maintains connection pools and retry logic
- Reduces implementation complexity and maintenance burden
- Follows constitutional principle of simplicity

**Alternatives considered**:
- Custom relay management: Would duplicate NDK functionality
- Single relay dependency: Would create single point of failure
- Manual relay selection: Would complicate user experience

**Implementation approach**:
- Use NDK's default relay discovery and selection
- Implement status tracking for backup distribution success/failure
- Provide user feedback on relay connectivity issues
- Allow manual relay configuration for advanced users

## Cross-Platform Considerations

**Decision**: Maintain Flutter's cross-platform approach with platform-specific optimizations  
**Rationale**:
- Existing codebase already targets all 5 platforms successfully
- FlutterSecureStorage handles platform differences automatically
- NDK provides consistent Nostr functionality across platforms
- Maintains constitutional requirement for cross-platform consistency

**Alternatives considered**:
- Platform-specific implementations: Would violate cross-platform consistency
- Web-only implementation: Would exclude mobile users
- Native implementations: Would create maintenance burden

**Implementation approach**:
- Use Flutter's platform channels only when necessary
- Leverage existing cross-platform packages (NDK, FlutterSecureStorage)
- Test backup functionality on all target platforms
- Maintain consistent UI/UX across platforms while respecting platform conventions
