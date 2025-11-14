import 'package:flutter/material.dart';

/// Dialog for replacing a file in a lockbox
/// 
/// STUB: This is a placeholder implementation for Phase 3.2
/// Full implementation will be added in Phase 3.6 (T035)
class FileReplacementDialog extends StatelessWidget {
  final String currentFileName;
  final VoidCallback onReplace;
  final VoidCallback onCancel;

  const FileReplacementDialog({
    super.key,
    required this.currentFileName,
    required this.onReplace,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Replace File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current file: $currentFileName',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            'STUB: File picker will appear here in Phase 3.6',
          ),
          const SizedBox(height: 16),
          const Text(
            'Replacing a file will:\n'
            '• Upload the new file to Blossom\n'
            '• Redistribute to all key holders\n'
            '• Delete the old file after 48 hours',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onReplace,
          child: const Text('Replace'),
        ),
      ],
    );
  }

  /// Show the file replacement dialog
  static Future<bool?> show(
    BuildContext context, {
    required String currentFileName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => FileReplacementDialog(
        currentFileName: currentFileName,
        onReplace: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }
}

