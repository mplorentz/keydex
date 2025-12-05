# Research: Vault Recovery

**Feature**: 003-vault-recovery  
**Date**: 2024-12-19  
**Status**: Complete

## Research Tasks

### 1. Nostr Protocol Integration for Recovery Requests

**Task**: Research Nostr protocol patterns for encrypted direct messages and recovery request handling

**Decision**: Use Nostr kind 4 (encrypted direct messages) for recovery requests with custom content structure

**Rationale**: 
- Kind 4 is the standard for encrypted DMs in Nostr
- Provides end-to-end encryption between stewards
- Widely supported by existing Nostr clients and relays
- Allows for custom JSON payloads within encrypted content

**Alternatives considered**:
- Kind 1059 (gift wrap) - too specific to key sharing, not suitable for requests
- Custom kind numbers - would require NIP specification and adoption
- Public events with encryption - less secure than direct messages

### 2. Relay Scanning and Management

**Task**: Research best practices for Nostr relay scanning and configuration management using NDK

**Decision**: Use NDK's built-in relay management with continuous background scanning and configurable relay lists

**Rationale**:
- NDK abstracts relay communication complexity and handles connection management
- NDK provides built-in retry logic and connection pooling
- Background scanning ensures timely receipt of recovery requests
- Configurable relays allow users to choose trusted infrastructure
- NDK handles WebSocket connections, reconnection, and error handling automatically

**Alternatives considered**:
- Direct WebSocket implementation - unnecessary complexity when NDK handles this
- Polling-based scanning - less efficient than NDK's event-driven approach
- Single relay dependency - creates single point of failure
- Push notifications - not available in Nostr protocol

### 3. Shamir's Secret Sharing Recovery

**Task**: Research Shamir's Secret Sharing implementation for content reassembly

**Decision**: Use existing crypto library with threshold-based reconstruction

**Rationale**:
- Leverages proven cryptographic implementation
- Threshold-based recovery matches existing backup configuration
- Secure reconstruction process with proper key validation
- Compatible with existing key share format

**Alternatives considered**:
- Custom implementation - security risk and unnecessary complexity
- Different secret sharing schemes - would break compatibility
- Centralized recovery - defeats purpose of distributed backup

### 4. UI/UX Patterns for Recovery Status

**Task**: Research UI patterns for displaying recovery progress and steward status

**Decision**: Use status indicators with clear visual hierarchy and actionable feedback

**Rationale**:
- Status indicators provide immediate visual feedback
- Clear hierarchy helps users understand recovery progress
- Actionable feedback guides users on next steps
- Consistent with existing app design patterns

**Alternatives considered**:
- Text-only status - less intuitive for non-technical users
- Complex progress bars - may confuse users about recovery process
- Minimal status display - insufficient information for decision making

### 5. Cross-Platform Secure Storage

**Task**: Research secure storage patterns for recovered vault contents

**Decision**: Use FlutterSecureStorage with platform-specific keychain/keystore integration

**Rationale**:
- FlutterSecureStorage provides cross-platform secure storage
- Platform-specific integration ensures maximum security
- Consistent API across all platforms
- Handles key rotation and secure deletion

**Alternatives considered**:
- Plain text storage - security risk
- Custom encryption - unnecessary complexity
- Cloud storage - privacy concerns and offline requirements

### 6. Recovery Request Lifecycle Management

**Task**: Research patterns for managing recovery request state and cleanup

**Decision**: Implement state machine with automatic cleanup and user-initiated actions

**Rationale**:
- State machine ensures consistent request handling
- Automatic cleanup prevents storage bloat
- User-initiated actions provide control over recovery process
- Clear state transitions improve user experience

**Alternatives considered**:
- Manual state management - error-prone and inconsistent
- No cleanup - storage bloat over time
- Automatic approval - security risk

## Technical Decisions Summary

1. **Nostr Integration**: Use kind 4 encrypted DMs for recovery requests
2. **Relay Management**: NDK's built-in relay management with continuous background scanning
3. **Cryptography**: Existing Shamir's Secret Sharing implementation
4. **UI/UX**: Status indicators with clear visual hierarchy
5. **Storage**: FlutterSecureStorage for cross-platform secure storage
6. **State Management**: State machine with automatic cleanup

## Dependencies Identified

- **NDK (Nostr)**: For Nostr protocol integration
- **FlutterSecureStorage**: For secure local storage
- **Crypto**: For Shamir's Secret Sharing operations
- **Flutter**: For cross-platform UI implementation

## Security Considerations

- All recovery requests are encrypted end-to-end
- Key shares are never transmitted in plaintext
- Secure storage ensures recovered content protection
- State machine prevents unauthorized recovery attempts
- Relay scanning includes validation and filtering

## Performance Considerations

- Background scanning optimized for battery life
- Efficient state management prevents memory leaks
- Cached relay connections reduce latency
- Lazy loading of recovery request details
- Optimized UI updates for status changes
