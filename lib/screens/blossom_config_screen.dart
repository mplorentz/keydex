import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';

/// Screen for configuring Blossom servers for temporary file storage
/// 
/// STUB: This is a placeholder implementation for Phase 3.2
/// Full implementation will be added in Phase 3.6 (T032)
class BlossomConfigScreen extends ConsumerWidget {
  const BlossomConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blossom Servers'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStubServerCard(context, 'localhost:10548', isDefault: true),
                const SizedBox(height: 8),
                _buildStubServerCard(context, 'example.com:10548'),
                const SizedBox(height: 16),
                const Text(
                  'STUB: Full Blossom server configuration UI coming in Phase 3.6\n\n'
                  'Features:\n'
                  '• Add/edit/delete servers\n'
                  '• Test connection\n'
                  '• Set default server\n'
                  '• Server status indicators',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          RowButton(
            onPressed: () => Navigator.pop(context),
            icon: Icons.check,
            text: 'Done',
          ),
        ],
      ),
    );
  }

  Widget _buildStubServerCard(BuildContext context, String serverUrl, {bool isDefault = false}) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.storage,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(serverUrl),
        subtitle: Text(isDefault ? 'Default server' : 'Available'),
        trailing: Icon(
          Icons.check_circle,
          color: isDefault ? theme.primaryColor : theme.colorScheme.onSurfaceVariant.withAlpha(102),
        ),
      ),
    );
  }
}

