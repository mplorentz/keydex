/// Enum representing the status of a key holder
enum KeyHolderStatus {
  /// Invitation sent, awaiting acceptance
  invited,

  /// Key share is being prepared for distribution OR invitation accepted, awaiting shard distribution
  awaitingKey,

  /// Key holder has an old key but needs an updated one (after version increment)
  awaitingNewKey,

  /// Shard received and confirmed (key holder is holding their key)
  holdingKey,

  /// Key holder is unresponsive or offline
  inactive,

  /// Error occurred during invitation or shard processing
  error,

  /// Key holder removed from backup configuration
  revoked,
}

/// Extension methods for KeyHolderStatus
extension KeyHolderStatusExtension on KeyHolderStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case KeyHolderStatus.invited:
        return 'Invitation sent, awaiting acceptance';
      case KeyHolderStatus.awaitingKey:
        return 'Awaiting key share distribution';
      case KeyHolderStatus.awaitingNewKey:
        return 'Has old key, awaiting updated key share';
      case KeyHolderStatus.holdingKey:
        return 'Key holder has confirmed receipt of their key share';
      case KeyHolderStatus.inactive:
        return 'Key holder is unresponsive or offline';
      case KeyHolderStatus.error:
        return 'Error occurred during invitation or shard processing';
      case KeyHolderStatus.revoked:
        return 'Key holder has been removed from backup';
    }
  }

  /// Get a short label for the status
  String get label {
    switch (this) {
      case KeyHolderStatus.invited:
        return 'Pending';
      case KeyHolderStatus.awaitingKey:
        return 'Awaiting Key';
      case KeyHolderStatus.awaitingNewKey:
        return 'Awaiting New Key';
      case KeyHolderStatus.holdingKey:
        return 'Holding Key';
      case KeyHolderStatus.inactive:
        return 'Inactive';
      case KeyHolderStatus.error:
        return 'Error';
      case KeyHolderStatus.revoked:
        return 'Revoked';
    }
  }

  /// Check if the key holder is active (can participate in recovery)
  bool get isActive {
    return this == KeyHolderStatus.awaitingKey ||
        this == KeyHolderStatus.awaitingNewKey ||
        this == KeyHolderStatus.holdingKey;
  }

  /// Check if the key holder has confirmed receipt
  bool get hasConfirmed {
    return this == KeyHolderStatus.holdingKey;
  }

  /// Check if the key holder is available for recovery
  bool get isAvailable {
    return this == KeyHolderStatus.awaitingKey ||
        this == KeyHolderStatus.awaitingNewKey ||
        this == KeyHolderStatus.holdingKey;
  }

  /// Check if the key holder is problematic
  bool get isProblematic {
    return this == KeyHolderStatus.inactive ||
        this == KeyHolderStatus.revoked ||
        this == KeyHolderStatus.error;
  }

  /// Check if the status is terminal (no further transitions expected)
  bool get isTerminal {
    return this == KeyHolderStatus.holdingKey ||
        this == KeyHolderStatus.revoked ||
        this == KeyHolderStatus.error;
  }

  /// Get the appropriate color for UI display
  String get colorName {
    switch (this) {
      case KeyHolderStatus.invited:
        return 'orange';
      case KeyHolderStatus.awaitingKey:
        return 'blue';
      case KeyHolderStatus.awaitingNewKey:
        return 'amber';
      case KeyHolderStatus.holdingKey:
        return 'green';
      case KeyHolderStatus.inactive:
        return 'grey';
      case KeyHolderStatus.error:
        return 'red';
      case KeyHolderStatus.revoked:
        return 'red';
    }
  }

  /// Get the appropriate icon name for UI display
  String get iconName {
    switch (this) {
      case KeyHolderStatus.invited:
        return 'mail_outline';
      case KeyHolderStatus.awaitingKey:
        return 'hourglass_empty';
      case KeyHolderStatus.awaitingNewKey:
        return 'update';
      case KeyHolderStatus.holdingKey:
        return 'check_circle';
      case KeyHolderStatus.inactive:
        return 'pause_circle';
      case KeyHolderStatus.error:
        return 'error_outline';
      case KeyHolderStatus.revoked:
        return 'cancel';
    }
  }
}
