import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget Function(ThemeData) makeWidget({
    AddToEstimateBlock? block,
    double? changeInEstimateTotal,
    VoidCallback? onDelete,
  }) =>
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
            changeInEstimateTotal: changeInEstimateTotal,
            onDelete: onDelete,
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

    for (final change in <double>[0, 200]) {
      testWidgets(
        'a11y: editing a line with a change of $change, the save button '
        'meets tap target and label guidelines in both themes',
        (tester) async {
          await setupA11yTest(tester);

          await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
            tester,
            makeWidget(changeInEstimateTotal: change),
            find.byKey(AddToEstimateFooter.buttonKey),
            // TODO: [CA-1257] re-enable once design fixes the 2.42:1 grey on the summary card.
            // https://ripplearc.youtrack.cloud/issue/CA-1257
            checkTextContrast: false,
          );
        },
      );
    }

    testWidgets(
      'a11y: the delete button meets tap target and label guidelines in both '
      'themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget(changeInEstimateTotal: 0, onDelete: () {}),
          find.byKey(AddToEstimateFooter.deleteButtonKey),
          // TODO: [CA-1257] re-enable once design fixes the 2.42:1 grey on the summary card.
          // https://ripplearc.youtrack.cloud/issue/CA-1257
          checkTextContrast: false,
        );
      },
    );

    testWidgets('a screen reader can activate the delete button', (
      tester,
    ) async {
      await setupA11yTest(tester);
      final semantics = tester.ensureSemantics();
      var deleteTaps = 0;

      await tester.pumpWidget(
        makeWidget(changeInEstimateTotal: 0, onDelete: () => deleteTaps++)(
          CoreTheme.light(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AddToEstimateFooter.deleteButtonKey));
      expect(deleteTaps, 1);

      deleteTaps = 0;
      tester.semantics.tap(
        find.semantics.byLabel(
          lookupAppLocalizations(const Locale('en')).deleteThisLineButton,
        ),
      );
      await tester.pump();

      expect(deleteTaps, 1);
      semantics.dispose();
    });
  });
}
