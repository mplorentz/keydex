import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_initialization.dart';
import '../providers/key_provider.dart';
import 'lockbox_list_screen.dart';
import 'login_screen.dart';
import 'account_created_screen.dart';

/// Screen showing three account setup options:
/// - Create Account: Generate new Nostr key
/// - Login: Import existing key
/// - Continue Without Account: Silent key generation
class AccountChoiceScreen extends ConsumerWidget {
  const AccountChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Create Account Card
              _AccountChoiceCard(
                icon: Icons.person_add,
                title: 'Create Account',
                description: 'Generate a new Nostr identity and back it up',
                onTap: () async {
                  // Generate new key
                  final loginService = ref.read(loginServiceProvider);
                  final keyPair = await loginService.generateAndStoreNostrKey();

                  // Navigate to AccountCreatedScreen with nsec format
                  if (context.mounted && keyPair.privateKeyBech32 != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountCreatedScreen(
                          nsec: keyPair.privateKeyBech32!,
                          isImported: false,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Login Card
              _AccountChoiceCard(
                icon: Icons.login,
                title: 'Login',
                description: 'Import your existing Nostr key',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Continue Without Account Card
              _AccountChoiceCard(
                icon: Icons.arrow_forward,
                title: 'Continue Without Account',
                description: 'Use the app without a Nostr identity',
                onTap: () async {
                  // Generate key silently
                  final loginService = ref.read(loginServiceProvider);
                  await loginService.initializeKey();

                  // Initialize services
                  await initializeAppServices(ref);

                  // Navigate to main app, clear onboarding stack
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LockboxListScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual card for each account setup option
class _AccountChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AccountChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurface,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
