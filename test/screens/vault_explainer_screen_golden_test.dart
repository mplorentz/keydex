import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/screens/vault_explainer_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  group('VaultExplainerScreen Golden Tests', () {
    testGoldens('default state', (tester) async {
      await pumpGoldenWidget(tester, const VaultExplainerScreen());

      await screenMatchesGolden(tester, 'vault_explainer_screen_default');
    });

    testGoldens('scrolled state', (tester) async {
      await pumpGoldenWidget(tester, const VaultExplainerScreen());

      // Scroll down to show the "Learn more" button and bottom content
      await tester.dragUntilVisible(
        find.text('Learn more'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'vault_explainer_screen_scrolled');
    });

    testGoldens('multiple device sizes', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const VaultExplainerScreen(), name: 'default');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: goldenMaterialAppWrapper,
      );

      await screenMatchesGolden(
        tester,
        'vault_explainer_screen_multiple_devices',
      );
    });
  });
}
