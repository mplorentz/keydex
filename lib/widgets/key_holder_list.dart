import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/lockbox.dart';
import '../models/key_holder.dart';
import '../models/key_holder_status.dart';
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
                    'Stewards',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading stewards: $error',
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
              child: Text('Vault not found'),
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
          data: (currentPubkey) => _buildKeyHolderContent(context, ref, lockbox, currentPubkey),
        );
      },
    );
  }

  Widget _buildKeyHolderContent(
      BuildContext context, WidgetRef ref, Lockbox lockbox, String? currentPubkey) {
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
              const SizedBox(width: 4),
              const Icon(Icons.people, color: Color(0xFFd2d7bf)),
              const SizedBox(width: 8),
              Text(
                'Stewards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFd2d7bf),
                    ),
              ),
              const Spacer(),
              // Only show settings button for owner
              if (currentPubkey != null && currentPubkey == lockbox.ownerPubkey)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BackupConfigScreen(
                          lockboxId: lockbox.id,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFd2d7bf).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Color(0xFFd2d7bf),
                      size: 20,
                    ),
                  ),
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
                    'No stewards configured',
                    style: TextStyle(
                      color: Color(0xFFd2d7bf),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Change backup settings to add stewards',
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
            Column(
              children: keyHolders.map((keyHolder) {
                return _buildKeyHolderItem(
                  context,
                  keyHolder,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyHolderItem(BuildContext context, KeyHolderInfo keyHolder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF666f62),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        keyHolder.displayName ??
                            (keyHolder.pubkey != null
                                ? Helpers.encodeBech32(keyHolder.pubkey!, 'npub')
                                : 'Unknown'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFd2d7bf),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
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
                ] else if (keyHolder.status != null) ...[
                  Text(
                    keyHolder.status!.label,
                    style: TextStyle(
                      color: const Color(0xFFd2d7bf).withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extract key holders from lockbox shard data
  List<KeyHolderInfo> _extractKeyHolders(Lockbox lockbox, String? currentPubkey) {
    // NEW: Try backupConfig first (owner will have this)
    if (lockbox.backupConfig != null) {
      final keyHolders = lockbox.backupConfig!.keyHolders.map((kh) {
        final isCurrentUser = currentPubkey != null && kh.pubkey == currentPubkey;
        final displayName = isCurrentUser ? 'You (${kh.displayName})' : kh.displayName;
        return KeyHolderInfo(
          pubkey: kh.pubkey,
          displayName: displayName,
          isOwner: kh.pubkey != null && kh.pubkey == lockbox.ownerPubkey,
          status: kh.status, // Use actual status from KeyHolder model
        );
      }).toList();

      // Sort: owner first, then others
      keyHolders.sort((a, b) {
        if (a.isOwner && !b.isOwner) return -1;
        if (!a.isOwner && b.isOwner) return 1;
        return 0;
      });

      return keyHolders;
    }

    // FALLBACK: Use shard peers (key holder perspective)
    if (lockbox.shards.isEmpty) {
      return [];
    }

    final shard = lockbox.shards.first;
    final keyHolders = <KeyHolderInfo>[];

    // Add owner first if ownerName is available
    if (shard.ownerName != null) {
      final isCurrentUser = currentPubkey != null && shard.creatorPubkey == currentPubkey;
      final ownerDisplayName = isCurrentUser ? 'You (${shard.ownerName})' : shard.ownerName;
      keyHolders.add(KeyHolderInfo(
        pubkey: shard.creatorPubkey,
        displayName: ownerDisplayName,
        isOwner: true,
        status: KeyHolderStatus.holdingKey,
      ));
    }

    // Add peers (key holders) - now a list of maps with name and pubkey
    if (shard.peers != null) {
      for (final peer in shard.peers!) {
        final peerPubkey = peer['pubkey'];
        final peerName = peer['name'];
        if (peerPubkey == null) continue;

        final isCurrentUser = currentPubkey != null && peerPubkey == currentPubkey;
        final displayName = isCurrentUser && peerName != null ? 'You ($peerName)' : peerName;

        keyHolders.add(KeyHolderInfo(
          pubkey: peerPubkey,
          displayName: displayName,
          isOwner: peerPubkey == lockbox.ownerPubkey,
          status: KeyHolderStatus.holdingKey, // Default for key holders with shards
        ));
      }
    }

    // Sort: owner first, then others
    keyHolders.sort((a, b) {
      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;
      return 0;
    });

    return keyHolders;
  }
}

/// Data class for key holder information
class KeyHolderInfo {
  final String? pubkey; // Nullable for invited key holders
  final String? displayName;
  final bool isOwner;
  final KeyHolderStatus? status; // Status from KeyHolder model

  KeyHolderInfo({
    this.pubkey,
    this.displayName,
    required this.isOwner,
    this.status,
  });
}
