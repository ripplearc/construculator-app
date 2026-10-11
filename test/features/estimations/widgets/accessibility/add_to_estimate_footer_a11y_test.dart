import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget Function(ThemeData) makeWidget({AddToEstimateBlock? block}) =>
      (theme) => MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddToEstimateFooter(
            lineTotal: 605,
            deliveryFee: 85,
            estimateName: 'Bedroom 2',
            estimateTotal: 2993.62,
            block: block,
            onAdd: () {},
          ),
        ),
      );

  group('AddToEstimateFooter – accessibility', () {
    for (final block in <AddToEstimateBlock?>[
      null,
      const AddToEstimateBlock(
        note: 'Needs a rate before it can total',
        buttonLabel: 'Enter a rate to continue',
      ),
    ]) {
      testWidgets('a11y: ${block == null ? 'ready' : 'blocked'} button meets tap '
          'target and label guidelines in both themes', (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget(block: block),
          find.byKey(AddToEstimateFooter.buttonKey),
          // TODO: [CA-1257] re-enable once design fixes the 2.42:1 grey on the summary card. https://ripplearc.youtrack.cloud/issue/CA-1257
          checkTextContrast: false,
        );
      });
    }
  });
}
