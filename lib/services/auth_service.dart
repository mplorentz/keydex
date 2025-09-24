// AuthService Implementation
// Handles user authentication using biometric or password authentication

import 'package:local_auth/local_auth.dart';
import '../contracts/auth_service.dart';
import 'storage_service.dart';

/// Implementation of AuthService using local_auth and StorageService
class AuthServiceImpl implements AuthService {
  AuthServiceImpl({
    LocalAuthentication? localAuth,
    required StorageService storageService,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storageService = storageService;

  final LocalAuthentication _localAuth;
  final StorageService _storageService;

  static const String _authConfiguredKey = 'auth_configured';
  static const String _authDisabledKey = 'auth_disabled';

  @override
  Future<bool> authenticateUser() async {
    try {
      // Check if authentication is disabled
      final isDisabled = await _storageService.getBool(_authDisabledKey) ?? false;
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
      return await _storageService.getBool(_authConfiguredKey) ?? false;
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
      await _storageService.setBool(_authConfiguredKey, true);
      await _storageService.setBool(_authDisabledKey, false);
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
      await _storageService.setBool(_authDisabledKey, true);
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
      await _storageService.setBool(_authDisabledKey, false);
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
      await _storageService.remove(_authConfiguredKey);
      await _storageService.remove(_authDisabledKey);
    } catch (e) {
      throw AuthException(
        'Failed to reset authentication: ${e.toString()}',
        errorCode: 'RESET_FAILED',
      );
    }
  }
}