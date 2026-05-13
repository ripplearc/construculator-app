# RULE 8: Widget Test Finders & Behavior

## Rule ID
RULE_8

## Category
Testing - Widget Tests

## Severity Levels
- **Critical:** Using fragile finders like `findsNWidgets` with `byType` for implementation-specific widgets
- **Major:** Tests rely on exact widget counts, tree structure, or internal implementation
- **Minor:** Finders use positional access (`.first`, `.last`) without semantic context
- **Suggestion:** Consider using Keys or semantic finders for better test resilience

## Description

Widget tests should focus on user-observable behavior, not implementation details. Use semantic finders (Keys, text, semantics) that remain stable across refactoring, rather than fragile finders that break when widget structure changes.

**Core Principle:** Test what the user sees and does, not how widgets are internally structured.

## Applicability

Applies to all widget tests in `test/features/**/widgets/` and `test/` directories.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Write tests that survive refactoring.** Tests should verify user-facing behavior, not internal widget composition. If you refactor a widget without changing its behavior, tests should still pass.

### Decision Tree: Which Finder Should I Use?

```
What am I trying to find?

├─ User-visible text?
│  └─ Use: find.text('Button Label')
│     └─ Or: find.widgetWithText(CoreButton, 'Continue')
│
├─ Interactive element with specific purpose?
│  └─ Use: find.byKey(Key('login_button'))
│     └─ Add Key to widget in production code
│
├─ Icon visible to user?
│  └─ Use: find.byKey(Key('search_icon'))
│     └─ Or: find.byIcon(Icons.search) if testing Material
│
├─ Semantically labeled element?
│  └─ Use: find.bySemanticsLabel('Close dialog')
│
└─ Specific widget TYPE for interaction?
   └─ Use: find.byType(SpecificWidget) ONLY if:
      - It's a leaf widget you're directly testing
      - Not counting instances (no findsNWidgets)
      - Not using positional access (.first, .last)
```

### What Finders to Use

#### ✅ Good: Semantic Finders

**Keys (Preferred):**

```dart
// Production code: Add Keys to important widgets
CoreButton(
  key: const Key('submit_button'),  // ✅ Semantic, stable
  label: 'Submit',
  onPressed: () => handleSubmit(),
)

// Test code: Find by Key
testWidgets('should submit form when button tapped', (tester) async {
  await tester.pumpWidget(MyApp());

  final submitButton = find.byKey(const Key('submit_button'));  // ✅
  expect(submitButton, findsOneWidget);

  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Assert on behavior
  expect(find.text('Success'), findsOneWidget);
});
```

**Text-based (For User-Visible Content):**

```dart
testWidgets('should display welcome message', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Tests what user sees
  expect(find.text('Welcome back'), findsOneWidget);
  expect(find.text('Logout'), findsOneWidget);
});
```

**Combined (Widget + Text):**

```dart
testWidgets('should render login button', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Semantic: finds button with specific text
  final loginButton = find.widgetWithText(CoreButton, 'Login');
  expect(loginButton, findsOneWidget);
});
```

**Semantics (For Accessibility):**

```dart
testWidgets('should have semantic label for screen readers', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Tests accessibility
  expect(find.bySemanticsLabel('Close dialog'), findsOneWidget);
});
```

#### ❌ Bad: Fragile Finders

**Type-based counting (Forbidden):**

```dart
// ❌ CRITICAL: Breaks if you add/remove any icon
expect(find.byType(CoreIconWidget), findsNWidgets(3));

// Why bad: If you add a 4th icon elsewhere, test breaks
// even though behavior is unchanged
```

**Positional access:**

```dart
// ❌ MAJOR: Fragile, order-dependent
final firstButton = find.byType(CoreButton).first;
await tester.tap(firstButton);

// Why bad: If button order changes, test breaks
// even though each button still works correctly
```

**Generic type finders:**

```dart
// ❌ MINOR: Too generic, may match unintended widgets
expect(find.byType(Row), findsOneWidget);
expect(find.byType(Container), findsWidgets);

// Why bad: Internal layout widgets shouldn't be test targets
```

### How to Write Widget Tests

#### Pattern 1: Test User Interactions

```dart
testWidgets('should navigate to settings when icon tapped', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Find by semantic Key
  final settingsIcon = find.byKey(const Key('settings_icon'));
  expect(settingsIcon, findsOneWidget);

  // ✅ Test user action
  await tester.tap(settingsIcon);
  await tester.pumpAndSettle();

  // ✅ Assert on observable result
  expect(find.text('Settings'), findsOneWidget);
  expect(find.byType(SettingsScreen), findsOneWidget);
});
```

#### Pattern 2: Test Displayed Content

```dart
testWidgets('should display estimation list', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Test user-visible content
  expect(find.text('Kitchen Remodel'), findsOneWidget);
  expect(find.text('\$25,000'), findsOneWidget);
  expect(find.text('Bathroom Renovation'), findsOneWidget);

  // ❌ Don't test internal structure
  // expect(find.byType(ListView), findsOneWidget);  // ❌
  // expect(find.byType(EstimationCard), findsNWidgets(2));  // ❌
});
```

#### Pattern 3: Test State Changes

```dart
testWidgets('should show error message on invalid input', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Find input field by Key
  final emailField = find.byKey(const Key('email_input'));

  // ✅ Simulate user input
  await tester.enterText(emailField, 'invalid-email');

  // ✅ Trigger validation
  final submitButton = find.byKey(const Key('submit_button'));
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // ✅ Assert on user-visible feedback
  expect(find.text('Invalid email format'), findsOneWidget);
});
```

### Adding Keys to Production Code

**When to add Keys:**

- ✅ Interactive elements (buttons, inputs, icons)
- ✅ Navigation targets (tabs, menu items)
- ✅ Dynamic content that needs testing (lists, cards)
- ✅ Elements with important state changes

**How to name Keys:**

Use descriptive, purpose-driven names:

| Element | ❌ Bad Key | ✅ Good Key |
|---------|-----------|------------|
| Submit button | `Key('button')` | `Key('submit_button')` or `Key('login_submit')` |
| Email input | `Key('input1')` | `Key('email_input')` |
| Search icon | `Key('icon')` | `Key('search_icon')` |
| Estimation card | `Key('card_0')` | `Key('estimation_$id')` or `Key('estimation_list_item_$index')` |

**Pattern:** `Key('{purpose}_{element_type}')` or `Key('{feature}_{action}')`

### What NOT to Test

❌ **Internal Widget Structure:**

```dart
// Bad: Tests implementation
testWidgets('should have correct widget tree', (tester) async {
  await tester.pumpWidget(MyApp());

  expect(find.byType(Column), findsOneWidget);  // ❌ Internal layout
  expect(find.byType(Padding), findsWidgets);  // ❌ Internal styling
  expect(find.byType(SizedBox), findsNWidgets(3));  // ❌ Spacers
});

// Good: Tests behavior
testWidgets('should display login form elements', (tester) async {
  await tester.pumpWidget(MyApp());

  expect(find.text('Email'), findsOneWidget);  // ✅ User-facing
  expect(find.text('Password'), findsOneWidget);  // ✅ User-facing
  expect(find.text('Login'), findsOneWidget);  // ✅ User-facing
});
```

❌ **Widget Count Assertions:**

```dart
// Bad: Fragile count assertion
expect(find.byType(CoreIconWidget), findsNWidgets(3));  // ❌

// Good: Test each icon has purpose
expect(find.byKey(const Key('home_icon')), findsOneWidget);  // ✅
expect(find.byKey(const Key('search_icon')), findsOneWidget);  // ✅
expect(find.byKey(const Key('profile_icon')), findsOneWidget);  // ✅
```

### Special Cases

#### Testing Lists with Dynamic Content

```dart
// ✅ Good: Use Keys with identifiers
ListView.builder(
  itemCount: estimations.length,
  itemBuilder: (context, index) {
    final estimation = estimations[index];
    return EstimationCard(
      key: Key('estimation_${estimation.id}'),  // ✅ Unique, stable key
      estimation: estimation,
    );
  },
)

// Test
testWidgets('should display specific estimation', (tester) async {
  await tester.pumpWidget(MyApp());

  final estimationCard = find.byKey(const Key('estimation_abc123'));  // ✅
  expect(estimationCard, findsOneWidget);
});
```

#### Testing Conditional Rendering

```dart
testWidgets('should show loading indicator when loading', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Test state-specific widget presence
  expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
  expect(find.byKey(const Key('content_view')), findsNothing);

  // Simulate data load
  await tester.pumpAndSettle();

  // ✅ Test state changed
  expect(find.byKey(const Key('loading_indicator')), findsNothing);
  expect(find.byKey(const Key('content_view')), findsOneWidget);
});
```

### Common Patterns

#### ✅ Scrolling to Find Widgets

```dart
testWidgets('should find widget by scrolling', (tester) async {
  await tester.pumpWidget(MyApp());

  // ✅ Scroll to specific item by Key
  await tester.scrollUntilVisible(
    find.byKey(const Key('estimation_xyz789')),
    100.0,
  );

  expect(find.byKey(const Key('estimation_xyz789')), findsOneWidget);
});
```

#### ✅ Testing Gestures

```dart
testWidgets('should dismiss item on swipe', (tester) async {
  await tester.pumpWidget(MyApp());

  final item = find.byKey(const Key('dismissible_item'));

  // ✅ Test gesture
  await tester.drag(item, const Offset(-500.0, 0.0));
  await tester.pumpAndSettle();

  // ✅ Assert item removed
  expect(item, findsNothing);
  expect(find.text('Item deleted'), findsOneWidget);
});
```

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: Fragile findsNWidgets with byType**

```bash
grep -rn "findsNWidgets" test/ | grep "byType"
```

**Regex:** `find\.byType\([^)]+\).*findsNWidgets\(|findsNWidgets\(.*find\.byType`

**Severity:** Critical

**Examples to catch:**
- `expect(find.byType(CoreIconWidget), findsNWidgets(3))`
- `expect(find.byType(EstimationCard), findsNWidgets(2))`

**Pattern 2: Positional Access**

```bash
grep -rn "\.first\|\.last\|\.at(" test/
```

**Regex:** `find\.[a-zA-Z]+\([^)]*\)\.(first|last|at\()`

**Severity:** Major

**Examples to catch:**
- `find.byType(CoreButton).first`
- `find.byType(IconButton).at(1)`

**Pattern 3: Generic Type Finders**

```bash
grep -rn "byType(Row)\|byType(Column)\|byType(Container)\|byType(Padding)" test/
```

**Severity:** Minor

**Pattern 4: Missing Keys on Interactive Elements**

Check if test tries to find interactive widgets without Keys:

```dart
await tester.tap(find.byType(CoreButton));  // ❌ Which button?
```

**Severity:** Major

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `expect(find.byType(Icon), findsNWidgets(3))` | Use `find.byKey(Key('icon_name'))` for each icon | Critical |
| `find.byType(CoreButton).first` | Add Key to button, use `find.byKey(Key('button_name'))` | Major |
| `expect(find.byType(Row), findsOneWidget)` | Test user-visible content, not layout widgets | Minor |
| `find.text('Submit').first` | Use `find.byKey` if multiple submit buttons exist | Major |
| No Keys in production code | Add Keys to interactive elements | Major |

### Review Questions

1. **Does this test break if we refactor widget structure?**
   - If YES → Test is too fragile

2. **Is this test counting internal implementation widgets?**
   - If YES → Violation

3. **Does this test use positional access without semantic meaning?**
   - If YES → Should use Keys instead

4. **Would a user notice if this test's assertion fails?**
   - If NO → Test is testing implementation, not behavior

---

## Summary: Suggested Fixes

1. **Replace type-based counting:** Use Keys for each distinct widget instance
2. **Add Keys to production code:** Tag interactive elements with semantic Keys
3. **Remove positional access:** Use `find.byKey` instead of `.first`, `.last`
4. **Test user-visible content:** Focus on text, semantics, and behavior
5. **Make tests refactor-safe:** Tests should survive internal widget restructuring

## References

- [Flutter Widget Testing Guide](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- Review Script Lines: 360-386 in `scripts/review_pr.sh`
- Related: RULE_9 (Unit Test Behavior) - same principle for unit tests

## Notes

**Key Principle:** If you can refactor a widget without changing user-visible behavior, tests should still pass. Tests that rely on internal structure are brittle and provide false confidence.

**Best Practice:** Add Keys during development, not as an afterthought. Include Keys in your widget's initial implementation for testability.
