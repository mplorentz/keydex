import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';
import '../widgets/lockbox_content_form.dart';
import '../widgets/lockbox_content_save_mixin.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Vault'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LockboxContentForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    contentController: _contentController,
                    ownerNameController: _ownerNameController,
                  ),
                ],
              ),
            ),
          ),
          RowButton(
            onPressed: () => _saveLockbox(),
            icon: Icons.arrow_forward,
            text: 'Next',
            addBottomSafeArea: true,
          ),
        ],
      ),
    );
  }

  Future<void> _saveLockbox() async {
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

    // After backup configuration is complete, pop all the way back to the list screen
    // This pops both LockboxCreateScreen and VaultExplainerScreen
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }
}
