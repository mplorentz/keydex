import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../services/key_service.dart';
import '../widgets/row_button.dart';
import 'backup_config_screen.dart';

/// Enhanced lockbox creation screen with integrated backup configuration
class LockboxCreateScreen extends ConsumerStatefulWidget {
  const LockboxCreateScreen({super.key});

  @override
  ConsumerState<LockboxCreateScreen> createState() => _LockboxCreateScreenState();
}

class _LockboxCreateScreenState extends ConsumerState<LockboxCreateScreen> {
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
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
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
                              color: _contentController.text.length > 4000
                                  ? Colors.red
                                  : Colors.grey[600],
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
          ),
          RowButton(
            onPressed: () => _saveLockbox(),
            icon: Icons.arrow_forward,
            text: 'Next',
          ),
        ],
      ),
    );
  }

  Future<void> _saveLockbox() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final lockbox = await _createLockbox();
      await _saveLockboxToRepository(lockbox);
      await _navigateToBackupConfig(lockbox.id);
    } catch (e) {
      _showError('Failed to save lockbox: ${e.toString()}');
    }
  }

  Future<Lockbox> _createLockbox() async {
    final currentPubkey = await KeyService.getCurrentPublicKey();
    if (currentPubkey == null) {
      throw Exception('Unable to get current user public key');
    }

    return Lockbox(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      content: _contentController.text,
      createdAt: DateTime.now(),
      ownerPubkey: currentPubkey,
    );
  }

  Future<void> _saveLockboxToRepository(Lockbox lockbox) async {
    final repository = ref.read(lockboxRepositoryProvider);
    await repository.addLockbox(lockbox);
  }

  Future<void> _navigateToBackupConfig(String lockboxId) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupConfigScreen(lockboxId: lockboxId),
      ),
    );

    // After backup configuration is complete, go back to the list screen
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
