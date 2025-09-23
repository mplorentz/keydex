// Lockbox Detail Screen - Shows decrypted content of a specific lockbox

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../contracts/lockbox_service.dart';
import 'edit_lockbox_screen.dart';

class LockboxDetailScreen extends StatefulWidget {
  static const String routeName = '/lockbox-detail';

  const LockboxDetailScreen({
    super.key,
    required this.lockboxId,
    required this.lockboxService,
  });

  final String lockboxId;
  final LockboxService lockboxService;

  @override
  State<LockboxDetailScreen> createState() => _LockboxDetailScreenState();
}

class _LockboxDetailScreenState extends State<LockboxDetailScreen> {
  LockboxContent? _lockboxContent;
  bool _isLoading = true;
  bool _contentVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLockboxContent();
  }

  Future<void> _loadLockboxContent() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final content = await widget.lockboxService.getLockboxContent(widget.lockboxId);
      
      setState(() {
        _lockboxContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_lockboxContent?.content != null) {
      await Clipboard.setData(ClipboardData(text: _lockboxContent!.content));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content copied to clipboard'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteLockbox() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Lockbox'),
            content: Text(
              'Are you sure you want to delete "${_lockboxContent?.name ?? 'this lockbox'}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await widget.lockboxService.deleteLockbox(widget.lockboxId);
        
        if (mounted) {
          Navigator.of(context).pop(true); // Signal that lockbox was deleted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lockbox deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete lockbox: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lockboxContent?.name ?? 'Lockbox'),
        actions: [
          if (_lockboxContent != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed(
                  EditLockboxScreen.routeName,
                  arguments: {
                    'lockboxId': widget.lockboxId,
                    'currentName': _lockboxContent!.name,
                    'currentContent': _lockboxContent!.content,
                  },
                );
                if (result == true) {
                  await _loadLockboxContent();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteLockbox,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _lockboxContent != null
                  ? _buildContentView()
                  : const Center(child: Text('No content available')),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Lockbox',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLockboxContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    final content = _lockboxContent!;
    final characterCount = content.content.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lockbox info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Text(
                        'Lockbox Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name', content.name),
                  _buildInfoRow('Created', _formatDateTime(content.createdAt)),
                  _buildInfoRow('Size', '$characterCount characters'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Content card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_open),
                      const SizedBox(width: 8),
                      Text(
                        'Decrypted Content',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _contentVisible ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _contentVisible = !_contentVisible;
                          });
                        },
                        tooltip: _contentVisible ? 'Hide content' : 'Show content',
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: _contentVisible ? _copyToClipboard : null,
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_contentVisible) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        content.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_off, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Content hidden for security',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the eye icon to reveal',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).pushNamed(
                      EditLockboxScreen.routeName,
                      arguments: {
                        'lockboxId': widget.lockboxId,
                        'currentName': content.name,
                        'currentContent': content.content,
                      },
                    );
                    if (result == true) {
                      await _loadLockboxContent();
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _contentVisible ? _copyToClipboard : null,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Security notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This content is encrypted using NIP-44 encryption and stored securely on your device.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}