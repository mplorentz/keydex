import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lockbox.dart';
import '../services/key_service.dart';
import '../services/lockbox_service.dart';
import '../services/logger.dart';
import 'create_lockbox_with_backup_screen.dart';
import 'lockbox_detail_screen.dart';
import 'relay_management_screen.dart';
import 'recovery_notification_overlay.dart';

/// Main list screen showing all lockboxes
class LockboxListScreen extends StatefulWidget {
  const LockboxListScreen({super.key});

  @override
  _LockboxListScreenState createState() => _LockboxListScreenState();
}

class _LockboxListScreenState extends State<LockboxListScreen> {
  String? _currentPublicKey;
  String? _currentNpub;
  List<Lockbox> _lockboxes = [];
  bool _isLoading = true;
  StreamSubscription<List<Lockbox>>? _lockboxesSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupLockboxListener();
  }

  @override
  void dispose() {
    _lockboxesSubscription?.cancel();
    super.dispose();
  }

  void _setupLockboxListener() {
    // Listen to lockbox changes and update UI
    _lockboxesSubscription = LockboxService.lockboxesStream.listen((lockboxes) {
      if (mounted) {
        setState(() {
          _lockboxes = lockboxes;
        });
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final publicKey = await KeyService.getCurrentPublicKey();
      final publicKeyBech32 = await KeyService.getCurrentPublicKeyBech32();
      final lockboxes = await LockboxService.getAllLockboxes();

      if (mounted) {
        setState(() {
          _currentPublicKey = publicKey;
          _currentNpub = publicKeyBech32;
          _lockboxes = lockboxes;
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.error('Error loading data', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lockboxes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RelayManagementScreen(),
                ),
              );
            },
            tooltip: 'Scan for Keys',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _lockboxes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No lockboxes yet',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap + to create your first secure lockbox',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _lockboxes.length,
                            itemBuilder: (context, index) {
                              final lockbox = _lockboxes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                                  ),
                                  title: Text(
                                    lockbox.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lockbox.content.length > 50
                                            ? '${lockbox.content.substring(0, 50)}...'
                                            : lockbox.content,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Created ${_formatDate(lockbox.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LockboxDetailScreen(lockboxId: lockbox.id),
                                      ),
                                    ).then((_) => _loadData()); // Refresh when returning
                                  },
                                ),
                              );
                            },
                          ),
                // Recovery notification overlay (inside the Stack)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: RecoveryNotificationOverlay(),
                ),
              ],
            ),
          ),
          // Debug section showing current user's public key
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'DEBUG INFO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Npub
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Npub (bech32):',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentNpub ?? 'Loading...',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _currentNpub != null
                          ? () => _copyToClipboard(_currentNpub!, 'Npub')
                          : null,
                      tooltip: 'Copy npub',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Hex Public Key
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Public Key (hex):',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentPublicKey ?? 'Loading...',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _currentPublicKey != null
                          ? () => _copyToClipboard(_currentPublicKey!, 'Hex key')
                          : null,
                      tooltip: 'Copy hex key',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateLockboxWithBackupScreen()),
          ).then((_) => _loadData()); // Refresh when returning
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
