import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/models/recovery_request.dart';
import 'package:keydex/models/shard_data.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/providers/key_provider.dart';
import 'package:keydex/providers/recovery_provider.dart';
import 'package:keydex/screens/lockbox_detail_screen.dart';
import 'package:keydex/widgets/theme.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;
  final thirdPubkey = 'c' * 64;

  // Helper to create shard data
  ShardData createTestShard({
    required int shardIndex,
    required String recipientPubkey,
    required String lockboxId,
    String lockboxName = 'Test Lockbox',
  }) {
    return createShardData(
      shard: 'test_shard_$shardIndex',
      threshold: 2,
      shardIndex: shardIndex,
      totalShards: 3,
      primeMod: 'test_prime_mod',
      creatorPubkey: testPubkey,
      lockboxId: lockboxId,
      lockboxName: lockboxName,
      peers: [otherPubkey, thirdPubkey],
      recipientPubkey: recipientPubkey,
      isReceived: true,
      receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

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
      respondedAt: respondedAt ?? DateTime.now().subtract(const Duration(minutes: 30)),
      shardData: approved
          ? createTestShard(
              shardIndex: 0,
              recipientPubkey: pubkey,
              lockboxId: 'test-lockbox',
            )
          : null,
    );
  }

  group('LockboxDetailScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Mock the lockbox list provider to return loading state
          lockboxListProvider.overrideWith((ref) => Stream.value([]).asyncMap((_) async {
                await Future.delayed(
                    const Duration(seconds: 10)); // Never completes to simulate loading
                return <Lockbox>[];
              })),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize:
            const Size(375, 1200), // Further increased height to prevent overflow // iPhone SE size
      );

      // Use pump instead of pumpAndSettle for loading state to avoid timeout
      await tester.pump();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_loading');

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Mock provider to throw an error
          lockboxListProvider.overrideWith(
            (ref) => Stream.error('Failed to load lockboxes'),
          ),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Further increased height to prevent overflow
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_error');

      container.dispose();
    });

    testGoldens('lockbox not found', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Mock provider to return empty list (lockbox not found)
          lockboxListProvider.overrideWith(
            (ref) => Stream.value(<Lockbox>[]),
          ),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Further increased height to prevent overflow
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_not_found');

      container.dispose();
    });

    testGoldens('owner - no backup configured', (tester) async {
      final ownedLockbox = Lockbox(
        id: 'test-lockbox',
        name: 'My Private Keys',
        content: null, // Content is encrypted, not shown in detail view
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        shards: [], // No shards yet - backup not configured
        recoveryRequests: [],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([ownedLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Further increased height to prevent overflow
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_owner_no_backup');

      container.dispose();
    });

    testGoldens('owner - backup configured, not in recovery', (tester) async {
      final ownedLockbox = Lockbox(
        id: 'test-lockbox',
        name: 'My Private Keys',
        content: null, // Content is encrypted, not shown in detail view
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(shardIndex: 0, recipientPubkey: otherPubkey, lockboxId: 'test-lockbox'),
          createTestShard(shardIndex: 1, recipientPubkey: thirdPubkey, lockboxId: 'test-lockbox'),
        ],
        recoveryRequests: [], // No active recovery
      );

      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([ownedLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show no active recovery
          recoveryStatusProvider.overrideWith((ref, lockboxId) {
            return const AsyncValue.data(RecoveryStatus(
              hasActiveRecovery: false,
              canRecover: false,
              activeRecoveryRequest: null,
            ));
          }),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Further increased height to prevent overflow
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_owner_backup_no_recovery');

      container.dispose();
    });

    testGoldens('owner - in recovery', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: testPubkey,
        status: RecoveryRequestStatus.inProgress,
        responses: {
          otherPubkey: createTestRecoveryResponse(pubkey: otherPubkey, approved: true),
          thirdPubkey: createTestRecoveryResponse(pubkey: thirdPubkey, approved: false),
        },
      );

      final ownedLockbox = Lockbox(
        id: 'test-lockbox',
        name: 'My Private Keys',
        content: null, // Content is encrypted, not shown in detail view
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(shardIndex: 0, recipientPubkey: otherPubkey, lockboxId: 'test-lockbox'),
          createTestShard(shardIndex: 1, recipientPubkey: thirdPubkey, lockboxId: 'test-lockbox'),
        ],
        recoveryRequests: [recoveryRequest],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([ownedLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show active recovery
          recoveryStatusProvider.overrideWith((ref, lockboxId) {
            return AsyncValue.data(RecoveryStatus(
              hasActiveRecovery: true,
              canRecover: true, // Has enough approvals
              activeRecoveryRequest: recoveryRequest,
            ));
          }),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Further increased height to prevent overflow
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_owner_in_recovery');

      container.dispose();
    });

    testGoldens('shard holder - not in recovery', (tester) async {
      final shardHolderLockbox = Lockbox(
        id: 'test-lockbox',
        name: "Alice's Backup",
        content: null,
        createdAt: DateTime(2024, 9, 15, 14, 20),
        ownerPubkey: otherPubkey, // Different owner
        shards: [
          createTestShard(shardIndex: 1, recipientPubkey: testPubkey, lockboxId: 'test-lockbox'),
        ],
        recoveryRequests: [], // No active recovery
      );

      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([shardHolderLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show no active recovery
          recoveryStatusProvider.overrideWith((ref, lockboxId) {
            return const AsyncValue.data(RecoveryStatus(
              hasActiveRecovery: false,
              canRecover: false,
              activeRecoveryRequest: null,
            ));
          }),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Further increased height to prevent overflow
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_shard_holder_no_recovery');

      container.dispose();
    });

    testGoldens('shard holder - in recovery', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        lockboxId: 'test-lockbox',
        initiatorPubkey: otherPubkey, // Different initiator
        status: RecoveryRequestStatus.inProgress,
        responses: {
          testPubkey: createTestRecoveryResponse(pubkey: testPubkey, approved: true),
          thirdPubkey: createTestRecoveryResponse(pubkey: thirdPubkey, approved: false),
        },
      );

      final shardHolderLockbox = Lockbox(
        id: 'test-lockbox',
        name: "Alice's Backup",
        content: null,
        createdAt: DateTime(2024, 9, 15, 14, 20),
        ownerPubkey: otherPubkey, // Different owner
        shards: [
          createTestShard(shardIndex: 1, recipientPubkey: testPubkey, lockboxId: 'test-lockbox'),
        ],
        recoveryRequests: [recoveryRequest],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([shardHolderLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show active recovery
          recoveryStatusProvider.overrideWith((ref, lockboxId) {
            return AsyncValue.data(RecoveryStatus(
              hasActiveRecovery: true,
              canRecover: false, // Not enough approvals yet
              activeRecoveryRequest: recoveryRequest,
            ));
          }),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxDetailScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Further increased height to prevent overflow
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'lockbox_detail_screen_shard_holder_in_recovery');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final ownedLockbox = Lockbox(
        id: 'test-lockbox',
        name: 'My Private Keys',
        content: null,
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(shardIndex: 0, recipientPubkey: otherPubkey, lockboxId: 'test-lockbox'),
          createTestShard(shardIndex: 1, recipientPubkey: thirdPubkey, lockboxId: 'test-lockbox'),
        ],
        recoveryRequests: [],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxListProvider.overrideWith(
            (ref) => Stream.value([ownedLockbox]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show no active recovery
          recoveryStatusProvider.overrideWith((ref, lockboxId) {
            return const AsyncValue.data(RecoveryStatus(
              hasActiveRecovery: false,
              canRecover: false,
              activeRecoveryRequest: null,
            ));
          }),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.iphone11,
          Device.tabletPortrait,
        ])
        ..addScenario(
          widget: const LockboxDetailScreen(lockboxId: 'test-lockbox'),
          name: 'owner_backup_no_recovery',
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

      await screenMatchesGolden(tester, 'lockbox_detail_screen_multiple_devices');

      container.dispose();
    });
  });
}
