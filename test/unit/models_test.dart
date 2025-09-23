// Unit Tests for Models
// Testing all model classes: LockboxMetadata, LockboxContent, TextContent, EncryptionKey, NostrKeyPair

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:keydex/models/lockbox.dart';
import 'package:keydex/models/text_content.dart';
import 'package:keydex/models/encryption_key.dart';
import 'package:keydex/models/nostr_key_pair.dart';

void main() {
  group('LockboxMetadata Model Tests', () {
    test('should create LockboxMetadata with valid data', () {
      final createdAt = DateTime.now();
      final metadata = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: createdAt,
        size: 100,
      );

      expect(metadata.id, 'test-id');
      expect(metadata.name, 'Test Lockbox');
      expect(metadata.createdAt, createdAt);
      expect(metadata.size, 100);
      expect(metadata.isValid, true);
    });

    test('should validate name constraints', () {
      final createdAt = DateTime.now();
      
      // Empty name should be invalid
      final invalidMetadata1 = LockboxMetadata(
        id: 'test-id',
        name: '',
        createdAt: createdAt,
        size: 100,
      );
      expect(invalidMetadata1.isValid, false);

      // Long name should be invalid
      final invalidMetadata2 = LockboxMetadata(
        id: 'test-id',
        name: 'a' * 101, // 101 characters
        createdAt: createdAt,
        size: 100,
      );
      expect(invalidMetadata2.isValid, false);
    });

    test('should validate size constraints', () {
      final createdAt = DateTime.now();
      
      // Negative size should be invalid
      final invalidMetadata1 = LockboxMetadata(
        id: 'test-id',
        name: 'Test',
        createdAt: createdAt,
        size: -1,
      );
      expect(invalidMetadata1.isValid, false);

      // Size over 4000 should be invalid
      final invalidMetadata2 = LockboxMetadata(
        id: 'test-id',
        name: 'Test',
        createdAt: createdAt,
        size: 4001,
      );
      expect(invalidMetadata2.isValid, false);
    });

    test('should serialize to and from JSON', () {
      final createdAt = DateTime.parse('2024-01-01T12:00:00.000Z');
      final metadata = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: createdAt,
        size: 100,
      );

      final json = metadata.toJson();
      final fromJson = LockboxMetadata.fromJson(json);

      expect(fromJson.id, metadata.id);
      expect(fromJson.name, metadata.name);
      expect(fromJson.createdAt, metadata.createdAt);
      expect(fromJson.size, metadata.size);
    });

    test('should support copyWith', () {
      final metadata = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      final copied = metadata.copyWith(name: 'Updated Name', size: 200);

      expect(copied.id, metadata.id);
      expect(copied.name, 'Updated Name');
      expect(copied.createdAt, metadata.createdAt);
      expect(copied.size, 200);
    });

    test('should implement equality correctly', () {
      final createdAt = DateTime.now();
      final metadata1 = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: createdAt,
        size: 100,
      );
      final metadata2 = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: createdAt,
        size: 100,
      );
      final metadata3 = LockboxMetadata(
        id: 'different-id',
        name: 'Test Lockbox',
        createdAt: createdAt,
        size: 100,
      );

      expect(metadata1, equals(metadata2));
      expect(metadata1, isNot(equals(metadata3)));
      expect(metadata1.hashCode, equals(metadata2.hashCode));
    });
  });

  group('LockboxContent Model Tests', () {
    test('should create LockboxContent with valid data', () {
      final createdAt = DateTime.now();
      final content = LockboxContent(
        id: 'test-id',
        name: 'Test Lockbox',
        content: 'Secret content',
        createdAt: createdAt,
      );

      expect(content.id, 'test-id');
      expect(content.name, 'Test Lockbox');
      expect(content.content, 'Secret content');
      expect(content.createdAt, createdAt);
      expect(content.isValid, true);
    });

    test('should convert to metadata', () {
      final createdAt = DateTime.now();
      final content = LockboxContent(
        id: 'test-id',
        name: 'Test Lockbox',
        content: 'Secret content',
        createdAt: createdAt,
      );

      final metadata = content.toMetadata();

      expect(metadata.id, content.id);
      expect(metadata.name, content.name);
      expect(metadata.createdAt, content.createdAt);
      expect(metadata.size, content.content.length);
    });

    test('should validate content length', () {
      final createdAt = DateTime.now();
      
      // Content over 4000 characters should be invalid
      final invalidContent = LockboxContent(
        id: 'test-id',
        name: 'Test',
        content: 'a' * 4001,
        createdAt: createdAt,
      );
      expect(invalidContent.isValid, false);
    });

    test('should serialize to and from JSON', () {
      final createdAt = DateTime.parse('2024-01-01T12:00:00.000Z');
      final content = LockboxContent(
        id: 'test-id',
        name: 'Test Lockbox',
        content: 'Secret content',
        createdAt: createdAt,
      );

      final json = content.toJson();
      final fromJson = LockboxContent.fromJson(json);

      expect(fromJson.id, content.id);
      expect(fromJson.name, content.name);
      expect(fromJson.content, content.content);
      expect(fromJson.createdAt, content.createdAt);
    });
  });

  group('TextContent Model Tests', () {
    test('should create TextContent with valid data', () {
      final textContent = TextContent(
        content: 'Some text content',
        lockboxId: 'lockbox-123',
      );

      expect(textContent.content, 'Some text content');
      expect(textContent.lockboxId, 'lockbox-123');
      expect(textContent.size, 17);
      expect(textContent.isEmpty, false);
      expect(textContent.isNotEmpty, true);
      expect(textContent.isValid, true);
    });

    test('should validate content length', () {
      // Valid content
      final validContent = TextContent(
        content: 'a' * 4000,
        lockboxId: 'lockbox-123',
      );
      expect(validContent.isValid, true);

      // Invalid content (too long)
      final invalidContent = TextContent(
        content: 'a' * 4001,
        lockboxId: 'lockbox-123',
      );
      expect(invalidContent.isValid, false);
    });

    test('should validate lockbox ID', () {
      // Valid lockbox ID
      final validContent = TextContent(
        content: 'content',
        lockboxId: 'lockbox-123',
      );
      expect(validContent.isValid, true);

      // Invalid lockbox ID (empty)
      final invalidContent = TextContent(
        content: 'content',
        lockboxId: '',
      );
      expect(invalidContent.isValid, false);
    });

    test('should throw validation exceptions', () {
      final textContent = TextContent(
        content: 'a' * 4001,
        lockboxId: '',
      );

      expect(() => textContent.validateLength(), 
        throwsA(isA<TextContentValidationException>()));
      expect(() => textContent.validateLockboxId(), 
        throwsA(isA<TextContentValidationException>()));
    });

    test('should support copyWith', () {
      final textContent = TextContent(
        content: 'original content',
        lockboxId: 'original-id',
      );

      final copied = textContent.copyWith(
        content: 'new content',
        lockboxId: 'new-id',
      );

      expect(copied.content, 'new content');
      expect(copied.lockboxId, 'new-id');
      expect(textContent.content, 'original content');
      expect(textContent.lockboxId, 'original-id');
    });

    test('should serialize to and from JSON', () {
      final textContent = TextContent(
        content: 'test content',
        lockboxId: 'lockbox-123',
      );

      final json = textContent.toJson();
      final fromJson = TextContent.fromJson(json);

      expect(fromJson.content, textContent.content);
      expect(fromJson.lockboxId, textContent.lockboxId);
    });
  });

  group('EncryptionKey Model Tests', () {
    test('should create EncryptionKey from generated KeyPair', () {
      final keyPair = KeyPair.generate();
      final encryptionKey = EncryptionKey.fromKeyPair(keyPair);

      expect(encryptionKey.privateKey, keyPair.privateKey);
      expect(encryptionKey.publicKey, keyPair.publicKey);
      expect(encryptionKey.isValid, true);
      expect(encryptionKey.isFullKeyPair, true);
      expect(encryptionKey.isPublicOnly, false);
    });

    test('should generate new EncryptionKey', () {
      final encryptionKey = EncryptionKey.generate();

      expect(encryptionKey.privateKey, isNotNull);
      expect(encryptionKey.publicKey, isNotNull);
      expect(encryptionKey.isValid, true);
      expect(encryptionKey.isFullKeyPair, true);
    });

    test('should create EncryptionKey from private key', () {
      final originalKeyPair = KeyPair.generate();
      final encryptionKey = EncryptionKey.fromPrivateKey(originalKeyPair.privateKey!);

      expect(encryptionKey.privateKey, originalKeyPair.privateKey);
      expect(encryptionKey.publicKey, originalKeyPair.publicKey);
      expect(encryptionKey.isValid, true);
    });

    test('should create public-only key', () {
      final originalKey = EncryptionKey.generate();
      final publicOnlyKey = originalKey.toPublicOnly();

      expect(publicOnlyKey.publicKey, originalKey.publicKey);
      expect(publicOnlyKey.privateKey, isNull);
      expect(publicOnlyKey.isPublicOnly, true);
      expect(publicOnlyKey.isFullKeyPair, false);
    });

    test('should validate key format', () {
      final validKey = EncryptionKey.generate();
      expect(validKey.isValid, true);

      // Test with invalid format would require mocking KeyPair
      // This is more of an integration test with the NDK library
    });

    test('should serialize to and from JSON', () {
      final encryptionKey = EncryptionKey.generate();

      final json = encryptionKey.toJson();
      final fromJson = EncryptionKey.fromJson(json);

      expect(fromJson.privateKey, encryptionKey.privateKey);
      expect(fromJson.publicKey, encryptionKey.publicKey);
    });

    test('should throw exception for public-only key serialization', () {
      final fullKey = EncryptionKey.generate();
      final publicOnlyKey = fullKey.toPublicOnly();

      expect(() => publicOnlyKey.toJson(), 
        throwsA(isA<EncryptionKeyException>()));
    });

    test('should implement equality correctly', () {
      final keyPair = KeyPair.generate();
      final key1 = EncryptionKey.fromKeyPair(keyPair);
      final key2 = EncryptionKey.fromKeyPair(keyPair);
      final key3 = EncryptionKey.generate();

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
      expect(key1.hashCode, equals(key2.hashCode));
    });
  });

  group('NostrKeyPair Model Tests', () {
    test('should create NostrKeyPair from KeyPair', () {
      final keyPair = KeyPair.generate();
      final nostrKeyPair = NostrKeyPair.fromKeyPair(keyPair);

      expect(nostrKeyPair.privateKey, keyPair.privateKey);
      expect(nostrKeyPair.publicKey, keyPair.publicKey);
      expect(nostrKeyPair.isValid, true);
      expect(nostrKeyPair.isFullKeyPair, true);
    });

    test('should generate new NostrKeyPair', () {
      final nostrKeyPair = NostrKeyPair.generate();

      expect(nostrKeyPair.privateKey, isNotNull);
      expect(nostrKeyPair.publicKey, isNotNull);
      expect(nostrKeyPair.isValid, true);
      expect(nostrKeyPair.isFullKeyPair, true);
    });

    test('should create from EncryptionKey', () {
      final encryptionKey = EncryptionKey.generate();
      final nostrKeyPair = NostrKeyPair.fromEncryptionKey(encryptionKey);

      expect(nostrKeyPair.privateKey, encryptionKey.privateKey);
      expect(nostrKeyPair.publicKey, encryptionKey.publicKey);
    });

    test('should convert to EncryptionKey', () {
      final nostrKeyPair = NostrKeyPair.generate();
      final encryptionKey = nostrKeyPair.toEncryptionKey();

      expect(encryptionKey.privateKey, nostrKeyPair.privateKey);
      expect(encryptionKey.publicKey, nostrKeyPair.publicKey);
    });

    test('should create from private key hex', () {
      final originalKeyPair = KeyPair.generate();
      final nostrKeyPair = NostrKeyPair.fromPrivateKeyHex(originalKeyPair.privateKey!);

      expect(nostrKeyPair.privateKey, originalKeyPair.privateKey);
      expect(nostrKeyPair.publicKey, originalKeyPair.publicKey);
    });

    test('should create from public key only', () {
      final originalKeyPair = KeyPair.generate();
      final publicOnlyPair = NostrKeyPair.fromPublicKeyHex(originalKeyPair.publicKey);

      expect(publicOnlyPair.publicKey, originalKeyPair.publicKey);
      expect(publicOnlyPair.privateKey, isNull);
      expect(publicOnlyPair.isPublicOnly, true);
    });

    test('should create public-only version', () {
      final fullKeyPair = NostrKeyPair.generate();
      final publicOnly = fullKeyPair.toPublicOnly();

      expect(publicOnly.publicKey, fullKeyPair.publicKey);
      expect(publicOnly.privateKey, isNull);
      expect(publicOnly.isPublicOnly, true);
    });

    test('should serialize to and from JSON', () {
      final nostrKeyPair = NostrKeyPair.generate();

      final json = nostrKeyPair.toJson();
      final fromJson = NostrKeyPair.fromJson(json);

      expect(fromJson.privateKey, nostrKeyPair.privateKey);
      expect(fromJson.publicKey, nostrKeyPair.publicKey);
    });

    test('should validate key format', () {
      final validKeyPair = NostrKeyPair.generate();
      expect(validKeyPair.isValid, true);

      // Test public key length validation
      expect(validKeyPair.publicKey.length, 64);
      if (validKeyPair.privateKey != null) {
        expect(validKeyPair.privateKey!.length, 64);
      }
    });

    test('should implement equality correctly', () {
      final keyPair = KeyPair.generate();
      final nostr1 = NostrKeyPair.fromKeyPair(keyPair);
      final nostr2 = NostrKeyPair.fromKeyPair(keyPair);
      final nostr3 = NostrKeyPair.generate();

      expect(nostr1, equals(nostr2));
      expect(nostr1, isNot(equals(nostr3)));
      expect(nostr1.hashCode, equals(nostr2.hashCode));
    });

    test('should handle bech32 formats', () {
      final nostrKeyPair = NostrKeyPair.generate();

      // Check if bech32 formats are available
      final hasBech32 = nostrKeyPair.hasBech32;
      expect(hasBech32, isA<bool>());

      if (hasBech32) {
        expect(nostrKeyPair.publicKeyBech32, isNotNull);
        expect(nostrKeyPair.privateKeyBech32, isNotNull);
      }
    });
  });

  group('Model Exception Tests', () {
    test('should create proper exception messages', () {
      final lockboxException = LockboxValidationException(
        'Test message', 
        field: 'testField'
      );
      expect(lockboxException.message, 'Test message');
      expect(lockboxException.field, 'testField');

      final textContentException = TextContentValidationException(
        'Content error',
        field: 'content'
      );
      expect(textContentException.message, 'Content error');
      expect(textContentException.field, 'content');

      final encryptionException = EncryptionKeyException(
        'Key error',
        errorCode: 'KEY_ERROR'
      );
      expect(encryptionException.message, 'Key error');
      expect(encryptionException.errorCode, 'KEY_ERROR');

      final nostrException = NostrKeyPairException(
        'Nostr error',
        errorCode: 'NOSTR_ERROR'
      );
      expect(nostrException.message, 'Nostr error');
      expect(nostrException.errorCode, 'NOSTR_ERROR');
    });
  });
}