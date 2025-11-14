import 'package:flutter/material.dart';

/// Stub dialog for file replacement
/// TODO: Implement file replacement dialog with file picker and confirmation
class FileReplacementDialog extends StatelessWidget {
  final String fileName; // TODO: Use LockboxFile model when created

  const FileReplacementDialog({
    super.key,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Replace File'),
      content: Text('Replace $fileName?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // TODO: Implement file picker and replacement logic
            Navigator.of(context).pop(true);
          },
          child: const Text('Replace'),
        ),
      ],
    );
  }

  static Future<bool?> show(BuildContext context, String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => FileReplacementDialog(fileName: fileName),
    );
  }
}

