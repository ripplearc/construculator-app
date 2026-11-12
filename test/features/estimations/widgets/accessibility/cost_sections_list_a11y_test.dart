import 'package:construculator/features/estimation/presentation/bloc/cost_items_bloc/cost_items_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_sections_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../helpers/cost_line_test_items.dart';

void main() {
  Widget Function(ThemeData) makeWidget(CostItemsLoaded costs) =>
      (theme) => MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CostSectionsList(
            costs: costs,
            highlightedItemId: null,
            onLineTap: (_) {},
            onAddFirstCost: () {},
          ),
        ),
      );

  group('CostSectionsList – accessibility', () {
    testWidgets('a11y: a cost line meets tap target and label guidelines in '
        'both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget(
          CostItemsLoaded(
            items: [materialLine(), laborLine(), equipmentLine()],
            materialsSubtotal: 211.34,
            laborSubtotal: 480,
            equipmentSubtotal: 665,
          ),
        ),
        find.byKey(const Key('cost_line_q1')),
      );
    });

    testWidgets('a11y: the first-cost button of an empty estimate meets tap '
        'target and label guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget(
          const CostItemsLoaded(
            items: [],
            materialsSubtotal: 0,
            laborSubtotal: 0,
            equipmentSubtotal: 0,
          ),
        ),
        find.byKey(CostSectionsList.addFirstCostButtonKey),
      );
    });
  });
}
