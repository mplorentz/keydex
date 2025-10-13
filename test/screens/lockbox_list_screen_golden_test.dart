import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/providers/key_provider.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/screens/lockbox_list_screen.dart';
import 'package:keydex/widgets/theme.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;

  final ownedLockbox = Lockbox(
    id: 'lockbox-1',
    name: 'My Private Keys',
    content: 'nsec1...',
    createdAt: DateTime(2024, 10, 1, 10, 30),
    ownerPubkey: testPubkey,
    shards: [],
    recoveryRequests: [],
  );

  final keyHolderLockbox = Lockbox(
    id: 'lockbox-2',
    name: "Alice's Backup",
    content: null,
    createdAt: DateTime(2024, 9, 15, 14, 20),
    ownerPubkey: otherPubkey,
    shards: [], // Would have shards in real scenario
    recoveryRequests: [],
  );

  final multipleLockboxes = [
    ownedLockbox,
    keyHolderLockbox,
    Lockbox(
      id: 'lockbox-3',
      name: 'Work Documents',
      content: null,
      createdAt: DateTime(2024, 9, 20, 9, 15),
      ownerPubkey: testPubkey,
      shards: [],
      recoveryRequests: [],
    ),
  ];

  group('LockboxListScreen Golden Tests', () {
    testGoldens('empty state - no lockboxes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Mock the lockbox stream provider to return empty list
          lockboxListProvider.overrideWith((ref) => Stream.value([])),
          // Mock the current user's pubkey
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxListScreen(),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      // Wait for all animations and async operations
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_list_screen_empty');

      container.dispose();
    });

    // Note: Loading state test is skipped as it's difficult to capture
    // without pumpAndSettle timing out. The loading state uses a simple
    // CircularProgressIndicator which is well-tested by Flutter itself.

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Mock provider to throw an error
          lockboxListProvider.overrideWith(
            (ref) => Stream.error('Failed to load lockboxes'),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxListScreen(),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_list_screen_error');

      container.dispose();
    });

    testGoldens('single owned lockbox', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([ownedLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxListScreen(),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_list_screen_single_owned');

      container.dispose();
    });

    testGoldens('single key holder lockbox', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([keyHolderLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxListScreen(),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_list_screen_single_key_holder');

      container.dispose();
    });

    testGoldens('multiple lockboxes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value(multipleLockboxes),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxListScreen(),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_list_screen_multiple');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value(multipleLockboxes),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ])
        ..addScenario(
          widget: const LockboxListScreen(),
          name: 'multiple_lockboxes',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
      );

      await screenMatchesGolden(tester, 'lockbox_list_screen_multiple_devices');

      container.dispose();
    });
  });
}
