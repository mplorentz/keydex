import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global test configuration for golden tests
/// This loads fonts and configures the test environment
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      // Load Material Design fonts (Roboto) that Golden Toolkit provides
      // This gives us proper text rendering without needing to download fonts
      await loadAppFonts();

      // Configure Google Fonts to use Roboto as a fallback for all fonts
      // This allows us to use the real app theme without HTTP errors
      GoogleFonts.config.allowRuntimeFetching = false;

      await testMain();
    },
    config: GoldenToolkitConfiguration(
      enableRealShadows: true,
      skipGoldenAssertion: () => !Platform.isMacOS,
    ),
  );
}
