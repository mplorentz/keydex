import 'package:flutter/material.dart';

/// Stub widget for displaying file distribution status per key holder
/// TODO: Implement distribution status display with pending/downloaded/missed_window states
class FileDistributionStatus extends StatelessWidget {
  final String lockboxId; // TODO: Use proper model when created

  const FileDistributionStatus({
    super.key,
    required this.lockboxId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribution Status',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Status: Pending',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

