import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:keydex/models/nostr_key_pair.dart';
import 'package:keydex/services/encryption_service.dart';
import 'package:keydex/services/key_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'key_service_test.mocks.dart';

@GenerateMocks([EncryptionService, SharedPreferences])
void main() {
  group('KeyService Tests', () {
    late MockEncryptionService mockEncryptionService;
    late MockSharedPreferences mockPrefs;
    late KeyService keyService;
    late KeyPair validKeyPair;

    setUp(() {
      mockEncryptionService = MockEncryptionService();
      mockPrefs = MockSharedPreferences();
      keyService = KeyService(
        encryptionService: mockEncryptionService,
        prefs: mockPrefs,
      );
      
      validKeyPair = KeyPair(
        privateKey: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        publicKey: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      );
    });

    group('Master Key Generation', () {
      test('should generate master key successfully', () async {
        // Arrange
        when(mockEncryptionService.generateKeyPair()).thenAnswer((_) async => validKeyPair);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        final result = await keyService.generateMasterKey(label: 'Test Master Key');

        // Assert
        expect(result.keyPair, equals(validKeyPair));
        expect(result.label, equals('Test Master Key'));
        expect(result.createdAt, isNotNull);
        verify(mockEncryptionService.generateKeyPair()).called(1);
        verify(mockEncryptionService.setKeyPair(validKeyPair)).called(1);
        verify(mockPrefs.setString('master_key', any)).called(1);
        verify(mockPrefs.setString('key_history', any)).called(1);
      });

      test('should generate master key with default label', () async {
        // Arrange
        when(mockEncryptionService.generateKeyPair()).thenAnswer((_) async => validKeyPair);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        final result = await keyService.generateMasterKey();

        // Assert
        expect(result.label, equals('Master Key'));
      });

      test('should throw KeyServiceException when encryption service fails', () async {
        // Arrange
        when(mockEncryptionService.generateKeyPair())
            .thenThrow(Exception('Generation failed'));

        // Act & Assert
        expect(
          () => keyService.generateMasterKey(),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'MASTER_KEY_GENERATION_FAILED',
          )),
        );
      });
    });

    group('Master Key Retrieval', () {
      test('should retrieve master key successfully', () async {
        // Arrange
        final masterKeyData = NostrKeyPair.fromKeyPair(validKeyPair, label: 'Master').toJson();
        when(mockPrefs.getString('master_key')).thenReturn(jsonEncode(masterKeyData));

        // Act
        final result = await keyService.getMasterKey();

        // Assert
        expect(result, isNotNull);
        expect(result!.publicKey, equals(validKeyPair.publicKey));
        expect(result.privateKey, equals(validKeyPair.privateKey));
        verify(mockPrefs.getString('master_key')).called(1);
      });

      test('should return null when no master key exists', () async {
        // Arrange
        when(mockPrefs.getString('master_key')).thenReturn(null);

        // Act
        final result = await keyService.getMasterKey();

        // Assert
        expect(result, isNull);
      });

      test('should check if master key exists', () async {
        // Arrange
        when(mockPrefs.getString('master_key')).thenReturn(null);

        // Act
        final hasMaster = await keyService.hasMasterKey();

        // Assert
        expect(hasMaster, isFalse);
      });

      test('should return true when master key exists', () async {
        // Arrange
        final masterKeyData = NostrKeyPair.fromKeyPair(validKeyPair).toJson();
        when(mockPrefs.getString('master_key')).thenReturn(jsonEncode(masterKeyData));

        // Act
        final hasMaster = await keyService.hasMasterKey();

        // Assert
        expect(hasMaster, isTrue);
      });

      test('should throw KeyServiceException when retrieval fails', () async {
        // Arrange
        when(mockPrefs.getString('master_key')).thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => keyService.getMasterKey(),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'MASTER_KEY_RETRIEVAL_FAILED',
          )),
        );
      });
    });

    group('Key Import - Hex', () {
      test('should import key pair from hex successfully', () async {
        // Arrange
        const privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        when(mockEncryptionService.validateKeyPair(any)).thenAnswer((_) async => true);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        final result = await keyService.importKeyPair(
          privateKeyHex: privateKeyHex,
          label: 'Imported Key',
        );

        // Assert
        expect(result.privateKey, equals(privateKeyHex));
        expect(result.label, equals('Imported Key'));
        verify(mockEncryptionService.validateKeyPair(any)).called(1);
        verify(mockEncryptionService.setKeyPair(any)).called(1);
      });

      test('should import key pair with default label', () async {
        // Arrange
        const privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        when(mockEncryptionService.validateKeyPair(any)).thenAnswer((_) async => true);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        final result = await keyService.importKeyPair(privateKeyHex: privateKeyHex);

        // Assert
        expect(result.label, equals('Imported Key'));
      });

      test('should throw KeyServiceException for invalid private key length', () async {
        // Act & Assert
        expect(
          () => keyService.importKeyPair(privateKeyHex: 'short'),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'INVALID_PRIVATE_KEY_LENGTH',
          )),
        );
      });

      test('should throw KeyServiceException for invalid key pair', () async {
        // Arrange
        const privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        when(mockEncryptionService.validateKeyPair(any)).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => keyService.importKeyPair(privateKeyHex: privateKeyHex),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'INVALID_KEY_PAIR',
          )),
        );
      });

      test('should handle validation exception', () async {
        // Arrange
        const privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        when(mockEncryptionService.validateKeyPair(any))
            .thenThrow(Exception('Validation failed'));

        // Act & Assert
        expect(
          () => keyService.importKeyPair(privateKeyHex: privateKeyHex),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'KEY_IMPORT_FAILED',
          )),
        );
      });
    });

    group('Key Import - Bech32', () {
      test('should import key pair from bech32 successfully', () async {
        // Arrange
        const privateKeyBech32 = 'nsec1test1234567890abcdef1234567890abcdef1234567890abcdef123456';
        when(mockEncryptionService.validateKeyPair(any)).thenAnswer((_) async => true);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        final result = await keyService.importKeyPairBech32(
          privateKeyBech32: privateKeyBech32,
          label: 'Bech32 Imported',
        );

        // Assert
        expect(result.label, equals('Bech32 Imported'));
        verify(mockEncryptionService.validateKeyPair(any)).called(1);
      });

      test('should throw KeyServiceException for invalid private key format', () async {
        // Act & Assert
        expect(
          () => keyService.importKeyPairBech32(privateKeyBech32: 'invalid'),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'INVALID_PRIVATE_KEY_FORMAT',
          )),
        );
      });

      test('should throw KeyServiceException for invalid public key format', () async {
        // Act & Assert
        expect(
          () => keyService.importKeyPairBech32(
            privateKeyBech32: 'nsec1test',
            publicKeyBech32: 'invalid',
          ),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'INVALID_PUBLIC_KEY_FORMAT',
          )),
        );
      });

      test('should handle bech32 conversion failure', () async {
        // Arrange
        const privateKeyBech32 = 'nsec1test1234567890abcdef1234567890abcdef1234567890abcdef123456';
        when(mockEncryptionService.validateKeyPair(any))
            .thenThrow(Exception('Bech32 conversion failed'));

        // Act & Assert
        expect(
          () => keyService.importKeyPairBech32(privateKeyBech32: privateKeyBech32),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'BECH32_IMPORT_FAILED',
          )),
        );
      });
    });

    group('Key Export', () {
      test('should export master key successfully', () async {
        // Arrange
        final masterKeyData = NostrKeyPair.fromKeyPair(validKeyPair, label: 'Master').toJson();
        when(mockPrefs.getString('master_key')).thenReturn(jsonEncode(masterKeyData));

        // Act
        final exported = await keyService.exportMasterKey();

        // Assert
        expect(exported['privateKeyHex'], equals(validKeyPair.privateKey));
        expect(exported['publicKeyHex'], equals(validKeyPair.publicKey));
        expect(exported['privateKeyBech32'], equals(validKeyPair.privateKeyBech32));
        expect(exported['publicKeyBech32'], equals(validKeyPair.publicKeyBech32));
      });

      test('should throw KeyServiceException when no master key exists', () async {
        // Arrange
        when(mockPrefs.getString('master_key')).thenReturn(null);

        // Act & Assert
        expect(
          () => keyService.exportMasterKey(),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'NO_MASTER_KEY',
          )),
        );
      });
    });

    group('Key History', () {
      test('should retrieve key history successfully', () async {
        // Arrange
        final keyHistory = [
          NostrKeyPair.fromKeyPair(validKeyPair, label: 'Key 1').toJson(),
          NostrKeyPair.fromKeyPair(validKeyPair, label: 'Key 2').toJson(),
        ];
        when(mockPrefs.getString('key_history')).thenReturn(jsonEncode(keyHistory));

        // Act
        final history = await keyService.getKeyHistory();

        // Assert
        expect(history, hasLength(2));
        expect(history[0].label, equals('Key 1'));
        expect(history[1].label, equals('Key 2'));
      });

      test('should return empty list when no history exists', () async {
        // Arrange
        when(mockPrefs.getString('key_history')).thenReturn(null);

        // Act
        final history = await keyService.getKeyHistory();

        // Assert
        expect(history, isEmpty);
      });

      test('should handle history retrieval failure', () async {
        // Arrange
        when(mockPrefs.getString('key_history')).thenThrow(Exception('Storage failed'));

        // Act & Assert
        expect(
          () => keyService.getKeyHistory(),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'KEY_HISTORY_RETRIEVAL_FAILED',
          )),
        );
      });
    });

    group('Key Rotation', () {
      test('should rotate master key successfully', () async {
        // Arrange
        final oldKeyPair = KeyPair(
          privateKey: 'old1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          publicKey: 'oldcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final oldMasterData = NostrKeyPair.fromKeyPair(oldKeyPair, label: 'Old Master').toJson();
        
        when(mockPrefs.getString('master_key')).thenReturn(jsonEncode(oldMasterData));
        when(mockEncryptionService.generateKeyPair()).thenAnswer((_) async => validKeyPair);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        final rotatedKey = await keyService.rotateMasterKey(label: 'Rotated Master');

        // Assert
        expect(rotatedKey.label, equals('Rotated Master'));
        expect(rotatedKey.publicKey, equals(validKeyPair.publicKey));
        verify(mockEncryptionService.generateKeyPair()).called(1);
        verify(mockPrefs.setString('key_metadata', any)).called(1);
      });

      test('should handle key rotation failure', () async {
        // Arrange
        when(mockPrefs.getString('master_key')).thenReturn(null);
        when(mockEncryptionService.generateKeyPair())
            .thenThrow(Exception('Generation failed'));

        // Act & Assert
        expect(
          () => keyService.rotateMasterKey(),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'KEY_ROTATION_FAILED',
          )),
        );
      });
    });

    group('Key Reset', () {
      test('should reset all keys successfully', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);
        when(mockEncryptionService.clearKeyPair()).thenAnswer((_) async {});

        // Act
        await keyService.resetAllKeys();

        // Assert
        verify(mockPrefs.remove('master_key')).called(1);
        verify(mockPrefs.remove('key_history')).called(1);
        verify(mockPrefs.remove('key_metadata')).called(1);
        verify(mockEncryptionService.clearKeyPair()).called(1);
      });

      test('should handle reset failure', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenThrow(Exception('Reset failed'));

        // Act & Assert
        expect(
          () => keyService.resetAllKeys(),
          throwsA(isA<KeyServiceException>().having(
            (e) => e.errorCode,
            'error code',
            'RESET_KEYS_FAILED',
          )),
        );
      });
    });

    group('Key Metadata', () {
      test('should store and retrieve key metadata', () async {
        // Arrange
        final metadata = {'lastRotation': DateTime.now().toIso8601String()};
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.getString('key_metadata')).thenReturn(jsonEncode(metadata));

        // Act
        await keyService._storeKeyMetadata(metadata);
        final retrieved = await keyService.getKeyMetadata();

        // Assert
        expect(retrieved, equals(metadata));
      });

      test('should return empty map when no metadata exists', () async {
        // Arrange
        when(mockPrefs.getString('key_metadata')).thenReturn(null);

        // Act
        final metadata = await keyService.getKeyMetadata();

        // Assert
        expect(metadata, isEmpty);
      });

      test('should handle metadata retrieval error gracefully', () async {
        // Arrange
        when(mockPrefs.getString('key_metadata')).thenThrow(Exception('Storage error'));

        // Act
        final metadata = await keyService.getKeyMetadata();

        // Assert
        expect(metadata, isEmpty);
      });
    });

    group('Private Methods - Key History Management', () {
      test('should add key to history correctly', () async {
        // Arrange
        final existingHistory = [
          NostrKeyPair.fromKeyPair(validKeyPair, label: 'Existing').toJson(),
        ];
        when(mockPrefs.getString('key_history')).thenReturn(jsonEncode(existingHistory));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Create a new key pair for testing
        final newKeyPair = KeyPair(
          privateKey: 'new1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          publicKey: 'newcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        );
        final newNostrKey = NostrKeyPair.fromKeyPair(newKeyPair, label: 'New');

        // Act - We can't directly call private method, so we'll test through generateMasterKey
        when(mockEncryptionService.generateKeyPair()).thenAnswer((_) async => newKeyPair);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        await keyService.generateMasterKey(label: 'New');

        // Assert - History should be updated
        verify(mockPrefs.setString('key_history', any)).called(1);
      });

      test('should limit key history to 10 entries', () async {
        // Arrange - Create history with 10 entries
        final existingHistory = List.generate(10, (index) => 
          NostrKeyPair.fromKeyPair(validKeyPair, label: 'Key $index').toJson()
        );
        when(mockPrefs.getString('key_history')).thenReturn(jsonEncode(existingHistory));
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act - Add 11th key through generation
        when(mockEncryptionService.generateKeyPair()).thenAnswer((_) async => validKeyPair);
        when(mockEncryptionService.setKeyPair(any)).thenAnswer((_) async {});

        await keyService.generateMasterKey(label: 'Key 11');

        // Assert - History should still be manageable size
        final historyCapture = verify(mockPrefs.setString('key_history', captureAny)).captured.last as String;
        final savedHistory = jsonDecode(historyCapture) as List;
        expect(savedHistory.length, lessThanOrEqualTo(10));
      });
    });
  });

  group('KeyServiceException Tests', () {
    test('should create exception with message only', () {
      // Act
      final exception = KeyServiceException('Test error message');

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, isNull);
    });

    test('should create exception with message and error code', () {
      // Act
      final exception = KeyServiceException(
        'Test error message',
        errorCode: 'TEST_ERROR',
      );

      // Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.errorCode, equals('TEST_ERROR'));
    });

    test('toString should include error code when present', () {
      // Arrange
      final exception = KeyServiceException(
        'Test error',
        errorCode: 'TEST_ERROR',
      );

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('KeyServiceException(TEST_ERROR)'));
      expect(stringRepresentation, contains('Test error'));
    });

    test('toString should work without error code', () {
      // Arrange
      final exception = KeyServiceException('Test error');

      // Act
      final stringRepresentation = exception.toString();

      // Assert
      expect(stringRepresentation, contains('KeyServiceException:'));
      expect(stringRepresentation, contains('Test error'));
    });
  });
}