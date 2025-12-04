import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/settings_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sample test data
  final testPubkey = 'npub1test1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz';

  group('SettingsScreen Golden Tests', () {
    testGoldens('loading state - public key loading', (tester) async {
      final completer = Completer<String?>();
      final container = ProviderContainer(
        overrides: [
          currentPublicKeyBech32Provider.overrideWith(
            (ref) => completer.future, // Never completes
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const SettingsScreen(),
        container: container,
        waitForSettle: false, // Loading state
      );

      await screenMatchesGoldenWithoutSettle<SettingsScreen>(
        tester,
        'settings_screen_loading',
      );

      container.dispose();
    });

    testGoldens('with public key', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentPublicKeyBech32Provider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const SettingsScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'settings_screen_with_key');

      container.dispose();
    });

    testGoldens('without public key', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentPublicKeyBech32Provider.overrideWith(
            (ref) => Future<String?>.value(null),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const SettingsScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'settings_screen_no_key');

      container.dispose();
    });

    testGoldens('error state - public key error', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentPublicKeyBech32Provider.overrideWith(
            (ref) => Future<String?>.error('Failed to load key'),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const SettingsScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'settings_screen_error');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentPublicKeyBech32Provider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const SettingsScreen(), name: 'with_key');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) =>
            goldenMaterialAppWrapperWithProviders(child: child, container: container),
      );

      await screenMatchesGolden(tester, 'settings_screen_multiple_devices');

      container.dispose();
    });
  });
}
