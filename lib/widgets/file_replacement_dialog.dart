import 'package:flutter/material.dart';
import '../models/lockbox_file.dart';

/// Dialog for confirming file replacement
class FileReplacementDialog extends StatelessWidget {
  final LockboxFile existingFile;

  const FileReplacementDialog({
    super.key,
    required this.existingFile,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Replace File?'),
      content: Text(
        'A file named "${existingFile.name}" already exists. Do you want to replace it with the new file?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Replace'),
        ),
      ],
    );
  }

  static Future<bool?> show(BuildContext context, LockboxFile existingFile) {
    return showDialog<bool>(
      context: context,
      builder: (context) => FileReplacementDialog(existingFile: existingFile),
    );
  }
}
