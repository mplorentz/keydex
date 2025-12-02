import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../utils/invite_code_utils.dart';
import '../widgets/row_button_stack.dart';
import 'lockbox_detail_screen.dart';
import 'lockbox_list_screen.dart';

/// Screen shown after account creation or import
/// Displays the nsec key and offers backup options
class AccountCreatedScreen extends ConsumerWidget {
  final String nsec;
  final bool isImported;

  const AccountCreatedScreen({
    super.key,
    required this.nsec,
    required this.isImported,
  });

  /// Redact nsec for display: show first 9 and last 6 chars
  String _redactNsec(String nsec) {
    if (nsec.length <= 15) return nsec;
    final start = nsec.substring(0, 9); // "nsec1" + 5 chars
    final end = nsec.substring(nsec.length - 6);
    return '$start...$end';
  }

  /// Create a lockbox with the nsec as content
  Future<void> _backupKeyInVault(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(lockboxRepositoryProvider);
    final loginService = ref.read(loginServiceProvider);

    // Get current user's public key
    final currentPubkey = await loginService.getCurrentPublicKey();
    if (currentPubkey == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No public key available')),
        );
      }
      return;
    }

    // Generate secure ID
    final lockboxId = generateSecureID();

    // Create lockbox with nsec as content
    final lockbox = Lockbox(
      id: lockboxId,
      name: 'Nostr Key Backup',
      content: nsec,
      createdAt: DateTime.now(),
      ownerPubkey: currentPubkey,
    );

    // Save lockbox
    await repository.addLockbox(lockbox);

    // Navigate to detail screen
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LockboxDetailScreen(lockboxId: lockboxId),
        ),
        (route) => false, // Clear all previous routes
      );
    }
  }

  /// Skip backup and go to main app
  void _skipBackup(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LockboxListScreen(),
      ),
      (route) => false, // Clear all previous routes
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // No back button - user must choose backup or skip
      body: SafeArea(
        bottom: false, // Let RowButtonStack handle bottom safe area
        child: Column(
          children: [
            const SizedBox(height: 64),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      isImported ? 'Account Imported' : 'Account Created',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Back up your Nostr key',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),

                    // Redacted nsec display with copy button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _redactNsec(nsec),
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: nsec));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Key copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copy key',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Warning text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: theme.colorScheme.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is your Nostr private key. Anyone with this key can access your account. Back it up securely.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            RowButtonStack(
              buttons: [
                RowButtonConfig(
                  onPressed: () => _skipBackup(context),
                  icon: Icons.skip_next,
                  text: 'Skip for Now',
                ),
                RowButtonConfig(
                  onPressed: () => _backupKeyInVault(context, ref),
                  icon: Icons.backup,
                  text: 'Back Up in Horcrux Vault',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
