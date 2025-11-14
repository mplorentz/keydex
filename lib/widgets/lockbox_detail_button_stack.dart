import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../models/key_holder_status.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../providers/recovery_provider.dart';
import '../widgets/row_button_stack.dart';
import '../widgets/instructions_dialog.dart';
import '../services/backup_service.dart';
import '../services/recovery_service.dart';
import '../services/lockbox_share_service.dart';
import '../services/relay_scan_service.dart';
import '../services/logger.dart';
import '../screens/backup_config_screen.dart';
import '../screens/edit_lockbox_screen.dart';
import '../screens/recovery_status_screen.dart';

/// Button stack widget for lockbox detail screen
class LockboxDetailButtonStack extends ConsumerWidget {
  final String lockboxId;

  const LockboxDetailButtonStack({
    super.key,
    required this.lockboxId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is steward or owner
    final lockboxAsync = ref.watch(lockboxProvider(lockboxId));
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return lockboxAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (lockbox) {
        if (lockbox == null) return const SizedBox.shrink();

        return currentPubkeyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (currentPubkey) {
            final isOwned = currentPubkey != null && lockbox.isOwned(currentPubkey);
            final isSteward = currentPubkey != null &&
                !lockbox.isOwned(currentPubkey) &&
                lockbox.shards.isNotEmpty;

            // Watch lockbox for Generate and Distribute Keys button
            final lockboxAsync = ref.watch(lockboxProvider(lockboxId));
            // Watch recovery status for recovery buttons
            final recoveryStatusAsync = ref.watch(recoveryStatusProvider(lockboxId));

            return lockboxAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (currentLockbox) {
                return recoveryStatusAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recoveryStatus) {
                    final buttons = <RowButtonConfig>[];

                    // View Instructions Button (only show for stewards)
                    if (isSteward) {
                      final instructions = _getInstructions(lockbox);
                      if (instructions != null && instructions.isNotEmpty) {
                        buttons.add(RowButtonConfig(
                          onPressed: () {
                            InstructionsDialog.show(context, instructions);
                          },
                          icon: Icons.info_outline,
                          text: 'View Instructions',
                        ));
                      }
                    }

                    // Edit Lockbox Button (only show if user owns the lockbox)
                    if (isOwned) {
                      buttons.add(RowButtonConfig(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditLockboxScreen(lockboxId: lockboxId),
                            ),
                          );
                        },
                        icon: Icons.edit,
                        text: 'Change Contents',
                      ));

                      // Backup Configuration Section
                      buttons.add(RowButtonConfig(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BackupConfigScreen(
                                lockboxId: lockboxId,
                              ),
                            ),
                          );
                        },
                        icon: Icons.settings,
                        text: 'Backup Settings',
                      ));

                      // Generate and Distribute Keys Button - show when all invited key holders have accepted
                      if (currentLockbox != null) {
                        final backupConfig = currentLockbox.backupConfig;
                        if (backupConfig != null && backupConfig.keyHolders.isNotEmpty) {
                          final keyHolders = backupConfig.keyHolders;
                          final hasInvitedKeyHolders =
                              keyHolders.any((kh) => kh.status == KeyHolderStatus.invited);
                          final allAccepted = keyHolders.every((kh) =>
                              kh.status == KeyHolderStatus.awaitingKey ||
                              kh.status == KeyHolderStatus.holdingKey);
                          final hasAwaitingKeyHolders =
                              keyHolders.any((kh) => kh.status == KeyHolderStatus.awaitingKey);

                          if (!hasInvitedKeyHolders && allAccepted && hasAwaitingKeyHolders) {
                            buttons.add(RowButtonConfig(
                              onPressed: () =>
                                  _generateAndDistributeKeys(context, ref, currentLockbox),
                              icon: Icons.vpn_key,
                              text: 'Generate and Distribute Keys',
                            ));
                          }
                        }
                      }
                    }

                    // Recovery buttons - show "Manage Recovery" if user initiated active recovery
                    if (recoveryStatus.hasActiveRecovery && recoveryStatus.isInitiator) {
                      buttons.add(RowButtonConfig(
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
                      ));
                    } else {
                      // Show "Initiate Recovery" if no active recovery or user didn't initiate it
                      buttons.add(RowButtonConfig(
                        onPressed: () => _initiateRecovery(context, ref, lockboxId),
                        icon: Icons.restore,
                        text: 'Initiate Recovery',
                      ));
                    }

                    if (buttons.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return RowButtonStack(buttons: buttons);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String? _getInstructions(Lockbox lockbox) {
    if (lockbox.shards.isNotEmpty) {
      return lockbox.shards.first.instructions;
    }
    return null;
  }

  Future<void> _generateAndDistributeKeys(
      BuildContext context, WidgetRef ref, Lockbox lockbox) async {
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
          content: Text('No stewards configured'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (lockbox.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot backup: lockbox has no files'),
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
          'This will generate ${config.totalKeys} key shares and distribute them to ${config.keyHolders.length} stewards.\n\n'
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

    if (!context.mounted) return;
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

  Future<void> _initiateRecovery(BuildContext context, WidgetRef ref, String lockboxId) async {
    // Show full-screen loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.8),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Text(
                        'Sending recovery requests...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final loginService = ref.read(loginServiceProvider);
      final currentPubkey = await loginService.getCurrentPublicKey();

      if (currentPubkey == null) {
        if (context.mounted) {
          Navigator.pop(context);
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
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No shard data available for recovery')),
          );
        }
        return;
      }

      // Get the first shard to extract peers info
      final firstShard = shards.first;
      Log.debug('First shard: $firstShard');

      // Use peers list for recovery
      final keyHolderPubkeys = <String>[];
      if (firstShard.peers != null) {
        for (final peer in firstShard.peers!) {
          final pubkey = peer['pubkey'];
          if (pubkey != null) {
            keyHolderPubkeys.add(pubkey);
          }
        }
      }

      if (keyHolderPubkeys.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
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
      }

      // Auto-approve if the initiator is also a key holder
      if (keyHolderPubkeys.contains(currentPubkey)) {
        try {
          Log.info('Initiator is a key holder, auto-approving recovery request');
          await recoveryService.respondToRecoveryRequestWithShard(
            recoveryRequest.id,
            currentPubkey,
            true,
          );
          Log.info('Auto-approved recovery request');
        } catch (e) {
          Log.error('Failed to auto-approve recovery request', e);
        }
      }

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery request initiated and sent')),
        );

        ref.invalidate(recoveryStatusProvider(lockboxId));

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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
