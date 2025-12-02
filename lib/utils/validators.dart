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

/// Validates that a string is a valid nsec (Nostr private key in bech32 format)
///
/// Expected format: nsec1 followed by bech32-encoded data
bool isValidNsec(String nsec) {
  if (nsec.isEmpty || !nsec.startsWith('nsec1')) return false;
  
  // Basic validation: nsec1 + at least 58 characters (typical bech32 encoded key)
  // Full bech32 validation would require more complex logic
  if (nsec.length < 63) return false;
  
  // Bech32 characters: a-z, 0-9 (excludes 1, b, i, o)
  final bech32Regex = RegExp(r'^nsec1[ac-hj-np-z02-9]+$');
  return bech32Regex.hasMatch(nsec);
}

/// Validates that a string is a valid bunker URL
///
/// Expected format: bunker://<pubkey>?relay=<relay_url>
bool isValidBunkerUrl(String url) {
  if (url.isEmpty || !url.startsWith('bunker://')) return false;
  
  try {
    final uri = Uri.parse(url);
    if (uri.scheme != 'bunker') return false;
    
    // Should have a host (pubkey) and a relay query parameter
    if (uri.host.isEmpty) return false;
    
    return true;
  } catch (e) {
    return false;
  }
}
