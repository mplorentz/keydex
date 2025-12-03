# Research: Invitation Links for Stewards

**Feature**: 004-invitation-links  
**Date**: 2025-01-27

## Research Questions

### 1. Deep Linking Package for Flutter

**Question**: What Flutter package should be used for deep linking/Universal Links across all platforms?

**Decision**: Use `app_links` package (https://pub.dev/packages/app_links)

**Rationale**:
- Well-maintained package with active development
- Supports all Flutter platforms: iOS (Universal Links), Android (App Links), Web (URL routing), macOS, Windows, Linux
- Handles both initial link (app opened via link) and subsequent links (app already running)
- Provides consistent API across platforms
- Handles link parsing and validation
- Supports both HTTP/HTTPS links and custom URL schemes
- Used by many production Flutter apps

**Alternatives Considered**:
- `uni_links`: Older package, less maintained, missing some platform support
- `go_router` with deep linking: Overkill for simple deep linking needs, better for complex navigation
- Platform-specific implementations: Would require significant code duplication and maintenance burden

**Implementation Notes**:
- Add `app_links: ^5.0.0` to `pubspec.yaml`
- Configure Universal Links on iOS (requires apple-app-site-association file on horcrux.app)
- Configure App Links on Android (requires assetlinks.json on horcrux.app)
- Handle link parsing in app initialization and when app is already running

### 2. Invitation Link URL Format

**Question**: What format should invitation links use?

**Decision**: Use human-readable format: `https://horcrux.app/invite/{inviteCode}`

**Rationale**:
- Human-readable URLs are easier to debug and verify
- Shorter URLs are easier to share via text/email
- Invite codes will be cryptographically secure random strings (32+ characters)
- Can add query parameters for additional data if needed: `?owner={ownerPubkey}&relays={relayUrls}`

**Format Details**:
- Base URL: `https://horcrux.app/invite/`
- Invite code: Base64URL encoded 32-byte random string (43 characters)
- Optional query params: `owner` (hex pubkey), `relays` (comma-separated URLs, URL-encoded)
- Example: `https://horcrux.app/invite/abc123...xyz?owner=789abc...def&relays=wss%3A%2F%2Frelay1.com`

**Security Considerations**:
- Invite codes must be cryptographically random (use `dart:math` Random.secure or `crypto` package)
- Codes are single-use and tracked in SharedPreferences
- Links expire when invitation is denied or removed from backup config
- Owner pubkey and relay URLs can be embedded in link or fetched separately (embedded preferred for offline support)

### 3. Invitation Code Generation and Storage

**Question**: How should invitation codes be generated and stored?

**Decision**: 
- Generate using cryptographically secure random: 32 bytes = 256 bits
- Encode as Base64URL (URL-safe, no padding needed)
- Store in SharedPreferences with structure: `{vaultId}_{inviteCode}: {inviteeName, createdAt, status, redeemedBy}`
- Store mapping: `invitation_{inviteCode}: {vaultId, ownerPubkey, relayUrls, createdAt}`

**Rationale**:
- 32 bytes provides 256 bits of entropy (sufficient security)
- Base64URL encoding creates human-readable but secure codes
- SharedPreferences is sufficient for non-sensitive tracking data
- Separate storage allows lookup by invite code (for redemption) and by vaultId (for management)

**Storage Structure**:
```json
{
  "invitations_vault_abc123": {
    "inviteCode1": {
      "inviteeName": "Alice",
      "createdAt": "2025-01-27T10:00:00Z",
      "status": "pending|redeemed|denied|invalidated",
      "redeemedBy": "pubkey_hex_or_null"
    }
  },
  "invitation_inviteCode1": {
    "vaultId": "abc123",
    "ownerPubkey": "owner_pubkey_hex",
    "relayUrls": ["wss://relay1.com", "wss://relay2.com"],
    "createdAt": "2025-01-27T10:00:00Z"
  }
}
```

### 4. Nostr Event Kinds for Invitation Events

**Question**: What Nostr event kinds should be used for RSVP, denial, and confirmation events?

**Decision**: Use Horcrux custom event kinds:
- `invitationRsvp`: 1340 (for accepting invitations)
- `invitationDenial`: 1341 (for denying invitations)
- `shardConfirmation`: 1342 (for confirming shard receipt)
- `shardError`: 1343 (for shard processing errors)
- `invitationInvalid`: 1344 (for notifying about invalid/used codes)

**Rationale**:
- Continues existing pattern (existing custom kinds: 1337-1339)
- All events encrypted using NIP-44 (kind 4 style)
- Event structure follows existing recovery event patterns
- Tags include: `['p', ownerPubkey]` for recipient, `['invite', inviteCode]` for invitation reference

**Event Structure**:
- RSVP: Encrypted content contains `{inviteCode, pubkey, timestamp}`
- Denial: Encrypted content contains `{inviteCode, timestamp, reason?}`
- Confirmation: Encrypted content contains `{vaultId, shardIndex, timestamp}`
- Error: Encrypted content contains `{vaultId, shardIndex, error, timestamp}`
- Invalid: Encrypted content contains `{inviteCode, reason}`

### 5. Relay URL Handling in Links

**Question**: How many relay URLs should be included in invitation links?

**Decision**: Include up to 3 relay URLs in the link, comma-separated in query parameter

**Rationale**:
- Provides redundancy without making URLs too long
- Users can configure up to 5 relays in backup config, but only include primary ones in link
- If relay URLs change, system can handle gracefully (invitee can use stored relays or ask owner)
- Relay URLs should be URL-encoded in query parameter

**Implementation**:
- Extract relay URLs from backup config when generating link
- Take first 3 relay URLs (or all if fewer than 3)
- Encode as query parameter: `?relays=wss%3A%2F%2Frelay1.com%2Cwss%3A%2F%2Frelay2.com`
- Store original relay list in invitation storage for reference

### 6. Universal Links Configuration Requirements

**Question**: What configuration is needed for Universal Links (iOS) and App Links (Android)?

**Decision**: 
- iOS: Requires `apple-app-site-association` file hosted at `https://horcrux.app/.well-known/apple-app-site-association`
- Android: Requires `assetlinks.json` file hosted at `https://horcrux.app/.well-known/assetlinks.json`
- Both files must be served with correct Content-Type headers
- App must be configured with associated domains (iOS) and intent filters (Android)

**Rationale**:
- Standard approach for Universal Links/App Links
- Requires domain ownership and ability to host files at horcrux.app
- File contents must match app's bundle identifier and signing certificate
- Configuration files are platform-specific JSON formats

**Configuration Files** (to be hosted on horcrux.app):
- `apple-app-site-association`: Contains app ID and paths to handle
- `assetlinks.json`: Contains package name, SHA-256 fingerprints, and paths

**Implementation Notes**:
- Domain configuration is out of scope for this feature (assumed to be handled separately)
- App code assumes proper Universal Links setup
- Deep link handling code will work once configuration files are in place

### 7. Custom URL Scheme for Local Testing

**Question**: How should we handle local testing and debugging before Universal Links are configured?

**Decision**: Support custom URL scheme `horcrux://` as fallback for local testing and development

**Rationale**:
- Universal Links require domain configuration (apple-app-site-association, assetlinks.json) which can be complex to set up
- Custom URL schemes work immediately without domain configuration
- Allows testing deep linking functionality during development
- Can be used as fallback if Universal Links fail
- Easy to test locally with command line or browser: `horcrux://horcrux.app/invite/{code}?owner={pubkey}&relays={urls}`

**URL Format**:
- Production: `https://horcrux.app/invite/{inviteCode}?owner={pubkey}&relays={urls}`
- Development/Testing: `horcrux://horcrux.app/invite/{inviteCode}?owner={pubkey}&relays={urls}`
- Maintains same path structure (`/invite/{code}`) for code reuse

**Implementation**:
- Configure custom URL scheme in iOS Info.plist and Android manifest
- Deep link service should handle both Universal Links and custom schemes
- Link parser should extract path and query params identically from both formats
- Prefer Universal Links when available, fall back to custom scheme

**Platform Configuration**:
- iOS: Add URL scheme `horcrux` to Info.plist CFBundleURLSchemes
- Android: Add intent filter with scheme `horcrux` to MainActivity
- macOS/Windows: Similar URL scheme registration

**Testing**:
- Can test locally with: `flutter run` and then open `horcrux://horcrux.app/invite/test123`
- iOS Simulator: `xcrun simctl openurl booted "horcrux://horcrux.app/invite/test123"`
- Android Emulator: `adb shell am start -a android.intent.action.VIEW -d "horcrux://horcrux.app/invite/test123"`
- Desktop: Can open from terminal or browser (if configured)

**Benefits**:
- No domain configuration needed for development
- Same code path for parsing (just different scheme)
- Easy to test locally before Universal Links setup
- Can be kept as fallback mechanism in production

## Dependencies and Best Practices

### Flutter Deep Linking Best Practices
- Handle both cold start (app opened via link) and warm start (app already running) scenarios
- Validate link format before processing
- Show appropriate error messages for invalid links
- Handle cases where app is not installed (redirect to app store/web fallback)

### Nostr Event Best Practices
- Always encrypt event content using NIP-44
- Include proper tags for filtering and routing
- Sign events with user's private key
- Broadcast to multiple relays for redundancy
- Handle relay failures gracefully

### Cross-Platform Considerations
- Test deep linking on all platforms during development
- Handle platform-specific deep link behaviors
- Ensure consistent user experience across platforms
- Fallback to web app if native app not available
- Support custom URL scheme for local testing before Universal Links are configured

## Remaining Implementation Decisions

The following items will be determined during implementation:
- Error recovery UI actions (retry distribution, revoke invitation, etc.)
- Invitation expiration timeout (if any)
- Maximum number of pending invitations per vault
- UI/UX for invitation acceptance flow for new users

