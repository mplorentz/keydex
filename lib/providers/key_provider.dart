import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/key_service.dart';

/// FutureProvider for the current public key in hex format
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyProvider = FutureProvider<String?>((ref) async {
  return await KeyService.getCurrentPublicKey();
});

/// FutureProvider for the current public key in bech32 format (npub)
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyBech32Provider = FutureProvider<String?>((ref) async {
  return await KeyService.getCurrentPublicKeyBech32();
});

/// Provider for key repository operations
/// This is a simple Provider (not StateProvider) because it provides
/// a stateless repository object
final keyRepositoryProvider = Provider<KeyRepository>((ref) {
  return KeyRepository(ref);
});

/// Repository class to handle key operations
/// This provides a clean API layer between the UI and the service
class KeyRepository {
  final Ref _ref;

  KeyRepository(this._ref);

  /// Get the current public key in hex format
  Future<String?> getPublicKey() async {
    return await KeyService.getCurrentPublicKey();
  }

  /// Get the current public key in bech32 format (npub)
  Future<String?> getPublicKeyBech32() async {
    return await KeyService.getCurrentPublicKeyBech32();
  }

  /// Clear stored keys and invalidate cached providers
  Future<void> clearKeys() async {
    await KeyService.clearStoredKeys();

    // Invalidate the cached key providers so they'll re-fetch
    _ref.invalidate(currentPublicKeyProvider);
    _ref.invalidate(currentPublicKeyBech32Provider);
  }

  /// Initialize the key (generate if doesn't exist, or load existing)
  Future<void> initializeKey() async {
    await KeyService.initializeKey();

    // Invalidate cached providers to pick up the new key
    _ref.invalidate(currentPublicKeyProvider);
    _ref.invalidate(currentPublicKeyBech32Provider);
  }
}
