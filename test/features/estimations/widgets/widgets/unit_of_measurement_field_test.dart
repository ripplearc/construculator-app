import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_of_measurement_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../helpers/unit_display_name_helper.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

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
    testWidgets('shows hint when no unit is selected', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byType(UnitOfMeasurementField), findsOneWidget);
      expect(find.text(l10n.unitOfMeasurementHint), findsWidgets);
    });

    testWidgets('tapping opens bottom sheet with mode question', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      expect(find.text(l10n.uomAddModeQuestion), findsOneWidget);
    });

    testWidgets('bottom sheet shows From list and Manually radio options', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      expect(find.text(l10n.uomFromListOption), findsOneWidget);
      expect(find.text(l10n.uomManuallyOption), findsOneWidget);
    });

    testWidgets('manual text field is hidden when From list is selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      expect(find.text(l10n.uomManualInputHint), findsNothing);
    });

    testWidgets('tapping Manually radio shows manual text field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.uomManuallyOption));
      await tester.pumpAndSettle();

      expect(find.text(l10n.uomManualInputHint), findsOneWidget);
    });

    testWidgets('Add UOM button is always disabled', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      expect(find.text(l10n.addUomButton), findsOneWidget);
    });

    testWidgets('displays the selected unit display name', (tester) async {
      await tester.pumpWidget(makeWidget(selectedUnit: Unit.kilograms));
      await tester.pumpAndSettle();

      expect(find.text(unitDisplayName(Unit.kilograms, l10n)), findsOneWidget);
    });
  });

  group('UnitOfMeasurementField — from cost file mode', () {
    testWidgets('shows hint text when no unit is prefilled', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.text(l10n.unitOfMeasurementHint), findsWidgets);
    });

    testWidgets('shows prefilled unit display name', (tester) async {
      await tester.pumpWidget(
        makeWidget(fromCostFile: true, selectedUnit: Unit.meters),
      );
      await tester.pumpAndSettle();

      expect(find.text(unitDisplayName(Unit.meters, l10n)), findsOneWidget);
    });

    testWidgets('does not open bottom sheet when disabled', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnitOfMeasurementField));
      await tester.pumpAndSettle();

      expect(find.text(l10n.uomAddModeQuestion), findsNothing);
    });
  });
}
