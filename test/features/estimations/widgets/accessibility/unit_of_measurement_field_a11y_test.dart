import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_of_measurement_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget makeWidget(ThemeData theme, {bool fromCostFile = false, Unit? selectedUnit}) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: UnitOfMeasurementField(
          fromCostFile: fromCostFile,
          selectedUnit: selectedUnit,
          onUnitSelected: (_) {},
        ),
      ),
    );
  }

  group('UnitOfMeasurementField — accessibility', () {
    testWidgets(
      'manual mode meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byType(UnitOfMeasurementField),
        );
      },
    );

    testWidgets(
      'disabled mode meets label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeWidget(theme, fromCostFile: true, selectedUnit: Unit.meters),
          find.byType(UnitOfMeasurementField),
          checkTapTargetSize: false,
          checkTextContrast: false,
        );
      },
    );
  });
}
