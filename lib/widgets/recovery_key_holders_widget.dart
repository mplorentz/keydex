import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';

/// Widget displaying key holder responses
class RecoveryKeyHoldersWidget extends ConsumerWidget {
  final String recoveryRequestId;

  const RecoveryKeyHoldersWidget({
    super.key,
    required this.recoveryRequestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(recoveryRequestByIdProvider(recoveryRequestId));

    return requestAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
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
                Text(
                  'Key Holders',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ...request.keyHolderResponses.values.map((response) {
                  return _buildKeyHolderItem(response);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyHolderItem(RecoveryResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getResponseColor(response.status).withValues(alpha: 0.1),
            child: Icon(
              _getResponseIcon(response.status),
              color: _getResponseColor(response.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${response.pubkey.substring(0, 16)}...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getResponseColor(response.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        response.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getResponseColor(response.status),
                        ),
                      ),
                    ),
                    if (response.respondedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          _formatDateTime(response.respondedAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResponseIcon(RecoveryResponseStatus status) {
    switch (status) {
      case RecoveryResponseStatus.pending:
        return Icons.schedule;
      case RecoveryResponseStatus.approved:
        return Icons.check_circle;
      case RecoveryResponseStatus.denied:
        return Icons.cancel;
      case RecoveryResponseStatus.timeout:
        return Icons.timer_off;
    }
  }

  Color _getResponseColor(RecoveryResponseStatus status) {
    switch (status) {
      case RecoveryResponseStatus.pending:
        return Colors.orange;
      case RecoveryResponseStatus.approved:
        return Colors.green;
      case RecoveryResponseStatus.denied:
        return Colors.red;
      case RecoveryResponseStatus.timeout:
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
