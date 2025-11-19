import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/lockbox.dart';
import '../models/key_holder.dart';
import '../services/recovery_service.dart';
import '../providers/key_provider.dart';
import '../services/logger.dart';
import '../providers/recovery_provider.dart';
import '../utils/snackbar_helper.dart';
import '../providers/lockbox_provider.dart';

/// Screen for viewing and responding to a recovery request
class RecoveryRequestDetailScreen extends ConsumerStatefulWidget {
  final RecoveryRequest recoveryRequest;

  const RecoveryRequestDetailScreen({super.key, required this.recoveryRequest});

  @override
  ConsumerState<RecoveryRequestDetailScreen> createState() => _RecoveryRequestDetailScreenState();
}

class _RecoveryRequestDetailScreenState extends ConsumerState<RecoveryRequestDetailScreen> {
  bool _isLoading = false;
  String? _currentPubkey;

  @override
  void initState() {
    super.initState();
    _loadCurrentPubkey();
  }

  Future<void> _loadCurrentPubkey() async {
    try {
      final loginService = ref.read(loginServiceProvider);
      final pubkey = await loginService.getCurrentPublicKey();
      if (mounted) {
        setState(() {
          _currentPubkey = pubkey;
        });
      }
    } catch (e) {
      Log.error('Error loading current pubkey', e);
    }
  }

  Future<void> _respondToRequest(RecoveryResponseStatus status) async {
    if (_currentPubkey == null) {
      context.showTopSnackBar(const SnackBar(content: Text('Error: Could not load current user')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final approved = status == RecoveryResponseStatus.approved;

      // Use the convenience method that handles shard retrieval and Nostr sending
      await ref
          .read(recoveryServiceProvider)
          .respondToRecoveryRequestWithShard(widget.recoveryRequest.id, _currentPubkey!, approved);

      if (mounted) {
        // Invalidate the recovery status provider to force a refresh when navigating back
        ref.invalidate(recoveryStatusProvider(widget.recoveryRequest.lockboxId));

        context.showTopSnackBar(
          SnackBar(
            content: Text(
              status == RecoveryResponseStatus.approved
                  ? 'Recovery request approved and shard sent'
                  : 'Recovery request denied',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Log.error('Error responding to recovery request', e);
      if (mounted) {
        context.showTopSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showApprovalDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Recovery'),
        content: const Text(
          'Are you sure you want to approve this recovery request? '
          'This will share your key shard with the requester.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _respondToRequest(RecoveryResponseStatus.approved);
    }
  }

  Future<void> _showDenialDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Recovery'),
        content: const Text(
          'Are you sure you want to deny this recovery request? '
          'The requester will not be able to use your shard.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _respondToRequest(RecoveryResponseStatus.denied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.recoveryRequest;
    final lockboxAsync = ref.watch(lockboxProvider(request.lockboxId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Request'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : lockboxAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error loading lockbox: $error')),
              data: (lockbox) => _buildContent(context, request, lockbox),
            ),
    );
  }

  Widget _buildContent(BuildContext context, RecoveryRequest request, Lockbox? lockbox) {
    // Get initiator name from lockbox shard data
    String? initiatorName;
    if (lockbox != null) {
      // First check lockbox ownerName
      if (lockbox.ownerPubkey == request.initiatorPubkey) {
        initiatorName = lockbox.ownerName;
      }

      // If not found and we have shards, check shard data
      if (initiatorName == null && lockbox.shards.isNotEmpty) {
        final firstShard = lockbox.shards.first;
        // Check if initiator is the owner
        if (firstShard.creatorPubkey == request.initiatorPubkey) {
          initiatorName = firstShard.ownerName ?? lockbox.ownerName;
        } else if (firstShard.peers != null) {
          // Check if initiator is in peers
          for (final peer in firstShard.peers!) {
            if (peer['pubkey'] == request.initiatorPubkey) {
              initiatorName = peer['name'];
              break;
            }
          }
        }
      }

      // Also check backupConfig
      if (initiatorName == null && lockbox.backupConfig != null) {
        try {
          final keyHolder = lockbox.backupConfig!.keyHolders.firstWhere(
            (kh) => kh.pubkey == request.initiatorPubkey,
          );
          initiatorName = keyHolder.displayName;
        } catch (e) {
          // Key holder not found in backupConfig
        }
      }
    }

    // Get instructions from lockbox
    String? instructions;
    if (lockbox != null) {
      // First try to get from backupConfig
      if (lockbox.backupConfig?.instructions != null &&
          lockbox.backupConfig!.instructions!.isNotEmpty) {
        instructions = lockbox.backupConfig!.instructions;
      } else if (lockbox.shards.isNotEmpty) {
        // Fallback to shard data
        instructions = lockbox.shards.first.instructions;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert card
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Someone is requesting recovery of a vault you have a key for',
                      style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Request details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildInfoRow('Request ID', request.id),
                  _buildInfoRow('Vault ID', request.lockboxId),
                  _buildInfoRow('Requested', _formatDateTime(request.requestedAt)),
                  if (request.expiresAt != null)
                    _buildInfoRow('Expires', _formatDateTime(request.expiresAt!)),
                  _buildInfoRow('Status', request.status.displayName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Initiator info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Initiator', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (initiatorName != null) ...[
                              Text(
                                initiatorName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                            ],
                            const Text(
                              'Public Key',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.initiatorPubkey,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Instructions section
          if (instructions != null && instructions.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Steward Instructions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(instructions, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Stewards summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stewards', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildStatRow('Total', request.totalKeyHolders, Colors.blue),
                  _buildStatRow('Approved', request.approvedCount, Colors.green),
                  _buildStatRow('Denied', request.deniedCount, Colors.red),
                  _buildStatRow(
                    'Pending',
                    request.totalKeyHolders - request.respondedCount,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          if (request.status.isActive) ...[
            Text('Your Response', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDenialDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Deny'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showApprovalDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
