import 'package:flutter/material.dart';

/// Widget to display a list of files attached to a lockbox
/// 
/// STUB: This is a placeholder implementation for Phase 3.2
/// Full implementation will be added in Phase 3.6 (T033)
class LockboxFileList extends StatelessWidget {
  final List<String> fileNames;

  const LockboxFileList({
    super.key,
    this.fileNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (fileNames.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
              ),
              const SizedBox(height: 12),
              Text(
                'No files selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fileNames.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(
            Icons.insert_drive_file,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(fileNames[index]),
          subtitle: const Text('STUB: Size and details coming in Phase 3.6'),
        );
      },
    );
  }
}

