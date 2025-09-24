// Authentication Screen - Initial screen for app authentication and setup

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/key_service.dart';
import '../contracts/auth_service.dart' as auth_contract;
import '../widgets/authentication_widget.dart';
import 'lockbox_list_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  static const String routeName = '/auth';

  const AuthenticationScreen({
    super.key,
    required this.authService,
    required this.keyService,
  });

  final AuthServiceImpl authService;
  final KeyService keyService;

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _isLoading = true;
  bool _needsSetup = false;
  bool _hasEncryptionKey = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if authentication is configured
      final isConfigured = await widget.authService.isAuthenticationConfigured();
      
      // Check if encryption key exists
      final hasKey = await widget.keyService.hasKey();

      setState(() {
        _needsSetup = !isConfigured || !hasKey;
        _hasEncryptionKey = hasKey;
        _isLoading = false;
      });

      // If everything is set up and not disabled, try auto-authentication
      if (!_needsSetup) {
        final isDisabled = await widget.authService.isAuthenticationDisabled();
        if (!isDisabled) {
          await _authenticate();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check authentication status: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final isAuthenticated = await widget.authService.authenticateUser();
      
      if (isAuthenticated && mounted) {
        Navigator.of(context).pushReplacementNamed(LockboxListScreen.routeName);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupApplication() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Set up authentication
      if (!await widget.authService.isAuthenticationConfigured()) {
        await widget.authService.setupAuthentication();
      }

      // Generate encryption key if needed
      if (!_hasEncryptionKey) {
        await widget.keyService.generateNewKey();
      }

      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LockboxListScreen.routeName);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Setup failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _skipAuthentication() async {
    try {
      await widget.authService.disableAuthentication();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LockboxListScreen.routeName);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to skip authentication: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo and title
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFF6750A4),
              ),
              const SizedBox(height: 24),
              Text(
                'Keydex',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6750A4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Text Lockboxes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // Error message
              if (_errorMessage != null) ...[
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Loading indicator
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Please wait...'),
              ] else ...[
                // Authentication widget
                AuthenticationWidget(
                  authService: widget.authService,
                  needsSetup: _needsSetup,
                  hasEncryptionKey: _hasEncryptionKey,
                  onAuthenticated: () {
                    Navigator.of(context).pushReplacementNamed(
                      LockboxListScreen.routeName,
                    );
                  },
                  onSetupRequired: _setupApplication,
                  onError: (error) {
                    setState(() {
                      _errorMessage = error;
                    });
                  },
                ),
                
                const SizedBox(height: 32),

                // Setup/Authentication buttons
                if (_needsSetup) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _setupApplication,
                      icon: const Icon(Icons.security),
                      label: const Text('Set Up Security'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _skipAuthentication,
                      child: const Text('Skip for Now (Less Secure)'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Authenticate'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _skipAuthentication,
                      child: const Text('Continue Without Authentication'),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 48),

              // Help text
              Text(
                'Your lockboxes are encrypted and stored securely on this device.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}