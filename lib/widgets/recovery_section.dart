import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recovery_provider.dart';
import '../services/key_service.dart';
import '../services/lockbox_share_service.dart';
import '../services/recovery_service.dart';
import '../services/relay_scan_service.dart';
import '../services/logger.dart';
import '../screens/recovery_status_screen.dart';
import 'row_button.dart';

/// Widget for recovery section on lockbox detail screen
class RecoverySection extends ConsumerWidget {
  final String lockboxId;

  const RecoverySection({super.key, required this.lockboxId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryStatusAsync = ref.watch(recoveryStatusProvider(lockboxId));

    return recoveryStatusAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
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
                'Error loading recovery status: $error',
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
        ),
      ),
      data: (recoveryStatus) => _buildRecoveryContent(context, recoveryStatus),
    );
  }

  Widget _buildRecoveryContent(BuildContext context, RecoveryStatus recoveryStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section in a card
        if (recoveryStatus.hasActiveRecovery) ...[
          RowButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecoveryStatusScreen(
                    recoveryRequestId: recoveryStatus.activeRecoveryRequest!.id,
                  ),
                ),
              );
            },
            icon: Icons.visibility,
            text: 'Manage Recovery',
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ] else ...[
          RowButton(
            onPressed: () => _initiateRecovery(context),
            icon: Icons.restore,
            text: 'Initiate Recovery',
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ],
        if (recoveryStatus.canRecover) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
          ),
        ],
      ],
    );
  }

  Future<void> _initiateRecovery(BuildContext context) async {
    try {
      final currentPubkey = await KeyService.getCurrentPublicKey();

      if (currentPubkey == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not load current user')),
          );
        }
        return;
      }

      // Get shard data to extract peers and creator information
      final shards = await LockboxShareService.getLockboxShares(lockboxId);

      if (shards.isEmpty) {
        if (context.mounted) {
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No key holders available for recovery')),
          );
        }
        return;
      }

      Log.info(
          'Initiating recovery with ${keyHolderPubkeys.length} key holders: ${keyHolderPubkeys.map((k) => k.substring(0, 8)).join(", ")}...');

      final recoveryRequest = await RecoveryService.initiateRecovery(
        lockboxId,
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery request initiated and sent')),
        );

        // Navigate to recovery status screen
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecoveryStatusScreen(
                recoveryRequestId: recoveryRequest.id,
              ),
            ),
          );
        }
      }
    } catch (e) {
      Log.error('Error initiating recovery', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
