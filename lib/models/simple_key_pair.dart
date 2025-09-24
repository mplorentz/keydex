// Simple KeyPair implementation to replace NDK KeyPair for now
// This provides basic functionality while we resolve NDK API issues

import 'dart:math';

class KeyPair {
  final String? privateKey;
  final String publicKey;
  final String? privateKeyBech32;
  final String? publicKeyBech32;

  const KeyPair({
    this.privateKey,
    required this.publicKey,
    this.privateKeyBech32,
    this.publicKeyBech32,
  });

  // Generate a new key pair
  factory KeyPair.generate() {
    final random = Random();
    final privateKey = _generateHexString(64, random);
    final publicKey = _generateHexString(64, random);
    
    return KeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  // Create from private key
  factory KeyPair.fromPrivateKey(String privateKey) {
    // In a real implementation, this would derive the public key
    final random = Random();
    final publicKey = _generateHexString(64, random);
    
    return KeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  // Create public-only key pair
  factory KeyPair.fromPublicKey(String publicKey) {
    return KeyPair(
      publicKey: publicKey,
    );
  }

  // Generate random hex string
  static String _generateHexString(int length, Random random) {
    const chars = '0123456789abcdef';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(16)))
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyPair &&
          runtimeType == other.runtimeType &&
          privateKey == other.privateKey &&
          publicKey == other.publicKey;

  @override
  int get hashCode => privateKey.hashCode ^ publicKey.hashCode;

  @override
  String toString() {
    return 'KeyPair{publicKey: ${publicKey.substring(0, 8)}..., hasPrivateKey: ${privateKey != null}}';
  }
}