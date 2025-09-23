// Edit Lockbox Screen - Form for editing existing lockboxes

import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart';

class EditLockboxScreen extends StatefulWidget {
  static const String routeName = '/edit-lockbox';

  const EditLockboxScreen({
    super.key,
    required this.lockboxId,
    required this.currentName,
    required this.currentContent,
    required this.lockboxService,
  });

  final String lockboxId;
  final String currentName;
  final String currentContent;
  final LockboxService lockboxService;

  @override
  State<EditLockboxScreen> createState() => _EditLockboxScreenState();
}

class _EditLockboxScreenState extends State<EditLockboxScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contentController;
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _contentController = TextEditingController(text: widget.currentContent);
    
    _nameController.addListener(_checkForChanges);
    _contentController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != widget.currentName;
    final contentChanged = _contentController.text != widget.currentContent;
    final newHasChanges = nameChanged || contentChanged;

    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final newName = _nameController.text.trim();
      final newContent = _contentController.text;

      // Update name if changed
      if (newName != widget.currentName) {
        await widget.lockboxService.updateLockboxName(
          lockboxId: widget.lockboxId,
          name: newName,
        );
      }

      // Update content if changed
      if (newContent != widget.currentContent) {
        await widget.lockboxService.updateLockbox(
          lockboxId: widget.lockboxId,
          content: newContent,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Signal successful update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lockbox updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return shouldPop ?? false;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a name for your lockbox';
    }
    if (value.trim().length > 100) {
      return 'Name cannot exceed 100 characters';
    }
    return null;
  }

  String? _validateContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some content to encrypt';
    }
    if (value.length > 4000) {
      return 'Content cannot exceed 4000 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final contentLength = _contentController.text.length;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Lockbox'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _hasChanges ? _saveChanges : null,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Changes indicator
                if (_hasChanges) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text(
                          'You have unsaved changes',
                          style: TextStyle(color: Colors.orange),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _saveChanges,
                          child: const Text('Save Now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Lockbox Name',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 24),

                // Content field
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    hintText: 'Enter the sensitive information you want to protect',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixText: '$contentLength/4000',
                    suffixStyle: TextStyle(
                      color: contentLength > 3900
                          ? Colors.orange
                          : contentLength > 4000
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                  validator: _validateContent,
                  maxLines: 8,
                  maxLength: 4000,
                  enabled: !_isLoading,
                  onChanged: (value) {
                    setState(() {}); // Update character counter
                  },
                ),

                const SizedBox(height: 24),

                // Information card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Information',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Changes will be encrypted with the same security\n'
                          '• Old versions are not kept for security reasons\n'
                          '• Maximum content length is 4,000 characters\n'
                          '• Remember to save your changes before leaving',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || !_hasChanges) ? null : _saveChanges,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () async {
                          if (_hasChanges) {
                            final shouldDiscard = await _onWillPop();
                            if (shouldDiscard && mounted) {
                              Navigator.of(context).pop();
                            }
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}