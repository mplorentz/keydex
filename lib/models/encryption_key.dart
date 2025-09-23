// EncryptionKey Model
// Wrapper for NDK KeyPair with additional functionality

import 'package:flutter/foundation.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

/// Represents the Nostr key used for encryption/decryption using NDK's KeyPair
@immutable
class EncryptionKey {
  const EncryptionKey({
    required this.keyPair,
    this.createdAt,
  });

  final KeyPair keyPair;
  final DateTime? createdAt;

  /// Creates an EncryptionKey from a KeyPair
  factory EncryptionKey.fromKeyPair(KeyPair keyPair) {
    return EncryptionKey(
      keyPair: keyPair,
      createdAt: DateTime.now(),
    );
  }

  /// Creates an EncryptionKey from JSON
  factory EncryptionKey.fromJson(Map<String, dynamic> json) {
    final keyPair = KeyPair(
      privateKey: json['privateKey'] as String?,
      publicKey: json['publicKey'] as String,
    );
    
    return EncryptionKey(
      keyPair: keyPair,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Converts EncryptionKey to JSON
  Map<String, dynamic> toJson() {
    return {
      'privateKey': keyPair.privateKey,
      'publicKey': keyPair.publicKey,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Gets the private key in hex format
  String? get privateKeyHex => keyPair.privateKey;

  /// Gets the public key in hex format
  String get publicKeyHex => keyPair.publicKey;

  /// Gets the private key in bech32 format (nsec)
  String? get privateKeyBech32 => keyPair.privateKeyBech32;

  /// Gets the public key in bech32 format (npub)
  String get publicKeyBech32 => keyPair.publicKeyBech32;

  /// Validates if the key pair is cryptographically valid
  bool isValid() {
    try {
      // Check if keys are valid hex strings
      if (privateKeyHex != null && privateKeyHex!.length != 64) {
        return false;
      }
      if (publicKeyHex.length != 64) {
        return false;
      }
      
      // Check if they are valid hex
      if (privateKeyHex != null) {
        int.parse(privateKeyHex!, radix: 16);
      }
      int.parse(publicKeyHex, radix: 16);
      
      // Additional validation could be added here to check
      // if the public key is correctly derived from private key
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the key has a private key (can sign and decrypt)
  bool get hasPrivateKey => keyPair.privateKey != null;

  /// Checks if this is a public-key-only instance
  bool get isPublicKeyOnly => keyPair.privateKey == null;

  /// Creates a copy with updated fields
  EncryptionKey copyWith({
    KeyPair? keyPair,
    DateTime? createdAt,
  }) {
    return EncryptionKey(
      keyPair: keyPair ?? this.keyPair,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptionKey &&
          runtimeType == other.runtimeType &&
          keyPair == other.keyPair &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(keyPair, createdAt);

  @override
  String toString() {
    return 'EncryptionKey{publicKey: ${publicKeyHex.substring(0, 8)}..., hasPrivateKey: $hasPrivateKey, createdAt: $createdAt}';
  }
}

/// Exception thrown when encryption key operations fail
class EncryptionKeyException implements Exception {
  final String message;
  final String? errorCode;

  const EncryptionKeyException(this.message, {this.errorCode});

  @override
  String toString() {
    return errorCode != null
        ? 'EncryptionKeyException($errorCode): $message'
        : 'EncryptionKeyException: $message';
  }
}