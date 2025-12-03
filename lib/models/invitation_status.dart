/// Enum representing the status of an invitation link
enum InvitationStatus {
  /// Invitation just generated, not yet sent
  created,

  /// Invitation sent, awaiting response
  pending,

  /// Invitation accepted by invitee
  redeemed,

  /// Invitation denied by invitee
  denied,

  /// Invitation invalidated by vault owner
  invalidated,

  /// Error occurred during redemption
  error,
}

/// Extension methods for InvitationStatus
extension InvitationStatusExtension on InvitationStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case InvitationStatus.created:
        return 'Invitation has been generated but not yet sent';
      case InvitationStatus.pending:
        return 'Invitation sent and awaiting response from invitee';
      case InvitationStatus.redeemed:
        return 'Invitation has been accepted by the invitee';
      case InvitationStatus.denied:
        return 'Invitation was denied by the invitee';
      case InvitationStatus.invalidated:
        return 'Invitation has been invalidated by the vault owner';
      case InvitationStatus.error:
        return 'An error occurred during invitation redemption';
    }
  }

  /// Get a short label for the status
  String get label {
    switch (this) {
      case InvitationStatus.created:
        return 'Created';
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.redeemed:
        return 'Redeemed';
      case InvitationStatus.denied:
        return 'Denied';
      case InvitationStatus.invalidated:
        return 'Invalidated';
      case InvitationStatus.error:
        return 'Error';
    }
  }

  /// Check if the invitation is in a terminal state
  bool get isTerminal {
    return this == InvitationStatus.redeemed ||
        this == InvitationStatus.denied ||
        this == InvitationStatus.invalidated ||
        this == InvitationStatus.error;
  }

  /// Check if the invitation can be redeemed
  bool get canRedeem {
    return this == InvitationStatus.created || this == InvitationStatus.pending;
  }

  /// Check if the invitation is active (awaiting response)
  bool get isActive {
    return this == InvitationStatus.created || this == InvitationStatus.pending;
  }
}
