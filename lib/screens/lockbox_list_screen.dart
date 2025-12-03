import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lockbox_provider.dart';
import '../widgets/row_button.dart';
import 'recovery_notification_overlay.dart';
import 'vault_explainer_screen.dart';
import '../widgets/lockbox_card.dart';

/// Main list screen showing all lockboxes
class LockboxListScreen extends ConsumerWidget {
  const LockboxListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the lockbox stream provider
    final lockboxesAsync = ref.watch(lockboxListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Horcrux'), centerTitle: false),
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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
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
                            Text('No vaults yet', style: textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                'Tap + to create a vault or if you received an invitation link open it now to join their vault.',
                                style: textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: lockboxes.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lockbox = lockboxes[index];
                        return LockboxCard(
                          key: ValueKey(lockbox.id),
                          lockbox: lockbox,
                        );
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
                  builder: (context) => const VaultExplainerScreen(),
                ),
              );
            },
            icon: Icons.add,
            text: 'Create Vault',
            addBottomSafeArea: true,
          ),
        ],
      ),
    );
  }
}
