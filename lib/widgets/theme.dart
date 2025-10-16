import 'package:flutter/material.dart';

/// Keydex app theme using bundled Archivo and OpenSans fonts
/// Fonts are bundled in fonts/ directory and declared in pubspec.yaml
final keydexTheme = ThemeData(
  primaryColor: const Color(0xFFdc714e),
  scaffoldBackgroundColor: const Color(0xFFc1c4b1),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFdc714e),
    brightness: Brightness.light,
    secondary: const Color(0xFF21271c), // Accent color
    surfaceContainerHighest: const Color(0xFF7f8571), // Border/surface color
    surfaceContainer: const Color(0xFF464d41), // Icon background color
  ),
  fontFamily: 'Archivo', // Default font family (bundled in fonts/)
  textTheme: const TextTheme(
    // All text styles explicitly use Archivo font (bundled in fonts/)
    bodyMedium: TextStyle(
      color: Color(0xFF21271C), // Primary text color
      fontFamily: 'Archivo',
    ),
    bodySmall: TextStyle(
      color: Color(0xFF676f62), // Secondary text color
      fontFamily: 'OpenSans', // Override to OpenSans for small text
    ),
    labelSmall: TextStyle(
      color: Color(0xFF676f62), // Secondary text color
      fontFamily: 'OpenSans', // Override to OpenSans for labels
    ),
    displayLarge: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    displayMedium: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    displaySmall: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    headlineLarge: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    headlineMedium: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    headlineSmall: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    titleLarge: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    titleMedium: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    titleSmall: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    bodyLarge: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    labelLarge: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
    ),
    labelMedium: TextStyle(
      color: Color(0xFF21271C),
      fontFamily: 'Archivo',
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
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFc1c4b1), // Scaffold background color
    foregroundColor: Color(0xFF21271C), // Primary text color
    elevation: 0,
    toolbarHeight: 100.0, // Increased height for more vertical spacing
    titleSpacing: 32.0, // Double the default spacing
    leadingWidth: 32.0,
    titleTextStyle: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w500,
      color: Color(0xFF21271C),
      fontFamily: 'Archivo', // Uses bundled Archivo font
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    errorStyle: TextStyle(
      fontFamily: 'OpenSans', // Same as bodySmall
      fontSize: 12,
      // Color will be set from theme.colorScheme.error automatically
    ),
    hintStyle: TextStyle(
      color: Color.fromRGBO(
          103, 111, 98, 0.6), // Lighter version of secondary text (0xFF676f62 at 60%)
      fontFamily: 'Archivo',
    ),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
