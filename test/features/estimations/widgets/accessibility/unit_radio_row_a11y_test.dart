import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_radio_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget makeApp(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            UnitRadioRow(
              unit: Unit.gallons,
              isSelected: true,
              onSelected: () {},
            ),
            UnitRadioRow(
              unit: Unit.pounds,
              isSelected: false,
              onSelected: () {},
            ),
          ],
        ),
      ),
    );
  }

  group('UnitRadioRow – accessibility', () {
    for (final unit in [Unit.gallons, Unit.pounds]) {
      testWidgets('the ${unit.name} row is labelled and meets tap target '
          'guidelines, selected or not', (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeApp,
          find.byKey(Key('unit_option_${unit.name}')),
        );
      });
    }
  });
}
