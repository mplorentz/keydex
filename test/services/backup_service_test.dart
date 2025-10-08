import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/services/backup_service.dart';

void main() {
  group('BackupService - Shamir Secret Sharing', () {
    const testSecret = 'This is a test secret that we want to protect with Shamir Secret Sharing!';
    const testCreatorPubkey = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
    const testLockboxId = 'test-lockbox-123';
    const testLockboxName = 'Test Lockbox';
    // Note: peers list excludes the creator
    const testPeers = [
      'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
      'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
    ];

    test('generateShamirShares creates correct number of shares', () async {
      // Arrange
      const threshold = 3;
      const totalShards = 5;

      // Act
      final shares = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      // Assert
      expect(shares, hasLength(totalShards));
      for (int i = 0; i < totalShards; i++) {
        expect(shares[i].threshold, threshold);
        expect(shares[i].totalShards, totalShards);
        expect(shares[i].shardIndex, i);
        expect(shares[i].creatorPubkey, testCreatorPubkey);
        expect(shares[i].shard, isA<String>());
        expect(shares[i].shard.isNotEmpty, true);
        expect(shares[i].primeMod, isA<String>());
        expect(shares[i].primeMod.isNotEmpty, true);
      }
    });

    test('generateShamirShares creates unique shares', () async {
      // Arrange
      const threshold = 2;
      const totalShards = 3;

      // Act
      final shares = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      // Assert - All shares should be unique
      final shardStrings = shares.map((s) => s.shard).toList();
      expect(shardStrings.toSet().length, totalShards);
    });

    test('reconstructFromShares recovers original secret with minimum threshold', () async {
      // Arrange
      const threshold = 3;
      const totalShards = 5;
      final originalShares = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      // Act - Use exactly threshold number of shares
      final reconstructed = await BackupService.reconstructFromShares(
        shares: originalShares.sublist(0, threshold),
      );

      // Assert
      expect(reconstructed, testSecret);
    });

    test('reconstructFromShares recovers original secret with more than threshold', () async {
      // Arrange
      const threshold = 2;
      const totalShards = 4;
      final originalShares = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      // Act - Use more than threshold shares (all 4)
      final reconstructed = await BackupService.reconstructFromShares(
        shares: originalShares,
      );

      // Assert
      expect(reconstructed, testSecret);
    });

    test('reconstructFromShares works with different share combinations', () async {
      // Arrange
      const threshold = 3;
      const totalShards = 5;
      final originalShares = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      // Act - Try different combinations of threshold shares
      final combination1 = await BackupService.reconstructFromShares(
        shares: [originalShares[0], originalShares[1], originalShares[2]],
      );
      final combination2 = await BackupService.reconstructFromShares(
        shares: [originalShares[1], originalShares[3], originalShares[4]],
      );
      final combination3 = await BackupService.reconstructFromShares(
        shares: [originalShares[0], originalShares[2], originalShares[4]],
      );

      // Assert - All combinations should recover the original secret
      expect(combination1, testSecret);
      expect(combination2, testSecret);
      expect(combination3, testSecret);
    });

    test('reconstructFromShares throws with insufficient shares', () async {
      // Arrange
      const threshold = 3;
      const totalShards = 5;
      final originalShares = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      // Act & Assert - Should throw when fewer than threshold shares provided
      expect(
        () => BackupService.reconstructFromShares(
          shares: originalShares.sublist(0, threshold - 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reconstructFromShares throws with mismatched parameters', () async {
      // Arrange - Create two different share sets
      final shares1 = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: 2,
        totalShards: 3,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );
      final shares2 = await BackupService.generateShamirShares(
        content: 'Different secret',
        threshold: 2,
        totalShards: 3,
        creatorPubkey: 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234',
        lockboxId: 'different-lockbox',
        lockboxName: 'Different Lockbox',
        peers: [
          'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234',
          '1111111111111111111111111111111111111111111111111111111111111111',
          '2222222222222222222222222222222222222222222222222222222222222222',
        ],
      );

      // Act & Assert - Should throw when mixing shares from different sets
      expect(
        () => BackupService.reconstructFromShares(
          shares: [shares1[0], shares2[1]],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reconstructFromShares throws with empty shares list', () async {
      // Act & Assert
      expect(
        () => BackupService.reconstructFromShares(shares: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('generateShamirShares works with long secrets', () async {
      // Arrange - Create a secret longer than 256 bits
      final longSecret = 'A' * 500;
      const threshold = 2;
      const totalShards = 3;

      // Act
      final shares = await BackupService.generateShamirShares(
        content: longSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      final reconstructed = await BackupService.reconstructFromShares(
        shares: shares.sublist(0, threshold),
      );

      // Assert
      expect(reconstructed, longSecret);
    });

    test('generateShamirShares works with special characters', () async {
      // Arrange
      const specialSecret = 'Test with émojis 🔐 and spëcial çhars!@#\$%^&*()';
      const threshold = 2;
      const totalShards = 3;

      // Act
      final shares = await BackupService.generateShamirShares(
        content: specialSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      final reconstructed = await BackupService.reconstructFromShares(
        shares: shares.sublist(0, threshold),
      );

      // Assert
      expect(reconstructed, specialSecret);
    });

    test('reconstructFromShares throws with invalid prime modulus', () async {
      // Arrange
      const threshold = 2;
      const totalShards = 3;

      // Generate valid shares first
      final validShares = await BackupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: testLockboxName,
        peers: testPeers,
      );

      // Create tampered shares with an invalid prime modulus
      const invalidPrimeMod = 'aW52YWxpZFByaW1lTW9kdWx1cw=='; // "invalidPrimeModulus" in base64

      // Import the factory function to create ShardData
      final tamperedShares = validShares.map((share) {
        return (
          shard: share.shard,
          threshold: share.threshold,
          shardIndex: share.shardIndex,
          totalShards: share.totalShards,
          primeMod: invalidPrimeMod, // Replace with invalid prime
          creatorPubkey: share.creatorPubkey,
          createdAt: share.createdAt,
          lockboxId: share.lockboxId,
          lockboxName: share.lockboxName,
          peers: share.peers,
          recipientPubkey: share.recipientPubkey,
          isReceived: share.isReceived,
          receivedAt: share.receivedAt,
          nostrEventId: share.nostrEventId,
        );
      }).toList();

      // Act & Assert
      expect(
        () => BackupService.reconstructFromShares(shares: tamperedShares),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid prime modulus'),
          ),
        ),
      );
    });
  });
}
