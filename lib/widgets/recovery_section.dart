import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recovery_provider.dart';
import '../providers/key_provider.dart';
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
                    'Vault Recovery',
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
      data: (recoveryStatus) => _buildRecoveryContent(context, ref, recoveryStatus),
    );
  }

  Widget _buildRecoveryContent(BuildContext context, WidgetRef ref, RecoveryStatus recoveryStatus) {
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
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: const Color.fromARGB(255, 253, 255, 240),
          ),
        ] else ...[
          RowButton(
            onPressed: () => _initiateRecovery(context, ref),
            icon: Icons.restore,
            text: 'Initiate Recovery',
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: const Color.fromARGB(255, 253, 255, 240),
          ),
        ],
      ],
    );
  }

  Future<void> _initiateRecovery(BuildContext context, WidgetRef ref) async {
    try {
      final loginService = ref.read(loginServiceProvider);
      final currentPubkey = await loginService.getCurrentPublicKey();

      if (currentPubkey == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not load current user')),
          );
        }
        return;
      }

      // Get shard data to extract peers and creator information
      final shareService = ref.read(lockboxShareServiceProvider);
      final shards = await shareService.getLockboxShares(lockboxId);

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
            const SnackBar(content: Text('No stewards available for recovery')),
          );
        }
        return;
      }

      Log.info(
          'Initiating recovery with ${keyHolderPubkeys.length} stewards: ${keyHolderPubkeys.map((k) => k.substring(0, 8)).join(", ")}...');

      final recoveryService = ref.read(recoveryServiceProvider);
      final recoveryRequest = await recoveryService.initiateRecovery(
        lockboxId,
        initiatorPubkey: currentPubkey,
        keyHolderPubkeys: keyHolderPubkeys,
        threshold: firstShard.threshold,
      );

      // Get relays and send recovery request via Nostr
      try {
        final relays =
            await ref.read(relayScanServiceProvider).getRelayConfigurations(enabledOnly: true);
        final relayUrls = relays.map((r) => r.url).toList();

        if (relayUrls.isEmpty) {
          Log.warning('No relays configured, recovery request not sent via Nostr');
        } else {
          await recoveryService.sendRecoveryRequestViaNostr(
            recoveryRequest,
            relays: relayUrls,
          );
        }
      } catch (e) {
        Log.error('Failed to send recovery request via Nostr', e);
        // Continue anyway - the request is still created locally
      }

      // Auto-approve if the initiator is also a key holder
      if (keyHolderPubkeys.contains(currentPubkey)) {
        try {
          Log.info('Initiator is a key holder, auto-approving recovery request');
          await recoveryService.respondToRecoveryRequestWithShard(
            recoveryRequest.id,
            currentPubkey,
            true, // approved
          );
          Log.info('Auto-approved recovery request');
        } catch (e) {
          Log.error('Failed to auto-approve recovery request', e);
          // Continue anyway - user can manually approve later
        }
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
