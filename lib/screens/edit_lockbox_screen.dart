import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../widgets/lockbox_content_form.dart';

/// Edit existing lockbox screen
class EditLockboxScreen extends ConsumerStatefulWidget {
  final String lockboxId;

  const EditLockboxScreen({super.key, required this.lockboxId});

  @override
  ConsumerState<EditLockboxScreen> createState() => _EditLockboxScreenState();
}

class _EditLockboxScreenState extends ConsumerState<EditLockboxScreen> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
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
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lockbox == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lockbox Not Found')),
        body: const Center(child: Text('This lockbox no longer exists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lockbox'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => _saveLockbox(),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: LockboxContentForm(
        formKey: _formKey,
        nameController: _nameController,
        contentController: _contentController,
        contentHintText: 'Enter your sensitive text here...',
      ),
    );
  }

  Future<void> _saveLockbox() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _updateLockboxInRepository();
      _showSuccessAndClose();
    } catch (e) {
      _showError('Failed to update lockbox: ${e.toString()}');
    }
  }

  Future<void> _updateLockboxInRepository() async {
    final repository = ref.read(lockboxRepositoryProvider);
    await repository.updateLockbox(
      widget.lockboxId,
      _nameController.text.trim(),
      _contentController.text,
    );
  }

  void _showSuccessAndClose() {
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lockbox "${_nameController.text.trim()}" updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
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
