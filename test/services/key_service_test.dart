import 'package:flutter_test/flutter_test.dart';

import 'package:keydex/services/key_service.dart';
import 'package:keydex/services/stores.dart';

// In-memory fake secure key store
class FakeSecureKeyStore implements SecureKeyStore {
  final Map<String, String> map = {};

  @override
  Future<void> delete({required String key}) async {
    map.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return map[key];
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureKeyStore fakeKeyStore;

  setUp(() async {
    fakeKeyStore = FakeSecureKeyStore();
    KeyService.setKeyStoreForTest(fakeKeyStore);
    await KeyService.clearStoredKeys();
    KeyService.resetCacheForTest();
  });

  tearDown(() async {
    await KeyService.clearStoredKeys();
    KeyService.resetCacheForTest();
  });

  test('generateAndStoreNostrKey persists private key and can reload it', () async {
    // Generate and store
    final keyPair1 = await KeyService.generateAndStoreNostrKey();
    expect(keyPair1.privateKey, isNotNull);
    expect(keyPair1.publicKey, isNotNull);

    // Ensure underlying secure storage contains the value
    // The service uses 'nostr_private_key' as the key
    expect(fakeKeyStore.map.containsKey('nostr_private_key'), isTrue);
    expect(fakeKeyStore.map['nostr_private_key']!.isNotEmpty, isTrue);

    // Reset cache to force a storage read path
    KeyService.resetCacheForTest();

    final keyPair2 = await KeyService.getStoredNostrKey();
    expect(keyPair2, isNotNull);
    expect(keyPair2!.publicKey, equals(keyPair1.publicKey));
    expect(keyPair2.privateKey, equals(keyPair1.privateKey));
  });
}

