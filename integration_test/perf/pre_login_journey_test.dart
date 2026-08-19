import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Identifies the measured journey inside the trend history.
///
/// Changing what the journey does invalidates comparisons against older runs,
/// so a materially different journey must be published under a new id (for
/// example `post_login_v1`) to start a fresh series rather than appending to
/// this one.
const String preLoginJourneyId = 'pre_login_v1';

/// Upper bound on frames pumped while waiting for a scripted step to appear.
///
/// A fixed budget keeps the journey deterministic: every run pumps at most the
/// same number of frames regardless of device speed, and a step that never
/// appears fails loudly instead of hanging.
const int _stepFrameBudget = 120;

/// Frames pumped after a gesture so the resulting animation is recorded.
const int _gestureFrameBudget = 60;

/// Cadence of a single pumped frame, matching a 60Hz display.
const Duration _frameInterval = Duration(milliseconds: 16);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('pre-login journey reaches the login screen and scrolls it', (
    WidgetTester tester,
  ) async {
    await binding.traceAction(() async {
      app.main();
      // Waits on login-screen copy rather than on a layout widget, so the
      // journey confirms it actually reached the login screen instead of
      // merely rendering something scrollable.
      await _pumpUntilPresent(tester, find.text(AppLocalizationsEn().welcomeBack));
      await _scrollLoginForm(tester);
    }, reportKey: preLoginJourneyId);
  });
}

/// Pumps frames until [target] is present, failing once the budget is spent.
Future<void> _pumpUntilPresent(WidgetTester tester, Finder target) async {
  for (int frame = 0; frame < _stepFrameBudget; frame++) {
    await tester.pump(_frameInterval);
    if (target.evaluate().isNotEmpty) {
      return;
    }
  }
  fail(
    'Journey step did not appear within $_stepFrameBudget frames. '
    'The app may have failed to start or routed somewhere unexpected.',
  );
}

/// Drags the login form to generate a scripted, repeatable frame workload.
///
/// Targets [SingleChildScrollView] rather than [Scrollable] because the page
/// contains two scrollables: the form's own scroll view and the one
/// [EditableText] builds inside the email field. A [Scrollable] finder matches
/// both, and [WidgetTester.fling] throws on an ambiguous target.
Future<void> _scrollLoginForm(WidgetTester tester) async {
  await tester.fling(
    find.byType(SingleChildScrollView),
    const Offset(0, -200),
    800,
  );
  for (int frame = 0; frame < _gestureFrameBudget; frame++) {
    await tester.pump(_frameInterval);
  }
}
