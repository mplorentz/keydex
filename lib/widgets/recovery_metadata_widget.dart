import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';

/// Widget displaying recovery request metadata
class RecoveryMetadataWidget extends ConsumerWidget {
  final String recoveryRequestId;

  const RecoveryMetadataWidget({
    super.key,
    required this.recoveryRequestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(recoveryRequestByIdProvider(recoveryRequestId));

    return requestAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
      data: (request) {
        if (request == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Recovery request not found'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(request.status),
                      color: _getStatusColor(request.status, context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      request.status.displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(request.status, context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Request ID', request.id),
                _buildInfoRow('Lockbox ID', request.lockboxId),
                _buildInfoRow('Requested', _formatDateTime(request.requestedAt)),
                if (request.expiresAt != null)
                  _buildInfoRow(
                    'Expires',
                    _formatDateTime(request.expiresAt!),
                    isWarning: request.isExpired,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(RecoveryRequestStatus status) {
    switch (status) {
      case RecoveryRequestStatus.pending:
        return Icons.schedule;
      case RecoveryRequestStatus.sent:
        return Icons.send;
      case RecoveryRequestStatus.inProgress:
        return Icons.sync;
      case RecoveryRequestStatus.completed:
        return Icons.check_circle;
      case RecoveryRequestStatus.failed:
        return Icons.error;
      case RecoveryRequestStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(RecoveryRequestStatus status, BuildContext context) {
    switch (status) {
      case RecoveryRequestStatus.pending:
        return Colors.orange;
      case RecoveryRequestStatus.sent:
        return Colors.blue;
      case RecoveryRequestStatus.inProgress:
        return Theme.of(context).primaryColor;
      case RecoveryRequestStatus.completed:
        return Colors.green;
      case RecoveryRequestStatus.failed:
        return Colors.red;
      case RecoveryRequestStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
