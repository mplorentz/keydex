// UI Helpers - Utility functions to reduce code duplication in UI components

import 'package:flutter/material.dart';

/// Utility class for common UI operations
class UIHelpers {
  /// Show a success snackbar with consistent styling
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show an error snackbar with consistent styling
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show an info snackbar with consistent styling
  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show a confirmation dialog with consistent styling
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: destructive
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  /// Hide the loading dialog
  static void hideLoadingDialog(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Format datetime consistently across the app
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format file size consistently
  static String formatSize(int size) {
    if (size < 1000) {
      return '$size chars';
    } else if (size < 1000000) {
      final kSize = (size / 1000).toStringAsFixed(1);
      return '${kSize}K chars';
    } else {
      final mSize = (size / 1000000).toStringAsFixed(1);
      return '${mSize}M chars';
    }
  }

  /// Get color for size indicator
  static Color getSizeColor(int size) {
    if (size > 3500) return Colors.red;
    if (size > 3000) return Colors.orange;
    if (size > 2000) return Colors.yellow[700]!;
    return Colors.green;
  }

  /// Common card theme for consistent styling
  static Widget buildCard({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return cardContent;
  }

  /// Build consistent section headers
  static Widget buildSectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  /// Build consistent empty state
  static Widget buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 32),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Build consistent info cards
  static Widget buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
    IconData? icon,
    Color? color,
  }) {
    final cardColor = color ?? Colors.blue;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: cardColor),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cardColor.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cardColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Common validation utilities
class ValidationHelpers {
  /// Validate lockbox name
  static String? validateLockboxName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a name for your lockbox';
    }
    if (value.trim().length > 100) {
      return 'Name cannot exceed 100 characters';
    }
    return null;
  }

  /// Validate content
  static String? validateContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some content';
    }
    if (value.length > 4000) {
      return 'Content cannot exceed 4000 characters';
    }
    return null;
  }

  /// Get character count text with color
  static TextStyle getCharacterCountStyle(int length, int maxLength, BuildContext context) {
    final ratio = length / maxLength;
    Color color;
    
    if (ratio > 1.0) {
      color = Colors.red;
    } else if (ratio > 0.9) {
      color = Colors.orange;
    } else if (ratio > 0.8) {
      color = Colors.yellow[700]!;
    } else {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return TextStyle(color: color, fontSize: 12);
  }
}