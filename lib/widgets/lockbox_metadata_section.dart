import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';

/// Widget for displaying lockbox metadata (ownership info)
class LockboxMetadataSection extends ConsumerWidget {
  final String lockboxId;

  const LockboxMetadataSection({super.key, required this.lockboxId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockboxAsync = ref.watch(lockboxProvider(lockboxId));
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Lockbox Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading lockbox: $error',
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
        ),
      ),
      data: (lockbox) {
        if (lockbox == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Lockbox not found'),
            ),
          );
        }

        return currentPubkeyAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading user info: $error'),
            ),
          ),
          data: (currentPubkey) => _buildMetadataContent(context, lockbox, currentPubkey),
        );
      },
    );
  }

  Widget _buildMetadataContent(BuildContext context, Lockbox lockbox, String? currentPubkey) {
    final isOwner = currentPubkey == lockbox.ownerPubkey;
    final threshold = lockbox.shards.isNotEmpty ? lockbox.shards.first.threshold : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOwner) ...[
              // Owner state
              Row(
                children: [
                  Icon(Icons.person, color: Theme.of(context).textTheme.titleMedium?.color),
                  const SizedBox(width: 8),
                  Text(
                    'You own this lockbox',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ] else ...[
              // Key holder state
              Row(
                children: [
                  Icon(Icons.key, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You hold a key for this lockbox',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Owner: ${_abbreviateNpub(lockbox.ownerPubkey)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$threshold keys are needed to recover and unlock the vault.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Abbreviate npub address for display
  String _abbreviateNpub(String hexPubkey) {
    try {
      final npub = Helpers.encodeBech32(hexPubkey, 'npub');
      return '${npub.substring(0, 8)}...${npub.substring(npub.length - 8)}';
    } catch (e) {
      // Fallback to hex abbreviation if bech32 conversion fails
      return '${hexPubkey.substring(0, 8)}...${hexPubkey.substring(hexPubkey.length - 8)}';
    }
  }
}
