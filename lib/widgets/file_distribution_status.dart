import 'package:flutter/material.dart';

/// Widget to display file distribution status for each key holder
/// 
/// STUB: This is a placeholder implementation for Phase 3.2
/// Full implementation will be added in Phase 3.6 (T036)
class FileDistributionStatus extends StatelessWidget {
  final List<String> keyHolderNames;
  final Map<String, String> distributionStatus;

  const FileDistributionStatus({
    super.key,
    this.keyHolderNames = const [],
    this.distributionStatus = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'File Distribution Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (keyHolderNames.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'STUB: No key holders configured',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keyHolderNames.length,
            itemBuilder: (context, index) {
              final name = keyHolderNames[index];
              final status = distributionStatus[name] ?? 'pending';
              
              return ListTile(
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status, theme),
                ),
                title: Text(name),
                subtitle: Text('STUB: Status - $status'),
                trailing: status == 'pending' 
                    ? TextButton(
                        onPressed: () {},
                        child: const Text('Retry'),
                      )
                    : null,
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'STUB: Full distribution status UI coming in Phase 3.6\n\n'
            'Features:\n'
            '• Real-time status updates\n'
            '• Manual retry/resend\n'
            '• Distribution window countdown\n'
            '• Download confirmation tracking',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'downloaded':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'downloaded':
        return Colors.green;
      case 'pending':
        return theme.colorScheme.onSurfaceVariant;
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

