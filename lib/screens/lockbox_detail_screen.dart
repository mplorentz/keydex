import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../services/lockbox_service.dart';
import '../widgets/recovery_section.dart';
import '../widgets/row_button.dart';
import 'backup_config_screen.dart';
import 'edit_lockbox_screen.dart';

/// Detail/view screen for displaying a lockbox
class LockboxDetailScreen extends ConsumerWidget {
  final String lockboxId;

  const LockboxDetailScreen({super.key, required this.lockboxId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockboxAsync = ref.watch(lockboxProvider(lockboxId));

    return lockboxAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          centerTitle: false,
        ),
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
              title: const Text('Lockbox Not Found'),
              centerTitle: false,
            ),
            body: const Center(child: Text('This lockbox no longer exists.')),
          );
        }

        return _buildLockboxDetail(context, lockbox);
      },
    );
  }

  Widget _buildLockboxDetail(BuildContext context, Lockbox lockbox) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lockbox.name),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditLockboxScreen(lockboxId: lockbox.id),
                ),
              );
            },
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
                _showDeleteDialog(context, lockbox);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Content Encrypted',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have ${lockbox.shards.length} shard${lockbox.shards.length == 1 ? '' : 's'} for this lockbox',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Edit to view or modify the content',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Backup Configuration Section
            RowButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackupConfigScreen(
                      lockboxId: lockbox.id,
                    ),
                  ),
                );
              },
              icon: Icons.settings,
              text: 'Backup Settings',
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            // Recovery Section
            RecoverySection(lockboxId: lockbox.id),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Lockbox lockbox) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lockbox'),
        content: Text(
            'Are you sure you want to delete "${lockbox.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await LockboxService.deleteLockbox(lockbox.id);
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
