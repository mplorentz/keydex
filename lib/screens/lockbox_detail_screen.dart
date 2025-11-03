import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../models/invitation_status.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../providers/invitation_provider.dart';
import '../widgets/recovery_section.dart';
import '../widgets/row_button.dart';
import '../widgets/lockbox_metadata_section.dart';
import '../widgets/key_holder_list.dart';
import '../services/backup_service.dart';
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
                _showDeleteDialog(context, ref, lockbox);
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner for awaitingKey state
          if (lockbox.state == LockboxState.awaitingKey)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Waiting for owner to distribute keys. You\'ve accepted the invitation and are ready to receive your key share.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          // Lockbox Metadata Section
          LockboxMetadataSection(lockboxId: lockbox.id),
          // Key Holder List (extends to edges)
          KeyHolderList(lockboxId: lockbox.id),
          // Fill remaining space with same color as KeyHolderList
          Expanded(
            child: Container(
              color: const Color(0xFF666f62),
            ),
          ),
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
            // Generate and Distribute Keys Button - show when all invited key holders have accepted
            _buildGenerateAndDistributeButton(context, ref, lockbox),
          ],
          // Recovery Section
          RecoverySection(lockboxId: lockbox.id),
        ],
      ),
    );
  }

  Widget _buildGenerateAndDistributeButton(BuildContext context, WidgetRef ref, Lockbox lockbox) {
    final pendingInvitationsAsync = ref.watch(pendingInvitationsProvider(lockbox.id));

    return pendingInvitationsAsync.when(
      data: (pendingInvitations) {
        // Only show button if:
        // 1. There are pending invitations that have been redeemed (i.e., all invited key holders accepted)
        // 2. All redeemed invitations have status "redeemed" (accepted)
        final redeemedInvitations = pendingInvitations.where((inv) => inv.status == InvitationStatus.redeemed).toList();
        final hasRedeemedInvitations = redeemedInvitations.isNotEmpty;
        
        // Check if backup config exists and has key holders
        final hasBackupConfig = lockbox.backupConfig != null && lockbox.backupConfig!.keyHolders.isNotEmpty;

        // Show button if there are redeemed invitations and backup config exists
        if (!hasRedeemedInvitations || !hasBackupConfig) {
          return const SizedBox.shrink();
        }

        return RowButton(
          onPressed: () => _generateAndDistributeKeys(context, ref, lockbox),
          icon: Icons.vpn_key,
          text: 'Generate and Distribute Keys',
          backgroundColor: const Color(0xFF5a6b55),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Future<void> _generateAndDistributeKeys(BuildContext context, WidgetRef ref, Lockbox lockbox) async {
    if (lockbox.backupConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup configuration not found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final config = lockbox.backupConfig!;
    if (config.keyHolders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No key holders configured'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (lockbox.content == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot backup: lockbox content is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate and Distribute Keys?'),
        content: Text(
          'This will generate ${config.totalKeys} key shares and distribute them to ${config.keyHolders.length} key holders.\n\n'
          'Threshold: ${config.threshold} (minimum keys needed for recovery)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate & Distribute'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating and distributing keys...'),
          ],
        ),
      ),
    );

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.createAndDistributeBackup(
        lockboxId: lockbox.id,
        threshold: config.threshold,
        totalKeys: config.totalKeys,
        keyHolders: config.keyHolders,
        relays: config.relays,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keys generated and distributed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh lockbox data
        ref.invalidate(lockboxProvider(lockbox.id));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate and distribute keys: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isOwned(BuildContext context, WidgetRef ref, Lockbox lockbox) {
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);
    return currentPubkeyAsync.when(
      data: (currentPubkey) => currentPubkey != null && lockbox.isOwned(currentPubkey),
      loading: () => false,
      error: (_, __) => false,
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Lockbox lockbox) {
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
