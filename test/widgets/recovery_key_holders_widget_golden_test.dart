import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/recovery_request.dart';
import 'package:keydex/providers/recovery_provider.dart';
import 'package:keydex/widgets/recovery_key_holders_widget.dart';
import 'package:keydex/widgets/theme.dart';

void main() {
  // Sample test data
  final testPubkey1 = 'a' * 64;
  final testPubkey2 = 'b' * 64;
  final testPubkey3 = 'c' * 64;

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String id,
    required Map<String, RecoveryResponse> responses,
  }) {
    return RecoveryRequest(
      id: id,
      lockboxId: 'test-lockbox',
      initiatorPubkey: testPubkey1,
      requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: RecoveryRequestStatus.inProgress,
      threshold: 2,
      keyHolderResponses: responses,
    );
  }

  // Helper to create response
  RecoveryResponse createResponse({
    required String pubkey,
    required RecoveryResponseStatus status,
    DateTime? respondedAt,
  }) {
    return RecoveryResponse(
      pubkey: pubkey,
      approved: status == RecoveryResponseStatus.approved,
      respondedAt: respondedAt ?? DateTime.now().subtract(const Duration(minutes: 30)),
    );
  }

  group('RecoveryKeyHoldersWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => Future.delayed(const Duration(seconds: 10), () => null),
          ),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryKeyHoldersWidget(recoveryRequestId: 'test-request'),
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

      await screenMatchesGolden(tester, 'recovery_key_holders_widget_loading');

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
        const RecoveryKeyHoldersWidget(recoveryRequestId: 'test-request'),
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

      await screenMatchesGolden(tester, 'recovery_key_holders_widget_error');

      container.dispose();
    });

    testGoldens('all pending responses', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        responses: {
          testPubkey2: createResponse(pubkey: testPubkey2, status: RecoveryResponseStatus.pending),
          testPubkey3: createResponse(pubkey: testPubkey3, status: RecoveryResponseStatus.pending),
        },
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith((ref) => Future.value(request)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryKeyHoldersWidget(recoveryRequestId: 'test-request'),
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

      await screenMatchesGolden(tester, 'recovery_key_holders_widget_all_pending');

      container.dispose();
    });

    testGoldens('mixed responses', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        responses: {
          testPubkey2: createResponse(
            pubkey: testPubkey2,
            status: RecoveryResponseStatus.approved,
            respondedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          testPubkey3: createResponse(
            pubkey: testPubkey3,
            status: RecoveryResponseStatus.denied,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith((ref) => Future.value(request)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryKeyHoldersWidget(recoveryRequestId: 'test-request'),
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

      await screenMatchesGolden(tester, 'recovery_key_holders_widget_mixed_responses');

      container.dispose();
    });

    testGoldens('all approved responses', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        responses: {
          testPubkey2: createResponse(
            pubkey: testPubkey2,
            status: RecoveryResponseStatus.approved,
            respondedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          testPubkey3: createResponse(
            pubkey: testPubkey3,
            status: RecoveryResponseStatus.approved,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith((ref) => Future.value(request)),
        ],
      );

      await tester.pumpWidgetBuilder(
        const RecoveryKeyHoldersWidget(recoveryRequestId: 'test-request'),
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

      await screenMatchesGolden(tester, 'recovery_key_holders_widget_all_approved');

      container.dispose();
    });
  });
}
