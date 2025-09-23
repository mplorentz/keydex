import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../contracts/lockbox_service.dart';
import 'edit_lockbox_screen.dart';

class LockboxDetailScreen extends StatefulWidget {
  final String lockboxId;
  final String lockboxName;

  const LockboxDetailScreen({
    super.key,
    required this.lockboxId,
    required this.lockboxName,
  });

  @override
  State<LockboxDetailScreen> createState() => _LockboxDetailScreenState();
}

class _LockboxDetailScreenState extends State<LockboxDetailScreen> {
  LockboxContent? _lockboxContent;
  bool _isLoading = true;
  bool _isContentVisible = false;

  @override
  void initState() {
    super.initState();
    _loadLockboxContent();
  }

  Future<void> _loadLockboxContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual LockboxService implementation
      // For now, show sample data
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _lockboxContent = (
          id: widget.lockboxId,
          name: widget.lockboxName,
          content: 'Sample encrypted content',
          createdAt: DateTime.now(),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lockbox: $e')),
        );
      }
    }
  }

  void _toggleContentVisibility() {
    setState(() {
      _isContentVisible = !_isContentVisible;
    });
  }

  void _copyToClipboard() {
    if (_lockboxContent != null) {
      Clipboard.setData(ClipboardData(text: _lockboxContent!.content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content copied to clipboard')),
      );
    }
  }

  void _navigateToEdit() async {
    if (_lockboxContent == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditLockboxScreen(
          lockboxId: widget.lockboxId,
          initialName: _lockboxContent!.name,
          initialContent: _lockboxContent!.content,
        ),
      ),
    );

    if (result == true) {
      _loadLockboxContent();
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lockbox'),
        content: const Text(
          'Are you sure you want to permanently delete this lockbox? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteLockbox();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLockbox() async {
    try {
      // TODO: Replace with actual LockboxService implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lockbox deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting lockbox: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lockboxName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _lockboxContent != null ? _navigateToEdit : null,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lockboxContent == null
              ? const Center(
                  child: Text('Failed to load lockbox content'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created: ${_formatDate(_lockboxContent!.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Content:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Encrypted Content',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _isContentVisible 
                                              ? Icons.visibility_off 
                                              : Icons.visibility,
                                          ),
                                          onPressed: _toggleContentVisibility,
                                          tooltip: _isContentVisible 
                                            ? 'Hide content' 
                                            : 'Show content',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy),
                                          onPressed: _isContentVisible ? _copyToClipboard : null,
                                          tooltip: 'Copy to clipboard',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        _isContentVisible 
                                          ? _lockboxContent!.content
                                          : '•' * 50,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          color: _isContentVisible 
                                            ? Colors.black87 
                                            : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}