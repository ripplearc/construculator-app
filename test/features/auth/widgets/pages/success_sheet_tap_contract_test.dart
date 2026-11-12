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

  Future<void> pumpHost(WidgetTester tester) async {
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
  }

  Future<void> showSlidingSheet(
    WidgetTester tester, {
    required AnimationStyle slideIn,
  }) async {
    await pumpHost(tester);
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
    await tester.pump();
  }

  testWidgets('taps the button of the real success modal', (tester) async {
    await pumpHost(tester);
    SuccessModal.show(
      context,
      message: 'Registered',
      buttonLabel: 'Continue',
      onPressed: () => continueTaps++,
    );

    await tapSuccessSheetOrFailFast(tester);

    expect(continueTaps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'taps once a sheet that held off-screen before sliding in reaches the screen',
    (tester) async {
      await showSlidingSheet(
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

  Future<Object?> failureOf(Future<void> action) async {
    try {
      await action;
    } on TestFailure catch (failure) {
      return failure;
    }
    return null;
  }

  testWidgets('fails with the toast message when a toast appears instead', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        home: Scaffold(
          body: Toast.error(description: 'Invalid code', closeLabel: 'Close'),
        ),
      ),
    );

    final failure = await failureOf(tapSuccessSheetOrFailFast(tester));

    expect(
      failure,
      isA<TestFailure>().having(
        (failure) => failure.message,
        'message',
        'Expected the success sheet but got a toast: Invalid code / Close',
      ),
    );
  });

  testWidgets('fails as a timeout when neither a sheet nor a toast appears', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: createTestTheme(), home: const SizedBox()),
    );

    final failure = await failureOf(
      tapSuccessSheetOrFailFast(
        tester,
        timeout: const Duration(milliseconds: 1),
      ),
    );

    expect(
      failure,
      isA<TestFailure>().having(
        (failure) => failure.message,
        'message',
        'Timed out after 0:00:00.001000 waiting for the success sheet. No toast '
            'appeared either, so the app genuinely never responded.',
      ),
    );
  });

  testWidgets(
    'fails naming the button when it is in the tree but never hit-testable',
    (tester) async {
      await showSlidingSheet(
        tester,
        slideIn: const AnimationStyle(duration: Duration(minutes: 1)),
      );

      final failure = await failureOf(
        tapSuccessSheetOrFailFast(
          tester,
          timeout: const Duration(milliseconds: 1),
        ),
      );

      expect(
        failure,
        isA<TestFailure>().having(
          (failure) => failure.message,
          'message',
          'Timed out after 0:00:00.001000: the success sheet button was in the '
              'widget tree but never became hit-testable, so no tap could land '
              'on it.',
        ),
      );
      expect(continueTaps, 0);
      await tester.pumpAndSettle();
    },
  );
}
