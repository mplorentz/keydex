/// Test fixture containing Nostr keys for testing purposes
///
/// These are test keys only and should never be used in production.
/// They are provided for consistent testing across the codebase.
library;

/// Test Nostr private keys in nsec format (bech32 encoded)
class TestNsecKeys {
  static const String alice = 'nsec1upvrf7lmwvept0wm5gyygd34v5kvwy5qfrge5mkxalujkm5s5f7q0dnfwe';
  static const String bob = 'nsec1ngtxruekgq3df5zyq9802kq455hfthpwgv98llj6dpj037e3ywfs2u3tza';
  static const String charlie = 'nsec1skktnkftrgqc4mhmpr2cs2796eap2gzd3k90t2ezqpx7j6tm6q3qvs3w6e';
  static const String diana = 'nsec1u5cks37ta94ma8lc3zn7yv04qt4q9kcedrwy43zp5n0amj94p9wqrhajnx';
}

/// Test Nostr public keys in hex format (64 characters, no 0x prefix)
///
/// These correspond to the nsec keys above and are used for testing
/// when we need the raw hex format for internal operations.
///
/// NOTE: These should be derived from the nsec keys above.
/// To get the actual public keys, run this in a Dart test:
/// ```dart
/// import 'package:ndk/shared/nips/nip01/helpers.dart';
/// import 'package:ndk/shared/nips/nip01/bip340.dart';
///
/// final alicePrivHex = Helpers.decodeBech32(TestNsecKeys.alice)[0];
/// final alicePubHex = Bip340.getPublicKey(alicePrivHex);
/// print('Alice pubkey: $alicePubHex');
/// ```
class TestHexPubkeys {
  // TODO: Replace these with actual derived public keys from the nsec values
  static const String alice = 'f2a3cab5d8706c42d5368aaa18b1a8a8383e3b207d1c36c2d624106aa2e21a48';
  static const String bob = 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321';
  static const String charlie = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
  static const String diana = '9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba';
}

/// Test Nostr public keys in npub format (bech32 encoded)
///
/// These correspond to the nsec keys above and are used for testing
/// when we need the bech32 format for display or user interaction.
class TestNpubKeys {
  static const String alice =
      'npub1alice1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
  static const String bob = 'npub1bob1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
  static const String charlie =
      'npub1charlie1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
  static const String diana =
      'npub1diana1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
}

/// Test data for creating BackupConfig objects
class TestBackupConfigs {
  /// A simple 2-of-2 backup configuration for testing
  static const String simple2of2LockboxId = 'test-lockbox-2of2';
  static const int simple2of2Threshold = 2;
  static const int simple2of2TotalKeys = 2;
  static const List<String> simple2of2Relays = ['ws://localhost:10547'];

  /// A 3-of-4 backup configuration for testing
  static const String complex3of4LockboxId = 'test-lockbox-3of4';
  static const int complex3of4Threshold = 3;
  static const int complex3of4TotalKeys = 4;
  static const List<String> complex3of4Relays = [
    'ws://localhost:10547',
    'wss://relay.example.com',
  ];
}

/// Test data for creating ShardData objects
class TestShardData {
  static const String testPrimeMod =
      '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
  static const String testCreatorPubkey =
      '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';

  /// Creates a list of test shards for a given configuration
  static List<Map<String, dynamic>> createTestShards({
    required int totalShards,
    required int threshold,
  }) {
    return List.generate(
        totalShards,
        (index) => {
              'shard': 'test-shard-data-$index',
              'threshold': threshold,
              'shardIndex': index,
              'totalShards': totalShards,
              'primeMod': testPrimeMod,
              'creatorPubkey': testCreatorPubkey,
            });
  }
}

/// Test data for creating KeyHolder objects
class TestKeyHolders {
  /// Creates a list of test key holders using the test keys
  static List<Map<String, dynamic>> createTestKeyHolders({
    required int count,
  }) {
    final keys = [
      {'pubkey': TestHexPubkeys.alice, 'name': 'Alice'},
      {'pubkey': TestHexPubkeys.bob, 'name': 'Bob'},
      {'pubkey': TestHexPubkeys.charlie, 'name': 'Charlie'},
      {'pubkey': TestHexPubkeys.diana, 'name': 'Diana'},
    ];

    return keys.take(count).toList();
  }
}
