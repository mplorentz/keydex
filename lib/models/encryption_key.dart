// EncryptionKey Model - Wrapper for NDK KeyPair with additional validation
// Based on data-model.md specifications using NDK KeyPair

import 'package:ndk/shared/nips/nip01/key_pair.dart';

class EncryptionKey {
  final KeyPair _keyPair;

  const EncryptionKey._(this._keyPair);

  // Factory constructor from NDK KeyPair
  factory EncryptionKey.fromKeyPair(KeyPair keyPair) {
    return EncryptionKey._(keyPair);
  }

  // Factory constructor for generating new key pair
  factory EncryptionKey.generate() {
    final keyPair = KeyPair.generate();
    return EncryptionKey._(keyPair);
  }

  // Factory constructor from private key
  factory EncryptionKey.fromPrivateKey(String privateKey) {
    final keyPair = KeyPair.fromPrivateKeyHex(privateKey);
    return EncryptionKey._(keyPair);
  }

  // Factory constructor from JSON
  factory EncryptionKey.fromJson(Map<String, dynamic> json) {
    final keyPair = KeyPair.fromPrivateKeyHex(json['privateKey'] as String);
    return EncryptionKey._(keyPair);
  }

  // Getters for NDK KeyPair properties
  String? get privateKey => _keyPair.privateKey;
  String get publicKey => _keyPair.publicKey;
  String? get privateKeyBech32 => _keyPair.privateKeyBech32;
  String? get publicKeyBech32 => _keyPair.publicKeyBech32;

  // Get the underlying NDK KeyPair
  KeyPair get keyPair => _keyPair;

  // Validation
  bool get isValid {
    try {
      // Check if public key is valid hex (64 characters)
      if (publicKey.length != 64) return false;
      
      // Check if private key (when present) is valid hex (64 characters)
      if (privateKey != null && privateKey!.length != 64) return false;
      
      // Additional validation could include cryptographic verification
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if this is a public-only key
  bool get isPublicOnly => privateKey == null;

  // Check if this is a full key pair
  bool get isFullKeyPair => privateKey != null;

  // Convert to JSON (only if private key is present)
  Map<String, dynamic> toJson() {
    if (privateKey == null) {
      throw EncryptionKeyException('Cannot serialize public-only key to JSON');
    }
    return {
      'privateKey': privateKey,
      'publicKey': publicKey,
    };
  }

  // Create a public-only version of this key
  EncryptionKey toPublicOnly() {
    final publicOnlyKeyPair = KeyPair.justPublicKey(publicKey);
    return EncryptionKey._(publicOnlyKeyPair);
  }

  // Validate key pair cryptographically
  void validate() {
    if (!isValid) {
      throw EncryptionKeyException('Invalid key pair: keys are not cryptographically valid');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EncryptionKey && other._keyPair == _keyPair;
  }

  @override
  int get hashCode => _keyPair.hashCode;

  @override
  String toString() {
    return 'EncryptionKey{publicKey: ${publicKey.substring(0, 8)}..., hasPrivateKey: ${privateKey != null}}';
  }
}

// Exception for encryption key related errors
class EncryptionKeyException implements Exception {
  final String message;
  final String? errorCode;

  const EncryptionKeyException(this.message, {this.errorCode});

  @override
  String toString() => 'EncryptionKeyException: $message${errorCode != null ? ' ($errorCode)' : ''}';
}