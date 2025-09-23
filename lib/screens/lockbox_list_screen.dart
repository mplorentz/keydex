import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart';
import '../widgets/lockbox_list_widget.dart';
import 'create_lockbox_screen.dart';
import 'settings_screen.dart';

class LockboxListScreen extends StatefulWidget {
  const LockboxListScreen({super.key});

  @override
  State<LockboxListScreen> createState() => _LockboxListScreenState();
}

class _LockboxListScreenState extends State<LockboxListScreen> {
  List<LockboxMetadata> _lockboxes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLockboxes();
  }

  Future<void> _loadLockboxes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual LockboxService implementation
      // For now, show empty list
      setState(() {
        _lockboxes = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lockboxes: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadLockboxes();
  }

  void _navigateToCreateLockbox() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateLockboxScreen()),
    );
    
    if (result == true) {
      _loadLockboxes();
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keydex Lockboxes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _lockboxes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_open,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No lockboxes yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to create your first lockbox',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : LockboxListWidget(
                    lockboxes: _lockboxes,
                    onRefresh: _onRefresh,
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateLockbox,
        tooltip: 'Create Lockbox',
        child: const Icon(Icons.add),
      ),
    );
  }
}