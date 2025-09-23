import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/key_service.dart';
import '../../services/storage_service.dart';
import '../../screens/authentication_screen.dart';
import 'settings_controller.dart';

/// Displays the various settings that can be customized by the user.
/// Enhanced to include security and data management options.
class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    required this.controller,
    required this.authService,
    required this.keyService,
    required this.storageService,
  });

  static const routeName = '/settings';

  final SettingsController controller;
  final AuthService authService;
  final KeyService keyService;
  final StorageService storageService;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isLoading = false;
  Map<String, dynamic>? _keyInfo;
  int? _storageSize;
  bool? _isAuthDisabled;

  @override
  void initState() {
    super.initState();
    _loadSecurityInfo();
  }

  Future<void> _loadSecurityInfo() async {
    try {
      final keyInfo = await widget.keyService.getKeyInfo();
      final storageSize = await widget.storageService.getStorageSize();
      final isAuthDisabled = await (widget.authService as AuthServiceImpl).isAuthenticationDisabled();

      setState(() {
        _keyInfo = keyInfo;
        _storageSize = storageSize;
        _isAuthDisabled = isAuthDisabled;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _exportKeyBackup() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final backup = await widget.keyService.exportKeyBackup();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Key Backup'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your encryption key backup:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      backup,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ Keep this backup safe! You\'ll need it to recover your lockboxes if you lose access to this device.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export backup: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rotateEncryptionKey() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Rotate Encryption Key'),
            content: const Text(
              'This will generate a new encryption key. Existing lockboxes will remain encrypted with the old key, but new ones will use the new key. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Rotate Key'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        setState(() {
          _isLoading = true;
        });

        await widget.keyService.rotateKey();
        await _loadSecurityInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Encryption key rotated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rotate key: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Clear All Data'),
            content: const Text(
              '⚠️ This will permanently delete all your lockboxes, encryption keys, and settings. This action cannot be undone!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete Everything'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        setState(() {
          _isLoading = true;
        });

        await widget.storageService.clearAllData();
        await (widget.keyService as KeyService).clearKeyPair();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AuthenticationScreen.routeName,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAuthentication() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_isAuthDisabled == true) {
        await (widget.authService as AuthServiceImpl).enableAuthentication();
      } else {
        await widget.authService.disableAuthentication();
      }

      await _loadSecurityInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAuthDisabled == true
                  ? 'Authentication enabled'
                  : 'Authentication disabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle authentication: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatStorageSize(int? size) {
    if (size == null) return 'Unknown';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Theme Settings
                _buildSection(
                  'Appearance',
                  [
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Theme'),
                      subtitle: Text(_getThemeDisplayName(widget.controller.themeMode)),
                      trailing: DropdownButton<ThemeMode>(
                        value: widget.controller.themeMode,
                        onChanged: widget.controller.updateThemeMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Security Settings
                _buildSection(
                  'Security',
                  [
                    ListTile(
                      leading: Icon(
                        _isAuthDisabled == true ? Icons.security_outlined : Icons.security,
                        color: _isAuthDisabled == true ? Colors.orange : Colors.green,
                      ),
                      title: const Text('Biometric Authentication'),
                      subtitle: Text(_isAuthDisabled == true ? 'Disabled' : 'Enabled'),
                      trailing: Switch(
                        value: _isAuthDisabled != true,
                        onChanged: (value) => _toggleAuthentication(),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Encryption Key'),
                      subtitle: Text(
                        _keyInfo?['hasKey'] == true
                            ? 'Key active (${_keyInfo?['keyType'] ?? 'unknown'})'
                            : 'No key found',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('Export Key Backup'),
                      subtitle: const Text('Create a backup of your encryption key'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _keyInfo?['hasKey'] == true ? _exportKeyBackup : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh, color: Colors.orange),
                      title: const Text('Rotate Encryption Key'),
                      subtitle: const Text('Generate a new encryption key'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _keyInfo?['hasKey'] == true ? _rotateEncryptionKey : null,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Data Management
                _buildSection(
                  'Data Management',
                  [
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Storage Usage'),
                      subtitle: Text('App data: ${_formatStorageSize(_storageSize)}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Clear All Data'),
                      subtitle: const Text('Permanently delete all lockboxes and keys'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _clearAllData,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // App Information
                _buildSection(
                  'About',
                  [
                    const ListTile(
                      leading: Icon(Icons.info),
                      title: Text('Version'),
                      subtitle: Text('1.0.0+1'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.security),
                      title: Text('Encryption'),
                      subtitle: Text('NIP-44 with Nostr key pairs'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.storage),
                      title: Text('Storage'),
                      subtitle: Text('Local device storage only'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getThemeDisplayName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'Follow system';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }
}