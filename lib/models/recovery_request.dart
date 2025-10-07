/// Recovery request status enum
enum RecoveryRequestStatus {
  pending, // Request created but not yet sent
  sent, // Request sent to key holders via Nostr
  inProgress, // Responses being collected
  completed, // Recovery successful, content reassembled
  failed, // Recovery failed (insufficient shares or timeout)
  cancelled, // Request cancelled by user
}

/// Recovery response status enum
enum RecoveryResponseStatus {
  pending, // No response yet
  approved, // Key holder approved and shared key
  denied, // Key holder denied the request
  timeout, // No response within timeout period
}

/// Extension methods for RecoveryRequestStatus
extension RecoveryRequestStatusExtension on RecoveryRequestStatus {
  String get displayName {
    switch (this) {
      case RecoveryRequestStatus.pending:
        return 'Pending';
      case RecoveryRequestStatus.sent:
        return 'Sent';
      case RecoveryRequestStatus.inProgress:
        return 'In Progress';
      case RecoveryRequestStatus.completed:
        return 'Completed';
      case RecoveryRequestStatus.failed:
        return 'Failed';
      case RecoveryRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive {
    return this == RecoveryRequestStatus.pending ||
        this == RecoveryRequestStatus.sent ||
        this == RecoveryRequestStatus.inProgress;
  }

  bool get isTerminal {
    return this == RecoveryRequestStatus.completed ||
        this == RecoveryRequestStatus.failed ||
        this == RecoveryRequestStatus.cancelled;
  }
}

/// Extension methods for RecoveryResponseStatus
extension RecoveryResponseStatusExtension on RecoveryResponseStatus {
  String get displayName {
    switch (this) {
      case RecoveryResponseStatus.pending:
        return 'Pending';
      case RecoveryResponseStatus.approved:
        return 'Approved';
      case RecoveryResponseStatus.denied:
        return 'Denied';
      case RecoveryResponseStatus.timeout:
        return 'Timeout';
    }
  }

  bool get isResolved {
    return this != RecoveryResponseStatus.pending;
  }
}

/// Represents a key holder's response to a recovery request
class RecoveryResponse {
  final String pubkey; // hex format, 64 characters
  final RecoveryResponseStatus status;
  final DateTime? respondedAt;
  final String? shardDataId; // Reference to collected shard data
  final String? nostrEventId;

  const RecoveryResponse({
    required this.pubkey,
    required this.status,
    this.respondedAt,
    this.shardDataId,
    this.nostrEventId,
  });

  /// Validate the recovery response
  bool get isValid {
    // Pubkey must be valid hex format (64 characters)
    if (pubkey.length != 64 || !_isHexString(pubkey)) {
      return false;
    }

    // RespondedAt must be in the past if status is not pending
    if (status != RecoveryResponseStatus.pending && respondedAt != null) {
      if (respondedAt!.isAfter(DateTime.now())) {
        return false;
      }
    }

    // ShardDataId must be present if status is approved
    if (status == RecoveryResponseStatus.approved && shardDataId == null) {
      return false;
    }

    return true;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'pubkey': pubkey,
      'status': status.name,
      'respondedAt': respondedAt?.toIso8601String(),
      'shardDataId': shardDataId,
      'nostrEventId': nostrEventId,
    };
  }

  /// Create from JSON
  factory RecoveryResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryResponse(
      pubkey: json['pubkey'] as String,
      status: RecoveryResponseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecoveryResponseStatus.pending,
      ),
      respondedAt:
          json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
      shardDataId: json['shardDataId'] as String?,
      nostrEventId: json['nostrEventId'] as String?,
    );
  }

  RecoveryResponse copyWith({
    String? pubkey,
    RecoveryResponseStatus? status,
    DateTime? respondedAt,
    String? shardDataId,
    String? nostrEventId,
  }) {
    return RecoveryResponse(
      pubkey: pubkey ?? this.pubkey,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      shardDataId: shardDataId ?? this.shardDataId,
      nostrEventId: nostrEventId ?? this.nostrEventId,
    );
  }

  @override
  String toString() {
    return 'RecoveryResponse(pubkey: ${pubkey.substring(0, 8)}..., status: ${status.displayName})';
  }
}

/// Represents a request to recover a lockbox
class RecoveryRequest {
  final String id;
  final String lockboxId;
  final String initiatorPubkey; // hex format, 64 characters
  final DateTime requestedAt;
  final RecoveryRequestStatus status;
  final String? nostrEventId;
  final DateTime? expiresAt;
  final Map<String, RecoveryResponse> keyHolderResponses; // pubkey -> response

  const RecoveryRequest({
    required this.id,
    required this.lockboxId,
    required this.initiatorPubkey,
    required this.requestedAt,
    required this.status,
    this.nostrEventId,
    this.expiresAt,
    this.keyHolderResponses = const {},
  });

  /// Validate the recovery request
  bool get isValid {
    // ID must be non-empty
    if (id.isEmpty) return false;

    // LockboxId must be non-empty
    if (lockboxId.isEmpty) return false;

    // InitiatorPubkey must be valid hex format (64 characters)
    if (initiatorPubkey.length != 64 || !_isHexString(initiatorPubkey)) {
      return false;
    }

    // RequestedAt must be in the past
    if (requestedAt.isAfter(DateTime.now())) {
      return false;
    }

    // ExpiresAt must be in the future if set
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
      return false;
    }

    return true;
  }

  /// Check if the request has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get the count of responses by status
  int getResponseCount(RecoveryResponseStatus status) {
    return keyHolderResponses.values.where((r) => r.status == status).length;
  }

  /// Get total number of key holders
  int get totalKeyHolders => keyHolderResponses.length;

  /// Get number of responses received
  int get respondedCount => keyHolderResponses.values.where((r) => r.status.isResolved).length;

  /// Get number of approvals
  int get approvedCount => getResponseCount(RecoveryResponseStatus.approved);

  /// Get number of denials
  int get deniedCount => getResponseCount(RecoveryResponseStatus.denied);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lockboxId': lockboxId,
      'initiatorPubkey': initiatorPubkey,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'nostrEventId': nostrEventId,
      'expiresAt': expiresAt?.toIso8601String(),
      'keyHolderResponses': keyHolderResponses.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Create from JSON
  factory RecoveryRequest.fromJson(Map<String, dynamic> json) {
    final responsesJson = json['keyHolderResponses'] as Map<String, dynamic>?;
    final responses = responsesJson?.map(
          (key, value) => MapEntry(
            key,
            RecoveryResponse.fromJson(value as Map<String, dynamic>),
          ),
        ) ??
        {};

    return RecoveryRequest(
      id: json['id'] as String,
      lockboxId: json['lockboxId'] as String,
      initiatorPubkey: json['initiatorPubkey'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      status: RecoveryRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecoveryRequestStatus.pending,
      ),
      nostrEventId: json['nostrEventId'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      keyHolderResponses: responses,
    );
  }

  RecoveryRequest copyWith({
    String? id,
    String? lockboxId,
    String? initiatorPubkey,
    DateTime? requestedAt,
    RecoveryRequestStatus? status,
    String? nostrEventId,
    DateTime? expiresAt,
    Map<String, RecoveryResponse>? keyHolderResponses,
  }) {
    return RecoveryRequest(
      id: id ?? this.id,
      lockboxId: lockboxId ?? this.lockboxId,
      initiatorPubkey: initiatorPubkey ?? this.initiatorPubkey,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      nostrEventId: nostrEventId ?? this.nostrEventId,
      expiresAt: expiresAt ?? this.expiresAt,
      keyHolderResponses: keyHolderResponses ?? this.keyHolderResponses,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecoveryRequest && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecoveryRequest(id: $id, lockboxId: $lockboxId, status: ${status.displayName})';
  }
}

/// Helper to validate hex strings
bool _isHexString(String str) {
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
}
