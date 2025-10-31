import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/key_service.dart';

/// Provider for KeyService
/// Riverpod automatically ensures this is a singleton - only one instance exists
final keyServiceProvider = Provider<KeyService>((ref) {
  return KeyService();
});

/// FutureProvider for the current public key in hex format
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyProvider = FutureProvider<String?>((ref) async {
  final keyService = ref.watch(keyServiceProvider);
  return await keyService.getCurrentPublicKey();
});

/// FutureProvider for the current public key in bech32 format (npub)
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyBech32Provider = FutureProvider<String?>((ref) async {
  final keyService = ref.watch(keyServiceProvider);
  return await keyService.getCurrentPublicKeyBech32();
});
