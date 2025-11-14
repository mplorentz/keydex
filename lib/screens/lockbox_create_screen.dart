import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';
import '../widgets/lockbox_content_save_mixin.dart';
import '../widgets/lockbox_file_list.dart';
import '../providers/file_storage_provider.dart';
import '../providers/blossom_config_provider.dart';
import '../providers/lockbox_provider.dart';
import '../models/lockbox_file.dart';
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
  final _contentController = TextEditingController(); // Kept for compatibility but not used
  final _ownerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<LockboxFile> _selectedFiles = [];
  bool _isUploading = false;

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
                      // File picker button
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickFiles,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.attach_file),
                        label: Text(_isUploading ? 'Uploading...' : 'Select Files'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LockboxFileList(
                        files: _selectedFiles,
                        onRemove: (file) {
                          setState(() {
                            _selectedFiles.remove(file);
                          });
                        },
                      ),
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

  Future<void> _pickFiles() async {
    try {
      final fileStorageService = ref.read(fileStorageServiceProvider);
      final blossomConfigService = ref.read(blossomConfigServiceProvider);

      // Get default Blossom server
      final defaultServer = await blossomConfigService.getDefaultServer();
      if (defaultServer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No Blossom server configured. Please configure a server first.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Pick files
      final pickedFiles = await fileStorageService.pickFiles(allowMultiple: true);
      if (pickedFiles.isEmpty) {
        return; // User cancelled
      }

      // Check total size
      final totalSize = pickedFiles.fold<int>(0, (sum, file) => sum + file.size);
      final currentTotalSize = _selectedFiles.fold<int>(0, (sum, file) => sum + file.sizeBytes);
      if (currentTotalSize + totalSize > 1073741824) { // 1GB
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Total file size exceeds 1GB limit'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Upload files
      setState(() {
        _isUploading = true;
      });

      final uploadedFiles = <LockboxFile>[];
      for (final pickedFile in pickedFiles) {
        try {
          // Generate encryption key (32 bytes) - in real implementation, this would be the lockbox secret
          // For now, generate a temporary key - will be replaced with actual lockbox key during backup
          final encryptionKey = List<int>.generate(32, (i) => i).cast<int>();
          
          final lockboxFile = await fileStorageService.encryptAndUploadFile(
            file: pickedFile,
            encryptionKey: Uint8List.fromList(encryptionKey),
            serverUrl: defaultServer.url,
          );
          uploadedFiles.add(lockboxFile);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading ${pickedFile.name}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      setState(() {
        _selectedFiles.addAll(uploadedFiles);
        _isUploading = false;
      });

      if (mounted && uploadedFiles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${uploadedFiles.length} file(s)')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveLockbox() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final lockboxId = await saveLockbox(
      formKey: _formKey,
      name: _nameController.text,
      content: '', // Deprecated - files used instead
      ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
    );

    if (lockboxId != null && mounted) {
      // Update lockbox with files
      final repository = ref.read(lockboxRepositoryProvider);
      final lockbox = await repository.getLockbox(lockboxId);
      if (lockbox != null) {
        await repository.saveLockbox(lockbox.copyWith(files: _selectedFiles));
      }
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
