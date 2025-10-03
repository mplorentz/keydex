import 'package:flutter/material.dart';
import '../models/lockbox.dart';
import '../services/lockbox_service.dart';
import 'backup_config_screen.dart';
import 'edit_lockbox_screen.dart';

/// Detail/view screen for displaying a lockbox
class LockboxDetailScreen extends StatelessWidget {
  final String lockboxId;

  const LockboxDetailScreen({super.key, required this.lockboxId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lockbox?>(
      future: LockboxService.getLockbox(lockboxId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final lockbox = snapshot.data;
        if (lockbox == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lockbox Not Found')),
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
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created ${_formatDate(lockbox.createdAt)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${lockbox.content.length} characters',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        lockbox.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Backup Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.backup, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Distributed Backup',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.blue[700],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure distributed backup for this lockbox using Shamir\'s Secret Sharing. '
                      'Your data will be split into multiple encrypted shares and distributed to trusted contacts via Nostr.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.settings),
                        label: const Text('Configure Backup Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
