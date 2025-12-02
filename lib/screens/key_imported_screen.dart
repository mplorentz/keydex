import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button_stack.dart';
import 'lockbox_list_screen.dart';
import 'vault_explainer_screen.dart';

/// Screen shown after successfully importing a Nostr key
/// Offers optional backup in Horcrux Vault
class KeyImportedScreen extends ConsumerWidget {
  final String nsec;

  const KeyImportedScreen({
    super.key,
    required this.nsec,
  });

  /// Navigate to vault creation flow with nsec pre-filled
  void _backupKeyInVault(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => VaultExplainerScreen(
          initialName: 'Nostr Key Backup',
          initialContent: nsec,
        ),
      ),
      (route) => false, // Clear all previous routes
    );
  }

  /// Skip backup and go to main app
  void _continueToApp(BuildContext context) {
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
      // No back button - user must choose backup or continue
      body: SafeArea(
        bottom: false, // Let RowButtonStack handle bottom safe area
        child: Column(
          children: [
            const SizedBox(height: 64),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Success icon
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Key Imported Successfully',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Your Nostr key has been imported and is ready to use.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Optional backup info
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can optionally back up your key in a Horcrux Vault for additional security.',
                              style: textTheme.bodyMedium,
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
                  onPressed: () => _continueToApp(context),
                  icon: Icons.arrow_forward,
                  text: 'Continue to App',
                ),
                RowButtonConfig(
                  onPressed: () => _backupKeyInVault(context),
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
