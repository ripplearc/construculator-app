import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_of_measurement_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  String unitName(Unit unit) => switch (unit) {
    Unit.pieces => l10n.unitPieces,
    Unit.meters => l10n.unitMeters,
    Unit.squareMeters => l10n.unitSquareMeters,
    Unit.cubicMeters => l10n.unitCubicMeters,
    Unit.kilograms => l10n.unitKilograms,
    Unit.tons => l10n.unitTons,
    Unit.liters => l10n.unitLiters,
    Unit.hours => l10n.unitHours,
    Unit.days => l10n.unitDays,
    Unit.boxes => l10n.unitBoxes,
    Unit.bags => l10n.unitBags,
    Unit.rolls => l10n.unitRolls,
    Unit.sheets => l10n.unitSheets,
  };

  Widget makeWidget({
    bool fromCostFile = false,
    Unit? selectedUnit,
    ValueChanged<Unit?>? onUnitSelected,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: UnitOfMeasurementField(
          fromCostFile: fromCostFile,
          selectedUnit: selectedUnit,
          onUnitSelected: onUnitSelected ?? (_) {},
        ),
      ),
    );
  }

  group('UnitOfMeasurementField — manual mode', () {
    testWidgets('shows label and hint when no unit is selected', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byType(UnitOfMeasurementField), findsOneWidget);
      expect(find.text(l10n.uomLabel), findsOneWidget);
      // SingleItemSelector renders hint both in InputDecoration and child Text
      expect(find.text(l10n.unitOfMeasurementHint), findsWidgets);
    });

    testWidgets('tapping opens bottom sheet with unit options', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectUnitTitle), findsOneWidget);
    });

    testWidgets('bottom sheet lists all 13 unit display names', (tester) async {
      // Tall viewport so FractionallySizedBox(0.4) gives 1200px — enough for all 13 ListView items
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      for (final unit in Unit.values) {
        expect(find.text(unitName(unit)), findsOneWidget);
      }
    });

    testWidgets('selecting a unit fires onUnitSelected with the correct Unit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Unit? captured;
      await tester.pumpWidget(makeWidget(onUnitSelected: (u) => captured = u));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      // Use meters (index 1) — always visible without scrolling in the bottom sheet
      await tester.tap(find.text(unitName(Unit.meters)));
      await tester.pumpAndSettle();

      expect(captured, Unit.meters);
    });

    testWidgets('displays the selected unit display name', (tester) async {
      await tester.pumpWidget(makeWidget(selectedUnit: Unit.kilograms));
      await tester.pumpAndSettle();

      expect(find.text(unitName(Unit.kilograms)), findsOneWidget);
    });
  });

  group('UnitOfMeasurementField — from cost file mode', () {
    testWidgets('shows hint text when no unit is prefilled', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      // SingleItemSelector renders hint both in InputDecoration and child Text
      expect(find.text(l10n.unitOfMeasurementHint), findsWidgets);
    });

    testWidgets('shows prefilled unit display name', (tester) async {
      await tester.pumpWidget(
        makeWidget(fromCostFile: true, selectedUnit: Unit.meters),
      );
      await tester.pumpAndSettle();

      expect(find.text(unitName(Unit.meters)), findsOneWidget);
    });

    testWidgets('does not open bottom sheet when disabled', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectUnitTitle), findsNothing);
    });
  });
}
