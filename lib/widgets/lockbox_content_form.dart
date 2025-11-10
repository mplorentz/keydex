import 'package:flutter/material.dart';

/// Reusable form widget for creating and editing lockbox content
class LockboxContentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController contentController;
  final String? nameHintText;
  final String? contentHintText;

  const LockboxContentForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.contentController,
    this.nameHintText = 'Give your lockbox a memorable name',
    this.contentHintText =
        'Enter your sensitive text here...\n\nThis content will be encrypted and stored securely.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Vault Name',
                hintText: nameHintText,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name for your vault';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Vault Contents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextFormField(
                controller: contentController,
                decoration: InputDecoration(
                  hintText: contentHintText,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                validator: (value) {
                  if (value != null && value.length > 4000) {
                    return 'Content cannot exceed 4000 characters (currently ${value.length})';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: contentController,
              builder: (context, value, child) {
                final length = value.text.length;
                return Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Content limit: $length/4000 characters',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: length > 4000
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
