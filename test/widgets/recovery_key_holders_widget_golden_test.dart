import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/recovery_request.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/models/backup_config.dart';
import 'package:keydex/models/key_holder.dart';
import 'package:keydex/providers/recovery_provider.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/widgets/recovery_key_holders_widget.dart';
import 'package:keydex/widgets/theme.dart';
import '../helpers/golden_test_helpers.dart';

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

  // Helper to create lockbox
  Lockbox createTestLockbox({
    required String id,
    required List<String> keyHolderPubkeys,
  }) {
    return Lockbox(
      id: id,
      name: 'Test Lockbox',
      content: 'test content',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: testPubkey1,
      backupConfig: createBackupConfig(
        lockboxId: id,
        threshold: 2,
        totalKeys: keyHolderPubkeys.length,
        keyHolders: keyHolderPubkeys
            .map((pubkey) => createKeyHolder(
                  pubkey: pubkey,
                ))
            .toList(),
        relays: ['wss://relay.example.com'],
      ),
    );
  }

  group('RecoveryKeyHoldersWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => const AsyncValue.loading(),
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

      await screenMatchesGoldenWithoutSettle<RecoveryKeyHoldersWidget>(
        tester,
        'recovery_key_holders_widget_loading',
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => const AsyncValue.error('Failed to load recovery request', StackTrace.empty),
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
        responses: {}, // Empty responses - all should show as pending
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        keyHolderPubkeys: [testPubkey2, testPubkey3],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request')
              .overrideWith((ref) => AsyncValue.data(request)),
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(lockbox)),
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

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        keyHolderPubkeys: [testPubkey2, testPubkey3],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request')
              .overrideWith((ref) => AsyncValue.data(request)),
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(lockbox)),
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

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        keyHolderPubkeys: [testPubkey2, testPubkey3],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request')
              .overrideWith((ref) => AsyncValue.data(request)),
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(lockbox)),
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
