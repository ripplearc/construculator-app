# RULE 8: Widget Test Finders & Behavior

## Rule ID
RULE_8

## Category
Testing - Widget Tests

## Severity Levels
- **Critical:** `findsNWidgets` + `byType` on implementation-specific widgets
- **Major:** Tests rely on exact widget counts, tree structure, or internal implementation
- **Minor:** Positional access (`.first`, `.last`) without semantic context
- **Suggestion:** Prefer Keys or semantic finders for resilience

## Description

Widget tests focus on user-observable behavior, not implementation structure. Use semantic finders (Keys, text, semantics) that survive refactoring, not fragile finders that break when widget structure changes.

**Core Principle:** Test what the user sees and does, not how widgets are internally structured.

## Applicability

All widget tests in `test/features/**/widgets/` and `test/`.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Write tests that survive refactoring.** If you refactor a widget without changing behavior, tests should still pass.

### Decision Tree: Which Finder Should I Use?

```
What am I trying to find?

├─ User-visible text?                  → find.text('Continue')  or  find.widgetWithText(CoreButton, 'Continue')
├─ Interactive element (specific role)? → find.byKey(Key('login_button'))  (add Key in production code)
├─ Icon visible to user?               → find.byKey(Key('search_icon'))  (or find.byIcon for Material)
├─ Semantically labeled element?       → find.bySemanticsLabel('Close dialog')
└─ Specific widget TYPE?               → find.byType(LeafWidget)
                                          ONLY if: leaf widget under test, no findsNWidgets,
                                          no .first/.last/.at(...)
```

### Fragile Finder → Stable Finder

| ❌ Fragile | ✅ Stable | Why |
|---|---|---|
| `find.byType(CoreIconWidget), findsNWidgets(3)` | `find.byKey(Key('home_icon')) // …` per icon | Adding/removing an unrelated icon breaks the count |
| `find.byType(CoreButton).first` | `find.byKey(Key('submit_button'))` | Order-dependent; first button changes with refactor |
| `find.byType(IconButton).at(1)` | `find.byKey(Key('action_<purpose>'))` | Same as above |
| `find.byType(Row)` / `byType(Column)` / `byType(Padding)` | `find.text(...)` or `find.byKey(...)` | Internal layout widgets aren't user-observable |
| `find.text('Submit').first` (multiple submits) | `find.byKey(Key('login_submit'))` | Disambiguates by purpose, not order |
| `tester.tap(find.byType(CoreButton))` | `tester.tap(find.byKey(Key('submit_button')))` | Without a Key, the test can't say *which* button |

### Adding Keys to Production Code

Add Keys to interactive elements, navigation targets, dynamic list items, and conditionally rendered state markers (loading, empty, content).

**Naming pattern:** `Key('{purpose}_{element_type}')` — descriptive, purpose-driven.

| Element | ❌ Bad | ✅ Good |
|---|---|---|
| Submit button | `Key('button')` | `Key('submit_button')` / `Key('login_submit')` |
| Email input | `Key('input1')` | `Key('email_input')` |
| Search icon | `Key('icon')` | `Key('search_icon')` |
| Dynamic list item | `Key('card_0')` | `Key('estimation_$id')` |

### Canonical Test Pattern

```dart
testWidgets('shows error message on invalid email', (tester) async {
  await tester.pumpWidget(makeTestableWidget(child: LoginPage()));

  await tester.enterText(find.byKey(const Key('email_input')), 'invalid');
  await tester.tap(find.byKey(const Key('submit_button')));
  await tester.pumpAndSettle();

  expect(find.text(l10n().invalidEmailError), findsOneWidget); // RULE_10
});
```

Test inputs by Key, taps by Key, assertions on user-visible text (always via `l10n`). Never assert on internal layout widgets (`Row`, `Column`, `Padding`) or widget counts.

---

## For Review Agents (Detective)

### Detection Patterns

| Pattern | Grep | Severity |
|---|---|---|
| `findsNWidgets` with `byType` | `grep -rn "findsNWidgets" test/ \| grep "byType"` | Critical |
| Positional access | `grep -rn "find\\.[a-zA-Z]\\+([^)]*)\\.\\(first\\|last\\|at(\\)" test/` | Major |
| Generic type finders | `grep -rn "byType(Row)\\|byType(Column)\\|byType(Container)\\|byType(Padding)" test/` | Minor |
| Tap by widget type, not Key | `grep -rn "tester\\.tap(find\\.byType" test/` | Major |

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `expect(find.byType(Icon), findsNWidgets(3))` | Find each icon by its own Key | Critical |
| `find.byType(CoreButton).first` | Add a Key; use `find.byKey(...)` | Major |
| `expect(find.byType(Row), findsOneWidget)` | Assert on user-visible content, not layout | Minor |
| `find.text('Submit').first` | Use `find.byKey` when multiple match | Major |
| Interactive widget without a Key in production code | Add a semantic Key | Major |

### Review Questions

1. Does this test break if widget structure is refactored without behavior change? → too fragile.
2. Is the test counting internal implementation widgets? → violation.
3. Does the test rely on `.first` / `.last` / `.at(...)` without semantic meaning? → use a Key.
4. Would a user notice if this assertion failed? → if no, it's testing implementation.

---

## Summary: Suggested Fixes

1. **Replace type-based counting** with per-instance Keys.
2. **Add Keys** to interactive elements in production code, at construction time — not as an afterthought.
3. **Remove positional access** (`.first`, `.last`, `.at`) — use `find.byKey`.
4. **Assert on user-visible content** (text via `l10n`, semantics labels).
5. **Tests must survive refactor** — if internal restructuring breaks tests, the test is wrong.

## References

- [Flutter Widget Testing Guide](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- Review Script Lines: 360-386 in `scripts/review_pr.sh`
- Related: RULE_9 (same principle for unit tests), RULE_10 (localized strings in assertions)

## Notes

**Best Practice:** Add Keys during initial widget development, not retrofitted. Include them in the constructor signature when testability matters.
