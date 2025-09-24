// Create Lockbox Screen - Form for creating new encrypted lockboxes

import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart' as contracts;
import '../services/lockbox_service.dart';

class CreateLockboxScreen extends StatefulWidget {
  static const String routeName = '/create-lockbox';

  const CreateLockboxScreen({
    super.key,
    required this.lockboxService,
  });

  final LockboxServiceImpl lockboxService;

  @override
  State<CreateLockboxScreen> createState() => _CreateLockboxScreenState();
}

class _CreateLockboxScreenState extends State<CreateLockboxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createLockbox() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await widget.lockboxService.createLockbox(
        name: _nameController.text.trim(),
        content: _contentController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Signal successful creation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lockbox created successfully'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lockbox'),
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
              onPressed: _createLockbox,
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
                  hintText: 'Enter a descriptive name',
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
                  labelText: 'Content to Encrypt',
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
                            'Security Information',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Your content will be encrypted using NIP-44 encryption\n'
                        '• The encrypted data is stored locally on this device\n'
                        '• Only you can decrypt and view this information\n'
                        '• Maximum content length is 4,000 characters',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createLockbox,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.security),
                  label: Text(_isLoading ? 'Creating...' : 'Create Encrypted Lockbox'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}