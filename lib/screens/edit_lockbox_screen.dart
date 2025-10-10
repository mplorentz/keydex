import 'package:flutter/material.dart';
import '../models/lockbox.dart';
import '../services/lockbox_service.dart';

/// Edit existing lockbox screen
class EditLockboxScreen extends StatefulWidget {
  final String lockboxId;

  const EditLockboxScreen({super.key, required this.lockboxId});

  @override
  _EditLockboxScreenState createState() => _EditLockboxScreenState();
}

class _EditLockboxScreenState extends State<EditLockboxScreen> {
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
    final lockbox = await LockboxService.getLockbox(widget.lockboxId);
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
        backgroundColor: Theme.of(context).primaryColor,
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
                    hintText: 'Enter your sensitive text here...',
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
        await LockboxService.updateLockbox(
          widget.lockboxId,
          _nameController.text.trim(),
          _contentController.text,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lockbox "${_nameController.text.trim()}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update lockbox: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
