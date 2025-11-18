import '../utils/validators.dart';
import 'key_holder_status.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Represents a trusted contact who holds a backup key
///
/// This model contains information about a key holder including
/// their Nostr public key, status, and acknowledgment details.
typedef KeyHolder = ({
  String id, // Unique identifier for this key holder
  String? pubkey, // Hex format - nullable for invited key holders
  String? name,
  String? inviteCode, // Invitation code for invited key holders (before they accept)
  KeyHolderStatus status,
  DateTime? lastSeen,
  String? keyShare,
  String? giftWrapEventId,
  DateTime? acknowledgedAt,
  String? acknowledgmentEventId,
  int? acknowledgedDistributionVersion, // Version tracking for redistribution detection (nullable for backward compatibility)
});

/// Create a new KeyHolder with validation
KeyHolder createKeyHolder({
  required String pubkey, // Takes hex format directly
  String? name,
  String? id, // Optional - will be generated if not provided
}) {
  if (!isValidHexPubkey(pubkey)) {
    throw ArgumentError('Invalid hex pubkey format: $pubkey');
  }

  return (
    id: id ?? _uuid.v4(),
    pubkey: pubkey,
    name: name,
    inviteCode: null,
    status: KeyHolderStatus.awaitingKey,
    lastSeen: null,
    keyShare: null,
    giftWrapEventId: null,
    acknowledgedAt: null,
    acknowledgmentEventId: null,
    acknowledgedDistributionVersion: null,
  );
}

/// Create a new KeyHolder for an invited person (no pubkey yet)
KeyHolder createInvitedKeyHolder({
  required String name,
  required String inviteCode,
  String? id, // Optional - will be generated if not provided
}) {
  return (
    id: id ?? _uuid.v4(),
    pubkey: null,
    name: name,
    inviteCode: inviteCode,
    status: KeyHolderStatus.invited,
    lastSeen: null,
    keyShare: null,
    giftWrapEventId: null,
    acknowledgedAt: null,
    acknowledgmentEventId: null,
    acknowledgedDistributionVersion: null,
  );
}

/// Create a copy of this KeyHolder with updated fields
KeyHolder copyKeyHolder(
  KeyHolder holder, {
  String? id,
  String? pubkey, // Hex format
  String? name,
  String? inviteCode,
  KeyHolderStatus? status,
  DateTime? lastSeen,
  String? keyShare,
  String? giftWrapEventId,
  DateTime? acknowledgedAt,
  String? acknowledgmentEventId,
  int? acknowledgedDistributionVersion,
}) {
  return (
    id: id ?? holder.id,
    pubkey: pubkey ?? holder.pubkey,
    name: name ?? holder.name,
    inviteCode: inviteCode ?? holder.inviteCode,
    status: status ?? holder.status,
    lastSeen: lastSeen ?? holder.lastSeen,
    keyShare: keyShare ?? holder.keyShare,
    giftWrapEventId: giftWrapEventId ?? holder.giftWrapEventId,
    acknowledgedAt: acknowledgedAt ?? holder.acknowledgedAt,
    acknowledgmentEventId: acknowledgmentEventId ?? holder.acknowledgmentEventId,
    acknowledgedDistributionVersion:
        acknowledgedDistributionVersion ?? holder.acknowledgedDistributionVersion,
  );
}

/// Extension methods for KeyHolder
extension KeyHolderExtension on KeyHolder {
  /// Check if this key holder is active
  bool get isActive {
    return status == KeyHolderStatus.awaitingKey ||
        status == KeyHolderStatus.awaitingNewKey ||
        status == KeyHolderStatus.holdingKey;
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

  /// Check if this key holder is invited (no pubkey yet)
  bool get isInvited {
    return status == KeyHolderStatus.invited && pubkey == null;
  }

  /// Get the bech32-encoded npub for display
  String? get npub {
    if (pubkey == null) return null;
    // pubkey is already in hex format without 0x prefix (Nostr convention)
    return Helpers.encodeBech32(pubkey!, 'npub');
  }

  /// Get display name (name if available, otherwise truncated npub)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    // For invited key holders without a real pubkey, show "Invited"
    if (isInvited) {
      return 'Invited';
    }
    final displayNpub = npub;
    if (displayNpub == null) {
      return 'Unknown';
    }
    return '${displayNpub.substring(0, 8)}...${displayNpub.substring(displayNpub.length - 8)}';
  }

  /// Get display subtitle (npub for real key holders, status for invited)
  String get displaySubtitle {
    if (isInvited) {
      return 'Invited';
    }
    return npub ?? 'No pubkey';
  }
}

/// Convert to JSON for storage
Map<String, dynamic> keyHolderToJson(KeyHolder holder) {
  return {
    'id': holder.id,
    'pubkey': holder.pubkey, // Store hex format, nullable
    'name': holder.name,
    'inviteCode': holder.inviteCode,
    'status': holder.status.name,
    'lastSeen': holder.lastSeen?.toIso8601String(),
    'keyShare': holder.keyShare,
    'giftWrapEventId': holder.giftWrapEventId,
    'acknowledgedAt': holder.acknowledgedAt?.toIso8601String(),
    'acknowledgmentEventId': holder.acknowledgmentEventId,
    'acknowledgedDistributionVersion': holder.acknowledgedDistributionVersion,
  };
}

/// Create from JSON
KeyHolder keyHolderFromJson(Map<String, dynamic> json) {
  return (
    id: json['id'] as String? ?? _uuid.v4(), // Generate ID if missing for backward compatibility
    pubkey: json['pubkey'] as String?, // Hex format without 0x prefix, nullable
    name: json['name'] as String?,
    inviteCode: json['inviteCode'] as String?, // Nullable for backward compatibility
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
    acknowledgedDistributionVersion: json['acknowledgedDistributionVersion'] as int?,
  );
}

/// String representation of KeyHolder
String keyHolderToString(KeyHolder holder) {
  final pubkeyPreview = holder.pubkey != null ? '${holder.pubkey!.substring(0, 8)}...' : 'null';
  return 'KeyHolder(id: ${holder.id}, pubkey: $pubkeyPreview, name: ${holder.name}, status: ${holder.status})';
}
