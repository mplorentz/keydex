import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../screens/backup_config_screen.dart';

/// Widget for displaying list of key holders who have shards
class KeyHolderList extends ConsumerWidget {
  final String lockboxId;

  const KeyHolderList({super.key, required this.lockboxId});

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
                  Icon(Icons.people, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Key Holders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading key holders: $error',
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
          data: (currentPubkey) => _buildKeyHolderContent(context, lockbox, currentPubkey),
        );
      },
    );
  }

  Widget _buildKeyHolderContent(BuildContext context, Lockbox lockbox, String? currentPubkey) {
    final keyHolders = _extractKeyHolders(lockbox, currentPubkey);

    return Container(
      width: double.infinity,
      color: const Color(0xFF666f62),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFFd2d7bf)),
              const SizedBox(width: 8),
              Text(
                'Key Holders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFd2d7bf),
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BackupConfigScreen(
                        lockboxId: lockbox.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Color(0xFFd2d7bf)),
                tooltip: 'Edit Backup Settings',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (keyHolders.isEmpty) ...[
            // Empty state
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.key_off,
                    size: 48,
                    color: const Color(0xFFd2d7bf).withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No key holders configured',
                    style: TextStyle(
                      color: Color(0xFFd2d7bf),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure backup settings to add key holders',
                    style: TextStyle(
                      color: const Color(0xFFd2d7bf).withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Key holder list
            ...keyHolders.map((keyHolder) => _buildKeyHolderItem(context, keyHolder)),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyHolderItem(BuildContext context, KeyHolderInfo keyHolder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFd2d7bf).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFd2d7bf).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFd2d7bf).withValues(alpha: 0.2),
            child: Icon(
              keyHolder.isOwner ? Icons.person : Icons.key,
              color: const Color(0xFFd2d7bf),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyHolder.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFd2d7bf),
                      ),
                ),
                if (keyHolder.isOwner) ...[
                  Text(
                    'Owner',
                    style: TextStyle(
                      color: const Color(0xFFd2d7bf).withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Key Holder',
                    style: TextStyle(
                      color: const Color(0xFFd2d7bf).withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extract key holders from lockbox shard data
  List<KeyHolderInfo> _extractKeyHolders(Lockbox lockbox, String? currentPubkey) {
    if (lockbox.shards.isEmpty) {
      return [];
    }

    final shard = lockbox.shards.first;
    final keyHolders = <KeyHolderInfo>[];
    final isCurrentUserOwner = currentPubkey == lockbox.ownerPubkey;

    // Add peers (key holders)
    if (shard.peers != null) {
      for (final peerPubkey in shard.peers!) {
        keyHolders.add(KeyHolderInfo(
          pubkey: peerPubkey,
          displayName: _abbreviateNpub(peerPubkey),
          isOwner: false,
        ));
      }
    }

    // Add owner if current user is NOT the owner and owner is in peers list
    if (!isCurrentUserOwner && shard.peers != null && shard.peers!.contains(lockbox.ownerPubkey)) {
      keyHolders.add(KeyHolderInfo(
        pubkey: lockbox.ownerPubkey,
        displayName: _abbreviateNpub(lockbox.ownerPubkey),
        isOwner: true,
      ));
    }

    // Sort: owner first, then others
    keyHolders.sort((a, b) {
      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;
      return 0;
    });

    return keyHolders;
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

/// Data class for key holder information
class KeyHolderInfo {
  final String pubkey;
  final String displayName;
  final bool isOwner;

  KeyHolderInfo({
    required this.pubkey,
    required this.displayName,
    required this.isOwner,
  });
}
