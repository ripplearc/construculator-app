import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Taps the package-owned success bottom sheet's button. Fails immediately
/// with the real message if any [Toast] appears instead, rather than waiting
/// out [timeout] for a success sheet that will never arrive.
///
/// The finder matches any [Toast] variant, not only the error one: coreui's
/// Toast exposes no public discriminator. The two screens this helper watches
/// (login, registration) only ever show an error toast, so a matched toast is
/// in practice the app reporting a failure. Revisit if either screen starts
/// showing a success or info toast.
///
/// A timeout thrown by this function means neither outcome happened within
/// [timeout]; that is a genuine timeout. A caught, fast failure here means
/// the app told us why it didn't succeed, and we should not have waited to
/// hear it.
///
/// [timeout] is this helper's own fail-fast budget, independent of the
/// [PatrolTesterConfig.visibleTimeout] the CUJ files set. Changing one does
/// not change the other.
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
      fail('Expected the success sheet but got a toast: $messages');
    }

    if (buttonFinder.evaluate().isNotEmpty) {
      await $.tester.tap(buttonFinder.first);
      return;
    }
  }

  fail(
    'Timed out after $timeout waiting for the success sheet. No toast '
    'appeared either, so the app genuinely never responded.',
  );
}
