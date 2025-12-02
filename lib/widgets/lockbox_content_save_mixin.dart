import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lockbox.dart';
import '../models/backup_config.dart';
import '../providers/lockbox_provider.dart';
import '../providers/key_provider.dart';
import '../services/backup_service.dart';
import '../utils/backup_distribution_helper.dart';
import '../utils/invite_code_utils.dart';

/// Mixin for shared lockbox save logic between create and edit screens
mixin LockboxContentSaveMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Save a lockbox (create new or update existing)
  /// Returns the lockbox ID (newly created ID or the existing one)
  Future<String?> saveLockbox({
    required GlobalKey<FormState> formKey,
    required String name,
    required String content,
    String? lockboxId, // null for create, value for update
    String? ownerName,
  }) async {
    if (!formKey.currentState!.validate()) return null;

    try {
      final repository = ref.read(lockboxRepositoryProvider);

      if (lockboxId == null) {
        // Create new lockbox
        final lockbox = await _createNewLockbox(name, content, ownerName);
        await repository.addLockbox(lockbox);
        return lockbox.id;
      } else {
        // Update existing lockbox - check if content, name, or ownerName changed
        final existingLockbox = await repository.getLockbox(lockboxId);
        if (existingLockbox == null) {
          throw Exception('Lockbox not found: $lockboxId');
        }

        final contentChanged = existingLockbox.content != content;
        final nameChanged = existingLockbox.name != name.trim();
        final newOwnerName = ownerName?.trim().isEmpty == true
            ? null
            : ownerName?.trim();
        final ownerNameChanged = existingLockbox.ownerName != newOwnerName;

        // Check if we need to show the regeneration alert
        // Show alert if content/name/ownerName changed AND all key holders have accepted invitations
        bool shouldAutoDistribute = false;
        final willChange = contentChanged || nameChanged || ownerNameChanged;

        if (willChange) {
          if (!mounted) return null;
          final shouldAutoDistributeResult =
              await BackupDistributionHelper.showRegenerationAlertIfNeeded(
                context: context,
                backupConfig: existingLockbox.backupConfig,
                willChange: true,
                mounted: mounted,
              );

          if (shouldAutoDistributeResult == false) {
            // User cancelled or widget disposed, don't save changes
            return null;
          }

          if (shouldAutoDistributeResult == true) {
            shouldAutoDistribute = true;
          }
        }

        // Update lockbox
        await repository.updateLockbox(lockboxId, name, content);

        // Also update ownerName (even if null, to clear it)
        await repository.saveLockbox(
          existingLockbox.copyWith(ownerName: newOwnerName),
        );

        // If content, name, or ownerName changed, increment distributionVersion
        if (contentChanged || nameChanged || ownerNameChanged) {
          final backupService = ref.read(backupServiceProvider);
          await backupService.handleContentChange(lockboxId);

          // If user confirmed, auto-distribute
          if (shouldAutoDistribute) {
            // Reload config to get updated version
            final updatedConfig = await repository.getBackupConfig(lockboxId);
            if (updatedConfig != null && updatedConfig.canDistribute) {
              try {
                await backupService.createAndDistributeBackup(
                  lockboxId: lockboxId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Keys regenerated and distributed successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to distribute keys: $e'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          }
        }

        return lockboxId;
      }
    } catch (e) {
      showError('Failed to save lockbox: ${e.toString()}');
      return null;
    }
  }

  /// Create a new lockbox with the current user's public key
  Future<Lockbox> _createNewLockbox(
    String name,
    String content,
    String? ownerName,
  ) async {
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
      ownerName: ownerName?.trim().isEmpty == true ? null : ownerName?.trim(),
    );
  }

  /// Show an error message to the user
  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
