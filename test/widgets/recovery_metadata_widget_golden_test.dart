import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/recovery_request.dart';
import 'package:keydex/providers/recovery_provider.dart';
import 'package:keydex/widgets/recovery_metadata_widget.dart';
import 'package:keydex/widgets/theme.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String id,
    RecoveryRequestStatus status = RecoveryRequestStatus.pending,
    DateTime? requestedAt,
    DateTime? expiresAt,
    int threshold = 2,
  }) {
    return RecoveryRequest(
      id: id,
      lockboxId: 'test-lockbox',
      initiatorPubkey: testPubkey,
      requestedAt: requestedAt ?? DateTime.now().subtract(const Duration(hours: 1)),
      status: status,
      threshold: threshold,
      expiresAt: expiresAt,
    );
  }

  group('RecoveryMetadataWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => Future.delayed(const Duration(seconds: 10), () => null),
          ),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 200),
      );

      await tester.pump();

      await screenMatchesGolden(tester, 'recovery_metadata_widget_loading');

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => Future.error('Failed to load recovery request'),
          ),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 200),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_metadata_widget_error');

      container.dispose();
    });

    testGoldens('pending status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.pending,
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith((ref) => Future.value(request)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 250),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_metadata_widget_pending');

      container.dispose();
    });

    testGoldens('in-progress status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.inProgress,
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith((ref) => Future.value(request)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 250),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_metadata_widget_in_progress');

      container.dispose();
    });

    testGoldens('completed status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.completed,
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith((ref) => Future.value(request)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 250),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_metadata_widget_completed');

      container.dispose();
    });

    testGoldens('expired warning', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.inProgress,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)), // Expired
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith((ref) => Future.value(request)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 250),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'recovery_metadata_widget_expired');

      container.dispose();
    });
  });
}
