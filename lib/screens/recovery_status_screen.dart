import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart';
import '../providers/recovery_provider.dart';
import '../services/logger.dart';

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
  bool _isPerformingRecovery = false;

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
        await ref.read(recoveryRepositoryProvider).cancelRecoveryRequest(widget.recoveryRequestId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recovery request cancelled')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        Log.error('Error cancelling recovery', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _performRecovery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recover Lockbox'),
        content: const Text(
          'This will recover and unlock your lockbox using the collected key shares. '
          'The recovered content will be displayed. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isPerformingRecovery = true;
      });

      // Perform the recovery using repository
      final content = await ref.read(recoveryRepositoryProvider).performRecovery(widget.recoveryRequestId);

      if (mounted) {
        setState(() {
          _isPerformingRecovery = false;
        });

        // Show the recovered content in a dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lockbox Recovered!'),
            content: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );

        // Refresh providers to show updated status
        ref.invalidate(recoveryRequestProvider(widget.recoveryRequestId));
        ref.invalidate(recoveryStatusProvider(widget.recoveryRequestId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lockbox successfully recovered!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      Log.error('Error performing recovery', e);
      if (mounted) {
        setState(() {
          _isPerformingRecovery = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the recovery request and status providers
    final requestAsync = ref.watch(recoveryRequestProvider(widget.recoveryRequestId));
    final statusAsync = ref.watch(recoveryStatusProvider(widget.recoveryRequestId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Status'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(recoveryRequestProvider(widget.recoveryRequestId));
              ref.invalidate(recoveryStatusProvider(widget.recoveryRequestId));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isPerformingRecovery
          ? const Center(child: CircularProgressIndicator())
          : requestAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading recovery request: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(recoveryRequestProvider(widget.recoveryRequestId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (request) {
                if (request == null) {
                  return const Center(child: Text('Recovery request not found'));
                }

                return _RecoveryStatusContent(
                  request: request,
                  statusAsync: statusAsync,
                  onCancel: _cancelRecovery,
                  onPerformRecovery: _performRecovery,
                );
              },
            ),
    );
  }
}

/// Extracted content widget for recovery status
class _RecoveryStatusContent extends StatelessWidget {
  final RecoveryRequest request;
  final AsyncValue<RecoveryStatus?> statusAsync;
  final VoidCallback onCancel;
  final VoidCallback onPerformRecovery;

  const _RecoveryStatusContent({
    required this.request,
    required this.statusAsync,
    required this.onCancel,
    required this.onPerformRecovery,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context),
          const SizedBox(height: 16),
          _buildProgressCard(context),
          const SizedBox(height: 16),
          _buildKeyHoldersSection(context),
          const SizedBox(height: 16),
          if (request.status.isActive) _buildCancelButton(context),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(request.status),
                  color: _getStatusColor(request.status, context),
                ),
                const SizedBox(width: 12),
                Text(
                  request.status.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(request.status, context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Request ID: ${request.id}'),
            Text('Lockbox ID: ${request.lockboxId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final progress = request.totalKeyHolders > 0
        ? request.approvedCount / request.totalKeyHolders
        : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                request.isComplete ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${request.approvedCount} of ${request.threshold} required key shares collected',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyHoldersSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Holders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Total: ${request.totalKeyHolders}'),
            Text('Approved: ${request.approvedCount}', style: const TextStyle(color: Colors.green)),
            Text('Denied: ${request.deniedCount}', style: const TextStyle(color: Colors.red)),
            Text('Pending: ${request.totalKeyHolders - request.respondedCount}', 
                 style: const TextStyle(color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onCancel,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Cancel Recovery Request'),
      ),
    );
  }

  IconData _getStatusIcon(RecoveryRequestStatus status) {
    switch (status) {
      case RecoveryRequestStatus.pending:
        return Icons.schedule;
      case RecoveryRequestStatus.sent:
        return Icons.send;
      case RecoveryRequestStatus.inProgress:
        return Icons.sync;
      case RecoveryRequestStatus.completed:
        return Icons.check_circle;
      case RecoveryRequestStatus.failed:
        return Icons.error;
      case RecoveryRequestStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(RecoveryRequestStatus status, BuildContext context) {
    switch (status) {
      case RecoveryRequestStatus.pending:
        return Colors.orange;
      case RecoveryRequestStatus.sent:
        return Colors.blue;
      case RecoveryRequestStatus.inProgress:
        return Theme.of(context).primaryColor;
      case RecoveryRequestStatus.completed:
        return Colors.green;
      case RecoveryRequestStatus.failed:
        return Colors.red;
      case RecoveryRequestStatus.cancelled:
        return Colors.grey;
    }
  }
}
