import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/lockbox.dart';
import '../models/key_holder.dart';
import '../providers/recovery_provider.dart';
import '../providers/lockbox_provider.dart';

/// Widget displaying key holder responses
class RecoveryKeyHoldersWidget extends ConsumerWidget {
  final String recoveryRequestId;

  const RecoveryKeyHoldersWidget({super.key, required this.recoveryRequestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(
      recoveryRequestByIdProvider(recoveryRequestId),
    );

    return requestAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
      data: (request) {
        if (request == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Recovery request not found'),
            ),
          );
        }

        // Now we have the request, get the lockbox
        final lockboxAsync = ref.watch(lockboxProvider(request.lockboxId));

        return lockboxAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading lockbox: $error'),
            ),
          ),
          data: (lockbox) {
            // Get all key holders for this lockbox
            final keyHolders = _extractKeyHolders(lockbox, request);

            if (keyHolders.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No key holders configured',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...keyHolders.map((info) {
                      return _buildKeyHolderItem(info);
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Extract all key holders from lockbox, merge with responses
  List<_KeyHolderInfo> _extractKeyHolders(
    Lockbox? lockbox,
    RecoveryRequest request,
  ) {
    if (lockbox == null) return [];

    // Get key holders with names from backupConfig if available
    if (lockbox.backupConfig?.keyHolders.isNotEmpty == true) {
      return lockbox.backupConfig!.keyHolders.where((kh) => kh.pubkey != null).map((kh) {
        final response = request.keyHolderResponses[kh.pubkey];
        return _KeyHolderInfo(
          pubkey: kh.pubkey!,
          name: kh.displayName,
          response: response,
        );
      }).toList();
    }

    // Fallback: use peers from shards
    if (lockbox.shards.isNotEmpty) {
      final firstShard = lockbox.shards.first;
      final keyHolders = <_KeyHolderInfo>[];

      // Add owner if ownerName is present
      if (lockbox.ownerName != null) {
        final response = request.keyHolderResponses[firstShard.creatorPubkey];
        keyHolders.add(
          _KeyHolderInfo(
            pubkey: firstShard.creatorPubkey,
            name: lockbox.ownerName,
            response: response,
          ),
        );
      } else if (firstShard.ownerName != null) {
        // Fallback to shard ownerName
        final response = request.keyHolderResponses[firstShard.creatorPubkey];
        keyHolders.add(
          _KeyHolderInfo(
            pubkey: firstShard.creatorPubkey,
            name: firstShard.ownerName,
            response: response,
          ),
        );
      }

      // Add peers (key holders) - now a list of maps with name and pubkey
      if (firstShard.peers != null) {
        for (final peer in firstShard.peers!) {
          final peerPubkey = peer['pubkey'];
          final peerName = peer['name'];
          if (peerPubkey == null) continue;

          final response = request.keyHolderResponses[peerPubkey];
          keyHolders.add(
            _KeyHolderInfo(
              pubkey: peerPubkey,
              name: peerName,
              response: response,
            ),
          );
        }
      }

      return keyHolders;
    }

    return [];
  }

  Widget _buildKeyHolderItem(_KeyHolderInfo info) {
    final response = info.response;
    final status = response?.status ?? RecoveryResponseStatus.pending;

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
            backgroundColor: _getResponseColor(status).withValues(alpha: 0.1),
            child: Icon(
              _getResponseIcon(status),
              color: _getResponseColor(status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name ?? '${info.pubkey.substring(0, 16)}...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (info.name != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${info.pubkey.substring(0, 16)}...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getResponseColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getResponseColor(status),
                        ),
                      ),
                    ),
                    if (response?.respondedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          _formatDateTime(response!.respondedAt!),
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
      case RecoveryResponseStatus.error:
        return Icons.error;
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
      case RecoveryResponseStatus.error:
        return Colors.red;
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

/// Internal data class for key holder info
class _KeyHolderInfo {
  final String pubkey;
  final String? name;
  final RecoveryResponse? response;

  _KeyHolderInfo({required this.pubkey, this.name, this.response});
}
