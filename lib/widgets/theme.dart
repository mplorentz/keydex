import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HorizontalBorderShape extends ShapeBorder {
  final BorderSide topBorder;
  final BorderSide bottomBorder;

  const HorizontalBorderShape({
    required this.topBorder,
    required this.bottomBorder,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(
        top: topBorder.width,
        bottom: bottomBorder.width,
      );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(Rect.fromLTRB(
        rect.left,
        rect.top + topBorder.width,
        rect.right,
        rect.bottom - bottomBorder.width,
      ));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (topBorder.style != BorderStyle.none) {
      final paint = topBorder.toPaint();
      canvas.drawLine(
        Offset(rect.left, rect.top + topBorder.width / 2),
        Offset(rect.right, rect.top + topBorder.width / 2),
        paint,
      );
    }
    if (bottomBorder.style != BorderStyle.none) {
      final paint = bottomBorder.toPaint();
      canvas.drawLine(
        Offset(rect.left, rect.bottom - bottomBorder.width / 2),
        Offset(rect.right, rect.bottom - bottomBorder.width / 2),
        paint,
      );
    }
  }

  @override
  ShapeBorder scale(double t) {
    return HorizontalBorderShape(
      topBorder: topBorder.scale(t),
      bottomBorder: bottomBorder.scale(t),
    );
  }
}

final keydexTheme = ThemeData(
  primaryColor: const Color(0xFFf47331),
  scaffoldBackgroundColor: const Color(0xFFc1c4b1),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFf47331),
    brightness: Brightness.light,
    secondary: const Color(0xFFdc714e), // Accent color
  ),
  textTheme: GoogleFonts.openSansTextTheme()
      .apply(
        bodyColor: const Color(0xFF212746), // Primary text color
        displayColor: const Color(0xFF212746), // Primary text color for headlines
      )
      .copyWith(
        bodySmall: GoogleFonts.openSans(
          color: const Color(0xFF939683), // Secondary text color
        ),
        labelSmall: GoogleFonts.openSans(
          color: const Color(0xFF939683), // Secondary text color
        ),
      ),
  cardTheme: const CardThemeData(
    color: Color(0xFFc1c4b1), // Same as scaffold background
    elevation: 0,
    shape: HorizontalBorderShape(
      topBorder: BorderSide(color: Color(0xFF7f8571), width: 2),
      bottomBorder: BorderSide(color: Color(0xFF7f8571), width: 2),
    ),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
