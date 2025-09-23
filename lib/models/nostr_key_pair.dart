// NostrKeyPair Model
// Extended functionality for Nostr key pairs

import 'package:flutter/foundation.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

/// Extended NostrKeyPair with additional methods and validation
@immutable
class NostrKeyPair {
  const NostrKeyPair({
    required this.keyPair,
    this.label,
    this.createdAt,
  });

  final KeyPair keyPair;
  final String? label;
  final DateTime? createdAt;

  /// Creates a NostrKeyPair from NDK KeyPair
  factory NostrKeyPair.fromKeyPair(KeyPair keyPair, {String? label}) {
    return NostrKeyPair(
      keyPair: keyPair,
      label: label,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a NostrKeyPair from JSON
  factory NostrKeyPair.fromJson(Map<String, dynamic> json) {
    final keyPair = KeyPair(
      privateKey: json['privateKey'] as String?,
      publicKey: json['publicKey'] as String,
    );

    return NostrKeyPair(
      keyPair: keyPair,
      label: json['label'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Converts NostrKeyPair to JSON
  Map<String, dynamic> toJson() {
    return {
      'privateKey': keyPair.privateKey,
      'publicKey': keyPair.publicKey,
      'label': label,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Gets the private key in hex format
  String? get privateKey => keyPair.privateKey;

  /// Gets the public key in hex format
  String get publicKey => keyPair.publicKey;

  /// Gets the private key in bech32 format (nsec)
  String? get privateKeyBech32 => keyPair.privateKeyBech32;

  /// Gets the public key in bech32 format (npub)
  String get publicKeyBech32 => keyPair.publicKeyBech32;

  /// Validates the key pair according to Nostr standards
  bool isValid() {
    try {
      // Check private key format if present
      if (privateKey != null) {
        if (privateKey!.length != 64) return false;
        int.parse(privateKey!, radix: 16);
      }

      // Check public key format
      if (publicKey.length != 64) return false;
      int.parse(publicKey, radix: 16);

      // Check bech32 formats
      if (privateKeyBech32 != null && !privateKeyBech32!.startsWith('nsec1')) {
        return false;
      }
      if (!publicKeyBech32.startsWith('npub1')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the key pair can be used for signing/decryption
  bool get canSign => keyPair.privateKey != null;

  /// Checks if this is a public-key-only instance
  bool get isPublicOnly => keyPair.privateKey == null;

  /// Gets a short identifier for the key pair
  String get shortId => publicKey.substring(0, 8);

  /// Gets the display name (label or short ID)
  String get displayName => label ?? shortId;

  /// Creates a public-only version of this key pair
  NostrKeyPair toPublicOnly() {
    return NostrKeyPair(
      keyPair: KeyPair(
        privateKey: null,
        publicKey: publicKey,
      ),
      label: label,
      createdAt: createdAt,
    );
  }

  /// Creates a copy with updated fields
  NostrKeyPair copyWith({
    KeyPair? keyPair,
    String? label,
    DateTime? createdAt,
  }) {
    return NostrKeyPair(
      keyPair: keyPair ?? this.keyPair,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NostrKeyPair &&
          runtimeType == other.runtimeType &&
          keyPair == other.keyPair &&
          label == other.label &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(keyPair, label, createdAt);

  @override
  String toString() {
    return 'NostrKeyPair{publicKey: $shortId..., canSign: $canSign, label: $label}';
  }
}

/// Exception thrown when Nostr key pair operations fail
class NostrKeyPairException implements Exception {
  final String message;
  final String? errorCode;

  const NostrKeyPairException(this.message, {this.errorCode});

  @override
  String toString() {
    return errorCode != null
        ? 'NostrKeyPairException($errorCode): $message'
        : 'NostrKeyPairException: $message';
  }
}