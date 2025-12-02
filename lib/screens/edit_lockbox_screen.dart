import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../widgets/lockbox_content_form.dart';
import '../widgets/lockbox_content_save_mixin.dart';

/// Edit existing lockbox screen
class EditLockboxScreen extends ConsumerStatefulWidget {
  final String lockboxId;

  const EditLockboxScreen({super.key, required this.lockboxId});

  @override
  ConsumerState<EditLockboxScreen> createState() => _EditLockboxScreenState();
}

class _EditLockboxScreenState extends ConsumerState<EditLockboxScreen>
    with LockboxContentSaveMixin {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Lockbox? _lockbox;

  @override
  void initState() {
    super.initState();
    _loadLockbox();
  }

  Future<void> _loadLockbox() async {
    final repository = ref.read(lockboxRepositoryProvider);
    final lockbox = await repository.getLockbox(widget.lockboxId);
    if (mounted && lockbox != null) {
      setState(() {
        _lockbox = lockbox;
        _nameController.text = lockbox.name;
        _contentController.text = lockbox.content ?? '';
        _ownerNameController.text = lockbox.ownerName ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lockbox == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vault Not Found')),
        body: const Center(child: Text('This vault no longer exists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vault'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => _saveLockbox(),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: LockboxContentForm(
        formKey: _formKey,
        nameController: _nameController,
        contentController: _contentController,
        ownerNameController: _ownerNameController,
        contentHintText: 'Enter your sensitive text here...',
      ),
    );
  }

  Future<void> _saveLockbox() async {
    final savedId = await saveLockbox(
      formKey: _formKey,
      name: _nameController.text,
      content: _contentController.text,
      lockboxId: widget.lockboxId,
      ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
    );

    if (savedId != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vault "${_nameController.text.trim()}" updated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
