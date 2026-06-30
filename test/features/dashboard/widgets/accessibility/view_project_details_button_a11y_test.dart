import 'package:construculator/features/dashboard/presentation/widgets/view_project_details_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget makeTestableWidget({
    required Widget child,
    required ThemeData theme,
  }) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ViewProjectDetailsButton - accessibility', () {
    testWidgets(
      'meets tap-target and label guidelines in both themes when onPressed set',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: ViewProjectDetailsButton(onPressed: () async {}),
          ),
          find.bySemanticsLabel('Project settings'),
        );
      },
    );

    testWidgets(
      'excludes semantics when onPressed is null',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: const ViewProjectDetailsButton(),
          ),
          find.byType(ViewProjectDetailsButton),
          checkLabeledTapTarget: false,
        );

        expect(find.bySemanticsLabel('Project settings'), findsNothing);
      },
    );

    testWidgets(
      'hit target is ${CoreSpacing.space12} × ${CoreSpacing.space12} points in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: ViewProjectDetailsButton(onPressed: () async {}),
          ),
          find.byType(ViewProjectDetailsButton),
          checkLabeledTapTarget: false,
          setupAfterPump: (tester) async {
            final box =
                tester.getRect(find.byType(ViewProjectDetailsButton));
            expect(box.width, CoreSpacing.space12);
            expect(box.height, CoreSpacing.space12);
          },
        );
      },
    );
  });
}
