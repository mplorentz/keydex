// EncryptionService Contract
// This file defines the interface for NIP-44 encryption operations
// Uses NDK KeyPair for compatibility

import 'package:ndk/shared/nips/nip01/key_pair.dart';

abstract class EncryptionService {
  /// Encrypts text content using NIP-44
  /// Returns base64-encoded encrypted string
  Future<String> encryptText(String plaintext);

  /// Decrypts text content using NIP-44
  /// Returns original plaintext
  Future<String> decryptText(String encryptedText);

  /// Generates a new Nostr key pair
  /// Returns the KeyPair for encryption/decryption
  Future<KeyPair> generateKeyPair();

  /// Validates if a key pair is valid
  /// Returns true if keys are cryptographically valid
  Future<bool> validateKeyPair(KeyPair keyPair);

  /// Gets the current encryption key pair
  /// Returns null if no key exists
  /// Returns the public key as a string
  Future<KeyPair?> getCurrentKeyPair();

  /// Sets the encryption key pair
  /// Used for key management and recovery
  Future<void> setKeyPair(KeyPair keyPair);
}

class EncryptionException implements Exception {
  final String message;
  final String? errorCode;

  EncryptionException(this.message, {this.errorCode});
}
