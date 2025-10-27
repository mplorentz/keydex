import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/recovery_status.dart' as models;
import 'package:keydex/providers/recovery_provider.dart';
import 'package:keydex/widgets/recovery_progress_widget.dart';
import 'package:keydex/widgets/theme.dart';

void main() {
  group('RecoveryProgressWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryStatusByIdProvider('test-request').overrideWith(
            (ref) => Future.delayed(const Duration(seconds: 10), () => null),
          ),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 300),
      );

      await tester.pump();

      await screenMatchesGolden(tester, 'recovery_progress_widget_loading');

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryStatusByIdProvider('test-request').overrideWith(
            (ref) => Future.error('Failed to load recovery status'),
          ),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 300),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_progress_widget_error');

      container.dispose();
    });

    testGoldens('low progress without button', (tester) async {
      final status = models.RecoveryStatus(
        recoveryRequestId: 'test-request',
        totalKeyHolders: 3,
        respondedCount: 1,
        approvedCount: 1,
        deniedCount: 0,
        collectedShardIds: ['pubkey1'],
        threshold: 2,
        canRecover: false,
        lastUpdated: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryStatusByIdProvider('test-request').overrideWith((ref) => Future.value(status)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 400),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_progress_widget_low_progress');

      container.dispose();
    });

    testGoldens('threshold met with button', (tester) async {
      final status = models.RecoveryStatus(
        recoveryRequestId: 'test-request',
        totalKeyHolders: 3,
        respondedCount: 2,
        approvedCount: 2,
        deniedCount: 0,
        collectedShardIds: ['pubkey1', 'pubkey2'],
        threshold: 2,
        canRecover: true,
        lastUpdated: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryStatusByIdProvider('test-request').overrideWith((ref) => Future.value(status)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 500),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_progress_widget_threshold_met');

      container.dispose();
    });

    testGoldens('completed state', (tester) async {
      final status = models.RecoveryStatus(
        recoveryRequestId: 'test-request',
        totalKeyHolders: 3,
        respondedCount: 3,
        approvedCount: 3,
        deniedCount: 0,
        collectedShardIds: ['pubkey1', 'pubkey2', 'pubkey3'],
        threshold: 2,
        canRecover: true,
        lastUpdated: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryStatusByIdProvider('test-request').overrideWith((ref) => Future.value(status)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 500),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_progress_widget_completed');

      container.dispose();
    });
  });
}
