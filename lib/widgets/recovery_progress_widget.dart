import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/recovery_provider.dart';
import '../providers/lockbox_provider.dart';
import '../providers/file_storage_provider.dart';
import '../services/recovery_service.dart';
import 'dart:typed_data';
import '../services/file_storage_service.dart';

/// Widget for displaying recovery progress and status
class RecoveryProgressWidget extends ConsumerWidget {
  final String recoveryRequestId;

  const RecoveryProgressWidget({
    super.key,
    required this.recoveryRequestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(recoveryRequestByIdProvider(recoveryRequestId));

    // We need both request and lockbox to calculate proper progress
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

        // Only watch lockbox provider when we have a valid lockboxId
        final lockboxId = request.lockboxId;
        if (lockboxId.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Recovery request has no lockbox ID'),
            ),
          );
        }

        final lockboxAsync = ref.watch(lockboxProvider(lockboxId));

        // Now get the lockbox to calculate proper totals
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
            // Get actual totals from lockbox
            final totalKeyHolders = _getTotalKeyHolders(lockbox);
            final approvedCount = request.approvedCount;
            final deniedCount = request.deniedCount;
            final threshold = request.threshold;
            final pendingCount = totalKeyHolders - (approvedCount + deniedCount);
            final canRecover = approvedCount >= threshold;

            // Calculate progress based on threshold
            final progress = threshold > 0 ? (approvedCount / threshold * 100).clamp(0, 100) : 0.0;

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
                      value: progress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        canRecover ? Colors.green : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${progress.toStringAsFixed(0)}% complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressRow(
                      'Threshold',
                      '$threshold',
                      'Minimum shares needed',
                    ),
                    _buildProgressRow(
                      'Approved',
                      '$approvedCount',
                      'Stewards approved',
                    ),
                    _buildProgressRow(
                      'Denied',
                      '$deniedCount',
                      'Stewards denied',
                    ),
                    _buildProgressRow(
                      'Pending',
                      '$pendingCount',
                      'Awaiting response',
                    ),
                    const SizedBox(height: 16),
                    if (canRecover) ...[
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
                          onPressed: () => _performRecovery(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          icon: const Icon(Icons.lock_open),
                          label: const Text(
                            'Recover Vault',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Extract total number of key holders from lockbox
  int _getTotalKeyHolders(Lockbox? lockbox) {
    if (lockbox == null) return 0;

    // Get from backupConfig if available
    if (lockbox.backupConfig?.keyHolders.isNotEmpty == true) {
      return lockbox.backupConfig!.keyHolders.length;
    }

    // Fallback: use shards
    if (lockbox.shards.isNotEmpty) {
      final firstShard = lockbox.shards.first;
      if (firstShard.peers != null) {
        // Peers is now a list of maps, count them
        var count = firstShard.peers!.length;
        // Also count owner if ownerName is present (from lockbox or shard)
        if (lockbox.ownerName != null || firstShard.ownerName != null) {
          count++;
        }
        return count;
      }
      // If no peers but ownerName is present, count owner
      if (lockbox.ownerName != null || firstShard.ownerName != null) {
        return 1;
      }
    }

    return 0;
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

  Future<void> _performRecovery(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recover Vault'),
        content: const Text(
          'This will recover and unlock your vault using the collected key shares. '
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
      // Perform the recovery
      final service = ref.read(recoveryServiceProvider);
      final recoveryRequest = await service.getRecoveryRequest(recoveryRequestId);
      if (recoveryRequest == null) {
        throw Exception('Recovery request not found');
      }

      final lockbox = ref.read(lockboxProvider(recoveryRequest.lockboxId)).value;
      if (lockbox == null) {
        throw Exception('Lockbox not found');
      }

      // Perform recovery (reconstructs secret/encryption key)
      final secret = await service.performRecovery(recoveryRequestId);

      if (context.mounted) {
        // T037: Handle file-based lockboxes
        if (lockbox.files.isNotEmpty) {
          // Convert secret to encryption key
          final encryptionKey = _secretToEncryptionKey(secret);
          final fileStorageService = ref.read(fileStorageServiceProvider);

          // Download and save each file
          int savedCount = 0;
          for (final file in lockbox.files) {
            try {
              final decryptedBytes = await fileStorageService.downloadAndDecryptFile(
                blossomUrl: file.blossomUrl,
                blossomHash: file.blossomHash,
                encryptionKey: Uint8List.fromList(encryptionKey),
              );

              final saved = await fileStorageService.saveFile(
                fileBytes: decryptedBytes,
                suggestedName: file.name,
                mimeType: file.mimeType,
              );

              if (saved) {
                savedCount++;
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving ${file.name}: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recovery complete! Saved $savedCount of ${lockbox.files.length} file(s)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Text-based lockbox - show content in dialog
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vault Recovered!'),
              content: SingleChildScrollView(
                child: SelectableText(
                  secret,
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

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vault successfully recovered!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Convert secret string to 32-byte encryption key
  List<int> _secretToEncryptionKey(String secret) {
    // If secret is hex, decode it
    if (secret.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(secret)) {
      final bytes = <int>[];
      for (int i = 0; i < 64; i += 2) {
        bytes.add(int.parse(secret.substring(i, i + 2), radix: 16));
      }
      return bytes;
    }
    // Otherwise, use first 32 bytes of UTF-8 encoding
    final utf8Bytes = secret.codeUnits;
    if (utf8Bytes.length >= 32) {
      return utf8Bytes.sublist(0, 32);
    }
    // Pad with zeros if needed
    final key = List<int>.filled(32, 0);
    key.setRange(0, utf8Bytes.length, utf8Bytes);
    return key;
  }
}
