import 'key_holder_status.dart';

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
    status: KeyHolderStatus.awaitingKey,
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
    return status == KeyHolderStatus.awaitingKey || status == KeyHolderStatus.holdingKey;
  }

  /// Check if this key holder has acknowledged receipt
  bool get hasAcknowledged {
    return status == KeyHolderStatus.holdingKey && acknowledgedAt != null;
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
      orElse: () => KeyHolderStatus.awaitingKey,
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
