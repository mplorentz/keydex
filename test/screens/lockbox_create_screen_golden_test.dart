import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/screens/lockbox_create_screen.dart';
import 'package:keydex/widgets/theme.dart';

void main() {
  group('LockboxCreateScreen Golden Tests', () {
    testGoldens('empty state - no input', (tester) async {
      await tester.pumpWidgetBuilder(
        const LockboxCreateScreen(),
        wrapper: (child) => ProviderScope(
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_create_screen_empty');
    });

    testGoldens('filled state - with content', (tester) async {
      await tester.pumpWidgetBuilder(
        const LockboxCreateScreen(),
        wrapper: (child) => ProviderScope(
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      // Fill in the name field (first TextFormField)
      await tester.enterText(
        find.byType(TextFormField).first,
        'My Private Keys',
      );

      // Fill in the content field (second TextFormField)
      await tester.enterText(
        find.byType(TextFormField).last,
        'This is my secret content that will be encrypted and stored securely.',
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_create_screen_filled');
    });

    testGoldens('validation errors - empty name', (tester) async {
      await tester.pumpWidgetBuilder(
        const LockboxCreateScreen(),
        wrapper: (child) => ProviderScope(
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      // Tap the Next button without entering any data
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_create_screen_validation_empty_name');
    });

    testGoldens('validation errors - content too long', (tester) async {
      await tester.pumpWidgetBuilder(
        const LockboxCreateScreen(),
        wrapper: (child) => ProviderScope(
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      // Fill in the name field (first TextFormField)
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Lockbox',
      );

      // Fill in content that exceeds 4000 characters
      final longContent = 'a' * 4100;
      await tester.enterText(
        find.byType(TextFormField).last,
        longContent,
      );

      await tester.pumpAndSettle();

      // Tap Next to trigger validation
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_create_screen_validation_content_too_long');
    });

    testGoldens('multiple device sizes', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ])
        ..addScenario(
          widget: const LockboxCreateScreen(),
          name: 'empty',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => ProviderScope(
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
      );

      await screenMatchesGolden(tester, 'lockbox_create_screen_multiple_devices');
    });

    testGoldens('filled content with character count', (tester) async {
      await tester.pumpWidgetBuilder(
        const LockboxCreateScreen(),
        wrapper: (child) => ProviderScope(
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      // Fill in the name field (first TextFormField)
      await tester.enterText(
        find.byType(TextFormField).first,
        'My Private Keys',
      );

      // Fill in content with a specific length to show character count
      final content = 'This is a test content. ' * 50; // ~1200 characters
      await tester.enterText(
        find.byType(TextFormField).last,
        content,
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_create_screen_with_char_count');
    });
  });
}
