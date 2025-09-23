import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../contracts/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual AuthService implementation
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _biometricEnabled = true; // For demo
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      if (value) {
        // TODO: Replace with actual AuthService implementation
        await Future.delayed(const Duration(milliseconds: 500));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication enabled')),
        );
      } else {
        final confirmed = await _showConfirmationDialog(
          'Disable Biometric Authentication',
          'Are you sure you want to disable biometric authentication? You will need to authenticate manually.',
        );
        
        if (confirmed) {
          // TODO: Replace with actual AuthService implementation
          await Future.delayed(const Duration(milliseconds: 500));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication disabled')),
          );
        } else {
          return; // Don't update the state
        }
      }
      
      setState(() {
        _biometricEnabled = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating biometric setting: $e')),
      );
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Keydex',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.lock, size: 48),
      children: [
        const Text(
          'Keydex is a secure encrypted lockbox application that uses NIP-44 encryption '
          'to protect your sensitive text data.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• NIP-44 encryption\n'
          '• Biometric authentication\n'
          '• Local storage\n'
          '• Open source',
        ),
      ],
    );
  }

  void _exportData() async {
    final confirmed = await _showConfirmationDialog(
      'Export Encrypted Data',
      'This will export your encrypted lockboxes. The data will remain encrypted and can only be decrypted with your key.',
    );

    if (confirmed) {
      try {
        // TODO: Implement actual data export
        await Future.delayed(const Duration(milliseconds: 1000));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data export feature coming soon')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  void _clearAllData() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Data',
      'This will permanently delete all your lockboxes and settings. This action cannot be undone.',
    );

    if (confirmed) {
      final doubleConfirmed = await _showConfirmationDialog(
        'Are you absolutely sure?',
        'This will permanently delete ALL your encrypted lockboxes. Type YES to confirm.',
      );

      if (doubleConfirmed) {
        try {
          // TODO: Implement actual data clearing
          await Future.delayed(const Duration(milliseconds: 1000));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Security Section
          _buildSectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use biometric authentication to unlock'),
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),
          const Divider(),

          // Data Section
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            subtitle: const Text('Export encrypted lockboxes'),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently delete all lockboxes'),
            onTap: _clearAllData,
          ),
          const Divider(),

          // App Info Section
          _buildSectionHeader('Application'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App version and information'),
            onTap: _showAboutDialog,
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Encryption'),
            subtitle: const Text('NIP-44 with Nostr key pairs'),
          ),
          const Divider(),

          // Privacy Section
          _buildSectionHeader('Privacy'),
          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Data Storage'),
            subtitle: Text('All data is stored locally on your device'),
          ),
          const ListTile(
            leading: Icon(Icons.shield),
            title: Text('Encryption'),
            subtitle: Text('End-to-end encryption with your private keys'),
          ),
          
          const SizedBox(height: 32),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Keydex - Secure Encrypted Lockboxes\nBuilt with Flutter and NIP-44 encryption',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}