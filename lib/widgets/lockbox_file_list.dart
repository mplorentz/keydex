import 'package:flutter/material.dart';
import '../models/lockbox_file.dart';

/// Widget for displaying files in a lockbox
class LockboxFileList extends StatelessWidget {
  final List<LockboxFile> files;
  final Function(LockboxFile)? onRemove;

  const LockboxFileList({
    super.key,
    required this.files,
    this.onRemove,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_library;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

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
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Selected Files (${files.length})',
            style: theme.textTheme.titleMedium,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              leading: Icon(_getFileIcon(file.mimeType)),
              title: Text(
                file.name,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_formatFileSize(file.sizeBytes)),
              trailing: onRemove != null
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onRemove!(file),
                      tooltip: 'Remove file',
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}

