/// Common validation utilities for Keydex
///
/// Provides reusable validation functions for hex strings, Base64 encoding,
/// relay URLs, and other common data formats used throughout the application.
library;

/// Validates that a string is a valid hex-encoded public key (64 characters)
///
/// Expected format: 64 hexadecimal characters (0-9, a-f, A-F), no 0x prefix
///
/// Example valid pubkeys:
/// - `3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d`
/// - `AB1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890AB`
bool isValidHexPubkey(String pubkey) {
  if (pubkey.length != 64) return false;

  // Hex characters: 0-9, a-f, A-F (exactly 64 characters)
  final hexRegex = RegExp(r'^[0-9a-fA-F]{64}$');
  return hexRegex.hasMatch(pubkey);
}

/// Validates that a string is a valid hex-encoded private key (64 characters)
///
/// Same format as public keys: 64 hexadecimal characters, no 0x prefix
/// This is an alias for [isValidHexPubkey] for semantic clarity
bool isValidHexPrivkey(String privkey) {
  return isValidHexPubkey(privkey);
}

/// Validates that a string is a valid hex-encoded event ID (64 characters)
///
/// Nostr event IDs are 64-character hex strings
/// This is an alias for [isValidHexPubkey] for semantic clarity
bool isValidEventId(String eventId) {
  return isValidHexPubkey(eventId);
}

/// Validates that a string is a valid hex string of any length
///
/// Allows any length hex string (even number of characters preferred)
bool isValidHexString(String hex) {
  if (hex.isEmpty) return false;

  final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
  return hexRegex.hasMatch(hex);
}

/// Validates that a relay URL is a valid WebSocket URL
///
/// Expected formats:
/// - `wss://relay.example.com` (secure WebSocket, production)
/// - `ws://localhost:7000` (insecure WebSocket, development only)
///
/// The URL must have a valid scheme (wss:// or ws://) and a non-empty host
bool isValidRelayUrl(String relayUrl) {
  if (relayUrl.isEmpty) return false;

  try {
    final uri = Uri.parse(relayUrl);
    return (uri.scheme == 'wss' || uri.scheme == 'ws') && uri.host.isNotEmpty;
  } catch (e) {
    return false;
  }
}

/// Validates that an invite code is in the correct Base64URL format
///
/// Expected format: Base64URL encoded string (alphanumeric + - and _)
/// No padding characters (=) should be present
///
/// Valid characters: A-Z, a-z, 0-9, -, _
bool isValidInviteCode(String inviteCode) {
  if (inviteCode.isEmpty) return false;

  // Base64URL characters: A-Z, a-z, 0-9, -, _
  final base64UrlRegex = RegExp(r'^[A-Za-z0-9_-]+$');
  return base64UrlRegex.hasMatch(inviteCode);
}

/// Validates that a string is valid Base64 (standard encoding with padding)
///
/// Valid characters: A-Z, a-z, 0-9, +, /, =
bool isValidBase64(String base64) {
  if (base64.isEmpty) return false;

  // Standard Base64 characters including padding
  final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');

  // Length must be multiple of 4 with padding
  if (!base64Regex.hasMatch(base64)) return false;
  if (base64.length % 4 != 0) return false;

  return true;
}

/// Validates that a string is valid Base64URL (URL-safe encoding, no padding)
///
/// Valid characters: A-Z, a-z, 0-9, -, _
bool isValidBase64Url(String base64Url) {
  if (base64Url.isEmpty) return false;

  // Base64URL characters: no padding
  final base64UrlRegex = RegExp(r'^[A-Za-z0-9_-]+$');
  return base64UrlRegex.hasMatch(base64Url);
}

/// Validates that a lockbox ID is in the correct format
///
/// Lockbox IDs are UUIDs (can be validated more strictly if needed)
/// For now, we just check it's not empty
bool isValidLockboxId(String lockboxId) {
  return lockboxId.trim().isNotEmpty;
}

/// Validates that a name string is valid (not empty after trimming)
bool isValidName(String name) {
  return name.trim().isNotEmpty;
}

/// Validates that a string is a valid nsec (bech32 encoded private key)
///
/// Expected format: nsec1 prefix followed by 58 bech32 characters
/// Bech32 charset: alphanumeric lowercase except '1', 'b', 'i', 'o'
///
/// Example valid nsec:
/// - `nsec1l6huq5jl0q9x8jf7lwfz3c9xt8lx6xqy0jhj8hklx8z7w6k9j5ksqy7w9l`
bool isValidNsec(String nsec) {
  if (!nsec.startsWith('nsec1')) return false;

  // Bech32 uses specific charset: qpzry9x8gf2tvdw0s3jn54khce6mua7l (no '1', 'b', 'i', 'o')
  // Length should be 63 total characters (nsec1 = 5 chars + 58 data chars)
  final bech32Regex = RegExp(r'^nsec1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{58}$');
  return bech32Regex.hasMatch(nsec);
}

/// Validates that a string is a valid npub (bech32 encoded public key)
///
/// Expected format: npub1 prefix followed by 58 bech32 characters
/// Bech32 charset: alphanumeric lowercase except '1', 'b', 'i', 'o'
///
/// Example valid npub:
/// - `npub1l6huq5jl0q9x8jf7lwfz3c9xt8lx6xqy0jhj8hklx8z7w6k9j5ksqy7w9l`
bool isValidNpub(String npub) {
  if (!npub.startsWith('npub1')) return false;

  // Same bech32 charset as nsec
  // Length should be 63 total characters (npub1 = 5 chars + 58 data chars)
  final bech32Regex = RegExp(r'^npub1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{58}$');
  return bech32Regex.hasMatch(npub);
}

/// Validates that a string is a valid bunker URL (NIP-46)
///
/// Expected format: bunker://<pubkey>?relay=<relay>&secret=<secret>
/// Or: nostr+walletconnect://<pubkey>?relay=<relay>&secret=<secret>
///
/// Example valid bunker URL:
/// - `bunker://a1b2c3...?relay=wss://relay.example.com&secret=abc123`
/// - `nostr+walletconnect://a1b2c3...?relay=wss://relay.example.com`
bool isValidBunkerUrl(String url) {
  if (url.isEmpty) return false;

  // Support both bunker:// and nostr+walletconnect:// schemes
  if (!url.startsWith('bunker://') && !url.startsWith('nostr+walletconnect://')) {
    return false;
  }

  try {
    // Try to parse as URI
    final uri = Uri.parse(url);

    // Validate scheme
    if (uri.scheme != 'bunker' && uri.scheme != 'nostr+walletconnect') {
      return false;
    }

    // Host should be the pubkey (non-empty)
    if (uri.host.isEmpty) return false;

    // Should have at least one query parameter (relay or secret)
    if (uri.queryParameters.isEmpty) return false;

    return true;
  } catch (e) {
    return false;
  }
}
