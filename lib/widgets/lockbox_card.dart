import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/lockbox.dart';
import '../providers/key_provider.dart';
import '../screens/lockbox_detail_screen.dart';

class LockboxCard extends ConsumerWidget {
  final Lockbox lockbox;

  const LockboxCard({super.key, required this.lockbox});

  String _getOwnerDisplayText(String? currentPubkey) {
    if (currentPubkey == null) {
      return Helpers.encodeBech32(lockbox.ownerPubkey, 'npub');
    }
    return currentPubkey == lockbox.ownerPubkey
        ? 'You'
        : Helpers.encodeBech32(lockbox.ownerPubkey, 'npub');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Determine icon based on lockbox state
    IconData stateIcon;

    switch (lockbox.state) {
      case LockboxState.recovery:
        stateIcon = Icons.refresh;
        break;
      case LockboxState.owned:
        stateIcon = Icons.lock_open;
        break;
      case LockboxState.keyHolder:
        stateIcon = Icons.key;
        break;
    }

    // Get current user's pubkey and determine owner display
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);
    final currentPubkey = currentPubkeyAsync.maybeWhen(
      data: (pubkey) => pubkey,
      orElse: () => null,
    );
    final ownerDisplayText = _getOwnerDisplayText(currentPubkey);
    final isOwnedByCurrentUser = currentPubkey == lockbox.ownerPubkey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LockboxDetailScreen(lockboxId: lockbox.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icon container with state-based icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stateIcon,
                  color: theme.scaffoldBackgroundColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lockbox.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Owner: $ownerDisplayText",
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: isOwnedByCurrentUser ? null : 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Date on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
