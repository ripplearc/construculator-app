import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/material_unit_list.dart';
import 'package:construculator/features/estimation/presentation/widgets/select_unit_sheet.dart';
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
      home: const Scaffold(
        body: SelectUnitSheet(
          groups: imperialMaterialUnits,
          selected: Unit.gallons,
        ),
      ),
    );
  }

  group('SelectUnitSheet – accessibility', () {
    testWidgets('unit rows are labelled and meet tap target guidelines', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeApp,
        find.byKey(const Key('unit_option_gallons')),
      );
      expect(
        find.bySemanticsLabel('gal, Gallon — paint, adhesive'),
        findsOneWidget,
      );
    });
  });
}
