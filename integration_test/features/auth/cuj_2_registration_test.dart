import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../utils/app_runner.dart';
import '../../utils/mailpit_client.dart';
import '../../utils/test_config.dart';

void main() {
  patrolTest(
    'CUJ-2: Registration — new user completes OTP verification and lands on the dashboard',
    ($) async {
      await startApp($);

      // App boots to the login screen; "Sign up" reaches registration.
      await $(const Key('auth_footer_link')).tap();

      final email = TestConfig.uniqueRegisterEmail();
      await $(const Key('register_email_field')).enterText(email);
      await $(const Key('register_email_continue_button')).tap();

      final otp = await MailpitClient.waitForOtp(email);
      await $(const Key('pin_input')).enterText(otp);
      await $(const Key('otp_verify_button')).tap();

      await $(const Key('create_account_first_name_field')).enterText('E2E');
      await $(const Key('create_account_last_name_field')).enterText('Tester');

      await $(const Key('create_account_role_selector')).tap();
      // Which professional role is seeded first doesn't matter to this
      // journey, only that a role is selected — scoped to the list's own key
      // rather than a bare, unscoped `ListTile` finder.
      await $(const Key('professional_role_list')).$(ListTile).at(0).tap();

      await $(
        const Key('create_account_password_field'),
      ).enterText(TestConfig.registerPassword);
      await $(
        const Key('create_account_confirm_password_field'),
      ).enterText(TestConfig.registerPassword);
      await $(const Key('create_account_submit_button')).tap();

      // The success modal is a package-owned bottom sheet whose button carries
      // no key, so it is anchored to the sheet rather than to screen position.
      await $(BottomSheet).$(CoreButton).tap();

      await $(const Key('app_shell_bottom_nav_bar')).waitUntilVisible();
    },
    config: const PatrolTesterConfig(visibleTimeout: Duration(seconds: 60)),
  );
}
