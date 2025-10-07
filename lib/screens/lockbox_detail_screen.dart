import 'package:flutter/material.dart';
import '../models/lockbox.dart';
import '../models/recovery_request.dart';
import '../services/lockbox_service.dart';
import '../services/lockbox_share_service.dart';
import '../services/recovery_service.dart';
import '../services/relay_scan_service.dart';
import '../services/key_service.dart';
import '../services/logger.dart';
import 'backup_config_screen.dart';
import 'edit_lockbox_screen.dart';
import 'recovery_status_screen.dart';

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
              backgroundColor: Theme.of(context).primaryColor,
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
        backgroundColor: Theme.of(context).primaryColor,
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
                    Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
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
                        Icon(Icons.backup, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Distributed Backup',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
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
                          backgroundColor: Theme.of(context).primaryColor,
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
            const SizedBox(height: 16),
            // Recovery Section
            _RecoverySection(lockboxId: lockbox.id),
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

/// Widget for recovery section on lockbox detail screen
class _RecoverySection extends StatefulWidget {
  final String lockboxId;

  const _RecoverySection({required this.lockboxId});

  @override
  _RecoverySectionState createState() => _RecoverySectionState();
}

class _RecoverySectionState extends State<_RecoverySection> {
  bool _canRecover = false;
  bool _isLoading = true;
  RecoveryRequest? _activeRecoveryRequest;

  @override
  void initState() {
    super.initState();
    _checkRecoveryStatus();
  }

  Future<void> _checkRecoveryStatus() async {
    try {
      final canRecover = await RecoveryService.canRecoverLockbox(widget.lockboxId);

      // Check for active recovery requests for this lockbox
      final requests = await RecoveryService.getRecoveryRequests(
        lockboxId: widget.lockboxId,
      );

      // Find the most recent active request (not completed, failed, or cancelled)
      RecoveryRequest? activeRequest;
      for (final request in requests) {
        if (request.status.isActive) {
          if (activeRequest == null || request.requestedAt.isAfter(activeRequest.requestedAt)) {
            activeRequest = request;
          }
        }
      }

      if (mounted) {
        setState(() {
          _canRecover = canRecover;
          _activeRecoveryRequest = activeRequest;
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.error('Error checking recovery status', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiateRecovery() async {
    try {
      final currentPubkey = await KeyService.getCurrentPublicKey();

      if (currentPubkey == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not load current user')),
          );
        }
        return;
      }

      // Get shard data to extract peers and creator information
      final shards = await LockboxShareService.getLockboxShares(widget.lockboxId);

      if (shards.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No shard data available for recovery')),
          );
        }
        return;
      }

      // Get the first shard to extract peers info
      final firstShard = shards.first;
      Log.debug('First shard: $firstShard');

      // Use peers list for recovery (excludes creator since they don't have a shard in current design)
      final keyHolderPubkeys = firstShard.peers ?? [];

      if (keyHolderPubkeys.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No key holders available for recovery')),
          );
        }
        return;
      }

      Log.info(
          'Initiating recovery with ${keyHolderPubkeys.length} key holders: ${keyHolderPubkeys.map((k) => k.substring(0, 8)).join(", ")}...');

      final recoveryRequest = await RecoveryService.initiateRecovery(
        widget.lockboxId,
        initiatorPubkey: currentPubkey,
        keyHolderPubkeys: keyHolderPubkeys,
        threshold: firstShard.threshold,
      );

      // Get relays and send recovery request via Nostr
      try {
        final relays = await RelayScanService.getRelayConfigurations(enabledOnly: true);
        final relayUrls = relays.map((r) => r.url).toList();

        if (relayUrls.isEmpty) {
          Log.warning('No relays configured, recovery request not sent via Nostr');
        } else {
          await RecoveryService.sendRecoveryRequestViaNostr(
            recoveryRequest,
            relays: relayUrls,
          );
        }
      } catch (e) {
        Log.error('Failed to send recovery request via Nostr', e);
        // Continue anyway - the request is still created locally
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery request initiated and sent')),
        );

        // Reload state to update button
        await _checkRecoveryStatus();

        // Navigate to recovery status screen
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecoveryStatusScreen(
                recoveryRequestId: recoveryRequest.id,
              ),
            ),
          );
          // Refresh state when returning (in case user cancelled)
          if (mounted) {
            await _checkRecoveryStatus();
          }
        }
      }
    } catch (e) {
      Log.error('Error initiating recovery', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Lockbox Recovery',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'If you have a key share for this lockbox, you can initiate a recovery request '
              'to collect shares from other key holders and restore the contents.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            // Show either "View Recovery Status" or "Initiate Recovery" button
            if (_activeRecoveryRequest != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecoveryStatusScreen(
                          recoveryRequestId: _activeRecoveryRequest!.id,
                        ),
                      ),
                    );
                    // Refresh state when returning from recovery status screen
                    if (mounted) {
                      await _checkRecoveryStatus();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Recovery Status'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _initiateRecovery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.restore),
                  label: const Text('Initiate Recovery'),
                ),
              ),
            ],
            if (_canRecover) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recovery is available for this lockbox',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
