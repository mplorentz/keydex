import 'package:flutter/material.dart';
import '../models/lockbox.dart';
import '../screens/lockbox_detail_screen.dart';

class LockboxCard extends StatelessWidget {
  final Lockbox lockbox;

  const LockboxCard({super.key, required this.lockbox});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Determine icon based on lockbox state
    IconData stateIcon;

    switch (lockbox.state) {
      case LockboxState.recovery:
        stateIcon = Icons.refresh;
        break;
      case LockboxState.owned:
        stateIcon = Icons.lock_open;
        break;
      case LockboxState.keyHolder:
        stateIcon = Icons.key;
        break;
    }

    // Determine content preview text
    final contentPreview = lockbox.content != null
        ? (lockbox.content!.length > 40
            ? '${lockbox.content!.substring(0, 40)}...'
            : lockbox.content!)
        : '[Encrypted - ${lockbox.shards.length} shard${lockbox.shards.length == 1 ? '' : 's'}]';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LockboxDetailScreen(lockboxId: lockbox.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icon container with state-based icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stateIcon,
                  color: theme.scaffoldBackgroundColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lockbox.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contentPreview,
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Date on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(lockbox.createdAt),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
