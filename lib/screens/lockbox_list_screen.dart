import 'package:flutter/material.dart';
import '../models/lockbox.dart';
import '../services/key_service.dart';
import '../services/lockbox_service.dart';
import '../services/logger.dart';
import 'create_lockbox_with_backup_screen.dart';
import 'lockbox_detail_screen.dart';

/// Main list screen showing all lockboxes
class LockboxListScreen extends StatefulWidget {
  const LockboxListScreen({super.key});

  @override
  _LockboxListScreenState createState() => _LockboxListScreenState();
}

class _LockboxListScreenState extends State<LockboxListScreen> {
  String? _currentPublicKey;
  List<Lockbox> _lockboxes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final publicKey = await KeyService.getCurrentPublicKey();
      final lockboxes = await LockboxService.getAllLockboxes();

      if (mounted) {
        setState(() {
          _currentPublicKey = publicKey;
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
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
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
                const SizedBox(height: 6),
                Text(
                  'Public Key: ${_currentPublicKey ?? 'Loading...'}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.grey[700],
                  ),
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
}
