import 'package:flutter/material.dart';
import 'row_button.dart';

/// Configuration for a single button in the stack
class RowButtonConfig {
  final VoidCallback? onPressed; // Nullable for disabled buttons
  final IconData icon;
  final String text;

  const RowButtonConfig({
    required this.onPressed,
    required this.icon,
    required this.text,
  });
}

/// A stack of RowButtons with an automatic gradient from primary orange at bottom
/// to progressively lighter/more muted colors going up
class RowButtonStack extends StatelessWidget {
  final List<RowButtonConfig> buttons;

  const RowButtonStack({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Generate gradient colors
    final colors = _generateGradientColors(buttons.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++)
          RowButton(
            onPressed: buttons[i].onPressed,
            icon: buttons[i].icon,
            text: buttons[i].text,
            backgroundColor: colors[i],
            addBottomSafeArea: i == buttons.length - 1, // Only add safe area to bottom button
          ),
      ],
    );
  }

  /// Generate gradient colors: orange at bottom, then #474d42 getting progressively lighter going up
  List<Color> _generateGradientColors(int count) {
    if (count == 1) {
      return [const Color(0xFFdc714e)]; // Primary orange
    }

    final colors = <Color>[];

    // Primary orange at bottom (last button)
    const primaryOrange = Color(0xFFdc714e);

    // Dark olive-sage base color
    const baseColor = Color(0xFF474d42);

    // Lightest version (for top button) - lighter than base
    const lightestColor = Color(0xFF6f7568);

    for (int i = 0; i < count; i++) {
      if (i == count - 1) {
        // Bottom button is always orange
        colors.add(primaryOrange);
      } else {
        // For buttons above, interpolate from lightest at top to baseColor
        // i = 0 is top (lightest), i = count-2 is just above orange (baseColor)
        final t = count > 2 ? i / (count - 2) : 0.0;
        colors.add(Color.lerp(lightestColor, baseColor, t)!);
      }
    }

    return colors;
  }
}
