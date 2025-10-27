import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';
import '../services/recovery_service.dart';
import '../widgets/recovery_metadata_widget.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Invalidate the provider to trigger refresh
              ref.invalidate(recoveryRequestByIdProvider(widget.recoveryRequestId));
            },
            tooltip: 'Refresh',
          ),
        ],
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecoveryMetadataWidget(recoveryRequestId: widget.recoveryRequestId),
                const SizedBox(height: 16),
                RecoveryProgressWidget(recoveryRequestId: widget.recoveryRequestId),
                const SizedBox(height: 16),
                RecoveryKeyHoldersWidget(recoveryRequestId: widget.recoveryRequestId),
                const SizedBox(height: 16),
                if (request.status.isActive) _buildCancelButton(),
              ],
            ),
          );
        },
      ),
    );
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
