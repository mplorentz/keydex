// EncryptionService Contract
// This file defines the interface for NIP-44 encryption operations

abstract class EncryptionService {
  /// Encrypts text content using NIP-44
  /// Returns base64-encoded encrypted string
  Future<String> encryptText(String plaintext);

  /// Decrypts text content using NIP-44
  /// Returns original plaintext
  Future<String> decryptText(String encryptedText);

  /// Generates a new Nostr key pair
  /// Returns the key pair for encryption/decryption
  Future<NostrKeyPair> generateKeyPair();

  /// Validates if a key pair is valid
  /// Returns true if keys are cryptographically valid
  Future<bool> validateKeyPair(NostrKeyPair keyPair);

  /// Gets the current encryption key pair
  /// Returns null if no key exists
  Future<NostrKeyPair?> getCurrentKeyPair();

  /// Sets the encryption key pair
  /// Used for key management and recovery
  Future<void> setKeyPair(NostrKeyPair keyPair);
}

class NostrKeyPair {
  final String privateKey;
  final String publicKey;

  NostrKeyPair({
    required this.privateKey,
    required this.publicKey,
  });
}

class EncryptionException implements Exception {
  final String message;
  final String? errorCode;

  EncryptionException(this.message, {this.errorCode});
}
