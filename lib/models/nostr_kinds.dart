/// Nostr event kinds used in Keydex
///
/// This enum defines all Nostr event kinds used throughout the application.
/// Standard NIP kinds and custom kinds for Keydex-specific functionality.
enum NostrKind {
  /// NIP-59: Seal event
  /// Used as the inner layer of gift wraps for encryption
  seal(13),

  /// NIP-59: Gift wrap event
  /// Used for private, encrypted messages with sender anonymity
  giftWrap(1059),

  /// Keydex custom: Shard data distribution
  /// Used to distribute Shamir secret shares to key holders
  shardData(1337),

  /// Keydex custom: Recovery request
  /// Used when a user initiates lockbox recovery
  recoveryRequest(1338),

  /// Keydex custom: Recovery response
  /// Used when a key holder responds to a recovery request
  recoveryResponse(1339);

  /// The numeric kind value
  final int value;

  const NostrKind(this.value);

  /// Get NostrKind from an integer value
  static NostrKind? fromValue(int value) {
    for (final kind in NostrKind.values) {
      if (kind.value == value) {
        return kind;
      }
    }
    return null;
  }

  /// Check if this kind is a Keydex custom kind
  bool get isCustom {
    return value >= 1337 && value <= 1339;
  }

  /// Check if this kind is a standard NIP kind
  bool get isStandard {
    return !isCustom;
  }

  @override
  String toString() {
    return 'NostrKind.$name($value)';
  }
}

/// Extension to easily convert NostrKind to int for NDK usage
extension NostrKindExtension on NostrKind {
  /// Convert to int for use in NDK filters and events
  int toInt() => value;
}
