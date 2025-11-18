import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/providers/key_provider.dart';
import 'package:keydex/screens/onboarding_screen.dart';
import 'package:keydex/services/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> secureStore = {};

  setUpAll(() {
    // Mock flutter_secure_storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
      switch (call.method) {
        case 'write':
          final String key = (call.arguments as Map)['key'] as String;
          final String? value = (call.arguments as Map)['value'] as String?;
          if (value == null) {
            secureStore.remove(key);
          } else {
            secureStore[key] = value;
          }
          return null;
        case 'read':
          final String key = (call.arguments as Map)['key'] as String;
          return secureStore[key];
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'delete':
          final String key = (call.arguments as Map)['key'] as String;
          secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'containsKey':
          final String key = (call.arguments as Map)['key'] as String;
          return secureStore.containsKey(key);
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  group('OnboardingScreen Golden Tests', () {
    setUp(() async {
      secureStore.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('onboarding screen - default state', (tester) async {
      // Create a LoginService with no stored key (user not logged in)
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      // Only override loginServiceProvider - other providers won't be accessed
      // during build, only when "Get Started" button is pressed
      final container = ProviderContainer(
        overrides: [
          loginServiceProvider.overrideWithValue(loginService),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const OnboardingScreen(),
        container: container,
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await screenMatchesGolden(tester, 'onboarding_screen_default');

      container.dispose();
    });

    testGoldens('onboarding screen - multiple device sizes', (tester) async {
      // Create a LoginService with no stored key (user not logged in)
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      final container = ProviderContainer(
        overrides: [
          loginServiceProvider.overrideWithValue(loginService),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ])
        ..addScenario(
          widget: const OnboardingScreen(),
          name: 'onboarding',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(tester, 'onboarding_screen_multiple_devices');

      container.dispose();
    });
  });
}
