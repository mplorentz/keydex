/// Enum representing the status of a key holder
enum KeyHolderStatus {
  /// Key holder added but gift wrap event not yet published
  pending,

  /// Gift wrap event published and key holder is responsive
  active,

  /// Key holder has acknowledged receipt of their key share
  acknowledged,

  /// Key holder is unresponsive or offline
  inactive,

  /// Key holder removed from backup configuration
  revoked,
}

/// Extension methods for KeyHolderStatus
extension KeyHolderStatusExtension on KeyHolderStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case KeyHolderStatus.pending:
        return 'Key share is being prepared for distribution';
      case KeyHolderStatus.active:
        return 'Key share has been sent and key holder is responsive';
      case KeyHolderStatus.acknowledged:
        return 'Key holder has confirmed receipt of their key share';
      case KeyHolderStatus.inactive:
        return 'Key holder is unresponsive or offline';
      case KeyHolderStatus.revoked:
        return 'Key holder has been removed from backup';
    }
  }

  /// Get a short label for the status
  String get label {
    switch (this) {
      case KeyHolderStatus.pending:
        return 'Pending';
      case KeyHolderStatus.active:
        return 'Active';
      case KeyHolderStatus.acknowledged:
        return 'Acknowledged';
      case KeyHolderStatus.inactive:
        return 'Inactive';
      case KeyHolderStatus.revoked:
        return 'Revoked';
    }
  }

  /// Check if the key holder is active (can participate in recovery)
  bool get isActive {
    return this == KeyHolderStatus.active || this == KeyHolderStatus.acknowledged;
  }

  /// Check if the key holder has confirmed receipt
  bool get hasConfirmed {
    return this == KeyHolderStatus.acknowledged;
  }

  /// Check if the key holder is available for recovery
  bool get isAvailable {
    return this == KeyHolderStatus.active || this == KeyHolderStatus.acknowledged;
  }

  /// Check if the key holder is problematic
  bool get isProblematic {
    return this == KeyHolderStatus.inactive || this == KeyHolderStatus.revoked;
  }

  /// Get the appropriate color for UI display
  String get colorName {
    switch (this) {
      case KeyHolderStatus.pending:
        return 'orange';
      case KeyHolderStatus.active:
        return 'blue';
      case KeyHolderStatus.acknowledged:
        return 'green';
      case KeyHolderStatus.inactive:
        return 'grey';
      case KeyHolderStatus.revoked:
        return 'red';
    }
  }

  /// Get the appropriate icon name for UI display
  String get iconName {
    switch (this) {
      case KeyHolderStatus.pending:
        return 'schedule';
      case KeyHolderStatus.active:
        return 'check_circle';
      case KeyHolderStatus.acknowledged:
        return 'verified';
      case KeyHolderStatus.inactive:
        return 'pause_circle';
      case KeyHolderStatus.revoked:
        return 'cancel';
    }
  }
}
