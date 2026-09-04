import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../utils/app_runner.dart';
import '../../utils/test_config.dart';

void main() {
  patrolTest(
    'CUJ-1: Login — returning user lands on the dashboard',
    ($) async {
      await startApp($);

      await $(const Key('login_email_field')).enterText(TestConfig.loginEmail);
      await $(const Key('login_email_continue_button')).tap();

      await $(
        const Key('login_password_field'),
      ).enterText(TestConfig.loginPassword);
      await $(const Key('login_password_continue_button')).tap();

      // The success modal is a package-owned bottom sheet whose button carries
      // no key, so it is anchored to the sheet rather than to screen position.
      await $(BottomSheet).$(CoreButton).tap();

      await $(const Key('app_shell_bottom_nav_bar')).waitUntilVisible();
    },
    config: const PatrolTesterConfig(
      visibleTimeout: Duration(seconds: 60),
      printLogs: true,
    ),
  );
}
