/// Enum representing the status of a Nostr event
enum EventStatus {
  /// Gift wrap event created but not yet published
  created,

  /// Event published to Nostr relays
  published,

  /// Recipient has acknowledged receipt
  confirmed,

  /// Publishing failed or event was rejected
  failed,
}

/// Extension methods for EventStatus
extension EventStatusExtension on EventStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case EventStatus.created:
        return 'Event has been created and is ready to publish';
      case EventStatus.published:
        return 'Event has been published to Nostr relays';
      case EventStatus.confirmed:
        return 'Recipient has acknowledged receipt of the event';
      case EventStatus.failed:
        return 'Event publishing failed or was rejected';
    }
  }

  /// Get a short label for the status
  String get label {
    switch (this) {
      case EventStatus.created:
        return 'Created';
      case EventStatus.published:
        return 'Published';
      case EventStatus.confirmed:
        return 'Confirmed';
      case EventStatus.failed:
        return 'Failed';
    }
  }

  /// Check if the event has been successfully published
  bool get isPublished {
    return this == EventStatus.published || this == EventStatus.confirmed;
  }

  /// Check if the event has been confirmed by the recipient
  bool get isConfirmed {
    return this == EventStatus.confirmed;
  }

  /// Check if the event failed
  bool get hasFailed {
    return this == EventStatus.failed;
  }

  /// Check if the event is in progress
  bool get isInProgress {
    return this == EventStatus.created || this == EventStatus.published;
  }

  /// Get the appropriate color for UI display
  String get colorName {
    switch (this) {
      case EventStatus.created:
        return 'blue';
      case EventStatus.published:
        return 'orange';
      case EventStatus.confirmed:
        return 'green';
      case EventStatus.failed:
        return 'red';
    }
  }

  /// Get the appropriate icon name for UI display
  String get iconName {
    switch (this) {
      case EventStatus.created:
        return 'add_circle';
      case EventStatus.published:
        return 'cloud_upload';
      case EventStatus.confirmed:
        return 'check_circle';
      case EventStatus.failed:
        return 'error';
    }
  }
}
