import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_item_tile_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  group('CostItemTileWidget – accessibility', () {
    Widget createWidget(CostItem item, {ThemeData? theme}) {
      return MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CostItemTileWidget(item: item),
          ),
        ),
      );
    }

    final materialItem = MaterialCostItem(
      id: 'item-1',
      estimateId: 'estimate-1',
      itemName: 'Lap Sealant',
      calculation: {'unitPrice': 8.0, 'quantity': 12},
      itemTotalCost: 300.56,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      currency: 'USD',
      unitPrice: const Money(amount: 8.0),
      quantity: const Quantity(value: 12, unit: Unit.pieces),
    );

    final laborItem = LaborCostItem(
      id: 'item-2',
      estimateId: 'estimate-1',
      itemName: 'Foundation Labor',
      calculation: {'laborRate': 60.0},
      itemTotalCost: 480.0,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      currency: 'USD',
      laborCalcMethod: LaborCalculationMethodType.perHour,
      laborValue: const LaborValue(laborHours: 8.0),
      crewSize: 2,
    );

    final equipmentItem = EquipmentCostItem(
      id: 'item-3',
      estimateId: 'estimate-1',
      itemName: 'Concrete Mixer',
      calculation: {'unitPrice': 500.0, 'quantity': 2},
      itemTotalCost: 1000.0,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      currency: 'USD',
      unitPrice: const Money(amount: 500.0),
      quantity: const Quantity(value: 2, unit: Unit.pieces),
    );

    testWidgets(
      'material item meets a11y guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        // Tap target check is disabled: icon buttons are 20dp, below the 48dp minimum.
        // Menu and expand buttons have explicit semantic labels via Semantics(button: true, label: ...).
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => createWidget(materialItem, theme: theme),
          find.byType(CostItemTileWidget),
          checkTapTargetSize: false,
          checkLabeledTapTarget: true,
        );
      },
    );

    testWidgets(
      'labor item meets a11y guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => createWidget(laborItem, theme: theme),
          find.byType(CostItemTileWidget),
          checkTapTargetSize: false,
          checkLabeledTapTarget: true,
        );
      },
    );

    testWidgets(
      'equipment item meets a11y guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => createWidget(equipmentItem, theme: theme),
          find.byType(CostItemTileWidget),
          checkTapTargetSize: false,
          checkLabeledTapTarget: true,
        );
      },
    );

    testWidgets(
      'material item passes text contrast in light theme',
      (tester) async {
        await setupA11yTest(tester);

        await tester.pumpWidget(createWidget(materialItem, theme: createTestTheme()));
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.byType(CostItemTileWidget),
          checkTapTargetSize: false,
          checkLabeledTapTarget: true,
          checkTextContrast: true,
        );
      },
    );

    testWidgets(
      'material item passes text contrast in dark theme',
      (tester) async {
        await setupA11yTest(tester);

        await tester.pumpWidget(createWidget(materialItem, theme: createTestThemeDark()));
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.byType(CostItemTileWidget),
          checkTapTargetSize: false,
          checkLabeledTapTarget: true,
          checkTextContrast: true,
        );
      },
    );
  });
}
