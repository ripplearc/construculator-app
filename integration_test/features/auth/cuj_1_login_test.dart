import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../utils/app_runner.dart';
import '../../utils/test_config.dart';

void main() {
  patrolTest(
    'CUJ-1: Login — returning user lands on the dashboard',
    ($) async {
      await startApp($);

      await $(TextField).first.enterText(TestConfig.loginEmail);
      await $('Continue').tap();
      await $.pumpAndSettle();

      await $(TextField).first.enterText(TestConfig.loginPassword);
      await $('Continue').tap();
      await $.pumpAndSettle();

      await $('Continue').tap();
      await $.pumpAndSettle();

      expect($(BottomNavigationBar), findsOneWidget);
    },
    config: const PatrolTesterConfig(
      visibleTimeout: Duration(seconds: 15),
      settleTimeout: Duration(seconds: 10),
    ),
  );
}
