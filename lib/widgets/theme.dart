import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final keydexTheme = ThemeData(
  primaryColor: const Color(0xFFf47331),
  scaffoldBackgroundColor: const Color(0xFFc1c4b1),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFf47331),
    brightness: Brightness.light,
    secondary: const Color(0xFF212746), // Accent color
    surfaceContainerHighest: const Color(0xFF7f8571), // Border/surface color
  ),
  textTheme: GoogleFonts.archivoTextTheme()
      .apply(
        bodyColor: const Color(0xFF212746), // Primary text color
        displayColor: const Color(0xFF212746), // Primary text color for headlines
      )
      .copyWith(
        bodySmall: GoogleFonts.openSans(
          color: const Color(0xFF676f62), // Secondary text color
        ),
        labelSmall: GoogleFonts.openSans(
          color: const Color(0xFF676f62), // Secondary text color
        ),
      ),
  cardTheme: const CardThemeData(
    color: Color(0xFFc1c4b1), // Same as scaffold background
    elevation: 0,
    // shape: HorizontalBorderShape(
    //   topBorder: BorderSide(color: Color(0xFF7f8571), width: 2),
    //   bottomBorder: BorderSide(color: Color(0xFF7f8571), width: 2),
    // ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFc1c4b1), // Scaffold background color
    foregroundColor: const Color(0xFF212746), // Primary text color
    elevation: 0,
    toolbarHeight: 100.0, // Increased height for more vertical spacing
    titleSpacing: 32.0, // Double the default spacing
    leadingWidth: 32.0,
    titleTextStyle: GoogleFonts.archivo(
      fontSize: 36,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF212746),
    ),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
