# RULE 14: Accessibility (A11y) Testing

## Rule ID
RULE_14

## Category
Testing - Accessibility

## Severity Levels
- **Critical:** Interactive elements without semantic labels or removing semantics without justification
- **Major:** UI changes to key screens without updating a11y tests
- **Minor:** Missing accessibility checks in widget tests for new interactive elements
- **Suggestion:** Consider adding semantic labels for screen reader support

## Description

User-facing flows must remain perceivable, operable, and understandable for assistive technology users. Accessibility-focused widget tests must be added or updated when UI structure, semantics, or interaction patterns change.

**This is a GATED practice:** Only applies when modifying user-facing UI screens.

## Applicability

**Apply when:**
- Modifying existing screens with user interactions
- Creating new user-facing flows
- Changing interactive elements (buttons, inputs, navigation)
- Modifying layouts that affect tap targets or focus order

**Test location:** `test/features/**/widgets/accessibility/*_a11y_test.dart`

---

## For Coding Agents (Prescriptive)

### Decision Gate: Do I Need A11y Tests?

```
Is this change user-facing UI?

├─ New screen or major UI change?
│  └─ YES → Create new a11y test file
│
├─ Modification to existing interactive screen?
│  └─ YES → Update existing a11y test
│
├─ New interactive element (button, input)?
│  └─ YES → Add semantic labels + a11y assertions
│
└─ Backend/domain logic only?
   └─ NO → Skip a11y tests
```

### Core Principles

1. **Perceivable:** All information must be available to screen readers
2. **Operable:** All interactions must work with assistive technology
3. **Understandable:** Navigation and feedback must be clear
4. **Robust:** Works across different assistive technologies

### Making Widgets Accessible

#### ✅ Add Semantic Labels

**Interactive elements MUST have meaningful labels:**

```dart
// ❌ Bad: Icon without label
IconButton(
  icon: Icon(Icons.close),
  onPressed: () => Navigator.pop(context),
)

// ✅ Good: Icon with semantic label
IconButton(
  icon: Icon(Icons.close),
  onPressed: () => Navigator.pop(context),
  tooltip: 'Close dialog',  // ✅ Screen reader announces this
)

// ✅ Better: Explicit semantics
Semantics(
  label: 'Close dialog',
  button: true,
  child: IconButton(
    icon: Icon(Icons.close),
    onPressed: () => Navigator.pop(context),
  ),
)
```

**Decorative elements can exclude semantics:**

```dart
// ✅ Good: Decorative icon (not interactive)
Semantics(
  excludeSemantics: true,  // ✅ Justified: decorative only
  child: Icon(Icons.star, color: Colors.gold),
)

// But adjacent text should have label:
Text('Premium Feature')  // Screen reader reads this instead
```

#### ✅ Ensure Tap Target Size

**Minimum tap target: 48x48 dp**

```dart
// ❌ Bad: Small tap target
GestureDetector(
  onTap: () => handleTap(),
  child: Container(
    width: 24,  // ❌ Too small
    height: 24,
    child: Icon(Icons.delete),
  ),
)

// ✅ Good: Adequate tap target
IconButton(  // IconButton enforces 48x48 minimum
  icon: Icon(Icons.delete),
  onPressed: () => handleTap(),
  tooltip: 'Delete item',
)

// ✅ Good: Custom with padding
GestureDetector(
  onTap: () => handleTap(),
  child: Padding(
    padding: EdgeInsets.all(12),  // ✅ Increases tap area
    child: Icon(Icons.delete, size: 24),
  ),
)
```

#### ✅ Provide Text Contrast

**Minimum contrast ratios:**
- Normal text: 4.5:1
- Large text (18pt+): 3:1
- Interactive elements: 3:1

```dart
// ✅ Use CoreUI colors (pre-validated for contrast)
Text(
  'Important message',
  style: CoreTypography.bodyMediumRegular().copyWith(
    color: CoreTextColors.primary,  // ✅ Meets contrast requirements
  ),
)

// ❌ Avoid custom low-contrast colors
Text(
  'Hard to read',
  style: TextStyle(
    color: Color(0xFFCCCCCC),  // ❌ Likely fails contrast check
  ),
)
```

#### ✅ Support Focus Navigation

```dart
// ✅ Good: Focusable interactive element
FocusableActionDetector(
  child: CoreButton(
    label: 'Submit',
    onPressed: () => handleSubmit(),
  ),
)

// ✅ Good: Custom focus order
Focus(
  skipTraversal: false,  // ✅ Included in tab order
  child: CustomInteractiveWidget(...),
)
```

### Writing A11y Tests

#### Test Structure

```dart
// test/features/auth/widgets/accessibility/login_screen_a11y_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/test_helpers/a11y_test_helpers.dart';

void main() {
  group('LoginScreen Accessibility', () {
    testWidgets('should meet tap target guidelines', (tester) async {
      // Arrange: Set up a11y test environment
      await setupA11yTest(tester);  // Helper: disables overflow checks

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen()),
      );

      // Act & Assert: Check tap targets and labels
      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        excludedPaths: ['decorative_icon'],  // Can exclude decorative elements
      );
    });

    testWidgets('should support both light and dark themes', (tester) async {
      await setupA11yTest(tester);

      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.lightTheme,
          home: LoginScreen(),
        ),
      );
      await expectMeetsTapTargetAndLabelGuidelines(tester);

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.darkTheme,
          home: LoginScreen(),
        ),
      );
      await expectMeetsTapTargetAndLabelGuidelines(tester);
    });

    testWidgets('should have semantic labels for all interactive elements', (tester) async {
      await setupA11yTest(tester);
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Assert: All buttons have labels
      final semantics = tester.getSemantics(find.byType(IconButton).first);
      expect(semantics.label, isNotEmpty);  // ✅ Has label
      expect(semantics.isButton, true);  // ✅ Marked as button
    });

    testWidgets('should have proper focus order', (tester) async {
      await setupA11yTest(tester);
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Verify focus order: email → password → submit
      final emailField = find.byKey(Key('email_input'));
      final passwordField = find.byKey(Key('password_input'));
      final submitButton = find.byKey(Key('submit_button'));

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(tester.binding.focusManager.primaryFocus?.debugLabel,
             contains('email'));  // ✅ First field focused

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(tester.binding.focusManager.primaryFocus?.debugLabel,
             contains('password'));  // ✅ Second field focused

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(tester.binding.focusManager.primaryFocus?.debugLabel,
             contains('submit'));  // ✅ Button focused
    });
  });
}
```

#### Helper: setupA11yTest

```dart
// test_helpers/a11y_test_helpers.dart

Future<void> setupA11yTest(WidgetTester tester) async {
  // Disable overflow checks (common in constrained a11y tests)
  tester.binding.setSurfaceSize(Size(1080, 1920));  // Standard phone size
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> expectMeetsTapTargetAndLabelGuidelines(
  WidgetTester tester, {
  List<String> excludedPaths = const [],
}) async {
  // Find all interactive elements
  final interactiveWidgets = [
    ...tester.widgetList(find.byType(IconButton)),
    ...tester.widgetList(find.byType(CoreButton)),
    ...tester.widgetList(find.byType(GestureDetector)),
  ];

  for (final widget in interactiveWidgets) {
    final renderObject = tester.renderObject(find.byWidget(widget));
    final size = renderObject.paintBounds.size;

    // Assert: Tap target at least 48x48
    expect(
      size.width >= 48 && size.height >= 48,
      true,
      reason: 'Widget $widget has tap target ${size.width}x${size.height}, minimum is 48x48',
    );

    // Assert: Has semantic label
    final semantics = tester.getSemantics(find.byWidget(widget));
    if (!excludedPaths.contains(widget.key?.toString())) {
      expect(
        semantics.label?.isNotEmpty ?? false,
        true,
        reason: 'Interactive widget $widget missing semantic label',
      );
    }
  }
}
```

### Common Patterns

#### Pattern 1: Test Screen Reader Announcements

```dart
testWidgets('should announce error messages', (tester) async {
  await setupA11yTest(tester);
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));

  // Trigger error
  await tester.tap(find.byKey(Key('submit_button')));
  await tester.pumpAndSettle();

  // Assert: Error message is semantically announced
  final errorSemantics = tester.getSemantics(
    find.text('Invalid email format'),
  );
  expect(errorSemantics.label, contains('Invalid email'));
  expect(errorSemantics.isLiveRegion, true);  // ✅ Announced immediately
});
```

#### Pattern 2: Test List Navigation

```dart
testWidgets('should support semantic list navigation', (tester) async {
  await setupA11yTest(tester);
  await tester.pumpWidget(MaterialApp(home: EstimationListScreen()));

  // Assert: List items have semantic index
  final listItems = tester.widgetList(find.byType(EstimationCard));

  for (var i = 0; i < listItems.length; i++) {
    final semantics = tester.getSemantics(find.byWidget(listItems.elementAt(i)));
    expect(semantics.indexInParent, i);  // ✅ Correct order
    expect(semantics.scrollChildCount, listItems.length);  // ✅ Total count
  }
});
```

#### Pattern 3: Test Dynamic Content

```dart
testWidgets('should announce loading state changes', (tester) async {
  await setupA11yTest(tester);
  await tester.pumpWidget(MaterialApp(home: DataScreen()));

  // Assert: Loading state announced
  expect(
    tester.getSemantics(find.byType(LoadingIndicator)).label,
    'Loading data',  // ✅ Screen reader announces
  );

  // Simulate data load
  await tester.pumpAndSettle();

  // Assert: Content state announced
  expect(
    find.bySemanticsLabel('Data loaded successfully'),
    findsOneWidget,
  );
});
```

### When to Exclude Semantics

**Valid reasons to use `excludeSemantics: true`:**

✅ **Decorative elements:**
```dart
Semantics(
  excludeSemantics: true,  // ✅ Decorative background
  child: Image.asset('background.png'),
)
```

✅ **Redundant nested widgets:**
```dart
// Parent has label, child doesn't need separate announcement
Semantics(
  label: 'Product: Blue Shirt, \$29.99',  // ✅ Complete info
  child: Row(
    children: [
      Semantics(
        excludeSemantics: true,  // ✅ Avoid duplicate reading
        child: Text('Blue Shirt'),
      ),
      Semantics(
        excludeSemantics: true,  // ✅ Avoid duplicate reading
        child: Text('\$29.99'),
      ),
    ],
  ),
)
```

❌ **NEVER exclude interactive elements:**
```dart
Semantics(
  excludeSemantics: true,  // ❌ FORBIDDEN: button must be announced
  child: IconButton(
    icon: Icon(Icons.delete),
    onPressed: () => deleteItem(),
  ),
)
```

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: Interactive Elements Without Labels**

```bash
# Find IconButtons without tooltip or Semantics
grep -rn "IconButton(" lib/features/**/presentation/ | grep -v "tooltip:"
```

**Severity:** Critical

**Pattern 2: Removed/Bypassed Semantics**

```bash
# Find excludeSemantics on interactive widgets
grep -rn "excludeSemantics: true" lib/ | grep -E "(Button|GestureDetector|InkWell)"
```

**Severity:** Critical (if not justified)

**Pattern 3: Modified Screens Without A11y Tests**

Check if:
- File `lib/features/**/presentation/screens/foo_screen.dart` was modified
- But `test/features/**/widgets/accessibility/foo_screen_a11y_test.dart` was NOT updated

**Severity:** Major

**Pattern 4: Small Tap Targets**

```bash
# Find small custom tap areas
grep -rn "GestureDetector\|InkWell" lib/ | grep -E "width:\s*[1-3][0-9]|height:\s*[1-3][0-9]"
```

**Severity:** Major

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `IconButton` without `tooltip` | Add `tooltip: 'Description'` | Critical |
| `excludeSemantics: true` on button | Remove or justify with comment | Critical |
| Modified screen, no a11y test update | Update `*_a11y_test.dart` file | Major |
| Custom `GestureDetector` with 24x24 size | Increase to ≥48x48 or use `IconButton` | Major |
| Text with low contrast color | Use `CoreTextColors.*` | Major |

### Review Questions

1. **Are there new interactive elements?**
   - Check for semantic labels

2. **Was an existing screen modified?**
   - Check if a11y tests were updated

3. **Are there small tap targets?**
   - Verify ≥48x48 dp

4. **Is `excludeSemantics` used?**
   - Verify justification (must be decorative or redundant)

---

## Summary: Suggested Fixes

1. **Add semantic labels:** Every interactive element needs `tooltip` or `Semantics` label
2. **Update a11y tests:** When modifying screens, update corresponding `*_a11y_test.dart`
3. **Ensure tap targets ≥48x48:** Use `IconButton` or add padding
4. **Test both themes:** Verify light and dark mode accessibility
5. **Remove unjustified `excludeSemantics`:** Only use for decorative elements

## References

- [Flutter Accessibility Guide](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- Review Script Lines: 501-514 in `scripts/review_pr.sh`

## Notes

**WCAG Levels:**
- **Level A:** Minimum (must meet)
- **Level AA:** Standard (target for most apps)
- **Level AAA:** Enhanced (ideal but not always achievable)

**Testing Tools:**
- Flutter's built-in semantic debugger
- Screen reader testing (TalkBack on Android, VoiceOver on iOS)
- Contrast checker tools

**Best Practice:** Enable TalkBack/VoiceOver and manually test critical flows to ensure good UX for assistive technology users.
