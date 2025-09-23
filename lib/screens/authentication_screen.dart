import 'package:flutter/material.dart';
import '../contracts/auth_service.dart';
import '../widgets/authentication_widget.dart';

class AuthenticationScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthenticationScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _isAuthenticationConfigured = false;
  bool _isBiometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual AuthService implementation
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isAuthenticationConfigured = false; // For demo, assume not configured
        _isBiometricAvailable = true; // For demo, assume biometric available
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAuthenticationSuccess() {
    widget.onAuthenticated();
  }

  void _onAuthenticationConfigured() {
    setState(() {
      _isAuthenticationConfigured = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 64,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // App Title
                  Text(
                    'Keydex',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Encrypted Lockboxes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Authentication Widget
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _isLoading
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Checking authentication...'),
                              ],
                            )
                          : AuthenticationWidget(
                              isAuthenticationConfigured: _isAuthenticationConfigured,
                              isBiometricAvailable: _isBiometricAvailable,
                              onAuthenticationSuccess: _onAuthenticationSuccess,
                              onAuthenticationConfigured: _onAuthenticationConfigured,
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Footer Text
                  Text(
                    'Your data is encrypted with NIP-44 encryption\nand protected by biometric authentication',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}