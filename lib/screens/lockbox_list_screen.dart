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
        title: const Text('My Lockboxes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(lockboxListProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (lockboxes) {
                    if (lockboxes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No lockboxes yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first secure lockbox',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateLockboxWithBackupScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.lock, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          lockbox.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lockbox.content.length > 50
                  ? '${lockbox.content.substring(0, 50)}...'
                  : lockbox.content,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Created ${_formatDate(lockbox.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LockboxDetailScreen(lockboxId: lockbox.id),
            ),
          );
        },
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'DEBUG INFO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bech32 key
          publicKeyBech32Async.when(
            loading: () => const Text('Loading...', style: TextStyle(fontSize: 10)),
            error: (err, _) => Text('Error: $err', style: const TextStyle(fontSize: 10)),
            data: (npub) => _KeyDisplay(
              label: 'Npub (bech32):',
              value: npub ?? 'Not available',
              tooltipLabel: 'Npub',
            ),
          ),
          const SizedBox(height: 8),
          // Hex key
          publicKeyAsync.when(
            loading: () => const Text('Loading...', style: TextStyle(fontSize: 10)),
            error: (err, _) => Text('Error: $err', style: const TextStyle(fontSize: 10)),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
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
