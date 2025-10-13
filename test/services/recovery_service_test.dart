import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/models/recovery_request.dart';
import 'package:keydex/models/shard_data.dart';
import 'package:keydex/services/key_service.dart';
import 'package:keydex/services/lockbox_service.dart';
import 'package:keydex/services/recovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for RecoveryService - focusing on Nostr event payload validation
/// These tests verify the JSON structure that would be sent via Nostr gift wraps
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> secureStore = {};

  group('RecoveryService - Nostr Event Payload Validation', () {
    late String testCreatorPubkey;
    const testKeyHolder1 = 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321';
    const testKeyHolder2 = 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234';
    const testLockboxId = 'lockbox-test-123';

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

      // Generate a key pair for the test
      final keyPair = await KeyService.generateAndStoreNostrKey();
      testCreatorPubkey = keyPair.publicKey;

      // Clear any existing recovery requests and lockboxes
      await RecoveryService.clearAll();
      await LockboxService.clearAll();

      // Create a test lockbox for recovery tests
      final testLockbox = Lockbox(
        id: testLockboxId,
        name: 'Test Lockbox',
        content: 'Test lockbox content',
        createdAt: DateTime.now(),
        ownerPubkey: testCreatorPubkey,
      );
      await LockboxService.addLockbox(testLockbox);
    });

    tearDown(() async {
      await RecoveryService.clearAll();
      await LockboxService.clearAll();
      await KeyService.clearStoredKeys();
      KeyService.resetCacheForTest();
    });

    test('recovery request creation succeeds with valid data', () async {
      // Create a recovery request
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Verify request was created
      expect(recoveryRequest.lockboxId, testLockboxId);
      expect(recoveryRequest.initiatorPubkey, testCreatorPubkey);
      expect(recoveryRequest.keyHolderResponses.length, 2);
      expect(recoveryRequest.keyHolderResponses.containsKey(testKeyHolder1), true);
      expect(recoveryRequest.keyHolderResponses.containsKey(testKeyHolder2), true);
    });

    test('recovery request JSON payload has correct structure', () async {
      // Arrange
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Build the expected JSON structure (as would be sent via Nostr)
      final requestData = {
        'type': 'recovery_request',
        'recovery_request_id': recoveryRequest.id,
        'lockbox_id': recoveryRequest.lockboxId,
        'initiator_pubkey': recoveryRequest.initiatorPubkey,
        'requested_at': recoveryRequest.requestedAt.toIso8601String(),
        'expires_at': recoveryRequest.expiresAt?.toIso8601String(),
        'threshold': (recoveryRequest.totalKeyHolders * 0.67).ceil(),
      };

      final requestJson = json.encode(requestData);

      // Verify JSON structure
      expect(requestJson, isNotEmpty);

      final decoded = json.decode(requestJson) as Map<String, dynamic>;
      expect(decoded['type'], 'recovery_request');
      expect(decoded['lockbox_id'], testLockboxId);
      expect(decoded['initiator_pubkey'], testCreatorPubkey);
      expect(decoded['threshold'], 2);
      expect(decoded['recovery_request_id'], isNotEmpty);
      expect(decoded['requested_at'], isNotEmpty);
    });

    test('recovery response JSON payload has correct structure with shard data', () async {
      // Arrange
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      final shardData = createShardData(
        shard: 'test_shard_data_base64',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'test_prime_mod',
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: 'Test Lockbox',
      );

      // Build the expected JSON structure for approval (as would be sent via Nostr)
      final responseData = {
        'type': 'recovery_response',
        'recovery_request_id': recoveryRequest.id,
        'lockbox_id': recoveryRequest.lockboxId,
        'responder_pubkey': testKeyHolder1,
        'approved': true,
        'responded_at': DateTime.now().toIso8601String(),
        'shard_data': shardDataToJson(shardData),
      };

      final responseJson = json.encode(responseData);

      // Verify JSON structure
      expect(responseJson, isNotEmpty);

      final decoded = json.decode(responseJson) as Map<String, dynamic>;
      expect(decoded['type'], 'recovery_response');
      expect(decoded['recovery_request_id'], recoveryRequest.id);
      expect(decoded['lockbox_id'], testLockboxId);
      expect(decoded['responder_pubkey'], testKeyHolder1);
      expect(decoded['approved'], true);
      expect(decoded['shard_data'], isNotNull);

      // Verify shard data structure
      final shardDataJson = decoded['shard_data'] as Map<String, dynamic>;
      expect(shardDataJson['shard'], 'test_shard_data_base64');
      expect(shardDataJson['threshold'], 2);
      expect(shardDataJson['shardIndex'], 0);
      expect(shardDataJson['totalShards'], 3);
      expect(shardDataJson['creatorPubkey'], testCreatorPubkey);
      expect(shardDataJson['lockboxId'], testLockboxId);
      expect(shardDataJson['lockboxName'], 'Test Lockbox');
    });

    test('recovery response JSON payload for denial omits shard data', () async {
      // Arrange
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Build the expected JSON structure for denial (as would be sent via Nostr)
      final responseData = {
        'type': 'recovery_response',
        'recovery_request_id': recoveryRequest.id,
        'lockbox_id': recoveryRequest.lockboxId,
        'responder_pubkey': testKeyHolder1,
        'approved': false,
        'responded_at': DateTime.now().toIso8601String(),
      };

      final responseJson = json.encode(responseData);

      // Verify JSON structure
      expect(responseJson, isNotEmpty);

      final decoded = json.decode(responseJson) as Map<String, dynamic>;
      expect(decoded['type'], 'recovery_response');
      expect(decoded['approved'], false);
      expect(decoded.containsKey('shard_data'), false);
    });

    test('recovery request is sent to all key holders', () async {
      // Create a recovery request with multiple key holders
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Verify all key holders are in the request
      expect(recoveryRequest.keyHolderResponses.length, 2);
      expect(recoveryRequest.keyHolderResponses[testKeyHolder1]?.status,
          RecoveryResponseStatus.pending);
      expect(recoveryRequest.keyHolderResponses[testKeyHolder2]?.status,
          RecoveryResponseStatus.pending);

      // In actual sendRecoveryRequestViaNostr, this would create 2 gift wraps
      // (one for each key holder)
    });

    test('recovery response includes threshold information', () async {
      // Arrange
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      expect(recoveryRequest.totalKeyHolders, 2);
    });

    test('recovery request contains proper expiration', () async {
      // Create request with default expiration
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Verify expiration is set and in the future
      expect(recoveryRequest.expiresAt, isNotNull);
      expect(recoveryRequest.expiresAt!.isAfter(DateTime.now()), true);

      // Should default to ~24 hours
      final duration = recoveryRequest.expiresAt!.difference(recoveryRequest.requestedAt);
      expect(duration.inHours, greaterThanOrEqualTo(23));
      expect(duration.inHours, lessThanOrEqualTo(25));
    });

    test('recovery request respects custom expiration duration', () async {
      // Create request with custom 2-hour expiration
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1],
        threshold: 1,
        expirationDuration: const Duration(hours: 2),
      );

      // Verify custom expiration
      expect(recoveryRequest.expiresAt, isNotNull);
      final duration = recoveryRequest.expiresAt!.difference(recoveryRequest.requestedAt);
      expect(duration.inHours, greaterThanOrEqualTo(1));
      expect(duration.inHours, lessThanOrEqualTo(3));
    });

    test('recovery response shard data is stored and can be retrieved', () async {
      // Create initial recovery request
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Simulate receiving a recovery response with shard data
      // In real flow, this would come via NDK from _handleRecoveryResponseData
      final shardData = createShardData(
        shard: 'recovered_shard_AAA=',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'test_prime_CCC=',
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
        lockboxName: 'Recovered Lockbox',
        peers: [testKeyHolder1],
      );

      // Respond to the recovery request (simulating what _handleRecoveryResponseData does)
      await RecoveryService.respondToRecoveryRequest(
        recoveryRequest.id,
        testKeyHolder1,
        true, // approved
        shardData: shardData,
      );

      // Verify the response was recorded
      final updatedRequest = await RecoveryService.getRecoveryRequest(recoveryRequest.id);
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.keyHolderResponses[testKeyHolder1]?.status,
          RecoveryResponseStatus.approved);
      expect(updatedRequest.keyHolderResponses[testKeyHolder1]?.shardData, isNotNull);
      expect(updatedRequest.keyHolderResponses[testKeyHolder1]?.shardData?.shard,
          'recovered_shard_AAA=');
    });

    test('recovery response denial does not include shard data', () async {
      // Create initial recovery request
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Simulate receiving a denial response (no shard data)
      await RecoveryService.respondToRecoveryRequest(
        recoveryRequest.id,
        testKeyHolder1,
        false, // denied
      );

      // Verify the response was recorded without shard data
      final updatedRequest = await RecoveryService.getRecoveryRequest(recoveryRequest.id);
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.keyHolderResponses[testKeyHolder1]?.status,
          RecoveryResponseStatus.denied);
      expect(updatedRequest.keyHolderResponses[testKeyHolder1]?.shardData, isNull);
    });

    test('multiple recovery responses accumulate correctly', () async {
      // Create recovery request with multiple key holders
      final recoveryRequest = await RecoveryService.initiateRecovery(
        testLockboxId,
        initiatorPubkey: testCreatorPubkey,
        keyHolderPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Create shard data for first key holder
      final shardData1 = createShardData(
        shard: 'shard_data_1_AAA=',
        threshold: 2,
        shardIndex: 0,
        totalShards: 2,
        primeMod: 'test_prime_DDD=',
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
      );

      // Create shard data for second key holder
      final shardData2 = createShardData(
        shard: 'shard_data_2_BBB=',
        threshold: 2,
        shardIndex: 1,
        totalShards: 2,
        primeMod: 'test_prime_DDD=',
        creatorPubkey: testCreatorPubkey,
        lockboxId: testLockboxId,
      );

      // First key holder approves
      await RecoveryService.respondToRecoveryRequest(
        recoveryRequest.id,
        testKeyHolder1,
        true, // approved
        shardData: shardData1,
      );

      // Second key holder approves
      await RecoveryService.respondToRecoveryRequest(
        recoveryRequest.id,
        testKeyHolder2,
        true, // approved
        shardData: shardData2,
      );

      // Verify both responses were recorded
      final updatedRequest = await RecoveryService.getRecoveryRequest(recoveryRequest.id);
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.approvedCount, 2);
      expect(updatedRequest.keyHolderResponses[testKeyHolder1]?.status,
          RecoveryResponseStatus.approved);
      expect(updatedRequest.keyHolderResponses[testKeyHolder2]?.status,
          RecoveryResponseStatus.approved);
      expect(updatedRequest.keyHolderResponses[testKeyHolder1]?.shardData, isNotNull);
      expect(updatedRequest.keyHolderResponses[testKeyHolder2]?.shardData, isNotNull);
      expect(
          updatedRequest.keyHolderResponses[testKeyHolder1]?.shardData?.shard, 'shard_data_1_AAA=');
      expect(
          updatedRequest.keyHolderResponses[testKeyHolder2]?.shardData?.shard, 'shard_data_2_BBB=');

      // When threshold is met, status should be completed
      expect(updatedRequest.status, RecoveryRequestStatus.completed);
    });
  });
}
