import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/login_service.dart';

/// Provider for LoginService
/// Riverpod automatically ensures this is a singleton - only one instance exists
final loginServiceProvider = Provider<LoginService>((ref) {
  return LoginService();
});

/// FutureProvider for the current public key in hex format
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyProvider = FutureProvider<String?>((ref) async {
  final loginService = ref.watch(loginServiceProvider);
  return await loginService.getCurrentPublicKey();
});

/// FutureProvider for the current public key in bech32 format (npub)
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyBech32Provider = FutureProvider<String?>((ref) async {
  final loginService = ref.watch(loginServiceProvider);
  return await loginService.getCurrentPublicKeyBech32();
});

/// FutureProvider that checks if user is logged in (has a stored private key)
/// Returns true if a key exists, false otherwise
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final loginService = ref.watch(loginServiceProvider);
  final keyPair = await loginService.getStoredNostrKey();
  return keyPair != null;
});
