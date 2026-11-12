import 'package:construculator/features/estimation/presentation/widgets/add_cost_bottom_bar.dart';
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
    home: Scaffold(
      bottomNavigationBar: AddCostBottomBar(
        isEstimateEmpty: false,
        total: 2097.02,
        onAddCost: () {},
        onPreview: () {},
      ),
    ),
  );

  group('AddCostBottomBar – accessibility', () {
    for (final entry in {
      '+ Add cost': AddCostBottomBar.addCostButtonKey,
      'Preview': AddCostBottomBar.previewButtonKey,
    }.entries) {
      testWidgets('a11y: ${entry.key} meets tap target and label guidelines '
          'in both themes', (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(entry.value),
        );
      });
    }
  });
}
