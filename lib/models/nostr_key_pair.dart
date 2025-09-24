// NostrKeyPair Model - Extended wrapper for NDK KeyPair with Nostr-specific functionality
// Based on data-model.md specifications using NDK KeyPair

import 'simple_key_pair.dart';
import 'encryption_key.dart';

class NostrKeyPair {
  final KeyPair _keyPair;

  const NostrKeyPair._(this._keyPair);

  // Factory constructor from NDK KeyPair
  factory NostrKeyPair.fromKeyPair(KeyPair keyPair) {
    return NostrKeyPair._(keyPair);
  }

  // Factory constructor from EncryptionKey
  factory NostrKeyPair.fromEncryptionKey(EncryptionKey encryptionKey) {
    return NostrKeyPair._(encryptionKey.keyPair);
  }

  // Factory constructor for generating new key pair
  factory NostrKeyPair.generate() {
    final keyPair = KeyPair.generate();
    return NostrKeyPair._(keyPair);
  }

  // Factory constructor from private key hex
  factory NostrKeyPair.fromPrivateKeyHex(String privateKeyHex) {
    final keyPair = KeyPair.fromPrivateKey(privateKeyHex);
    return NostrKeyPair._(keyPair);
  }

  // Factory constructor from private key bech32 (nsec)
  factory NostrKeyPair.fromPrivateKeyBech32(String privateKeyBech32) {
    final keyPair = KeyPair.fromPrivateKey(privateKeyBech32);
    return NostrKeyPair._(keyPair);
  }

  // Factory constructor from public key only
  factory NostrKeyPair.fromPublicKeyHex(String publicKeyHex) {
    final keyPair = KeyPair.fromPublicKey(publicKeyHex);
    return NostrKeyPair._(keyPair);
  }

  // Factory constructor from JSON
  factory NostrKeyPair.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('privateKey')) {
      return NostrKeyPair.fromPrivateKeyHex(json['privateKey'] as String);
    } else if (json.containsKey('publicKey')) {
      return NostrKeyPair.fromPublicKeyHex(json['publicKey'] as String);
    } else {
      throw NostrKeyPairException('Invalid JSON: missing privateKey or publicKey');
    }
  }

  // Getters for NDK KeyPair properties
  String? get privateKey => _keyPair.privateKey;
  String get publicKey => _keyPair.publicKey;
  String? get privateKeyBech32 => _keyPair.privateKeyBech32;
  String? get publicKeyBech32 => _keyPair.publicKeyBech32;

  // Get the underlying NDK KeyPair
  KeyPair get keyPair => _keyPair;

  // Convert to EncryptionKey
  EncryptionKey toEncryptionKey() {
    return EncryptionKey.fromKeyPair(_keyPair);
  }

  // Validation
  bool get isValid {
    try {
      // Validate hex format and length
      if (publicKey.length != 64) return false;
      if (privateKey != null && privateKey!.length != 64) return false;
      
      // Validate hex characters
      final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
      if (!hexRegex.hasMatch(publicKey)) return false;
      if (privateKey != null && !hexRegex.hasMatch(privateKey!)) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if this is a public-only key
  bool get isPublicOnly => privateKey == null;

  // Check if this is a full key pair
  bool get isFullKeyPair => privateKey != null;

  // Check if bech32 formats are available
  bool get hasBech32 => privateKeyBech32 != null && publicKeyBech32 != null;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'publicKey': publicKey,
    };
    
    if (privateKey != null) {
      json['privateKey'] = privateKey;
    }
    
    if (publicKeyBech32 != null) {
      json['publicKeyBech32'] = publicKeyBech32;
    }
    
    if (privateKeyBech32 != null) {
      json['privateKeyBech32'] = privateKeyBech32;
    }
    
    return json;
  }

  // Create a public-only version of this key pair
  NostrKeyPair toPublicOnly() {
    final publicOnlyKeyPair = KeyPair.fromPublicKey(publicKey);
    return NostrKeyPair._(publicOnlyKeyPair);
  }

  // Validate key pair cryptographically
  void validate() {
    if (!isValid) {
      throw NostrKeyPairException('Invalid Nostr key pair: keys are not valid');
    }
  }

  // Generate a new key pair
  static NostrKeyPair generateNew() {
    return NostrKeyPair.generate();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NostrKeyPair && other._keyPair == _keyPair;
  }

  @override
  int get hashCode => _keyPair.hashCode;

  @override
  String toString() {
    return 'NostrKeyPair{publicKey: ${publicKey.substring(0, 8)}..., hasPrivateKey: ${privateKey != null}, hasBech32: $hasBech32}';
  }
}

// Exception for Nostr key pair related errors
class NostrKeyPairException implements Exception {
  final String message;
  final String? errorCode;

  const NostrKeyPairException(this.message, {this.errorCode});

  @override
  String toString() => 'NostrKeyPairException: $message${errorCode != null ? ' ($errorCode)' : ''}';
}