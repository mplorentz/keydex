import 'package:flutter/material.dart';
import '../models/lockbox.dart';
import '../services/lockbox_service.dart';
import '../services/key_service.dart';

/// Enhanced lockbox creation screen with integrated backup configuration
class CreateLockboxWithBackupScreen extends StatefulWidget {
  const CreateLockboxWithBackupScreen({super.key});

  @override
  State<CreateLockboxWithBackupScreen> createState() => _CreateLockboxWithBackupScreenState();
}

class _CreateLockboxWithBackupScreenState extends State<CreateLockboxWithBackupScreen> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Lockbox'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => _saveLockbox(),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Lockbox Name',
                  hintText: 'Give your lockbox a memorable name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name for your lockbox';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText:
                        'Enter your sensitive text here...\n\nThis content will be encrypted and stored securely.',
                    border: OutlineInputBorder(),
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
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Content limit: ${_contentController.text.length}/4000 characters',
                      style: TextStyle(
                        color:
                            _contentController.text.length > 4000 ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveLockbox() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user's public key for ownership
        final currentPubkey = await KeyService.getCurrentPublicKey();
        if (currentPubkey == null) {
          throw Exception('Unable to get current user public key');
        }

        final newLockbox = Lockbox(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          content: _contentController.text,
          createdAt: DateTime.now(),
          ownerPubkey: currentPubkey,
        );

        await LockboxService.addLockbox(newLockbox);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lockbox "${newLockbox.name}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save lockbox: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
