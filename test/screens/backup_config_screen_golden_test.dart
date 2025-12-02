import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:keydex/models/backup_config.dart';
import 'package:keydex/models/key_holder.dart';
import 'package:keydex/models/key_holder_status.dart';
import 'package:keydex/providers/lockbox_provider.dart';
import 'package:keydex/screens/backup_config_screen.dart';
import 'package:keydex/services/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
  final Map<String, dynamic> sharedPreferencesStore = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, (call) async {
          final args = call.arguments as Map? ?? {};
          if (call.method == 'getAll') {
            return Map<String, dynamic>.from(sharedPreferencesStore);
          } else if (call.method == 'setString') {
            sharedPreferencesStore[args['key']] = args['value'];
            return true;
          } else if (call.method == 'getString') {
            return sharedPreferencesStore[args['key']];
          } else if (call.method == 'remove') {
            sharedPreferencesStore.remove(args['key']);
            return true;
          } else if (call.method == 'getStringList') {
            final value = sharedPreferencesStore[args['key']];
            return value is List ? value : null;
          } else if (call.method == 'setStringList') {
            sharedPreferencesStore[args['key']] = args['value'];
            return true;
          } else if (call.method == 'clear') {
            sharedPreferencesStore.clear();
            return true;
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, null);
  });

  // Sample test data
  final keyHolder1Pubkey = 'b' * 64;
  final keyHolder2Pubkey = 'c' * 64;

  // Helper to create key holders
  KeyHolder createTestKeyHolder({
    required String pubkey,
    String? name,
    KeyHolderStatus status = KeyHolderStatus.awaitingKey,
  }) {
    return createKeyHolder(pubkey: pubkey, name: name);
  }

  KeyHolder createTestInvitedKeyHolder({
    required String name,
    required String inviteCode,
  }) {
    return createInvitedKeyHolder(name: name, inviteCode: inviteCode);
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
    setUp(() async {
      sharedPreferencesStore.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('loading state', (tester) async {
      // Create a repository that never completes loading
      final mockRepository = _MockLockboxRepository(null, neverCompletes: true);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        container: container,
        waitForSettle: false, // Loading state
      );

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

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        container: container,
        surfaceSize: const Size(375, 1000), // Taller to show full form
      );

      await screenMatchesGolden(tester, 'backup_config_screen_empty');

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

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        container: container,
        surfaceSize: const Size(375, 1200), // Taller to show all key holders
      );

      await screenMatchesGolden(
        tester,
        'backup_config_screen_manual_key_holders',
      );

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

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'backup_config_screen_invited_key_holders',
      );

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
          'wss://relay3.example.com',
        ],
      );

      final mockRepository = _MockLockboxRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          lockboxRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'backup_config_screen_mixed_key_holders',
      );

      container.dispose();
    });

    testGoldens('with existing config - multiple relays', (tester) async {
      final keyHolders = [
        createTestKeyHolder(pubkey: keyHolder1Pubkey, name: 'Grace'),
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

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(lockboxId: 'test-lockbox'),
        container: container,
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(tester, 'backup_config_screen_multiple_relays');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final keyHolders = [
        createTestKeyHolder(pubkey: keyHolder1Pubkey, name: 'Henry'),
        createTestKeyHolder(pubkey: keyHolder2Pubkey, name: 'Iris'),
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
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const BackupConfigScreen(lockboxId: 'test-lockbox'),
          name: 'with_key_holders',
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
        'backup_config_screen_multiple_devices',
      );

      container.dispose();
    });
  });
}

/// Mock LockboxRepository for testing
class _MockLockboxRepository extends LockboxRepository {
  final BackupConfig? _backupConfig;
  final bool _neverCompletes;

  _MockLockboxRepository(this._backupConfig, {bool neverCompletes = false})
    : _neverCompletes = neverCompletes,
      super(LoginService());

  @override
  Future<BackupConfig?> getBackupConfig(String lockboxId) async {
    if (_neverCompletes) {
      // Use a Completer that never completes to simulate loading state
      final completer = Completer<BackupConfig?>();
      return completer.future; // This will never complete
    }
    return _backupConfig;
  }
}
