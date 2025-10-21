import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/models/shard_data.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/providers/key_provider.dart';
import 'package:keydex/widgets/key_holder_list.dart';
import 'package:keydex/widgets/theme.dart';
import 'dart:async';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;
  final thirdPubkey = 'c' * 64;
  final fourthPubkey = 'd' * 64;

  // Helper to create shard data
  ShardData createTestShard({
    required int shardIndex,
    required String recipientPubkey,
    required String lockboxId,
    String lockboxName = 'Test Lockbox',
    int threshold = 2,
    List<String>? peers,
  }) {
    return createShardData(
      shard: 'test_shard_$shardIndex',
      threshold: threshold,
      shardIndex: shardIndex,
      totalShards: peers?.length ?? 3,
      primeMod: 'test_prime_mod',
      creatorPubkey: testPubkey,
      lockboxId: lockboxId,
      lockboxName: lockboxName,
      peers: peers ?? [otherPubkey, thirdPubkey],
      recipientPubkey: recipientPubkey,
      isReceived: true,
      receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  // Helper to create lockbox
  Lockbox createTestLockbox({
    required String id,
    required String ownerPubkey,
    List<ShardData>? shards,
  }) {
    return Lockbox(
      id: id,
      name: 'Test Lockbox',
      content: null, // No decrypted content for key holder state
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: ownerPubkey,
      shards: shards ?? [],
    );
  }

  group('KeyHolderList Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => const AsyncValue.loading()),
          currentPublicKeyProvider.overrideWith((ref) => Future.value('test-pubkey')),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
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

      // Use pump instead of pumpAndSettle to avoid timeout
      await tester.pump();

      // Manually capture the golden without pumpAndSettle
      await expectLater(
        find.byType(KeyHolderList),
        matchesGoldenFile('goldens/key_holder_list_loading.png'),
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith(
            (ref) => AsyncValue.error('Failed to load lockbox', StackTrace.current),
          ),
          currentPublicKeyProvider.overrideWith((ref) => Future.value('test-pubkey')),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'key_holder_list_error');

      container.dispose();
    });

    testGoldens('empty state', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: testPubkey,
        shards: [], // No shards
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => AsyncValue.data(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'key_holder_list_empty');

      container.dispose();
    });

    testGoldens('single key holder', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            lockboxId: 'test-lockbox',
            peers: [otherPubkey], // Only one peer
            threshold: 1, // Fix: threshold must be <= totalShards
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => AsyncValue.data(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'key_holder_list_single');

      container.dispose();
    });

    testGoldens('multiple key holders', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            lockboxId: 'test-lockbox',
            peers: [otherPubkey, thirdPubkey, fourthPubkey], // Multiple peers
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => AsyncValue.data(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'key_holder_list_multiple');

      container.dispose();
    });

    testGoldens('key holder viewing list with owner in peers', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: otherPubkey, // Different owner
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey, // Current user is recipient
            lockboxId: 'test-lockbox',
            peers: [otherPubkey, thirdPubkey], // Owner is in peers
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => AsyncValue.data(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 350),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'key_holder_list_with_owner');

      container.dispose();
    });

    testGoldens('key holder viewing list without owner in peers', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: fourthPubkey, // Owner not in peers
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey, // Current user is recipient
            lockboxId: 'test-lockbox',
            peers: [otherPubkey, thirdPubkey], // Owner not in peers
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => AsyncValue.data(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: Scaffold(body: child),
          ),
        ),
        surfaceSize: const Size(375, 350),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'key_holder_list_without_owner');

      container.dispose();
    });

    testGoldens('current user key loading', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            lockboxId: 'test-lockbox',
          ),
        ],
      );

      // Create a completer that never completes to simulate loading
      final completer = Completer<String?>();

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => AsyncValue.data(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => completer.future),
        ],
      );

      await tester.pumpWidgetBuilder(
        const KeyHolderList(lockboxId: 'test-lockbox'),
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

      // Use pump instead of pumpAndSettle to avoid timeout
      await tester.pump();

      // Manually capture the golden without pumpAndSettle
      await expectLater(
        find.byType(KeyHolderList),
        matchesGoldenFile('goldens/key_holder_list_user_loading.png'),
      );

      container.dispose();
    });
  });
}
