import 'package:flutter/material.dart';
import '../models/backup_config.dart';
import '../models/steward_status.dart';

/// Helper functions for backup distribution logic
class BackupDistributionHelper {
  /// Show alert and get user confirmation for key regeneration
  ///
  /// Returns:
  /// - `true` if user confirmed and should auto-distribute
  /// - `false` if user cancelled or widget is not mounted
  /// - `null` if alert should not be shown (stewards still invited)
  ///
  /// Parameters:
  /// - [context] - BuildContext for showing dialog
  /// - [backupConfig] - Current backup configuration
  /// - [willChange] - Whether changes will be made that require redistribution
  /// - [mounted] - Whether the widget is still mounted
  static Future<bool?> showRegenerationAlertIfNeeded({
    required BuildContext context,
    required BackupConfig? backupConfig,
    required bool willChange,
    required bool mounted,
  }) async {
    // Don't show alert if no backup config exists
    if (backupConfig == null) return null;

    // Check if all stewards have accepted invitations (no one is still invited)
    final allStewardsHaveAccepted = backupConfig.stewards.every(
      (h) => h.status != StewardStatus.invited,
    );

    // Only show alert if changes will be made AND all stewards have accepted invitations
    // (Skip alert if any stewards are still invited - waiting for them to accept)
    if (!willChange || !allStewardsHaveAccepted) {
      return null;
    }

    // Show alert asking if user wants to regenerate and distribute keys
    if (!mounted) return false;

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Keys?'),
        content: const Text(
          'Modifying your vault will cause keys to be regenerated. '
          'Proceed with key regeneration and distribution?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Regenerate & Distribute'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || !mounted) {
      // User cancelled or widget disposed
      return false;
    }

    // User confirmed - auto-distribute since all stewards have accepted invitations
    return true;
  }
}
