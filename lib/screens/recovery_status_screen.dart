import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart';
import '../services/recovery_service.dart';
import '../services/logger.dart';

/// Screen for displaying recovery request status and key holder responses
class RecoveryStatusScreen extends StatefulWidget {
  final String recoveryRequestId;

  const RecoveryStatusScreen({
    super.key,
    required this.recoveryRequestId,
  });

  @override
  State<RecoveryStatusScreen> createState() => _RecoveryStatusScreenState();
}

class _RecoveryStatusScreenState extends State<RecoveryStatusScreen> {
  RecoveryRequest? _request;
  RecoveryStatus? _status;
  bool _isLoading = true;
  StreamSubscription<RecoveryRequest>? _recoveryRequestSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRecoveryListener();
  }

  @override
  void dispose() {
    _recoveryRequestSubscription?.cancel();
    super.dispose();
  }

  /// Listen for real-time updates to the recovery request
  void _setupRecoveryListener() {
    _recoveryRequestSubscription = RecoveryService.recoveryRequestStream.listen((updatedRequest) {
      // Only update if it's for this specific recovery request
      if (updatedRequest.id == widget.recoveryRequestId && mounted) {
        _loadData(); // Reload all data to get updated status
        Log.info('Recovery status screen auto-updated for request ${updatedRequest.id}');
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final request = await RecoveryService.getRecoveryRequest(widget.recoveryRequestId);
      final status = await RecoveryService.getRecoveryStatus(widget.recoveryRequestId);

      if (mounted) {
        setState(() {
          _request = request;
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.error('Error loading recovery status', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        await RecoveryService.cancelRecoveryRequest(widget.recoveryRequestId);

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
        _isLoading = true;
      });

      // Perform the recovery
      final content = await RecoveryService.performRecovery(widget.recoveryRequestId);

      if (mounted) {
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

        // Reload data to show updated status
        await _loadData();

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
          _isLoading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Status'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('Recovery request not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildProgressCard(),
                      const SizedBox(height: 16),
                      _buildKeyHoldersSection(),
                      const SizedBox(height: 16),
                      if (_request!.status.isActive) _buildCancelButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(_request!.status),
                  color: _getStatusColor(_request!.status),
                ),
                const SizedBox(width: 12),
                Text(
                  _request!.status.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_request!.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Request ID', _request!.id),
            _buildInfoRow('Lockbox ID', _request!.lockboxId),
            _buildInfoRow('Requested', _formatDateTime(_request!.requestedAt)),
            if (_request!.expiresAt != null)
              _buildInfoRow(
                'Expires',
                _formatDateTime(_request!.expiresAt!),
                isWarning: _request!.isExpired,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    if (_status == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recovery Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _status!.recoveryProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _status!.canRecover ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_status!.recoveryProgress.toStringAsFixed(0)}% complete',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressRow(
              'Threshold',
              '${_status!.threshold}',
              'Minimum shares needed',
            ),
            _buildProgressRow(
              'Approved',
              '${_status!.approvedCount}',
              'Key holders approved',
            ),
            _buildProgressRow(
              'Denied',
              '${_status!.deniedCount}',
              'Key holders denied',
            ),
            _buildProgressRow(
              'Pending',
              '${_status!.pendingCount}',
              'Awaiting response',
            ),
            const SizedBox(height: 16),
            if (_status!.canRecover) ...[
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
                        'Sufficient shares collected! Recovery is possible.',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _performRecovery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.lock_open),
                  label: const Text(
                    'Recover Lockbox',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeyHoldersSection() {
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
            const SizedBox(height: 16),
            ..._request!.keyHolderResponses.values.map((response) {
              return _buildKeyHolderItem(response);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyHolderItem(RecoveryResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getResponseColor(response.status).withValues(alpha: 0.1),
            child: Icon(
              _getResponseIcon(response.status),
              color: _getResponseColor(response.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${response.pubkey.substring(0, 16)}...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getResponseColor(response.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        response.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getResponseColor(response.status),
                        ),
                      ),
                    ),
                    if (response.respondedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          _formatDateTime(response.respondedAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
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

  Color _getStatusColor(RecoveryRequestStatus status) {
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

  IconData _getResponseIcon(RecoveryResponseStatus status) {
    switch (status) {
      case RecoveryResponseStatus.pending:
        return Icons.schedule;
      case RecoveryResponseStatus.approved:
        return Icons.check_circle;
      case RecoveryResponseStatus.denied:
        return Icons.cancel;
      case RecoveryResponseStatus.timeout:
        return Icons.timer_off;
    }
  }

  Color _getResponseColor(RecoveryResponseStatus status) {
    switch (status) {
      case RecoveryResponseStatus.pending:
        return Colors.orange;
      case RecoveryResponseStatus.approved:
        return Colors.green;
      case RecoveryResponseStatus.denied:
        return Colors.red;
      case RecoveryResponseStatus.timeout:
        return Colors.grey;
    }
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
