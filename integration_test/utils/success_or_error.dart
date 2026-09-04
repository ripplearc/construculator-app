import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Taps the package-owned success bottom sheet's button — but fails
/// immediately with the real error message if an error [Toast] appears
/// instead, rather than waiting out [timeout] for a success sheet an error
/// means will never arrive.
///
/// A timeout thrown by this function means neither outcome happened within
/// [timeout]; that is a genuine timeout. A caught, fast failure here means
/// the app told us why it didn't succeed, and we should not have waited to
/// hear it.
Future<void> tapSuccessSheetOrFailFast(
  PatrolIntegrationTester $, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  final buttonFinder = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byType(CoreButton),
  );
  final toastFinder = find.byType(Toast);

  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 300));

    if (toastFinder.evaluate().isNotEmpty) {
      final messages = find
          .descendant(of: toastFinder, matching: find.byType(Text))
          .evaluate()
          .map((element) => (element.widget as Text).data)
          .whereType<String>()
          .join(' / ');
      fail('Expected the success sheet but got an error toast: $messages');
    }

    if (buttonFinder.evaluate().isNotEmpty) {
      await $.tester.tap(buttonFinder.first);
      return;
    }
  }

  fail(
    'Timed out after $timeout waiting for the success sheet — no error '
    'toast appeared either, so the app genuinely never responded.',
  );
}
