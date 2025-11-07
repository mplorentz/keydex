import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/backup_config.dart';
import 'package:keydex/models/key_holder.dart';
import 'package:keydex/models/key_holder_status.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/screens/backup_config_screen.dart';
import 'package:keydex/services/login_service.dart';
import 'package:keydex/widgets/theme.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sample test data
  final keyHolder1Pubkey = 'b' * 64;
  final keyHolder2Pubkey = 'c' * 64;

  // Helper to create key holders
  KeyHolder createTestKeyHolder({
    required String pubkey,
    String? name,
    KeyHolderStatus status = KeyHolderStatus.awaitingKey,
  }) {
    return createKeyHolder(
      pubkey: pubkey,
      name: name,
    );
  }

  KeyHolder createTestInvitedKeyHolder({
    required String name,
    required String inviteCode,
  }) {
    return createInvitedKeyHolder(
      name: name,
      inviteCode: inviteCode,
    );
  }

  // Helper to create backup config
  BackupConfig createTestBackupConfig({
    required String lockboxId,
    required int threshold,
    required List<KeyHolder> keyHolders,
    required List<String> relays,
  }) {
    return createBackupConfig(
      lockboxId: lockboxId,
      threshold: threshold,
      totalKeys: keyHolders.length,
      keyHolders: keyHolders,
      relays: relays,
    );
  }

  group('BackupConfigScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      // Create a repository that takes time to load
      final mockRepository = _MockLockboxRepository(null, delay: const Duration(hours: 1));

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await tester.pumpWidgetBuilder(
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      // Capture the loading state
      await tester.pump();

      await screenMatchesGoldenWithoutSettle<BackupConfigScreen>(
        tester,
        'backup_config_screen_loading',
      );

      container.dispose();
    });

    testGoldens('empty state - no existing config', (tester) async {
      // Create a repository that returns null (no existing config)
      final mockRepository = _MockLockboxRepository(null);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await tester.pumpWidgetBuilder(
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1000), // Taller to show full form
      );

      // Wait for async loading to complete
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'backup_config_screen_empty');

      container.dispose();
    });

    testGoldens('with existing config - no key holders', (tester) async {
      final backupConfig = createTestBackupConfig(
        lockboxId: 'test-lockbox',
        threshold: 2,
        keyHolders: [],
        relays: ['wss://relay.example.com'],
      );

      final mockRepository = _MockLockboxRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await tester.pumpWidgetBuilder(
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1000),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'backup_config_screen_no_key_holders');

      container.dispose();
    });

    testGoldens('with existing config - manual key holders', (tester) async {
      final keyHolders = [
        createTestKeyHolder(
          pubkey: keyHolder1Pubkey,
          name: 'Alice',
          status: KeyHolderStatus.awaitingKey,
        ),
        createTestKeyHolder(
          pubkey: keyHolder2Pubkey,
          name: 'Bob',
          status: KeyHolderStatus.awaitingKey,
        ),
      ];

      final backupConfig = createTestBackupConfig(
        lockboxId: 'test-lockbox',
        threshold: 2,
        keyHolders: keyHolders,
        relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
      );

      final mockRepository = _MockLockboxRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await tester.pumpWidgetBuilder(
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200), // Taller to show all key holders
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'backup_config_screen_manual_key_holders');

      container.dispose();
    });

    testGoldens('with existing config - invited key holders', (tester) async {
      final keyHolders = [
        createTestInvitedKeyHolder(
          name: 'Charlie',
          inviteCode: 'invite-code-123',
        ),
        createTestInvitedKeyHolder(
          name: 'Diana',
          inviteCode: 'invite-code-456',
        ),
      ];

      final backupConfig = createTestBackupConfig(
        lockboxId: 'test-lockbox',
        threshold: 2,
        keyHolders: keyHolders,
        relays: ['wss://relay.example.com'],
      );

      final mockRepository = _MockLockboxRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await tester.pumpWidgetBuilder(
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'backup_config_screen_invited_key_holders');

      container.dispose();
    });

    testGoldens('with existing config - mixed key holders', (tester) async {
      final keyHolders = [
        createTestKeyHolder(
          pubkey: keyHolder1Pubkey,
          name: 'Eve',
          status: KeyHolderStatus.holdingKey,
        ),
        createTestInvitedKeyHolder(
          name: 'Frank',
          inviteCode: 'invite-code-789',
        ),
      ];

      final backupConfig = createTestBackupConfig(
        lockboxId: 'test-lockbox',
        threshold: 2,
        keyHolders: keyHolders,
        relays: [
          'wss://relay1.example.com',
          'wss://relay2.example.com',
          'wss://relay3.example.com'
        ],
      );

      final mockRepository = _MockLockboxRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await tester.pumpWidgetBuilder(
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1200),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'backup_config_screen_mixed_key_holders');

      container.dispose();
    });

    testGoldens('with existing config - multiple relays', (tester) async {
      final keyHolders = [
        createTestKeyHolder(
          pubkey: keyHolder1Pubkey,
          name: 'Grace',
        ),
      ];

      final backupConfig = createTestBackupConfig(
        lockboxId: 'test-lockbox',
        threshold: 1,
        keyHolders: keyHolders,
        relays: [
          'wss://relay1.example.com',
          'wss://relay2.example.com',
          'wss://relay3.example.com',
        ],
      );

      final mockRepository = _MockLockboxRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await tester.pumpWidgetBuilder(
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        wrapper: (child) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: keydexTheme,
            home: child,
          ),
        ),
        surfaceSize: const Size(375, 1000),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'backup_config_screen_multiple_relays');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final keyHolders = [
        createTestKeyHolder(
          pubkey: keyHolder1Pubkey,
          name: 'Henry',
        ),
        createTestKeyHolder(
          pubkey: keyHolder2Pubkey,
          name: 'Iris',
        ),
      ];

      final backupConfig = createTestBackupConfig(
        lockboxId: 'test-lockbox',
        threshold: 2,
        keyHolders: keyHolders,
        relays: ['wss://relay.example.com'],
      );

      final mockRepository = _MockLockboxRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ])
        ..addScenario(
          widget: const BackupConfigScreen(lockboxId: 'test-lockbox'),
          name: 'with_key_holders',
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

      await screenMatchesGolden(tester, 'backup_config_screen_multiple_devices');

      container.dispose();
    });
  });
}

/// Mock LockboxRepository for testing
class _MockLockboxRepository extends LockboxRepository {
  final BackupConfig? _backupConfig;
  final Duration? _delay;

  _MockLockboxRepository(this._backupConfig, {Duration? delay})
      : _delay = delay,
        super(LoginService());

  @override
  Future<BackupConfig?> getBackupConfig(String lockboxId) async {
    final delay = _delay;
    if (delay != null) {
      await Future.delayed(delay);
    }
    return _backupConfig;
  }
}
