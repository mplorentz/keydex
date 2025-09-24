// Authentication Widget - Reusable component for user authentication

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../contracts/auth_service.dart' as auth_contract;

class AuthenticationWidget extends StatefulWidget {
  const AuthenticationWidget({
    super.key,
    required this.authService,
    required this.needsSetup,
    required this.hasEncryptionKey,
    required this.onAuthenticated,
    required this.onSetupRequired,
    required this.onError,
  });

  final AuthServiceImpl authService;
  final bool needsSetup;
  final bool hasEncryptionKey;
  final VoidCallback onAuthenticated;
  final VoidCallback onSetupRequired;
  final ValueChanged<String> onError;

  @override
  State<AuthenticationWidget> createState() => _AuthenticationWidgetState();
}

class _AuthenticationWidgetState extends State<AuthenticationWidget> {
  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await widget.authService.isBiometricAvailable();
      setState(() {
        _biometricAvailable = isAvailable;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final isAuthenticated = await widget.authService.authenticateUser();
      
      if (isAuthenticated) {
        widget.onAuthenticated();
      } else {
        widget.onError('Authentication was cancelled or failed');
      }
    } catch (e) {
      widget.onError('Authentication failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.needsSetup) {
      return _buildSetupWidget();
    } else {
      return _buildAuthenticationWidget();
    }
  }

  Widget _buildSetupWidget() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Setup Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (!widget.hasEncryptionKey) ...[
              const ListTile(
                leading: Icon(Icons.key, color: Colors.orange),
                title: Text('Encryption key needed'),
                subtitle: Text('A secure key will be generated for encrypting your lockboxes'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            
            const ListTile(
              leading: Icon(Icons.fingerprint, color: Colors.orange),
              title: Text('Biometric authentication setup'),
              subtitle: Text('Set up fingerprint or face recognition for secure access'),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 16),
            
            if (!_biometricAvailable) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biometric authentication is not available on this device. Please enable it in your device settings.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _biometricAvailable && !_isLoading ? widget.onSetupRequired : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.security),
                label: Text(_isLoading ? 'Setting up...' : 'Complete Setup'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationWidget() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Authentication Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              'Please authenticate to access your encrypted lockboxes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green[700],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.fingerprint, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _biometricAvailable
                        ? 'Use your fingerprint or face to unlock'
                        : 'Biometric authentication not available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _biometricAvailable && !_isLoading ? _authenticate : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(_isLoading ? 'Authenticating...' : 'Authenticate'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}