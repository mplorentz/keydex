// Lockbox List Screen - Main screen showing all user lockboxes

import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart' as contracts;
import '../models/lockbox.dart';
import '../services/auth_service.dart';
import '../services/lockbox_service.dart';
import '../widgets/lockbox_list_widget.dart';
import 'create_lockbox_screen.dart';
import 'authentication_screen.dart';
import '../src/settings/settings_view.dart';

class LockboxListScreen extends StatefulWidget {
  static const String routeName = '/lockboxes';

  const LockboxListScreen({
    super.key,
    required this.lockboxService,
    required this.authService,
  });

  final LockboxServiceImpl lockboxService;
  final AuthServiceImpl authService;

  @override
  State<LockboxListScreen> createState() => _LockboxListScreenState();
}

class _LockboxListScreenState extends State<LockboxListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LockboxMetadata> _lockboxes = [];
  List<LockboxMetadata> _filteredLockboxes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLockboxes();
    _searchController.addListener(_filterLockboxes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLockboxes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final lockboxes = await widget.lockboxService.getAllLockboxes();
      
      setState(() {
        _lockboxes = lockboxes;
        _filteredLockboxes = lockboxes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load lockboxes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterLockboxes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLockboxes = _lockboxes;
      } else {
        _filteredLockboxes = _lockboxes
            .where((lockbox) => lockbox.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _deleteLockbox(String lockboxId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Lockbox'),
            content: const Text(
              'Are you sure you want to delete this lockbox? This action cannot be undone.',
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
        await widget.lockboxService.deleteLockbox(lockboxId);
        await _loadLockboxes();
        
        if (mounted) {
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

  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );

      if (confirmed == true && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AuthenticationScreen.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lockboxes'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Toggle search functionality is handled by the search field below
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.of(context).pushNamed(SettingsView.routeName);
                  break;
                case 'refresh':
                  _loadLockboxes();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search lockboxes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadLockboxes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Lockbox list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLockboxes.isEmpty
                    ? _buildEmptyState()
                    : LockboxListWidget(
                        lockboxes: _filteredLockboxes,
                        onTap: (lockbox) {
                          Navigator.of(context).pushNamed(
                            '/lockbox-detail',
                            arguments: {'lockboxId': lockbox.id},
                          );
                        },
                        onDelete: _deleteLockbox,
                        onRefresh: _loadLockboxes,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed(
            CreateLockboxScreen.routeName,
          );
          if (result == true) {
            await _loadLockboxes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Lockbox'),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No lockboxes found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No lockboxes yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first secure lockbox',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                CreateLockboxScreen.routeName,
              );
              if (result == true) {
                await _loadLockboxes();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Lockbox'),
          ),
        ],
      ),
    );
  }
}