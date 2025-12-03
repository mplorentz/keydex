import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../widgets/key_holder_list.dart';
import '../widgets/lockbox_detail_button_stack.dart';
import '../widgets/lockbox_status_banner.dart';
import 'lockbox_settings_screen.dart';

/// Detail/view screen for displaying a lockbox
class LockboxDetailScreen extends ConsumerWidget {
  final String lockboxId;

  const LockboxDetailScreen({super.key, required this.lockboxId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockboxAsync = ref.watch(lockboxProvider(lockboxId));

    return lockboxAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...'), centerTitle: false),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error'), centerTitle: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(lockboxProvider(lockboxId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (lockbox) {
        if (lockbox == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Vault Not Found'),
              centerTitle: false,
            ),
            body: const Center(child: Text('This vault no longer exists.')),
          );
        }

        return _buildLockboxDetail(context, ref, lockbox);
      },
    );
  }

  Widget _buildLockboxDetail(
    BuildContext context,
    WidgetRef ref,
    Lockbox lockbox,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lockbox.name),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LockboxSettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, ref, lockbox);
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner showing recovery readiness
          LockboxStatusBanner(lockbox: lockbox),
          // Scrollable content
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Key Holder List (extends to edges)
                    KeyHolderList(lockboxId: lockbox.id),
                  ],
                ),
              ),
            ),
          ),
          // Fixed buttons at bottom
          LockboxDetailButtonStack(lockboxId: lockbox.id),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Lockbox lockbox) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vault'),
        content: Text(
          'Are you sure you want to delete "${lockbox.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Use Riverpod to get the repository - much better for testing!
              final repository = ref.read(lockboxRepositoryProvider);
              await repository.deleteLockbox(lockbox.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
