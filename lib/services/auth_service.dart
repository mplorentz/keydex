// AuthService Implementation
// Implements biometric and password authentication using local_auth

import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/auth_service.dart';

class AuthServiceImpl implements AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _authConfiguredKey = 'auth_configured';
  static const String _authDisabledKey = 'auth_disabled';
  
  @override
  Future<bool> authenticateUser() async {
    try {
      // Check if authentication is disabled
      final prefs = await SharedPreferences.getInstance();
      final isDisabled = prefs.getBool(_authDisabledKey) ?? false;
      if (isDisabled) {
        return true; // Allow access if authentication is disabled
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
      final isBiometricAvailable = await this.isBiometricAvailable();
      if (!isBiometricAvailable) {
        throw AuthException(
          'Biometric authentication is not available on this device.',
          errorCode: 'BIOMETRIC_NOT_AVAILABLE',
        );
      }

      // Perform biometric authentication
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your encrypted lockboxes',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return isAuthenticated;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Authentication failed: ${e.toString()}',
        errorCode: 'AUTH_FAILED',
      );
    }
  }

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device supports biometric authentication
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return false;
      }

      // Check if biometrics are available
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      // Check what biometric types are available
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isAuthenticationConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_authConfiguredKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> setupAuthentication() async {
    try {
      // Check if biometric authentication is available
      final isBiometricAvailable = await this.isBiometricAvailable();
      if (!isBiometricAvailable) {
        throw AuthException(
          'Biometric authentication is not available. Please enable it in device settings.',
          errorCode: 'BIOMETRIC_NOT_AVAILABLE',
        );
      }

      // Test authentication to ensure it works
      final testAuth = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to set up lockbox security',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!testAuth) {
        throw AuthException(
          'Authentication setup cancelled or failed.',
          errorCode: 'SETUP_CANCELLED',
        );
      }

      // Mark authentication as configured
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authConfiguredKey, true);
      await prefs.setBool(_authDisabledKey, false);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to setup authentication: ${e.toString()}',
        errorCode: 'SETUP_FAILED',
      );
    }
  }

  @override
  Future<void> disableAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authDisabledKey, true);
    } catch (e) {
      throw AuthException(
        'Failed to disable authentication: ${e.toString()}',
        errorCode: 'DISABLE_FAILED',
      );
    }
  }

  // Additional helper methods
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<void> enableAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authDisabledKey, false);
    } catch (e) {
      throw AuthException(
        'Failed to enable authentication: ${e.toString()}',
        errorCode: 'ENABLE_FAILED',
      );
    }
  }

  Future<bool> isAuthenticationDisabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_authDisabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }
}