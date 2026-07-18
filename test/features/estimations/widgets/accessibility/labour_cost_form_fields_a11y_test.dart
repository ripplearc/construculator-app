import 'package:construculator/features/estimation/presentation/widgets/labour_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget makeWidget(ThemeData theme, {bool fromCostFile = false}) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LabourCostFormFields(fromCostFile: fromCostFile),
      ),
    );
  }

  group('LabourCostFormFields – accessibility', () {
    testWidgets(
      'a11y: calc method card meets label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('calc_method_card')),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );

    testWidgets(
      'a11y: per day radio option has semantic label in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('per_day_option')),
        );
      },
    );
  });
}
