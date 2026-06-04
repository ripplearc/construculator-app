# RULE 14: Accessibility (A11y) Testing

## Rule ID
RULE_14

## Category
Testing - Accessibility

## Severity Levels
- **Critical:** Interactive elements without semantic labels, or removing semantics without justification
- **Major:** UI changes to key screens without updating a11y tests
- **Minor:** Missing accessibility checks in widget tests for new interactive elements
- **Suggestion:** Consider adding semantic labels for screen reader support

## Description

User-facing flows must remain perceivable, operable, and understandable for assistive technology users. Accessibility-focused widget tests must be added or updated when UI structure, semantics, or interaction patterns change.

**GATED:** only applies when modifying user-facing UI.

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

├─ New screen or major UI change?              → Create new a11y test file
├─ Modification to existing interactive screen?→ Update existing a11y test
├─ New interactive element (button, input)?    → Add semantic labels + a11y test
└─ Backend/domain logic only?                  → Skip a11y tests
```

### Making Widgets Accessible

- **Semantic labels:** every interactive element needs a label — prefer `IconButton(tooltip: ...)`, or wrap in `Semantics(label:, button: true, ...)`. Decorative widgets may set `excludeSemantics: true` — **never** on interactive elements.
- **Tap targets ≥48×48 dp:** prefer `IconButton` (enforces it) or add `Padding` around custom `GestureDetector`s.
- **Contrast:** use `CoreTextColors.*` / CoreUI tokens (pre-validated). Don't hand-pick low-contrast hex colors.
- **Focus order:** rely on widget tree order; only override with `Focus`/`FocusTraversalGroup` when needed.

### Writing A11y Tests — Use the Shared Helpers

All a11y tests use helpers from **`test/utils/a11y/a11y_guidelines.dart`**:

- `setupA11yTest(tester)` — sets the standard a11y surface size, restores it in tear-down.
- `expectMeetsTapTargetAndLabelGuidelines(tester, finder)` — asserts Android + iOS tap target, labeled tap target, text contrast.
- `expectMeetsTapTargetAndLabelGuidelinesForEachTheme(tester, buildWidget, finder)` — runs the same assertions in both light and dark themes; use this for screen-level tests.

Canonical pattern:

```dart
testWidgets('login screen meets a11y guidelines', (tester) async {
  await setupA11yTest(tester);
  await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
    tester,
    (theme) => makeTestableWidget(theme: theme, child: LoginWithEmailPage()),
    find.text(l10n().continueButton),
  );
});
```

Existing examples: `test/features/auth/widgets/accessibility/*`, `test/features/estimations/widgets/accessibility/*`.

---

## For Review Agents (Detective)

### Detection Patterns

| Pattern | Grep | Severity |
|---|---|---|
| IconButton without tooltip | `grep -rn "IconButton(" lib/features/**/presentation/ \| grep -v "tooltip:"` | Critical |
| `excludeSemantics` on interactive widgets | `grep -rn "excludeSemantics: true" lib/ \| grep -E "(Button\|GestureDetector\|InkWell)"` | Critical |
| Small custom tap targets | `grep -rn "GestureDetector\|InkWell" lib/ \| grep -E "width:\s*[1-3][0-9]\|height:\s*[1-3][0-9]"` | Major |
| Modified screen, a11y test not touched | Diff check: `lib/.../foo_page.dart` changed but `test/.../foo_page_a11y_test.dart` not changed | Major |

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `IconButton` without `tooltip` | Add `tooltip: 'Description'` | Critical |
| `excludeSemantics: true` on a button/tap target | Remove or justify with comment (decorative/redundant only) | Critical |
| Custom `GestureDetector` with 24×24 size | Increase to ≥48×48 or use `IconButton` | Major |
| Text with low-contrast color | Use `CoreTextColors.*` | Major |
| Modified screen, no a11y test update | Update `*_a11y_test.dart` | Major |
| A11y test does not run in both themes | Use `expectMeetsTapTargetAndLabelGuidelinesForEachTheme` | Minor |

### Review Questions

1. Are there new interactive elements? → check for semantic labels.
2. Was an existing screen modified? → check whether a11y tests were updated.
3. Are there small tap targets (<48×48)? → flag.
4. Is `excludeSemantics: true` used? → must be justified (decorative or duplicate-info only).

---

## Summary: Suggested Fixes

1. **Semantic labels:** every interactive element gets `tooltip:` or a `Semantics` wrapper.
2. **A11y tests:** when modifying screens, update the corresponding `*_a11y_test.dart`.
3. **Tap targets ≥48×48:** use `IconButton` or pad `GestureDetector`.
4. **Both themes:** use the `…ForEachTheme` helper for screen-level checks.
5. **Justify `excludeSemantics`:** only for decorative or redundant elements.

## References

- Shared helpers: **`test/utils/a11y/a11y_guidelines.dart`**
- Examples: `test/features/auth/widgets/accessibility/`, `test/features/estimations/widgets/accessibility/`
- [Flutter Accessibility Guide](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [WCAG 2.1 Quickref](https://www.w3.org/WAI/WCAG21/quickref/)
- Review Script Lines: 501-514 in `scripts/review_pr.sh`

## Notes

WCAG target: **Level AA**. Manual testing with TalkBack (Android) / VoiceOver (iOS) on critical flows remains the gold standard — automated helpers cover the basics, not the full UX.
