import 'package:flutter/material.dart';
import '../contracts/auth_service.dart';

class AuthenticationWidget extends StatefulWidget {
  final bool isAuthenticationConfigured;
  final bool isBiometricAvailable;
  final VoidCallback onAuthenticationSuccess;
  final VoidCallback onAuthenticationConfigured;

  const AuthenticationWidget({
    super.key,
    required this.isAuthenticationConfigured,
    required this.isBiometricAvailable,
    required this.onAuthenticationSuccess,
    required this.onAuthenticationConfigured,
  });

  @override
  State<AuthenticationWidget> createState() => _AuthenticationWidgetState();
}

class _AuthenticationWidgetState extends State<AuthenticationWidget> {
  bool _isAuthenticating = false;
  bool _isConfiguring = false;
  String? _errorMessage;

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual AuthService implementation
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate successful authentication
      widget.onAuthenticationSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _setupAuthentication() async {
    setState(() {
      _isConfiguring = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual AuthService implementation
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful setup
      widget.onAuthenticationConfigured();
      setState(() {
        _isConfiguring = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication configured successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to configure authentication. Please try again.';
        _isConfiguring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAuthenticationConfigured) {
      return _buildSetupWidget();
    } else {
      return _buildAuthenticationWidget();
    }
  }

  Widget _buildSetupWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.security,
          size: 48,
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 16),
        Text(
          'Setup Authentication',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure biometric authentication to secure your lockboxes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
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
            onPressed: _isConfiguring ? null : _setupAuthentication,
            icon: _isConfiguring 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(widget.isBiometricAvailable 
                  ? Icons.fingerprint 
                  : Icons.lock),
            label: Text(_isConfiguring 
              ? 'Setting up...' 
              : widget.isBiometricAvailable 
                ? 'Setup Biometric Auth'
                : 'Setup Password Auth'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        if (widget.isBiometricAvailable) ...[
          const SizedBox(height: 12),
          Text(
            'Biometric authentication is available on this device',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthenticationWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.isBiometricAvailable ? Icons.fingerprint : Icons.lock,
          size: 48,
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Authenticate to access your encrypted lockboxes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
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
            onPressed: _isAuthenticating ? null : _authenticate,
            icon: _isAuthenticating 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(widget.isBiometricAvailable 
                  ? Icons.fingerprint 
                  : Icons.lock),
            label: Text(_isAuthenticating 
              ? 'Authenticating...' 
              : widget.isBiometricAvailable 
                ? 'Authenticate with Biometrics'
                : 'Authenticate with Password'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 16),
        
        Row(
          children: [
            Icon(Icons.shield, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your data is protected with end-to-end encryption',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}