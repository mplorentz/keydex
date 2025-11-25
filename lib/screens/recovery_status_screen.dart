import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';
import '../providers/lockbox_provider.dart';
import '../services/recovery_service.dart';
import '../widgets/recovery_progress_widget.dart';
import '../widgets/recovery_key_holders_widget.dart';

/// Screen for displaying recovery request status and key holder responses
class RecoveryStatusScreen extends ConsumerStatefulWidget {
  final String recoveryRequestId;

  const RecoveryStatusScreen({
    super.key,
    required this.recoveryRequestId,
  });

  @override
  ConsumerState<RecoveryStatusScreen> createState() => _RecoveryStatusScreenState();
}

class _RecoveryStatusScreenState extends ConsumerState<RecoveryStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(recoveryRequestByIdProvider(widget.recoveryRequestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery'),
        centerTitle: false,
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (request) {
          if (request == null) {
            return const Center(child: Text('Recovery request not found'));
          }

          // Get lockbox to extract instructions
          final lockboxAsync = ref.watch(lockboxProvider(request.lockboxId));

          return lockboxAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading lockbox: $error')),
            data: (lockbox) {
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
                              Text(
                                instructions,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    RecoveryProgressWidget(recoveryRequestId: widget.recoveryRequestId),
                    const SizedBox(height: 16),
                    RecoveryKeyHoldersWidget(recoveryRequestId: widget.recoveryRequestId),
                    const SizedBox(height: 16),
                    if (request.status.isActive) _buildCancelButton(),
                    if (request.status == RecoveryRequestStatus.completed)
                      _buildExitRecoveryButton(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExitRecoveryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exitRecoveryMode,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Exit Recovery Mode'),
      ),
    );
  }

  Future<void> _exitRecoveryMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Recovery Mode'),
        content: const Text(
          'This will archive the recovery request and delete the recovered content and steward keys. '
          'Your own key to the vault will be preserved.\n\n'
          'Are you sure you want to exit recovery mode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Recovery Mode'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get lockboxId before exiting recovery mode
        final request =
            await ref.read(recoveryServiceProvider).getRecoveryRequest(widget.recoveryRequestId);
        final lockboxId = request?.lockboxId;

        await ref.read(recoveryServiceProvider).exitRecoveryMode(widget.recoveryRequestId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exited recovery mode successfully')),
          );
          // Invalidate providers to refresh the UI
          ref.invalidate(recoveryRequestByIdProvider(widget.recoveryRequestId));
          if (lockboxId != null) {
            ref.invalidate(lockboxProvider(lockboxId));
          }
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cancelRecovery,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.cancel),
        label: const Text('Cancel Recovery Request'),
      ),
    );
  }

  Future<void> _cancelRecovery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recovery'),
        content: const Text('Are you sure you want to cancel this recovery request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(recoveryServiceProvider).cancelRecoveryRequest(widget.recoveryRequestId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recovery request cancelled')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
