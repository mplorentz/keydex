// EncryptionService Implementation
// Handles NIP-44 encryption operations using NDK

import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';
import '../contracts/encryption_service.dart';
import 'key_service.dart';

/// Implementation of EncryptionService using NIP-44 encryption
class EncryptionServiceImpl implements EncryptionService {
  EncryptionServiceImpl({required KeyService keyService}) : _keyService = keyService;

  final KeyService _keyService;

  @override
  Future<String> encryptText(String plaintext) async {
    try {
      if (plaintext.isEmpty) {
        throw EncryptionException(
          'Cannot encrypt empty text',
          errorCode: 'EMPTY_PLAINTEXT',
        );
      }

      if (plaintext.length > 4000) {
        throw EncryptionException(
          'Text too large: ${plaintext.length} characters (max 4000)',
          errorCode: 'TEXT_TOO_LARGE',
        );
      }

      final keyPair = await getCurrentKeyPair();
      if (keyPair == null) {
        throw EncryptionException(
          'No encryption key available. Generate a key pair first.',
          errorCode: 'NO_KEY_PAIR',
        );
      }

      if (keyPair.privateKey == null) {
        throw EncryptionException(
          'Private key not available for encryption',
          errorCode: 'NO_PRIVATE_KEY',
        );
      }

      // Use NIP-44 encryption - return directly without base64 encoding
      return Nip44.encryptMessage(
        plaintext,
        keyPair.privateKey!,
        keyPair.publicKey,
      );
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Encryption failed: ${e.toString()}',
        errorCode: 'ENCRYPTION_FAILED',
      );
    }
  }

  @override
  Future<String> decryptText(String encryptedText) async {
    try {
      if (encryptedText.isEmpty) {
        throw EncryptionException(
          'Cannot decrypt empty text',
          errorCode: 'EMPTY_ENCRYPTED_TEXT',
        );
      }

      final keyPair = await getCurrentKeyPair();
      if (keyPair == null) {
        throw EncryptionException(
          'No encryption key available for decryption',
          errorCode: 'NO_KEY_PAIR',
        );
      }

      if (keyPair.privateKey == null) {
        throw EncryptionException(
          'Private key not available for decryption',
          errorCode: 'NO_PRIVATE_KEY',
        );
      }

      // Use NIP-44 decryption directly - no base64 decoding needed
      return Nip44.decryptMessage(
        encryptedText,
        keyPair.privateKey!,
        keyPair.publicKey,
      );
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Decryption failed: ${e.toString()}',
        errorCode: 'DECRYPTION_FAILED',
      );
    }
  }

  @override
  Future<KeyPair> generateKeyPair() async {
    // Delegate to KeyService
    return await _keyService.generateKeyPair();
  }

  @override
  Future<bool> validateKeyPair(KeyPair keyPair) async {
    // Delegate to KeyService
    return _keyService.validateKeyPair(keyPair);
  }

  @override
  Future<KeyPair?> getCurrentKeyPair() async {
    // Delegate to KeyService
    return await _keyService.getCurrentKeyPair();
  }

  @override
  Future<void> setKeyPair(KeyPair keyPair) async {
    // Delegate to KeyService
    await _keyService.setCurrentKeyPair(keyPair);
  }

  /// Checks if a key pair is currently available
  Future<bool> hasKeyPair() async {
    return await _keyService.hasMasterKey();
  }
}