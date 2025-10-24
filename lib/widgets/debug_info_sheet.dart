import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/key_provider.dart';
import '../providers/lockbox_provider.dart';
import '../services/lockbox_share_service.dart';
import '../services/recovery_service.dart';
import '../services/relay_scan_service.dart';
import '../services/logger.dart';

/// Debug information sheet widget
class DebugInfoSheet extends ConsumerWidget {
  const DebugInfoSheet({super.key});

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

    if (confirmed != true || !context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clearing all data...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Clear all services using providers
      await ref.read(lockboxRepositoryProvider).clearAll();
      await ref.read(lockboxShareServiceProvider).clearAll();
      await ref.read(recoveryServiceProvider).clearAll();
      await ref.read(relayScanServiceProvider).clearAll();
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
    // Watch both key providers
    final publicKeyAsync = ref.watch(currentPublicKeyProvider);
    final publicKeyBech32Async = ref.watch(currentPublicKeyBech32Provider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                size: 24,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Text(
                'Debug Information',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 12),
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
          ),
          const SizedBox(height: 24),
          // Clear all data button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _clearAllData(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Data'),
            ),
          ),
        ],
      ),
    );
  }
}

// Key display widget with copy functionality
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
