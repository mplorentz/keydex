import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/models/shard_data.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/providers/key_provider.dart';
import 'package:keydex/widgets/lockbox_metadata_section.dart';
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
    int threshold = 2,
    List<String>? peers,
  }) {
    return createShardData(
      shard: 'test_shard_$shardIndex',
      threshold: threshold,
      shardIndex: shardIndex,
      totalShards: 3,
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

  group('LockboxMetadataSection Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(null)),
          currentPublicKeyProvider.overrideWith((ref) => Future.value('test-pubkey')),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxMetadataSection(lockboxId: 'test-lockbox'),
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
        find.byType(LockboxMetadataSection),
        matchesGoldenFile('goldens/lockbox_metadata_section_loading.png'),
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith(
            (ref) => Stream.error('Failed to load lockbox'),
          ),
          currentPublicKeyProvider.overrideWith((ref) => Future.value('test-pubkey')),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxMetadataSection(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'lockbox_metadata_section_error');

      container.dispose();
    });

    testGoldens('owner state', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            lockboxId: 'test-lockbox',
            threshold: 2,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxMetadataSection(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'lockbox_metadata_section_owner');

      container.dispose();
    });

    testGoldens('key holder state', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: otherPubkey, // Different owner
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey, // Current user is recipient
            lockboxId: 'test-lockbox',
            threshold: 3,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxMetadataSection(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'lockbox_metadata_section_key_holder');

      container.dispose();
    });

    testGoldens('key holder state with no shards', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: otherPubkey, // Different owner
        shards: [], // No shards
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxMetadataSection(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'lockbox_metadata_section_key_holder_no_shards');

      container.dispose();
    });

    testGoldens('current user key loading', (tester) async {
      final lockbox = createTestLockbox(
        id: 'test-lockbox',
        ownerPubkey: otherPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey,
            lockboxId: 'test-lockbox',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          lockboxProvider('test-lockbox').overrideWith((ref) => Stream.value(lockbox)),
          currentPublicKeyProvider.overrideWith((ref) => Future<String?>.delayed(
                const Duration(seconds: 10),
                () => testPubkey,
              )),
        ],
      );

      await tester.pumpWidgetBuilder(
        const LockboxMetadataSection(lockboxId: 'test-lockbox'),
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

      await screenMatchesGolden(tester, 'lockbox_metadata_section_user_loading');

      container.dispose();
    });
  });
}
