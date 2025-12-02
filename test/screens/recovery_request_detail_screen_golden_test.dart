import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/models/recovery_request.dart';
import 'package:keydex/models/backup_config.dart';
import 'package:keydex/models/key_holder.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/providers/key_provider.dart';
import 'package:keydex/screens/recovery_request_detail_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey (current user - steward)
  final initiatorPubkey = 'b' * 64; // Initiator of recovery
  final ownerPubkey = 'c' * 64; // Owner of the vault
  final otherStewardPubkey = 'd' * 64; // Another steward

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String lockboxId,
    required String initiatorPubkey,
    RecoveryRequestStatus status = RecoveryRequestStatus.inProgress,
    Map<String, RecoveryResponse>? responses,
  }) {
    return RecoveryRequest(
      id: 'recovery-$lockboxId',
      lockboxId: lockboxId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: status,
      threshold: 2,
      keyHolderResponses: responses ?? {},
    );
  }

  // Helper to create recovery response
  RecoveryResponse createTestRecoveryResponse({
    required String pubkey,
    required bool approved,
    DateTime? respondedAt,
  }) {
    return RecoveryResponse(
      pubkey: pubkey,
      approved: approved,
      respondedAt:
          respondedAt ?? DateTime.now().subtract(const Duration(minutes: 30)),
    );
  }

  // Helper to create lockbox with backup config
  Lockbox createTestLockbox({
    required String id,
    required String name,
    required String ownerPubkey,
    String? ownerName,
    String? instructions,
    List<KeyHolder>? keyHolders,
  }) {
    final defaultKeyHolders = [
      createKeyHolder(pubkey: initiatorPubkey, name: 'Alice'),
      createKeyHolder(pubkey: testPubkey, name: 'Bob'),
      createKeyHolder(pubkey: otherStewardPubkey, name: 'Charlie'),
    ];

    return Lockbox(
      id: id,
      name: name,
      content: null,
      createdAt: DateTime(2024, 10, 1, 10, 30),
      ownerPubkey: ownerPubkey,
      ownerName: ownerName,
      backupConfig: createBackupConfig(
        lockboxId: id,
        threshold: 2,
        totalKeys: (keyHolders ?? defaultKeyHolders).length,
        keyHolders: keyHolders ?? defaultKeyHolders,
        relays: ['wss://relay.example.com'],
        instructions: instructions,
      ),
    );
  }

  group('RecoveryRequestDetailScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: initiatorPubkey,
      );

      final container = ProviderContainer(
        overrides: [
          // Mock the lockbox provider to return loading state
          lockboxProvider('test-lockbox').overrideWith(
            (ref) => Stream.value(null).asyncMap((_) async {
              await Future.delayed(
                const Duration(seconds: 10),
              ); // Never completes to simulate loading
              return null;
            }),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        container: container,
        surfaceSize: const Size(375, 1200),
        waitForSettle: false, // Loading state has infinite animations
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_loading',
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: initiatorPubkey,
      );

      final container = ProviderContainer(
        overrides: [
          // Mock provider to throw an error
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.error('Failed to load lockbox')),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        container: container,
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(tester, 'recovery_request_detail_screen_error');

      container.dispose();
    });

    testGoldens('active request with instructions', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.inProgress,
        responses: {
          otherStewardPubkey: createTestRecoveryResponse(
            pubkey: otherStewardPubkey,
            approved: true,
          ),
        },
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions:
            'Please verify the requester\'s identity before approving. Contact me at alice@example.com if you have any questions.',
        keyHolders: [
          createKeyHolder(pubkey: initiatorPubkey, name: 'Alice'),
          createKeyHolder(pubkey: testPubkey, name: 'Bob'),
          createKeyHolder(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_active_with_instructions',
      );

      container.dispose();
    });

    testGoldens('active request without instructions', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.inProgress,
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: null, // No instructions
        keyHolders: [
          createKeyHolder(pubkey: initiatorPubkey, name: 'Alice'),
          createKeyHolder(pubkey: testPubkey, name: 'Bob'),
          createKeyHolder(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        container: container,
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_active_no_instructions',
      );

      container.dispose();
    });

    testGoldens('request with unknown initiator', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: 'x' * 64, // Unknown pubkey
        status: RecoveryRequestStatus.inProgress,
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'Please verify identity before approving.',
        keyHolders: [
          createKeyHolder(pubkey: testPubkey, name: 'Bob'),
          createKeyHolder(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        container: container,
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_unknown_initiator',
      );

      container.dispose();
    });

    testGoldens('completed request (no action buttons)', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.completed,
        responses: {
          testPubkey: createTestRecoveryResponse(
            pubkey: testPubkey,
            approved: true,
          ),
          otherStewardPubkey: createTestRecoveryResponse(
            pubkey: otherStewardPubkey,
            approved: true,
          ),
        },
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'Recovery completed successfully.',
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        container: container,
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_completed',
      );

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.inProgress,
      );

      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions:
            'Please verify the requester\'s identity before approving.',
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider(
            'test-lockbox',
          ).overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
          name: 'active_request',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_multiple_devices',
      );

      container.dispose();
    });
  });
}
