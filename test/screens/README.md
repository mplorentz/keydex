# Golden Tests for Lockbox List Screen

This directory contains golden (screenshot) tests for the Keydex app using [Golden Toolkit](https://pub.dev/packages/golden_toolkit).

## What Are Golden Tests?

Golden tests capture screenshots of your UI and compare them against baseline "golden" images. They help catch unintended visual regressions automatically.

## Running the Tests

### Run all golden tests
```bash
flutter test test/screens
```

### Update golden files (after intentional UI changes)
```bash
flutter test test/screens --update-goldens
```

### Run a specific test
```bash
flutter test test/screens --plain-name="empty state"
```

## Test Coverage

The `lockbox_list_screen_golden_test.dart` includes tests for:

1. **Empty State** - No lockboxes to display
2. **Error State** - Failed to load lockboxes
3. **Single Owned Lockbox** - User owns the lockbox (has content)
4. **Single Key Holder** - User holds a shard for someone else's lockbox
5. **Multiple Lockboxes** - List with multiple lockboxes in different states
6. **Multiple Device Sizes** - Same content on phone, iPhone 11, and tablet

## Golden Files Location

Golden images are stored in: `test/screens/goldens/`

## Workflow

### When Tests Fail

1. **Check the failure directory**: When a golden test fails, diff images are created in `test/screens/failures/` showing:
   - The expected image (golden)
   - The actual rendered image
   - A diff highlighting the differences

2. **Review the changes**:
   - Are the changes intentional? → Update goldens
   - Are they unintended bugs? → Fix the code

3. **Update goldens (if changes are intentional)**:
   ```bash
   flutter test test/screens/lockbox_list_screen_golden_test.dart --update-goldens
   ```

4. **Commit the updated golden files** with your code changes

### In Pull Requests

1. Developer makes UI changes
2. Developer runs `flutter test --update-goldens` locally
3. Developer commits both code + updated golden PNGs
4. Reviewer sees the PNG diff on GitHub
5. Reviewer uses GitHub's image diff viewer (2-up, swipe, onion skin)
6. If changes look good → approve and merge

### GitHub's Image Diff Viewer

When you view a PR with changed PNG files on GitHub, you can:
- **2-up**: See before/after side-by-side
- **Swipe**: Slide between old and new with a draggable divider
- **Onion Skin**: Overlay images with transparency slider
- **Difference**: Highlight changed pixels

## Tips

### Platform Differences ⚠️

**IMPORTANT:** Golden images MUST be generated on macOS only.

Golden tests produce different pixel output on different platforms due to:
- Different font rendering engines (Core Text vs Freetype vs DirectWrite)
- Different anti-aliasing algorithms
- Subtle pixel differences (~5%) even with identical code

The test configuration in `flutter_test_config.dart` includes:
```dart
skipGoldenAssertion: () => !Platform.isMacOS
```

**What this means:**
- ✅ **macOS**: Tests run AND validate against golden images
- ⚠️ **Linux/Windows**: Tests run but SKIP image validation (always pass)
- ⚠️ **CI (if Linux)**: Tests execute but don't actually validate visuals

**Rules for your team:**
1. **Only macOS developers can update goldens**
2. Run `flutter test --update-goldens` only on macOS
3. Linux/Windows devs: Your golden tests will pass but aren't validating anything
4. CI must run on macOS for real validation (or accept that CI only validates code, not visuals)

### Font Rendering

Google Fonts are disabled in tests to avoid HTTP requests. We use a test-specific theme that uses system fonts instead of the app's Google Fonts.

### Layout Overflow Warnings

You may see warnings about RenderFlex overflow during tests. These are usually harmless in tests with fixed surface sizes. If they appear in the actual app, they should be fixed.

## Configuration Files

- `test/flutter_test_config.dart` - Global test configuration
  - Disables Google Fonts fetching
  - Loads app fonts
  - Configures golden toolkit

- `test/screens/lockbox_list_screen_golden_test.dart` - Test file
  - Defines test theme (without Google Fonts)
  - Creates mock data
  - Tests different UI states

## Troubleshooting

### Tests fail with "Font not found"
- Ensure `GoogleFonts.config.allowRuntimeFetching = false` is set in `flutter_test_config.dart`
- Use the test theme instead of the app's theme (which uses Google Fonts)

### Tests timeout
- Check that providers are properly mocked
- Avoid infinite streams or futures that never complete
- Use `pump()` instead of `pumpAndSettle()` for loading states

### Golden images don't match
- Verify you're running on the same platform (macOS)
- Ensure fonts are loaded consistently
- Check that screen sizes match (`surfaceSize` parameter)

## Resources

- [Golden Toolkit Documentation](https://pub.dev/packages/golden_toolkit)
- [Flutter Golden Tests Guide](https://docs.flutter.dev/cookbook/testing/widget/golden-image)
- [Keydex Contributing Guide](../../CONTRIBUTING.md)

