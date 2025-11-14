import 'package:flutter/material.dart';

/// Stub widget for displaying selected files in a lockbox
/// TODO: Implement file list display with names, sizes, and icons
class LockboxFileList extends StatelessWidget {
  final List<dynamic> files; // TODO: Change to List<LockboxFile> when model is created

  const LockboxFileList({
    super.key,
    this.files = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (files.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No files selected',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Files',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...files.map((file) => ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text('File ${files.indexOf(file) + 1}'),
                subtitle: const Text('Size: 0 KB'),
              )),
        ],
      ),
    );
  }
}

