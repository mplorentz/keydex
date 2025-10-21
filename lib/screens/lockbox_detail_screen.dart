import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../services/lockbox_service.dart';
import '../widgets/recovery_section.dart';
import '../widgets/row_button.dart';
import '../widgets/lockbox_metadata_section.dart';
import '../widgets/key_holder_list.dart';
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

        return _buildLockboxDetail(context, ref, lockbox);
      },
    );
  }

  Widget _buildLockboxDetail(BuildContext context, WidgetRef ref, Lockbox lockbox) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lockbox.name),
        centerTitle: false,
        actions: [
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lockbox Metadata Section
          LockboxMetadataSection(lockboxId: lockbox.id),
          // Key Holder List (extends to edges)
          KeyHolderList(lockboxId: lockbox.id),
          const Spacer(),
          // Edit Lockbox Button (only show if user owns the lockbox)
          if (_isOwned(context, ref, lockbox)) ...[
            RowButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditLockboxScreen(lockboxId: lockbox.id),
                  ),
                );
              },
              icon: Icons.edit,
              text: 'Change Contents',
              backgroundColor: const Color(0xFF798472),
            ),
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
                backgroundColor: const Color(0xFF6f7a69)),
          ],
          // Recovery Section
          RecoverySection(lockboxId: lockbox.id),
        ],
      ),
    );
  }

  bool _isOwned(BuildContext context, WidgetRef ref, Lockbox lockbox) {
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);
    return currentPubkeyAsync.when(
      data: (currentPubkey) => currentPubkey != null && lockbox.isOwned(currentPubkey),
      loading: () => false,
      error: (_, __) => false,
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
