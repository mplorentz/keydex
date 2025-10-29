import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

/// Matches a golden file without calling `pumpAndSettle()`.
///
/// This helper is specifically designed for cases where `screenMatchesGolden`
/// would timeout because it calls `pumpAndSettle()` internally, which never
/// completes for widgets with infinite animations like `CircularProgressIndicator`.
///
/// Instead, this function:
/// 1. Pumps the widget tree to ensure layout is complete
/// 2. Uses `expectLater` with `matchesGoldenFile` directly, avoiding
///    the `pumpAndSettle` call that causes timeouts
///
/// Usage:
/// ```dart
/// await tester.pumpWidgetBuilder(...);
/// await tester.pump();
/// await screenMatchesGoldenWithoutSettle<MyWidget>(tester, 'my_widget_loading');
/// ```
///
/// Parameters:
/// - [tester] - The widget tester instance
/// - [goldenName] - The name of the golden file (without path/extension)
Future<void> screenMatchesGoldenWithoutSettle<T extends Widget>(
  WidgetTester tester,
  String goldenName,
) async {
  // Use pump instead of pumpAndSettle to avoid timeout
  await tester.pump();

  // Manually capture the golden without pumpAndSettle
  await expectLater(
    find.byType(T),
    matchesGoldenFile('goldens/$goldenName.png'),
  );
}

/// Matches a golden file without calling `pumpAndSettle()`, using a custom finder.
///
/// This is useful when you need to match a specific widget instance
/// rather than just finding by type.
///
/// Usage:
/// ```dart
/// await tester.pumpWidgetBuilder(...);
/// await tester.pump();
/// await screenMatchesGoldenWithoutSettleWithFinder(
///   tester,
///   'my_widget_loading',
///   find.byKey(myKey),
/// );
/// ```
Future<void> screenMatchesGoldenWithoutSettleWithFinder(
  WidgetTester tester,
  String goldenName,
  Finder finder,
) async {
  // Use pump instead of pumpAndSettle to avoid timeout
  await tester.pump();

  // Manually capture the golden without pumpAndSettle
  await expectLater(
    finder,
    matchesGoldenFile('goldens/$goldenName.png'),
  );
}
