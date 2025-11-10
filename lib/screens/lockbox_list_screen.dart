import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lockbox_provider.dart';
import '../widgets/row_button.dart';
import '../widgets/debug_info_sheet.dart';
import 'lockbox_create_screen.dart';
import 'relay_management_screen.dart';
import 'recovery_notification_overlay.dart';
import '../widgets/lockbox_card.dart';

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
        title: const Text('Keydex'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi),
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
                              'No vaults yet',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first secure vault',
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
                        return LockboxCard(key: ValueKey(lockbox.id), lockbox: lockbox);
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
                  builder: (context) => const LockboxCreateScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            icon: Icons.add,
            text: 'Create Vault',
          ),
        ],
      ),
    );
  }
}
