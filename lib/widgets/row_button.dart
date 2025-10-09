import 'package:flutter/material.dart';

/// A full-width button with an icon and text in a row layout
class RowButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? iconSize;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const RowButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = 24,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.primaryColor;
    final effectiveForegroundColor = foregroundColor ?? const Color(0xFFdcd0b5);

    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: effectiveForegroundColor,
              size: iconSize,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: textStyle ??
                  theme.textTheme.titleLarge?.copyWith(
                    color: effectiveForegroundColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
