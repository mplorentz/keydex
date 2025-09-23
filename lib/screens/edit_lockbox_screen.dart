import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart';

class EditLockboxScreen extends StatefulWidget {
  final String lockboxId;
  final String initialName;
  final String initialContent;

  const EditLockboxScreen({
    super.key,
    required this.lockboxId,
    required this.initialName,
    required this.initialContent,
  });

  @override
  State<EditLockboxScreen> createState() => _EditLockboxScreenState();
}

class _EditLockboxScreenState extends State<EditLockboxScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  bool _isUpdating = false;
  bool _isContentVisible = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _contentController = TextEditingController(text: widget.initialContent);
    
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
    final hasChanges = _nameController.text != widget.initialName ||
                      _contentController.text != widget.initialContent;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _toggleContentVisibility() {
    setState(() {
      _isContentVisible = !_isContentVisible;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<void> _updateLockbox() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // TODO: Replace with actual LockboxService implementation
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lockbox updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating lockbox: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Lockbox'),
          actions: [
            if (_hasChanges && !_isUpdating)
              TextButton(
                onPressed: _updateLockbox,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit your encrypted lockbox content.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Lockbox Name',
                    hintText: 'Enter a name for your lockbox',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for your lockbox';
                    }
                    if (value.trim().length > 50) {
                      return 'Name must be 50 characters or less';
                    }
                    return null;
                  },
                  enabled: !_isUpdating,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Content',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: Icon(
                        _isContentVisible 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                      ),
                      onPressed: _toggleContentVisibility,
                      tooltip: _isContentVisible 
                        ? 'Hide content' 
                        : 'Show content',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Enter the text you want to encrypt and store...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(16),
                      suffixText: '${_contentController.text.length}/10000',
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    obscureText: !_isContentVisible,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter some content to encrypt';
                      }
                      if (value.length > 10000) {
                        return 'Content must be 10,000 characters or less';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {}); // Update character count
                    },
                    enabled: !_isUpdating,
                  ),
                ),
                const SizedBox(height: 16),
                if (_hasChanges) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have unsaved changes that will be re-encrypted.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isUpdating)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Updating encrypted lockbox...'),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _updateLockbox : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update Encrypted Lockbox'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}