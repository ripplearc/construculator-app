import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_cost_category_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget makeWidget(ThemeData theme) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: AddCostCategorySheet()),
  );

  group('AddCostCategorySheet – accessibility', () {
    for (final type in CostItemType.values) {
      testWidgets('a11y: the ${type.name} row meets tap target and label '
          'guidelines in both themes', (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(AddCostCategorySheet.rowKey(type)),
        );
      });
    }
  });
}
