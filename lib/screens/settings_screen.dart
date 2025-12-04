import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/key_provider.dart';
import 'relay_management_screen.dart';

/// Settings screen for app configuration and account management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final publicKeyAsync = ref.watch(currentPublicKeyBech32Provider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Account section
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'Account',
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.account_circle, color: colorScheme.onSurface),
                    title: const Text('Public Key'),
                    subtitle: publicKeyAsync.when(
                      data: (pubkey) => pubkey != null
                          ? Text(
                              pubkey,
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            )
                          : const Text('Not available'),
                      loading: () => const Text('Loading...'),
                      error: (_, __) => const Text('Error loading key'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // App settings section
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'App Settings',
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.wifi, color: colorScheme.onSurface),
                    title: const Text('Relay Management'),
                    subtitle: const Text('Manage Nostr relay configurations'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RelayManagementScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  ListTile(
                    leading: Icon(Icons.bug_report, color: colorScheme.onSurface),
                    title: const Text('Debug Info'),
                    subtitle: const Text('View app debug information'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface),
                    onTap: () {
                      // Debug info would be shown here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debug info not yet implemented')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
