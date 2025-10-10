import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:keydex/models/lockbox.dart';
import 'package:keydex/services/key_service.dart';
import 'package:keydex/services/lockbox_service.dart' as app_lockbox_service;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> secureStore = {};

  setUp(() async {
    secureStore.clear();
    SharedPreferences.setMockInitialValues({});

    // Mock secure storage
    secureStorageChannel.setMockMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'write':
          final String key = (call.arguments as Map)['key'] as String;
          final String? value = (call.arguments as Map)['value'] as String?;
          if (value == null) {
            secureStore.remove(key);
          } else {
            secureStore[key] = value;
          }
          return null;
        case 'read':
          final String key = (call.arguments as Map)['key'] as String;
          return secureStore[key];
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'delete':
          final String key = (call.arguments as Map)['key'] as String;
          secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'containsKey':
          final String key = (call.arguments as Map)['key'] as String;
          return secureStore.containsKey(key);
        default:
          return null;
      }
    });

    await KeyService.clearStoredKeys();
    KeyService.resetCacheForTest();

    // Ensure no sample data during tests
    app_lockbox_service.LockboxService.disableSampleDataForTest(true);
    await app_lockbox_service.LockboxService.clearAll();
  });

  tearDown(() async {
    await app_lockbox_service.LockboxService.clearAll();
    await KeyService.clearStoredKeys();
    KeyService.resetCacheForTest();
  });

  test('add/get/update/delete lockbox persists via encrypted SharedPreferences', () async {
    // Initialize key so encrypt/decrypt works
    final keyPair = await KeyService.generateAndStoreNostrKey();
    final ownerPubkey = keyPair.publicKey;

    // Start with empty list
    final startList = await app_lockbox_service.LockboxService.getAllLockboxes();
    expect(startList, isEmpty);

    final lockbox = Lockbox(
      id: 'abc',
      name: 'Secret',
      content: 'Top secret content',
      createdAt: DateTime(2024, 1, 1),
      ownerPubkey: ownerPubkey,
    );

    await app_lockbox_service.LockboxService.addLockbox(lockbox);

    // Verify ciphertext stored, not plaintext
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('encrypted_lockboxes');
    expect(encrypted, isNotNull);
    expect(encrypted!.isNotEmpty, isTrue);
    expect(encrypted.contains('Top secret content'), isFalse);
    expect(encrypted.contains('Secret'), isFalse); // name is inside JSON

    // Now load and ensure we can read back decrypted content via service
    final listAfterAdd = await app_lockbox_service.LockboxService.getAllLockboxes();
    expect(listAfterAdd.length, 1);
    final fetched = await app_lockbox_service.LockboxService.getLockbox('abc');
    expect(fetched, isNotNull);
    expect(fetched!.name, 'Secret');
    expect(fetched.content, 'Top secret content');

    // Update
    await app_lockbox_service.LockboxService.updateLockbox('abc', 'Renamed', 'Still hidden');

    final fetched2 = await app_lockbox_service.LockboxService.getLockbox('abc');
    expect(fetched2, isNotNull);
    expect(fetched2!.name, 'Renamed');
    expect(fetched2.content, 'Still hidden');

    // Ensure on disk string does not contain plaintext after update
    final encrypted2 = prefs.getString('encrypted_lockboxes');
    expect(encrypted2, isNotNull);
    expect(encrypted2!.contains('Still hidden'), isFalse);
    expect(encrypted2.contains('Renamed'), isFalse);

    // Delete
    await app_lockbox_service.LockboxService.deleteLockbox('abc');
    final afterDelete = await app_lockbox_service.LockboxService.getLockbox('abc');
    expect(afterDelete, isNull);
  });
}
