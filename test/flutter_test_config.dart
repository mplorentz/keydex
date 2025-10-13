import 'dart:async';
import 'dart:io';

import 'package:golden_toolkit/golden_toolkit.dart';

/// Global test configuration for golden tests
/// Loads bundled fonts from pubspec.yaml (Archivo, OpenSans, RobotoMono)
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      // Load all app fonts from pubspec.yaml fonts section
      // This includes Archivo, OpenSans, and RobotoMono
      await loadAppFonts();

      await testMain();
    },
    config: GoldenToolkitConfiguration(
      enableRealShadows: true,
      // Only validate golden images on macOS to ensure consistent rendering
      // Different platforms (Linux/Windows) have different font engines
      skipGoldenAssertion: () => !Platform.isMacOS,
    ),
  );
}
