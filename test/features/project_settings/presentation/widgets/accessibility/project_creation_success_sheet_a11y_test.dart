import 'package:construculator/features/project_settings/presentation/widgets/project_creation_success_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../../utils/screenshot/font_loader.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Widget buildTestApp(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProjectCreationSuccessSheetContent(
          onBackToCalculation: () {},
          onContinue: () {},
        ),
      ),
    );
  }

  setUpAll(loadAppFontsAll);

  group('ProjectCreationSuccessSheetContent - accessibility', () {
    testWidgets(
      '"Back to calculation" button meets a11y guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          buildTestApp,
          find.byKey(const Key('back_to_calculation_button')),
        );
      },
    );

    testWidgets(
      '"Continue" button meets a11y guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          buildTestApp,
          find.byKey(const Key('continue_button')),
        );
      },
    );

    testWidgets(
      'success message text meets contrast guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          buildTestApp,
          find.text(l10n.projectCreationSuccessMessage),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );
  });
}
