import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';
import '../services/logger.dart';
import 'recovery_request_detail_screen.dart';

/// Overlay widget for displaying recovery request notifications
class RecoveryNotificationOverlay extends ConsumerStatefulWidget {
  const RecoveryNotificationOverlay({super.key});

  @override
  ConsumerState<RecoveryNotificationOverlay> createState() => _RecoveryNotificationOverlayState();
}

class _RecoveryNotificationOverlayState extends ConsumerState<RecoveryNotificationOverlay> {
  bool _isExpanded = false;

  Future<void> _viewNotification(RecoveryRequest request) async {
    try {
      await ref.read(recoveryRepositoryProvider).markNotificationAsViewed(request.id);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecoveryRequestDetailScreen(
              recoveryRequest: request,
            ),
          ),
        );
      }
    } catch (e) {
      Log.error('Error viewing notification', e);
    }
  }

  Future<void> _dismissNotification(RecoveryRequest request) async {
    try {
      await ref.read(recoveryRepositoryProvider).markNotificationAsViewed(request.id);
    } catch (e) {
      Log.error('Error dismissing notification', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the pending notifications provider
    final notificationsAsync = ref.watch(pendingNotificationsProvider);

    return notificationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        Log.error('Error loading notifications', error);
        return const SizedBox.shrink();
      },
      data: (pendingNotifications) {
        if (pendingNotifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isExpanded ? 300 : 80,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 8,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Header
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            '${pendingNotifications.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recovery Requests',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${pendingNotifications.length} pending request${pendingNotifications.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _isExpanded ? Icons.expand_more : Icons.expand_less,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),

                // Notification list (when expanded)
                if (_isExpanded)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pendingNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = pendingNotifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(RecoveryRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: const Icon(Icons.lock_open, color: Colors.orange),
        ),
        title: const Text(
          'Recovery Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lockbox ID: ${request.lockboxId.substring(0, 8)}...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'From: ${request.initiatorPubkey.substring(0, 16)}...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              _formatDateTime(request.requestedAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _dismissNotification(request),
              tooltip: 'Dismiss',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, size: 20),
              onPressed: () => _viewNotification(request),
              color: Theme.of(context).primaryColor,
              tooltip: 'View',
            ),
          ],
        ),
        onTap: () => _viewNotification(request),
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
