import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:keydex/services/login_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> secureStore = {};

  setUp(() async {
    // Reset in-memory stores
    secureStore.clear();
    SharedPreferences.setMockInitialValues({});

    // Mock flutter_secure_storage platform channel
    // This simulates secure writes/reads in memory for tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
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

    final loginService = LoginService();
    await loginService.clearStoredKeys();
    loginService.resetCacheForTest();
  });

  tearDown(() async {
    final loginService = LoginService();
    await loginService.clearStoredKeys();
    loginService.resetCacheForTest();
  });

  test('generateAndStoreNostrKey persists private key and can reload it', () async {
    final loginService = LoginService();
    
    // Generate and store
    final keyPair1 = await loginService.generateAndStoreNostrKey();
    expect(keyPair1.privateKey, isNotNull);
    expect(keyPair1.publicKey, isNotNull);

    // Ensure underlying secure storage contains the value
    // The service uses 'nostr_private_key' as the key
    expect(secureStore.containsKey('nostr_private_key'), isTrue);
    expect(secureStore['nostr_private_key']!.isNotEmpty, isTrue);

    // Reset cache to force a storage read path
    loginService.resetCacheForTest();

    final keyPair2 = await loginService.getStoredNostrKey();
    expect(keyPair2, isNotNull);
    expect(keyPair2!.publicKey, equals(keyPair1.publicKey));
    expect(keyPair2.privateKey, equals(keyPair1.privateKey));
  });
}
