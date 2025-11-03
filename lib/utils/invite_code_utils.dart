import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Utilities for generating and validating Base64URL-encoded invitation codes

/// Generates a cryptographically secure ID
///
/// Returns a Base64URL-encoded string from 32 random bytes (~43 characters).
/// Uses a cryptographically secure random number generator.
/// Can be used for invitation codes, lockbox IDs, recovery request IDs, and other secure identifiers.
String generateSecureID() {
  final random = Random.secure();
  final bytes = Uint8List(32); // 32 bytes = 256 bits

  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = random.nextInt(256);
  }

  // Encode to Base64URL (RFC 4648)
  // Base64URL uses - and _ instead of + and / and omits padding (=)
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Validates the format of an invite code
///
/// Returns true if the code is a valid Base64URL string,
/// false otherwise.
///
/// Valid Base64URL characters: A-Z, a-z, 0-9, -, _
bool isValidInviteCodeFormat(String inviteCode) {
  if (inviteCode.isEmpty) return false;

  // Base64URL characters: A-Z, a-z, 0-9, -, _
  // For 32 bytes, expected length is 43 characters (no padding)
  final base64UrlRegex = RegExp(r'^[A-Za-z0-9_-]+$');

  if (!base64UrlRegex.hasMatch(inviteCode)) {
    return false;
  }

  // Optionally verify it's a reasonable length
  // 32 bytes => 43 chars, but allow some flexibility
  if (inviteCode.length < 20 || inviteCode.length > 50) {
    return false;
  }

  return true;
}

/// Decodes a Base64URL invite code to bytes
///
/// Returns the decoded bytes, or null if decoding fails.
Uint8List? decodeInviteCode(String inviteCode) {
  try {
    // Add padding if needed (Base64 requires length to be multiple of 4)
    String padded = inviteCode;
    while (padded.length % 4 != 0) {
      padded += '=';
    }

    return base64Url.decode(padded);
  } catch (e) {
    return null;
  }
}

/// Verifies that an invite code can be decoded successfully
///
/// Returns true if the code is valid Base64URL and can be decoded,
/// false otherwise.
bool canDecodeInviteCode(String inviteCode) {
  return decodeInviteCode(inviteCode) != null;
}
