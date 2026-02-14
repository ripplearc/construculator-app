import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screenshot/font_loader.dart';

const Size kDefaultA11yScreenSize = Size(412, 917);

/// Themes used for accessibility tests. Includes both light and dark so color
/// contrast and tap target guidelines are verified in both modes.
final List<ThemeData> kA11yTestThemes = [
  createTestTheme(),
  createTestThemeDark(),
];

/// Configures the test surface size for accessibility tests and registers
/// tear-down to restore the original surface size after the test.
///
/// Use this at the start of an a11y test so tap target and layout checks
/// run against a consistent viewport. If [screenSize] is omitted,
/// [kDefaultA11yScreenSize] is used.
Future<void> setupA11yTest(WidgetTester tester, {Size? screenSize}) async {
  final size = screenSize ?? kDefaultA11yScreenSize;
  await tester.binding.setSurfaceSize(size);

  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

/// Asserts that the widget found by [target] meets accessibility guidelines
/// based on the enabled checks.
///
/// These flags exist so individual tests can opt out of specific checks in
/// well-understood, temporary situations, but **by default all checks are
/// enabled** because our a11y test suite expects them to run.
/// Typical examples:
/// - [checkTapTargetSize]: verifies Android and iOS tap target size guidelines.
///   This can be turned off for widgets that are not meant to be interactive
///   (but are still using this helper for convenience).
/// - [checkLabeledTapTarget]: verifies that tap targets have an accessible
///   label. This can be turned off for purely decorative widgets that are
///   intentionally excluded from the semantics tree.
/// - [checkTextContrast]: verifies that text meets the minimum contrast ratio.
///   This can be turned off when the component under test does not render any
///   text, or when a known contrast issue is being worked on separately.
/// Fails if [target] does not match exactly one widget or any guideline fails.
Future<void> expectMeetsTapTargetAndLabelGuidelines(
  WidgetTester tester,
  Finder target, {
  bool checkTapTargetSize = true,
  bool checkLabeledTapTarget = true,
  bool checkTextContrast = true,
}) async {
  final semanticsHandle = tester.ensureSemantics();
  try {
    expect(target, findsOneWidget);

    if (checkTapTargetSize) {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    }

    if (checkLabeledTapTarget) {
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }

    if (checkTextContrast) {
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
  } finally {
    semanticsHandle.dispose();
  }
}

/// Asserts that the widget meets accessibility guidelines in both light and
/// dark themes.
///
/// Use this when testing screens that render text or have theme-dependent
/// colors, so contrast and tap target guidelines are verified in both modes.
/// [buildWidget] is called with each theme to build the widget under test.
/// Call [setupA11yTest] before this helper.
///
/// [buildWidget] should return the full app (e.g. MaterialApp with BlocProviders)
/// for screen tests.
///
/// Example:
/// ```dart
/// await setupA11yTest(tester);
/// await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
///   tester,
///   (theme) => makeTestableWidget(theme: theme, child: LoginWithEmailPage()),
///   find.text(l10n().continueButton),
/// );
/// ```
Future<void> expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
  WidgetTester tester,
  Widget Function(ThemeData theme) buildWidget,
  Finder targetFinder, {
  bool checkTapTargetSize = true,
  bool checkLabeledTapTarget = true,
  bool checkTextContrast = true,
}) async {
  for (final theme in kA11yTestThemes) {
    final widget = buildWidget(theme);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await expectMeetsTapTargetAndLabelGuidelines(
      tester,
      targetFinder,
      checkTapTargetSize: checkTapTargetSize,
      checkLabeledTapTarget: checkLabeledTapTarget,
      checkTextContrast: checkTextContrast,
    );
  }
}
