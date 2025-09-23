import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart';

class CreateLockboxScreen extends StatefulWidget {
  const CreateLockboxScreen({super.key});

  @override
  State<CreateLockboxScreen> createState() => _CreateLockboxScreenState();
}

class _CreateLockboxScreenState extends State<CreateLockboxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isCreating = false;
  bool _isContentVisible = true;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleContentVisibility() {
    setState(() {
      _isContentVisible = !_isContentVisible;
    });
  }

  Future<void> _createLockbox() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // TODO: Replace with actual LockboxService implementation
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lockbox created successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating lockbox: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lockbox'),
        actions: [
          if (!_isCreating)
            TextButton(
              onPressed: _createLockbox,
              child: const Text('Create'),
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
                'Create a new encrypted lockbox to securely store your text content.',
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
                enabled: !_isCreating,
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
                  enabled: !_isCreating,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your content will be encrypted using NIP-44 encryption before being stored.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isCreating)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Creating encrypted lockbox...'),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createLockbox,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Create Encrypted Lockbox'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}