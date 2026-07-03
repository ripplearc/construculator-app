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

**File:** `test/features/{feature}/screenshots/{widget}_screenshot_test.dart`

In `setUp`, call `await loadAppFonts()` (from `test/utils/screenshot/font_loader.dart`). Pump the widget inside a `MaterialApp(theme: createTestTheme(), home: Material(child: ...))`. Set `tester.view.physicalSize` and `devicePixelRatio = 1.0` before pumping, `pumpAndSettle()` after, then assert:

```dart
await expectLater(
  find.byType({WidgetToTest}),
  matchesGoldenFile('goldens/{widget}/${size.width}x${size.height}/{widget}_default.png'),
);
```

See `test/features/auth/screenshots/` for a complete example.

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

Use `flutter test --update-goldens <path>` to generate/update, plain `flutter test <path>` to verify.

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
