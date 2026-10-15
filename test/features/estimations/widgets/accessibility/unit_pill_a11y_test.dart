import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_pill.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget makeWidget(ThemeData theme, {Unit? unit}) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: UnitPill(
          key: const Key('unit_pill'),
          unit: unit,
          onUnitSelected: (_) {},
        ),
      ),
    ),
  );

  group('UnitPill – accessibility', () {
    testWidgets('a11y: the pill with no unit meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(const Key('unit_pill')),
      );
    });

    testWidgets('a11y: the pill with a unit meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeWidget(theme, unit: Unit.liters),
        find.byKey(const Key('unit_pill')),
      );
    });
  });
}
