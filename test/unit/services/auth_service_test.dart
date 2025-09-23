import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/contracts/auth_service.dart';
import 'package:keydex/services/auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([LocalAuthentication, SharedPreferences])
void main() {
  group('AuthServiceImpl Tests', () {
    late MockLocalAuthentication mockLocalAuth;
    late MockSharedPreferences mockPrefs;
    late AuthServiceImpl authService;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      mockPrefs = MockSharedPreferences();
      authService = AuthServiceImpl(localAuth: mockLocalAuth, prefs: mockPrefs);
    });

    group('Biometric Availability', () {
      test('should return true when biometric authentication is available', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);

        // Act
        final result = await authService.isBiometricAvailable();

        // Assert
        expect(result, isTrue);
        verify(mockLocalAuth.isDeviceSupported()).called(1);
        verify(mockLocalAuth.canCheckBiometrics).called(1);
        verify(mockLocalAuth.getAvailableBiometrics()).called(1);
      });

      test('should return false when device is not supported', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await authService.isBiometricAvailable();

        // Assert
        expect(result, isFalse);
        verify(mockLocalAuth.isDeviceSupported()).called(1);
        verifyNever(mockLocalAuth.canCheckBiometrics);
        verifyNever(mockLocalAuth.getAvailableBiometrics());
      });

      test('should return false when cannot check biometrics', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

        // Act
        final result = await authService.isBiometricAvailable();

        // Assert
        expect(result, isFalse);
        verify(mockLocalAuth.isDeviceSupported()).called(1);
        verify(mockLocalAuth.canCheckBiometrics).called(1);
        verifyNever(mockLocalAuth.getAvailableBiometrics());
      });

      test('should return false when no biometrics available', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        // Act
        final result = await authService.isBiometricAvailable();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when exception occurs', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenThrow(Exception('Device error'));

        // Act
        final result = await authService.isBiometricAvailable();

        // Assert
        expect(result, isFalse);
      });
    });

    group('Authentication Configuration', () {
      test('should return true when authentication is configured', () async {
        // Arrange
        when(mockPrefs.getBool('auth_configured')).thenReturn(true);

        // Act
        final result = await authService.isAuthenticationConfigured();

        // Assert
        expect(result, isTrue);
        verify(mockPrefs.getBool('auth_configured')).called(1);
      });

      test('should return false when authentication is not configured', () async {
        // Arrange
        when(mockPrefs.getBool('auth_configured')).thenReturn(null);

        // Act
        final result = await authService.isAuthenticationConfigured();

        // Assert
        expect(result, isFalse);
        verify(mockPrefs.getBool('auth_configured')).called(1);
      });

      test('should return false when authentication is explicitly disabled', () async {
        // Arrange
        when(mockPrefs.getBool('auth_configured')).thenReturn(false);

        // Act
        final result = await authService.isAuthenticationConfigured();

        // Assert
        expect(result, isFalse);
      });

      test('should handle exception gracefully', () async {
        // Arrange
        when(mockPrefs.getBool('auth_configured')).thenThrow(Exception('Storage error'));

        // Act
        final result = await authService.isAuthenticationConfigured();

        // Assert
        expect(result, isFalse);
      });
    });

    group('Setup Authentication', () {
      test('should setup authentication successfully', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);

        // Act
        await authService.setupAuthentication();

        // Assert
        verify(mockLocalAuth.authenticate(
          localizedReason: 'Set up authentication for your secure lockboxes',
          options: anyNamed('options'),
        )).called(1);
        verify(mockPrefs.setBool('auth_configured', true)).called(1);
        verify(mockPrefs.setBool('auth_disabled', false)).called(1);
      });

      test('should throw AuthException when biometric not available', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => authService.setupAuthentication(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'BIOMETRIC_NOT_AVAILABLE',
          )),
        );
        verifyNever(mockPrefs.setBool(any, any));
      });

      test('should throw AuthException when authentication fails', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => authService.setupAuthentication(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'SETUP_AUTH_FAILED',
          )),
        );
        verifyNever(mockPrefs.setBool(any, any));
      });

      test('should handle authentication exception', () async {
        // Arrange
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenThrow(Exception('Auth error'));

        // Act & Assert
        expect(
          () => authService.setupAuthentication(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'SETUP_FAILED',
          )),
        );
      });
    });

    group('Authenticate User', () {
      test('should authenticate successfully', () async {
        // Arrange
        when(mockPrefs.getBool('auth_disabled')).thenReturn(false);
        when(mockPrefs.getBool('auth_configured')).thenReturn(true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await authService.authenticateUser();

        // Assert
        expect(result, isTrue);
        verify(mockLocalAuth.authenticate(
          localizedReason: 'Authenticate to access your secure lockboxes',
          options: anyNamed('options'),
        )).called(1);
      });

      test('should skip authentication when disabled', () async {
        // Arrange
        when(mockPrefs.getBool('auth_disabled')).thenReturn(true);

        // Act
        final result = await authService.authenticateUser();

        // Assert
        expect(result, isTrue);
        verifyNever(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ));
      });

      test('should throw AuthException when not configured', () async {
        // Arrange
        when(mockPrefs.getBool('auth_disabled')).thenReturn(false);
        when(mockPrefs.getBool('auth_configured')).thenReturn(false);

        // Act & Assert
        expect(
          () => authService.authenticateUser(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'AUTH_NOT_CONFIGURED',
          )),
        );
      });

      test('should throw AuthException when biometric not available', () async {
        // Arrange
        when(mockPrefs.getBool('auth_disabled')).thenReturn(false);
        when(mockPrefs.getBool('auth_configured')).thenReturn(true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => authService.authenticateUser(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'BIOMETRIC_NOT_AVAILABLE',
          )),
        );
      });

      test('should return false when authentication fails', () async {
        // Arrange
        when(mockPrefs.getBool('auth_disabled')).thenReturn(false);
        when(mockPrefs.getBool('auth_configured')).thenReturn(true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        // Act
        final result = await authService.authenticateUser();

        // Assert
        expect(result, isFalse);
      });

      test('should handle authentication exception', () async {
        // Arrange
        when(mockPrefs.getBool('auth_disabled')).thenReturn(false);
        when(mockPrefs.getBool('auth_configured')).thenReturn(true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenThrow(Exception('Auth failed'));

        // Act & Assert
        expect(
          () => authService.authenticateUser(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'AUTH_FAILED',
          )),
        );
      });
    });

    group('Disable Authentication', () {
      test('should disable authentication successfully', () async {
        // Arrange
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);

        // Act
        await authService.disableAuthentication();

        // Assert
        verify(mockPrefs.setBool('auth_disabled', true)).called(1);
      });

      test('should throw AuthException when disable fails', () async {
        // Arrange
        when(mockPrefs.setBool('auth_disabled', true)).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => authService.disableAuthentication(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'DISABLE_FAILED',
          )),
        );
      });
    });

    group('Enable Authentication', () {
      test('should enable authentication successfully', () async {
        // Arrange
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);

        // Act
        await authService.enableAuthentication();

        // Assert
        verify(mockPrefs.setBool('auth_disabled', false)).called(1);
      });

      test('should throw AuthException when enable fails', () async {
        // Arrange
        when(mockPrefs.setBool('auth_disabled', false)).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => authService.enableAuthentication(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'ENABLE_FAILED',
          )),
        );
      });
    });

    group('Reset Authentication', () {
      test('should reset authentication successfully', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        // Act
        await authService.resetAuthentication();

        // Assert
        verify(mockPrefs.remove('auth_configured')).called(1);
        verify(mockPrefs.remove('auth_disabled')).called(1);
      });

      test('should throw AuthException when reset fails', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => authService.resetAuthentication(),
          throwsA(isA<AuthException>().having(
            (e) => e.errorCode,
            'error code',
            'RESET_FAILED',
          )),
        );
      });
    });
  });

  group('AuthException Tests', () {
    test('should create exception with message only', () {
      // Act
      final exception = AuthException('Test error message');

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, isNull);
    });

    test('should create exception with message and error code', () {
      // Act
      final exception = AuthException(
        'Test error message',
        errorCode: 'TEST_ERROR',
      );

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, equals('TEST_ERROR'));
    });
  });
}