import 'key_holder_status.dart';
import '../services/logger.dart';

/// Represents a trusted contact who holds a backup key
///
/// This model contains information about a key holder including
/// their Nostr public key, status, and acknowledgment details.
import 'package:ndk/shared/nips/nip01/helpers.dart';

typedef KeyHolder = ({
  String pubkey, // Hex format
  String? name,
  KeyHolderStatus status,
  DateTime? lastSeen,
  String? keyShare,
  String? giftWrapEventId,
  DateTime? acknowledgedAt,
  String? acknowledgmentEventId,
});

/// Create a new KeyHolder with validation
KeyHolder createKeyHolder({
  required String pubkey, // Takes hex format directly
  String? name,
}) {
  if (!_isValidHexPubkey(pubkey)) {
    throw ArgumentError('Invalid hex pubkey format: $pubkey');
  }

  return (
    pubkey: pubkey,
    name: name,
    status: KeyHolderStatus.pending,
    lastSeen: null,
    keyShare: null,
    giftWrapEventId: null,
    acknowledgedAt: null,
    acknowledgmentEventId: null,
  );
}

/// Create a copy of this KeyHolder with updated fields
KeyHolder copyKeyHolder(
  KeyHolder holder, {
  String? pubkey, // Hex format
  String? name,
  KeyHolderStatus? status,
  DateTime? lastSeen,
  String? keyShare,
  String? giftWrapEventId,
  DateTime? acknowledgedAt,
  String? acknowledgmentEventId,
}) {
  return (
    pubkey: pubkey ?? holder.pubkey,
    name: name ?? holder.name,
    status: status ?? holder.status,
    lastSeen: lastSeen ?? holder.lastSeen,
    keyShare: keyShare ?? holder.keyShare,
    giftWrapEventId: giftWrapEventId ?? holder.giftWrapEventId,
    acknowledgedAt: acknowledgedAt ?? holder.acknowledgedAt,
    acknowledgmentEventId: acknowledgmentEventId ?? holder.acknowledgmentEventId,
  );
}

/// Extension methods for KeyHolder
extension KeyHolderExtension on KeyHolder {
  /// Check if this key holder is active
  bool get isActive {
    return status == KeyHolderStatus.active || status == KeyHolderStatus.acknowledged;
  }

  /// Check if this key holder has acknowledged receipt
  bool get hasAcknowledged {
    return status == KeyHolderStatus.acknowledged && acknowledgedAt != null;
  }

  /// Check if this key holder is responsive (seen recently)
  bool get isResponsive {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    final timeSinceLastSeen = now.difference(lastSeen!);
    return timeSinceLastSeen.inHours < 24; // Consider responsive if seen within 24 hours
  }

  /// Get the bech32-encoded npub for display
  String get npub {
    // pubkey is already in hex format without 0x prefix (Nostr convention)
    return Helpers.encodeBech32(pubkey, 'npub');
  }

  /// Get display name (name if available, otherwise truncated npub)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    final displayNpub = npub;
    return '${displayNpub.substring(0, 8)}...${displayNpub.substring(displayNpub.length - 8)}';
  }
}

/// Convert to JSON for storage
Map<String, dynamic> keyHolderToJson(KeyHolder holder) {
  return {
    'pubkey': holder.pubkey, // Store hex format
    'name': holder.name,
    'status': holder.status.name,
    'lastSeen': holder.lastSeen?.toIso8601String(),
    'keyShare': holder.keyShare,
    'giftWrapEventId': holder.giftWrapEventId,
    'acknowledgedAt': holder.acknowledgedAt?.toIso8601String(),
    'acknowledgmentEventId': holder.acknowledgmentEventId,
  };
}

/// Create from JSON
KeyHolder keyHolderFromJson(Map<String, dynamic> json) {
  return (
    pubkey: json['pubkey'] as String, // Hex format without 0x prefix
    name: json['name'] as String?,
    status: KeyHolderStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => KeyHolderStatus.pending,
    ),
    lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
    keyShare: json['keyShare'] as String?,
    giftWrapEventId: json['giftWrapEventId'] as String?,
    acknowledgedAt:
        json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt'] as String) : null,
    acknowledgmentEventId: json['acknowledgmentEventId'] as String?,
  );
}

/// String representation of KeyHolder
String keyHolderToString(KeyHolder holder) {
  return 'KeyHolder(pubkey: ${holder.pubkey.substring(0, 8)}..., name: ${holder.name}, status: ${holder.status})';
}

/// Validate hex pubkey format
bool _isValidHexPubkey(String pubkey) {
  if (pubkey.length != 64) return false;

  // Check if all characters are valid hex
  for (int i = 0; i < pubkey.length; i++) {
    final char = pubkey[i];
    if (!((char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) || // 0-9
        (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 102))) {
      // a-f
      return false;
    }
  }
  return true;
}

/// Validate npub format (bech32 encoded Nostr public key)
bool _isValidNpub(String npub) {
  if (!npub.startsWith('npub1')) return false;
  if (npub.length < 60 || npub.length > 70) return false;

  // Basic bech32 validation
  try {
    // Check for valid bech32 characters
    for (int i = 0; i < npub.length; i++) {
      final char = npub[i];
      if (i < 5) {
        // First 5 characters should be 'npub1'
        if (char != 'npub1'[i]) return false;
      } else {
        // Rest should be valid bech32 characters
        if (!_isValidBech32Char(char)) return false;
      }
    }
    return true;
  } catch (e) {
    return false;
  }
}

/// Check if character is valid in bech32 encoding
bool _isValidBech32Char(String char) {
  if (char.length != 1) return false;
  final code = char.codeUnitAt(0);
  return (code >= 97 && code <= 122) || // a-z
      (code >= 48 && code <= 57) || // 0-9
      char == 'q' ||
      char == 'p' ||
      char == 'z' ||
      char == 'r' ||
      char == 'y' ||
      char == '9' ||
      char == 'x' ||
      char == '8' ||
      char == 'g' ||
      char == 'f' ||
      char == '2' ||
      char == 't' ||
      char == 'v' ||
      char == 'd' ||
      char == 'w' ||
      char == '0' ||
      char == 's' ||
      char == '3' ||
      char == 'j' ||
      char == 'n' ||
      char == '5' ||
      char == '4' ||
      char == 'k' ||
      char == 'h' ||
      char == 'c' ||
      char == 'e' ||
      char == '6' ||
      char == 'm' ||
      char == 'u' ||
      char == 'a' ||
      char == '7' ||
      char == 'l';
}
