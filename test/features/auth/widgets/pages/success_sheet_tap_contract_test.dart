import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../../integration_test/utils/success_or_error.dart';
import '../../../../utils/screenshot/font_loader.dart';

// The registration and login journeys in `integration_test/` end by tapping the
// success sheet's button through `tapSuccessSheetOrFailFast`. `flutter test`
// does not run that folder, and the CUJ workflow runs it only weekly, on a
// manual dispatch or on a `#RunE2E` comment, so a tap that misses the button
// would surface only there.
void main() {
  late BuildContext context;
  late int continueTaps;

  setUp(() {
    continueTaps = 0;
  });

  Future<void> showSuccessSheet(
    WidgetTester tester, {
    AnimationStyle? slideIn,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        sheetAnimationStyle: slideIn,
        builder: (_) => SizedBox(
          height: 200,
          child: Center(
            child: CoreButton(
              label: 'Continue',
              onPressed: () => continueTaps++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('taps the button of a sheet that slides in normally', (
    tester,
  ) async {
    await showSuccessSheet(tester);

    await tapSuccessSheetOrFailFast(tester);

    expect(continueTaps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'does not tap while the sheet is still off-screen and holding still',
    (tester) async {
      await showSuccessSheet(
        tester,
        slideIn: AnimationStyle(
          duration: const Duration(seconds: 2),
          curve: const Interval(0.4, 1),
        ),
      );

      await tapSuccessSheetOrFailFast(tester);

      expect(continueTaps, 1);
      await tester.pumpAndSettle();
    },
  );
}
