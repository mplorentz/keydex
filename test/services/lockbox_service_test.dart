import 'package:flutter_test/flutter_test.dart';

import 'package:keydex/models/lockbox.dart';
import 'package:keydex/services/key_service.dart';
import 'package:keydex/services/lockbox_service.dart' as app_lockbox_service;
import 'package:keydex/services/stores.dart';

// In-memory fakes
class FakeSecureKeyStore implements SecureKeyStore {
  final Map<String, String> map = {};
  @override
  Future<void> delete({required String key}) async => map.remove(key);
  @override
  Future<String?> read({required String key}) async => map[key];
  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
  }
}

class FakePreferencesStore implements PreferencesStore {
  final Map<String, String> map = {};
  @override
  Future<String?> getString(String key) async => map[key];
  @override
  Future<void> setString(String key, String value) async => map[key] = value;
  @override
  Future<void> remove(String key) async => map.remove(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureKeyStore fakeKeyStore;
  late FakePreferencesStore fakePrefs;

  setUp(() async {
    fakeKeyStore = FakeSecureKeyStore();
    fakePrefs = FakePreferencesStore();
    KeyService.setKeyStoreForTest(fakeKeyStore);
    app_lockbox_service.LockboxService.setStoresForTest(prefsStore: fakePrefs);
    await KeyService.clearStoredKeys();
    KeyService.resetCacheForTest();
    await app_lockbox_service.LockboxService.clearAll();
  });

  tearDown(() async {
    await app_lockbox_service.LockboxService.clearAll();
    await KeyService.clearStoredKeys();
    KeyService.resetCacheForTest();
  });

  test('add/get/update/delete lockbox persists via encrypted SharedPreferences', () async {
    // Initialize key so encrypt/decrypt works
    await KeyService.generateAndStoreNostrKey();
    // Ensure no sample data is created
    await app_lockbox_service.LockboxService.initialize(createSampleDataIfEmpty: false);

    // Start with empty list
    final startList = await app_lockbox_service.LockboxService.getAllLockboxes();
    expect(startList, isEmpty);

    final lockbox = Lockbox(
      id: 'abc',
      name: 'Secret',
      content: 'Top secret content',
      createdAt: DateTime(2024, 1, 1),
    );

    await app_lockbox_service.LockboxService.addLockbox(lockbox);

    // Verify ciphertext stored, not plaintext
    final encrypted = await fakePrefs.getString('encrypted_lockboxes');
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
    final encrypted2 = await fakePrefs.getString('encrypted_lockboxes');
    expect(encrypted2, isNotNull);
    expect(encrypted2!.contains('Still hidden'), isFalse);
    expect(encrypted2.contains('Renamed'), isFalse);

    // Delete
    await app_lockbox_service.LockboxService.deleteLockbox('abc');
    final afterDelete = await app_lockbox_service.LockboxService.getLockbox('abc');
    expect(afterDelete, isNull);
    // Verify preferences no longer contain the key
    final afterDeleteStored = await fakePrefs.getString('encrypted_lockboxes');
    expect(afterDeleteStored, isNull);
  });
}

