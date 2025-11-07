import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../utils/invite_code_utils.dart';

/// Mixin for shared lockbox save logic between create and edit screens
mixin LockboxContentSaveMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Save a lockbox (create new or update existing)
  /// Returns the lockbox ID (newly created ID or the existing one)
  Future<String?> saveLockbox({
    required GlobalKey<FormState> formKey,
    required String name,
    required String content,
    String? lockboxId, // null for create, value for update
  }) async {
    if (!formKey.currentState!.validate()) return null;

    try {
      final repository = ref.read(lockboxRepositoryProvider);

      if (lockboxId == null) {
        // Create new lockbox
        final lockbox = await _createNewLockbox(name, content);
        await repository.addLockbox(lockbox);
        return lockbox.id;
      } else {
        // Update existing lockbox
        await repository.updateLockbox(lockboxId, name, content);
        return lockboxId;
      }
    } catch (e) {
      showError('Failed to save lockbox: ${e.toString()}');
      return null;
    }
  }

  /// Create a new lockbox with the current user's public key
  Future<Lockbox> _createNewLockbox(String name, String content) async {
    final loginService = ref.read(loginServiceProvider);
    final currentPubkey = await loginService.getCurrentPublicKey();
    if (currentPubkey == null) {
      throw Exception('Unable to get current user public key');
    }

    // Generate cryptographically secure lockbox ID
    // Lockbox IDs are exposed in invitation URLs, so they must be unguessable
    final lockboxId = generateSecureID();

    return Lockbox(
      id: lockboxId,
      name: name.trim(),
      content: content,
      createdAt: DateTime.now(),
      ownerPubkey: currentPubkey,
    );
  }

  /// Show an error message to the user
  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
