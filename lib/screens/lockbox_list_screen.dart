import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../widgets/row_button.dart';
import '../widgets/debug_info_sheet.dart';
import 'create_lockbox_with_backup_screen.dart';
import 'lockbox_detail_screen.dart';
import 'relay_management_screen.dart';
import 'recovery_notification_overlay.dart';

/// Main list screen showing all lockboxes
class LockboxListScreen extends ConsumerWidget {
  const LockboxListScreen({super.key});

  void _showDebugInfo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DebugInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the lockbox stream provider
    final lockboxesAsync = ref.watch(lockboxListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lockboxes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RelayManagementScreen(),
                ),
              );
            },
            tooltip: 'Scan for Keys',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugInfo(context, ref),
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Use AsyncValue.when() to handle loading/error/data states
                lockboxesAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  error: (error, stack) {
                    final textTheme = Theme.of(context).textTheme;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $error',
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.refresh(lockboxListProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  },
                  data: (lockboxes) {
                    if (lockboxes.isEmpty) {
                      final theme = Theme.of(context);
                      final textTheme = theme.textTheme;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No lockboxes yet',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first secure lockbox',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: lockboxes.length,
                      itemBuilder: (context, index) {
                        final lockbox = lockboxes[index];
                        return _LockboxCard(lockbox: lockbox);
                      },
                    );
                  },
                ),
                // Recovery notification overlay (inside the Stack)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: RecoveryNotificationOverlay(),
                ),
              ],
            ),
          ),
          // Create lockbox button at bottom
          RowButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateLockboxWithBackupScreen(),
                ),
              );
            },
            icon: Icons.add,
            text: 'Create Lockbox',
          ),
        ],
      ),
    );
  }
}

// Extracted widget for lockbox card
class _LockboxCard extends StatelessWidget {
  final Lockbox lockbox;

  const _LockboxCard({required this.lockbox});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
              // Icon container with darker background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock,
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
                      lockbox.content.length > 40
                          ? '${lockbox.content.substring(0, 40)}...'
                          : lockbox.content,
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
