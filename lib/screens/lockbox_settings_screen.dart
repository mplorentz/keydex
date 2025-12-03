import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/debug_info_sheet.dart';
import 'relay_management_screen.dart';

/// Settings screen for lockbox, containing debug menu and relay management
class LockboxSettingsScreen extends ConsumerWidget {
  const LockboxSettingsScreen({super.key});

  void _showDebugInfo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DebugInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainer,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // Debug Menu Section
                  Text(
                    'Debug',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.bug_report,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    title: const Text('Debug Information'),
                    subtitle: const Text('View debug info and clear data'),
                    onTap: () => _showDebugInfo(context, ref),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  // Relay Management Section
                  Text(
                    'Relay Management',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.wifi,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    title: const Text('Relay Management'),
                    subtitle: const Text('Manage Nostr relay configurations'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RelayManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
