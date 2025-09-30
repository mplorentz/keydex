import 'package:flutter/material.dart';
import '../models/lockbox.dart';
import '../services/lockbox_service.dart';
import 'backup_config_screen.dart';

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
  bool _enableBackup = false;

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
        title: const Text('Create Lockbox'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _saveLockbox(),
            child: const Text('Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 24),

              // Backup Configuration Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.backup, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Distributed Backup',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue[700],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a distributed backup of this lockbox using Shamir\'s Secret Sharing. '
                        'Your data will be split into multiple encrypted shares and distributed to trusted contacts via Nostr.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Enable Distributed Backup'),
                        subtitle:
                            const Text('Split lockbox into encrypted shares for trusted contacts'),
                        value: _enableBackup,
                        onChanged: (value) {
                          setState(() {
                            _enableBackup = value;
                          });
                        },
                        secondary: Icon(
                          _enableBackup ? Icons.security : Icons.security_outlined,
                          color: _enableBackup ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (_enableBackup) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to backup configuration screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BackupConfigScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Configure Backup Settings'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
        final newLockbox = Lockbox(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          content: _contentController.text,
          createdAt: DateTime.now(),
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
