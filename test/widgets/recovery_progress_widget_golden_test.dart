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
import 'package:keydex/widgets/recovery_progress_widget.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey1 = 'a' * 64;
  final testPubkey2 = 'b' * 64;
  final testPubkey3 = 'c' * 64;

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
        keyHolders: keyHolderPubkeys.map((pubkey) => createKeyHolder(pubkey: pubkey)).toList(),
        relays: ['wss://relay.example.com'],
      ),
    );
  }

  group('RecoveryProgressWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => const AsyncValue.loading()),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 300),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<RecoveryProgressWidget>(
        tester,
        'recovery_progress_widget_loading',
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => const AsyncValue.error(
              'Failed to load recovery request',
              StackTrace.empty,
            ),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 300),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_progress_widget_error');

      container.dispose();
    });

    testGoldens('low progress without button', (tester) async {
      final request = RecoveryRequest(
        id: 'test-request',
        lockboxId: 'test-lockbox',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        keyHolderResponses: {
          testPubkey2: RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        },
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        keyHolderPubkeys: [testPubkey2, testPubkey3, testPubkey1],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 400),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'recovery_progress_widget_low_progress',
      );

      container.dispose();
    });

    testGoldens('threshold met with button', (tester) async {
      final request = RecoveryRequest(
        id: 'test-request',
        lockboxId: 'test-lockbox',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        keyHolderResponses: {
          testPubkey2: RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          testPubkey3: RecoveryResponse(
            pubkey: testPubkey3,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        },
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        keyHolderPubkeys: [testPubkey2, testPubkey3, testPubkey1],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 500),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'recovery_progress_widget_threshold_met',
      );

      container.dispose();
    });

    testGoldens('completed state', (tester) async {
      final request = RecoveryRequest(
        id: 'test-request',
        lockboxId: 'test-lockbox',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        keyHolderResponses: {
          testPubkey2: RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          testPubkey3: RecoveryResponse(
            pubkey: testPubkey3,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        },
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        keyHolderPubkeys: [testPubkey2, testPubkey3, testPubkey1],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 500),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_progress_widget_completed');

      container.dispose();
    });
  });
}
