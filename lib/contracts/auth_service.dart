// AuthService Contract
// This file defines the interface for user authentication

abstract class AuthService {
  /// Authenticates user using biometric or password
  /// Returns true if authentication succeeds
  Future<bool> authenticateUser();

  /// Checks if biometric authentication is available
  /// Returns true if device supports biometrics
  Future<bool> isBiometricAvailable();

  /// Checks if user has set up authentication
  /// Returns true if authentication is configured
  Future<bool> isAuthenticationConfigured();

  /// Sets up authentication for the first time
  /// Configures biometric or password authentication
  Future<void> setupAuthentication();

  /// Disables authentication (for testing or user preference)
  Future<void> disableAuthentication();
}

class AuthException implements Exception {
  final String message;
  final String? errorCode;

  AuthException(this.message, {this.errorCode});
}
