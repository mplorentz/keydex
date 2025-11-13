import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import '../helpers/golden_test_helpers.dart';
import 'package:keydex/screens/keydex_gallery_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeydexGallery Golden Test', () {
    testGoldens('gallery screen - keydex2 theme', (tester) async {
      await pumpGoldenWidget(
        tester,
        const KeydexGallery(),
        surfaceSize: const Size(375, 812), // iPhone X size
      );

      await screenMatchesGolden(tester, 'keydex_gallery_screen');
    });
  });
}
