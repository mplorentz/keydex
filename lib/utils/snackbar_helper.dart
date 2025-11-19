import 'package:flutter/material.dart';

/// Extension to show SnackBars at the top of the screen
extension TopSnackBar on BuildContext {
  /// Shows a SnackBar at the top of the screen
  void showTopSnackBar(SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(this);

    // Clone the SnackBar with margin positioned at the top
    final topSnackBar = SnackBar(
      content: snackBar.content,
      backgroundColor: snackBar.backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(this).size.height - 100, // Position at top
        left: 16,
        right: 16,
        top: 16,
      ),
      duration: snackBar.duration,
      action: snackBar.action,
      actionOverflowThreshold: snackBar.actionOverflowThreshold,
      animation: snackBar.animation,
      closeIconColor: snackBar.closeIconColor,
      dismissDirection: snackBar.dismissDirection,
      elevation: snackBar.elevation,
      onVisible: snackBar.onVisible,
      padding: snackBar.padding,
      shape: snackBar.shape,
      showCloseIcon: snackBar.showCloseIcon,
      width: snackBar.width,
    );

    messenger.showSnackBar(topSnackBar);
  }
}

/// Custom ScaffoldMessenger wrapper that positions SnackBars at the top
/// This is a simple pass-through widget that doesn't interfere with Flutter's widget tree
class TopSnackBarScaffoldMessenger extends StatelessWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  const TopSnackBarScaffoldMessenger({
    super.key,
    required this.scaffoldMessengerKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Just return the child - MaterialApp already handles ScaffoldMessenger via scaffoldMessengerKey
    return child;
  }
}
