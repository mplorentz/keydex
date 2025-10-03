/// Enum representing the status of a backup configuration
enum BackupStatus {
  /// Backup configuration created but keys not yet distributed or need redistribution
  pending,

  /// All keys successfully distributed and backup is functional
  active,

  /// Backup is disabled or configuration is invalid
  inactive,

  /// Key distribution failed and backup is not functional
  failed,
}

/// Extension methods for BackupStatus
extension BackupStatusExtension on BackupStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case BackupStatus.pending:
        return 'Backup is being set up or needs redistribution';
      case BackupStatus.active:
        return 'Backup is active and functional';
      case BackupStatus.inactive:
        return 'Backup is disabled or invalid';
      case BackupStatus.failed:
        return 'Backup setup failed';
    }
  }

  /// Get a short label for the status
  String get label {
    switch (this) {
      case BackupStatus.pending:
        return 'Pending';
      case BackupStatus.active:
        return 'Active';
      case BackupStatus.inactive:
        return 'Inactive';
      case BackupStatus.failed:
        return 'Failed';
    }
  }

  /// Check if the backup is in a working state
  bool get isWorking {
    return this == BackupStatus.active;
  }

  /// Check if the backup needs attention
  bool get needsAttention {
    return this == BackupStatus.pending || this == BackupStatus.failed;
  }

  /// Check if the backup is completely disabled
  bool get isDisabled {
    return this == BackupStatus.inactive;
  }

  /// Get the appropriate color for UI display
  String get colorName {
    switch (this) {
      case BackupStatus.pending:
        return 'orange';
      case BackupStatus.active:
        return 'green';
      case BackupStatus.inactive:
        return 'grey';
      case BackupStatus.failed:
        return 'red';
    }
  }
}
