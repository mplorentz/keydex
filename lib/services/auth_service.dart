// AuthService Implementation
// Handles user authentication using biometric or password authentication

import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/auth_service.dart';

/// Implementation of AuthService using local_auth and shared_preferences
class AuthServiceImpl implements AuthService {
  AuthServiceImpl({LocalAuthentication? localAuth, SharedPreferences? prefs})
      : _localAuth = localAuth ?? LocalAuthentication(),
        _prefs = prefs;

  final LocalAuthentication _localAuth;
  SharedPreferences? _prefs;

  static const String _authConfiguredKey = 'auth_configured';
  static const String _authDisabledKey = 'auth_disabled';

  /// Gets shared preferences instance
  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<bool> authenticateUser() async {
    try {
      final prefs = await _preferences;
      
      // Check if authentication is disabled
      final isDisabled = prefs.getBool(_authDisabledKey) ?? false;
      if (isDisabled) {
        return true; // Skip authentication if disabled
      }

      // Check if authentication is configured
      final isConfigured = await isAuthenticationConfigured();
      if (!isConfigured) {
        throw AuthException(
          'Authentication not configured. Please set up authentication first.',
          errorCode: 'AUTH_NOT_CONFIGURED',
        );
      }

      // Check if biometric authentication is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw AuthException(
          'Biometric authentication is not available on this device.',
          errorCode: 'BIOMETRIC_NOT_AVAILABLE',
        );
      }

      // Attempt biometric authentication
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your secure lockboxes',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Authentication failed: ${e.toString()}',
        errorCode: 'AUTH_FAILED',
      );
    }
  }

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device is capable of biometric authentication
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // Check if biometric authentication is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      // Get available biometric types
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isAuthenticationConfigured() async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(_authConfiguredKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> setupAuthentication() async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw AuthException(
          'Cannot set up authentication: biometric authentication is not available on this device.',
          errorCode: 'BIOMETRIC_NOT_AVAILABLE',
        );
      }

      // Test authentication to ensure it works
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Set up authentication for your secure lockboxes',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) {
        throw AuthException(
          'Authentication setup failed: could not authenticate user.',
          errorCode: 'SETUP_AUTH_FAILED',
        );
      }

      // Mark authentication as configured
      final prefs = await _preferences;
      await prefs.setBool(_authConfiguredKey, true);
      await prefs.setBool(_authDisabledKey, false);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to set up authentication: ${e.toString()}',
        errorCode: 'SETUP_FAILED',
      );
    }
  }

  @override
  Future<void> disableAuthentication() async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_authDisabledKey, true);
    } catch (e) {
      throw AuthException(
        'Failed to disable authentication: ${e.toString()}',
        errorCode: 'DISABLE_FAILED',
      );
    }
  }

  /// Enables authentication (removes disabled flag)
  Future<void> enableAuthentication() async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_authDisabledKey, false);
    } catch (e) {
      throw AuthException(
        'Failed to enable authentication: ${e.toString()}',
        errorCode: 'ENABLE_FAILED',
      );
    }
  }

  /// Resets all authentication settings
  Future<void> resetAuthentication() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_authConfiguredKey);
      await prefs.remove(_authDisabledKey);
    } catch (e) {
      throw AuthException(
        'Failed to reset authentication: ${e.toString()}',
        errorCode: 'RESET_FAILED',
      );
    }
  }
}