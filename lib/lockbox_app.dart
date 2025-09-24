import 'dart:io';
import 'package:flutter/material.dart';
import 'models/lockbox.dart';
import 'services/key_service.dart';
import 'services/lockbox_service.dart';

void main() {
  runApp(const LockboxApp());
}

class LockboxApp extends StatefulWidget {
  const LockboxApp({super.key});

  @override
  State<LockboxApp> createState() => _LockboxAppState();
}

class _LockboxAppState extends State<LockboxApp> {
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize the Nostr key on app launch
      await KeyService.initializeKey();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to initialize secure storage: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keydex Lockbox',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _isInitializing
          ? const _InitializingScreen()
          : _initError != null
              ? _ErrorScreen(error: _initError!)
              : const LockboxListScreen(),
    );
  }
}

// Loading screen shown during app initialization
class _InitializingScreen extends StatelessWidget {
  const _InitializingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blue[700],
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Keydex...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Setting up secure storage',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Error screen shown if initialization fails
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  exit(0);
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main list screen
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
      print('Error loading data: $e');
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
        backgroundColor: Colors.blue[700],
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
                                backgroundColor: Colors.blue[100],
                                child: Icon(Icons.lock, color: Colors.blue[700]),
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
            MaterialPageRoute(builder: (context) => const CreateLockboxScreen()),
          ).then((_) => _loadData()); // Refresh when returning
        },
        backgroundColor: Colors.blue[700],
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

// Detail/view screen
class LockboxDetailScreen extends StatelessWidget {
  final String lockboxId;

  const LockboxDetailScreen({super.key, required this.lockboxId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lockbox?>(
      future: LockboxService.getLockbox(lockboxId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final lockbox = snapshot.data;
        if (lockbox == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lockbox Not Found')),
            body: const Center(child: Text('This lockbox no longer exists.')),
          );
        }

        return _buildLockboxDetail(context, lockbox);
      },
    );
  }

  Widget _buildLockboxDetail(BuildContext context, Lockbox lockbox) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lockbox.name),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditLockboxScreen(lockboxId: lockbox.id),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, lockbox);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created ${_formatDate(lockbox.createdAt)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${lockbox.content.length} characters',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      lockbox.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Lockbox lockbox) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lockbox'),
        content: Text(
            'Are you sure you want to delete "${lockbox.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await LockboxService.deleteLockbox(lockbox.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Create new lockbox screen
class CreateLockboxScreen extends StatefulWidget {
  const CreateLockboxScreen({super.key});

  @override
  _CreateLockboxScreenState createState() => _CreateLockboxScreenState();
}

class _CreateLockboxScreenState extends State<CreateLockboxScreen> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lockbox'),
        backgroundColor: Colors.blue[700],
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
                  hintText: 'Give your lockbox a memorable name',
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
                    hintText:
                        'Enter your sensitive text here...\n\nThis content will be encrypted and stored securely.',
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
        final newLockbox = Lockbox(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          content: _contentController.text,
          createdAt: DateTime.now(),
        );

        await LockboxService.addLockbox(newLockbox);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lockbox "${newLockbox.name}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save lockbox: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Edit existing lockbox screen
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
        _contentController.text = lockbox.content;
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
        backgroundColor: Colors.blue[700],
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
