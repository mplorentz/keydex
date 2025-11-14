import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';
import '../widgets/lockbox_content_save_mixin.dart';
import '../widgets/lockbox_file_list.dart';
import 'backup_config_screen.dart';

/// Enhanced lockbox creation screen with integrated backup configuration
class LockboxCreateScreen extends ConsumerStatefulWidget {
  const LockboxCreateScreen({super.key});

  @override
  ConsumerState<LockboxCreateScreen> createState() => _LockboxCreateScreenState();
}

class _LockboxCreateScreenState extends ConsumerState<LockboxCreateScreen>
    with LockboxContentSaveMixin {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<dynamic> _selectedFiles = []; // TODO: Change to List<LockboxFile> when model is created

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Vault'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                          labelText: 'Vault Name',
                          hintText: 'Give your lockbox a memorable name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name for your vault';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(
                          labelText: "Your name",
                          hintText: 'Enter your name as the vault owner',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
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
                      // Stub file picker button (replaces content editor)
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement file picker integration
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File picker (stub)')),
                          );
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Select Files'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LockboxFileList(files: _selectedFiles),
                    ],
                  ),
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
    // TODO: Update to use files instead of content when models/services are implemented
    final lockboxId = await saveLockbox(
      formKey: _formKey,
      name: _nameController.text,
      content: _contentController.text,
      ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
    );

    if (lockboxId != null && mounted) {
      await _navigateToBackupConfig(lockboxId);
    }
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
}
