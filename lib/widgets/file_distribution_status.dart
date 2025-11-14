import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_distribution_provider.dart';
import '../models/file_distribution_status.dart';

/// Widget for displaying file distribution status per key holder
class FileDistributionStatusWidget extends ConsumerWidget {
  final String lockboxId;

  const FileDistributionStatusWidget({
    super.key,
    required this.lockboxId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fileDistributionService = ref.read(fileDistributionServiceProvider);

    return FutureBuilder<List<FileDistributionStatus>>(
      future: fileDistributionService.getDistributionStatus(lockboxId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide if no status or error
        }

        final statuses = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Distribution Status',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...statuses.map((status) => _buildStatusRow(context, status)),
                  const SizedBox(height: 8),
                  if (statuses.any((s) => s.state == DistributionState.missedWindow))
                    OutlinedButton.icon(
                      onPressed: () => _retryDistribution(context, ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Distribution'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(BuildContext context, FileDistributionStatus status) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String label;

    switch (status.state) {
      case DistributionState.downloaded:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Downloaded';
        break;
      case DistributionState.missedWindow:
        icon = Icons.error_outline;
        color = Colors.orange;
        label = 'Missed Window';
        break;
      case DistributionState.pending:
        icon = Icons.hourglass_empty;
        color = Colors.grey;
        label = 'Pending';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${status.keyHolderPubkey.substring(0, 8)}...: $label',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (status.downloadedAt != null)
            Text(
              '${_formatTime(status.downloadedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  Future<void> _retryDistribution(BuildContext context, WidgetRef ref) async {
    final fileDistributionService = ref.read(fileDistributionServiceProvider);
    try {
      await fileDistributionService.reuploadForKeyHolders(lockboxId: lockboxId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Distribution retry initiated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error retrying distribution: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
