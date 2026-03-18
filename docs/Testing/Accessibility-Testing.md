# Accessibility (a11y) Testing

This page is the canonical reference for a11y testing conventions in Construculator.

Accessibility tests ensure our application is usable for everyone by verifying:

- Semantic labels
- Tap target sizes
- Color contrast ratios
- Behavior across both light and dark themes

Unlike standard widget tests that focus on logic, state, and interaction, a11y tests focus on compliance, layout constraints, and UI composition.

---

## Folder Structure

To keep tests readable and maintainable, we separate logic tests from accessibility tests using a **peer folder structure**.

Accessibility tests live inside an `accessibility/` folder that sits parallel to the components or pages they test. Files must end with `_a11y_test.dart`.

Example:

```bash
test/features/estimation/
├── pages/          # Logic & interaction tests
│   └── cost_estimation_landing_page_test.dart
└── accessibility/  # A11y & visual compliance tests
    └── cost_estimation_landing_page_a11y_test.dart
```

**Rules:**

- Place a11y tests under an `accessibility/` subfolder parallel to `pages/`, `widgets/`, etc.
- Name files using the pattern: `<base_name>_a11y_test.dart`.

---

## A11y Test Harness

We use a custom test harness (`a11y_guidelines.dart` and `test_harness.dart`) to standardize the environment and reduce boilerplate.

The harness is responsible for:

- **Screen size**: Forces the viewport to the design spec (e.g., 375x667, 412x917) to avoid false-positive vertical overflow errors.
- **Theme injection**: Automatically runs checks against both `CoreTheme.light()` and `CoreTheme.dark()`.
- **App shell wrapper**: Provides a consistent `MaterialApp` + `Scaffold` wrapper for testing isolated widgets.

Use the helpers from the harness instead of manually wiring up themes and layouts.

---

## Writing Accessibility Tests

### 1. Isolated components

When testing a small, isolated widget (e.g., a custom button), the helper will automatically wrap it in a `MaterialApp`.

Typical flow:

1. Call `setupA11yTest(tester)` to configure viewport, theme cycling, and app shell.
2. Use `expectMeetsTapTargetAndLabelGuidelinesForEachTheme` to assert a11y guidelines for each theme.

Example snippet:

```dart
testWidgets('SubmitButton meets a11y guidelines', (tester) async {
  await setupA11yTest(tester);

  await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
    tester,
    (theme) => const SubmitButton(label: 'Submit'),
    find.byType(SubmitButton),
  );
});
```

### 2. Full screens / pages

When testing a full screen that already sets up its own layout, routing, or providers:

1. Call `setupA11yTest(tester)`.
2. Use a helper like `pumpAppAtRoute` (or equivalent in the harness) to bootstrap the app at the desired route.
3. Optionally use `setupAfterPump` to navigate or wait for asynchronous setup.
4. Call `expectMeetsTapTargetAndLabelGuidelinesForEachTheme`.

Example snippet:

```dart
testWidgets('CostEstimationLandingPage meets guidelines', (tester) async {
  await setupA11yTest(tester);

  await pumpAppAtRoute(tester, testEstimationRoute);

  await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
    tester,
    (theme) => makeApp(theme: theme),
    find.byKey(const Key('menuIcon')),
    setupAfterPump: (t) async {
      Modular.to.navigate(testEstimationRoute);
      await t.pumpAndSettle();
    },
  );
});
```

---

## Bypassing Specific Guidelines (Edge Cases)

By default, the test harness enforces all guidelines:

- Text contrast
- Tap target size
- Labeled tap targets

Use boolean flags such as `checkTextContrast`, `checkTapTargetSize`, and `checkLabeledTapTarget` **only when there is a strong UX or standards-based justification**. When disabling any check, ensure that one of the documented edge cases applies.

### A. Text contrast (`checkTextContrast: false`)

Valid reasons:

- **Disabled / inactive UI components**
  - WCAG 1.4.3 exempts inactive components from contrast requirements.
  - A lower-contrast disabled state is a common, expected cue that an element is not interactive.
- **Logos and strict brand colors**
  - Logo text or third-party buttons (e.g., "Sign in with Google") must follow external brand guidelines that may not meet contrast ratios.

### B. Tap target size (`checkTapTargetSize: false`)

Valid reasons:

- **Non-interactive display components**
  - Purely informational widgets (e.g., empty state text, base avatar) are not tappable by themselves.
  - The responsibility for tap target size lies with the parent widget (`InkWell`, `GestureDetector`, etc.) that makes them interactive.
- **Inline text links**
  - WCAG 2.5.5 exempts inline targets inside a block of text.
  - Enforcing a 48x48px tap target on a single word inside a paragraph would destroy layout and readability.

### C. Labeled tap targets (`checkLabeledTapTarget: false`)

Valid reasons:

- **Preventing "double reads" (semantic merging)**
  - For composite cards (e.g., `EstimationTile` with text, prices, icons) wrapped in `MergeSemantics`, we want the screen reader to announce the whole card as a single button.
  - If an inner `InkWell`/`GestureDetector` is also labeled, the screen reader will announce the action twice. In such cases, we bypass the label requirement on the inner target.
- **Background gesture catchers**
  - Full-screen invisible `GestureDetector`s used to dismiss keyboards or close dropdowns should not have semantic labels.
  - Announcing "Dismiss keyboard" on a tap in empty space is noisy and confusing for screen reader users.

---

## Further Reading

If you need to dive deeper into accessibility standards or platform specifics, refer to:

- **WCAG 2.1** – [Web Content Accessibility Guidelines](https://www.w3.org/TR/WCAG21/)
- **Flutter docs: Accessibility testing** – [Accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
- **Material Design: Accessible design** – [Accessible design](https://m3.material.io/foundations/accessible-design/overview)
- **Apple Human Interface Guidelines: Accessibility** – [Apple HIG – Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

