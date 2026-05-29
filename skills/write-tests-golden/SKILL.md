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
import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('{Widget} Screenshot Tests', () {
    goldenTest(
      '{Widget} displays correctly',
      fileName: '{widget}_name',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'default state',
            child: WidgetToTest(),
          ),
          GoldenTestScenario(
            name: 'loading state',
            child: WidgetToTest(isLoading: true),
          ),
          GoldenTestScenario(
            name: 'error state',
            child: WidgetToTest(error: 'Error message'),
          ),
        ],
      ),
    );
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

## File Organization

```
test/features/{feature}/screenshots/
├── {widget}_screenshot_test.dart
└── goldens/
    └── {widget}_name/
        └── 390.0x56.0/
            ├── {widget}_name_default_state.png
            ├── {widget}_name_loading_state.png
            └── {widget}_name_error_state.png
```

**Golden files are auto-generated.**

## Running Golden Tests

```bash
# Generate/update golden files
flutter test --update-goldens test/features/{feature}/screenshots/

# Verify golden tests
flutter test test/features/{feature}/screenshots/
```

## Anti-Patterns

| ❌ Don't | ✅ Do |
|---------|------|
| Test every prop combination | Test meaningful visual states |
| Screenshot entire pages | Isolate widget under test |
| Create redundant scenarios | One scenario per unique visual state |
| Test non-visual logic | Use unit/widget tests for logic |

## Coverage Notes

- Golden tests **do NOT contribute to code coverage**
- They catch visual regressions, not logic bugs
- Use sparingly for layout-sensitive components

## Key Principles

1. **Gated skill** — Only for layout-sensitive UI changes
2. **Test visual states** — Loading, error, empty, default
3. **Isolate components** — Test widgets, not full pages
4. **Descriptive scenarios** — Clear naming for each visual state
5. **Run with `--update-goldens`** — To generate reference images
6. **Keep scope tight** — Prefer meaningful visual states over prop combinations or full-page screenshots

## References

- **Testing Docs:** `docs/Testing/Directories.md` — Screenshot test file structure
- **Examples:** `test/features/auth/screenshots/`
- **Alchemist Docs:** For advanced golden test patterns
- **Next:** `write-tests-mutation` skill — Gated skill for logic-heavy changes (3+ branches)
