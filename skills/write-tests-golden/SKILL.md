---
name: write-tests-golden
description: |
  Stage 4: Testing - GATED - Write golden/screenshot tests for layout-sensitive UI changes.
  Visual regression testing to catch unintended UI changes.

  ⚠️ GATED: Only when ticket introduces or changes UI that affects layout, spacing, sizing, component arrangement, or visual themes (for example, new pages, multi-state widgets, or theme changes).

  Trigger: "write golden tests", "create screenshot tests", "add visual tests"

disable-model-invocation: false
---

# Write Tests Golden Skill

**Verb:** Write golden/screenshot tests for visual regression.

⚠️ **GATED** — Only for UI changes that affect layout, spacing, sizing, component arrangement, or visual themes.

## Gate Check

- Write golden tests for new pages, multi-state widgets, critical user journey UI, and visual theme changes.
- Skip golden tests for simple text changes, logic-only changes, backend/domain changes, or when unit tests are sufficient.

## Golden Test Pattern

**File location:** `test/features/{feature}/screenshots/{widget}_screenshot_test.dart`

**Basic structure:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 844); // adjust to the widget's expected dimensions
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('{Widget} Screenshot Tests', () {
    Future<void> pump{Widget}({required WidgetTester tester}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Material(child: {WidgetToTest}()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders default state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await pump{Widget}(tester: tester);

      await expectLater(
        find.byType({WidgetToTest}),
        matchesGoldenFile('goldens/{widget}/${size.width}x${size.height}/{widget}_default.png'),
      );
    });
  });
}
```

## Key Scenarios to Test

| UI State | When to Test |
|----------|--------------|
| **Default/Happy Path** | Always |
| **Loading** | If widget shows loading indicators |
| **Error** | If widget displays error states |
| **Empty** | If widget handles empty data |
| **Long content** | If text/lists can overflow |
| **Light/Dark themes** | For critical UI components |

**Golden files are auto-generated** in `test/features/{feature}/screenshots/goldens/`.

## Running Golden Tests

- Generate/update: `flutter test --update-goldens test/features/{feature}/screenshots/`
- Verify: `flutter test test/features/{feature}/screenshots/`

## Anti-Patterns

| ❌ Don't | ✅ Do |
|---------|------|
| Test every prop combination | Test meaningful visual states |
| Screenshot entire pages | Isolate widget under test |
| Create redundant scenarios | One scenario per unique visual state |
| Test non-visual logic | Use unit/widget tests for logic |

## References

- **Testing Docs:** `docs/Testing/Directories.md` — Screenshot test file structure
- **Examples:** `test/features/auth/screenshots/`
- **Font loader:** `test/utils/screenshot/font_loader.dart` — `loadAppFonts()` + `createTestTheme()`
- **Next:** `write-tests-mutation` skill — Gated skill for logic-heavy changes (3+ branches)
