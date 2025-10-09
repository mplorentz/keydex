import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../services/lockbox_share_service.dart';
import '../services/recovery_service.dart';
import '../services/relay_scan_service.dart';
import '../services/backup_service.dart';
import '../services/logger.dart';
import '../widgets/row_button.dart';
import 'create_lockbox_with_backup_screen.dart';
import 'lockbox_detail_screen.dart';
import 'relay_management_screen.dart';
import 'recovery_notification_overlay.dart';

/// Main list screen showing all lockboxes
class LockboxListScreen extends ConsumerWidget {
  const LockboxListScreen({super.key});

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete:\n'
          '• All lockboxes\n'
          '• All key holder shards\n'
          '• All recovery requests\n'
          '• All recovery shards\n'
          '• All relay configurations\n'
          '• Your Nostr keys\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clearing all data...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Clear all services using providers
      await ref.read(lockboxRepositoryProvider).clearAll();
      await LockboxShareService.clearAll();
      await RecoveryService.clearAll(); // Now includes notifications
      await RelayScanService.clearAll();
      await BackupService.clearAll();
      await ref.read(keyRepositoryProvider).clearKeys();

      Log.info('All app data cleared successfully');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared! App will restart...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh providers to pick up the cleared state
      ref.invalidate(lockboxListProvider);
      ref.invalidate(currentPublicKeyProvider);
      ref.invalidate(currentPublicKeyBech32Provider);
    } catch (e) {
      Log.error('Error clearing all data', e);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _clearAllData(context, ref),
            tooltip: 'Clear All Data (Debug)',
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
          // Debug section showing current user's public key
          const _DebugSection(),
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
            text: 'Create New Lockbox',
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

// Extracted widget for debug section
class _DebugSection extends ConsumerWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both key providers
    final publicKeyAsync = ref.watch(currentPublicKeyProvider);
    final publicKeyBech32Async = ref.watch(currentPublicKeyBech32Provider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.surfaceContainerHighest,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'DEBUG INFO',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bech32 key
          publicKeyBech32Async.when(
            loading: () => Text(
              'Loading...',
              style: textTheme.bodySmall,
            ),
            error: (err, _) => Text(
              'Error: $err',
              style: textTheme.bodySmall,
            ),
            data: (npub) => _KeyDisplay(
              label: 'Npub (bech32):',
              value: npub ?? 'Not available',
              tooltipLabel: 'Npub',
            ),
          ),
          const SizedBox(height: 8),
          // Hex key
          publicKeyAsync.when(
            loading: () => Text(
              'Loading...',
              style: textTheme.bodySmall,
            ),
            error: (err, _) => Text(
              'Error: $err',
              style: textTheme.bodySmall,
            ),
            data: (pubkey) => _KeyDisplay(
              label: 'Public Key (hex):',
              value: pubkey ?? 'Not available',
              tooltipLabel: 'Hex key',
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted widget for key display with copy
class _KeyDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String tooltipLabel;

  const _KeyDisplay({
    required this.label,
    required this.value,
    required this.tooltipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy,
            size: 16,
            color: Theme.of(context).colorScheme.secondary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: value != 'Not available' && value != 'Loading...'
              ? () => _copyToClipboard(context, value, tooltipLabel)
              : null,
          tooltip: 'Copy $tooltipLabel',
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
