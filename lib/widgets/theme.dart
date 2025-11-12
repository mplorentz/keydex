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

/// Keydex v2 theme (terminal-adjacent, ledger vibes, flat, confident type)
final ThemeData keydex2 = ThemeData(
  // Background slightly lighter / less green than 0xFFC1C4B1
  scaffoldBackgroundColor: const Color(0xFFD5D8C7),
  primaryColor: const Color(0xFFDC714E), // Accent for RowButton, etc.
  // Material 3 color scheme with explicit roles
  // Use an inky neutral as the seed so harmonized roles align with the ledger palette.
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF21271C),
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF243036), // Navy‑Ink as primary
    onPrimary: const Color(0xFFFDFFF0), // Ivory on inky
    secondary: const Color(0xFF7A4A2F), // Umber as secondary
    onSecondary: const Color(0xFFFDFFF0),
    // Calm, ledger-like olive/sage neutrals
    surface: const Color(0xFFD9DDCC),
    onSurface: const Color(0xFF21271C),
    // Match old keydexTheme chip background for icon container in lists
    surfaceContainer: const Color(0xFF464D41),
    // Used around borders and low-contrast elements
    outline: const Color(0xFF7F8571),
    // Used by components that reference surface containers
    surfaceContainerHighest: const Color(0xFF8A917E),
    // Errors tuned to feel flat and readable
    error: const Color(0xFFD95C5C),
    onError: const Color(0xFFFDFFF0),
  ),
  // Keep it flat by removing tint; borderless, lower rounding like list screen
  cardTheme: const CardThemeData(
    color: Color(0xFFD9DDCC),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFD5D8C7),
    foregroundColor: Color(0xFF21271C),
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      fontFamily: 'Archivo',
      color: Color(0xFF21271C),
    ),
  ),
  // Inputs: preserve outlined borders and fill tone from v1 that you liked
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFDDE1CE),
    // Label colors
    labelStyle: const TextStyle(color: Color(0xFF7F8571), fontFamily: 'OpenSans'),
    floatingLabelStyle: const TextStyle(
        color: Color(0xFF7F8571), fontFamily: 'OpenSans', fontWeight: FontWeight.w600),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4), // match lockbox_create_screen
      borderSide: const BorderSide(color: Color(0xFF7F8571), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF7F8571), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF7F8571), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFFD95C5C), width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    hintStyle: const TextStyle(color: Color(0xFF5D695E), fontFamily: 'OpenSans'),
    errorStyle: const TextStyle(fontFamily: 'OpenSans', fontSize: 12),
  ),
  // Text selection and cursor (highlight when selecting text)
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color(0xFF1E2A20),
    selectionColor: Color(0x331E2A20),
    selectionHandleColor: Color(0xFF1E2A20),
  ),
  // Primary buttons: accent with ivory text
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF243036), // Default Elevated = neutral primary
      foregroundColor: const Color(0xFFFDFFF0), // Ivory text
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  // Secondary buttons: rust tone with outlined treatment
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF7A4A2F),
      side: const BorderSide(color: Color(0xFF7A4A2F), width: 1.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
  // Tertiary/text buttons: dark ink, confident type
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF1E2A20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  ),
  // Snackbar: flat, high-contrast
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Color(0xFF2C3227),
    contentTextStyle: TextStyle(color: Color(0xFFE9EDD9), fontFamily: 'OpenSans'),
  ),
  // List tiles to align with LockboxCard spacing/shape and icon emphasis
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    // Match older keydexTheme chevron/icon tone for lists
    iconColor: const Color(0xFF21271C),
    textColor: const Color(0xFF21271C),
    titleTextStyle: const TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Color(0xFF21271C),
    ),
    subtitleTextStyle: const TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      color: Color(0xFF5D695E),
    ),
  ),
  // Menus: flat with ledger paper feel
  popupMenuTheme: const PopupMenuThemeData(
    color: Color(0xFFDDE1CE),
    textStyle: TextStyle(color: Color(0xFF172018), fontFamily: 'OpenSans'),
    surfaceTintColor: Colors.transparent,
  ),
  // Typography: Archivo for titles, OpenSans for body
  fontFamily: 'OpenSans',
  textTheme: const TextTheme(
    // Big/section titles
    displayLarge:
        TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w700, color: Color(0xFF21271C)),
    displayMedium:
        TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w700, color: Color(0xFF21271C)),
    displaySmall: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 36 / 28,
        color: Color(0xFF21271C)),
    headlineLarge:
        TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, color: Color(0xFF21271C)),
    headlineMedium:
        TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, color: Color(0xFF21271C)),
    headlineSmall:
        TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, color: Color(0xFF21271C)),
    // Body content
    bodyLarge: TextStyle(
        fontFamily: 'OpenSans',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 22 / 14,
        color: Color(0xFF21271C)),
    bodyMedium: TextStyle(
        fontFamily: 'OpenSans',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 20 / 14,
        color: Color(0xFF5D695E)),
    bodySmall: TextStyle(
        fontFamily: 'OpenSans',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 16 / 12,
        color: Color(0xFF676F62)),
    // Labels
    labelSmall: TextStyle(
        fontFamily: 'OpenSans',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 16 / 12,
        color: Color(0xFF5D695E)),
    labelMedium:
        TextStyle(fontFamily: 'OpenSans', fontWeight: FontWeight.w600, color: Color(0xFF21271C)),
    labelLarge:
        TextStyle(fontFamily: 'OpenSans', fontWeight: FontWeight.w600, color: Color(0xFF21271C)),
    titleLarge: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 24 / 18,
        color: Color(0xFF21271C)),
    titleMedium:
        TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, color: Color(0xFF21271C)),
    titleSmall:
        TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w600, color: Color(0xFF21271C)),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
