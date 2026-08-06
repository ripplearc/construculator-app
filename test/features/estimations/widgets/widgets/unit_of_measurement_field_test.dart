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

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(UnitOfMeasurementField));
    await tester.pumpAndSettle();
  }

  group('UnitOfMeasurementField — manual mode', () {
    testWidgets('shows label when no unit is selected', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();

      expect(find.byType(UnitOfMeasurementField), findsOneWidget);
      expect(find.text(l10n.unitOfMeasurementLabel), findsOneWidget);
    });

    testWidgets('tapping opens bottom sheet with mode question', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await openSheet(tester);

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
      await openSheet(tester);

      expect(find.text(l10n.uomFromListOption), findsOneWidget);
      expect(find.text(l10n.uomManuallyOption), findsOneWidget);
    });

    testWidgets('displays the selected unit display name', (tester) async {
      await tester.pumpWidget(makeWidget(selectedUnit: Unit.kilograms));
      await tester.pumpAndSettle();

      expect(find.text(unitDisplayName(Unit.kilograms, l10n)), findsOneWidget);
    });
  });

  group('UnitOfMeasurementField — From list mode', () {
    testWidgets('shows all six category tabs', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await openSheet(tester);

      expect(find.text(l10n.uomCategoryLength), findsOneWidget);
      expect(find.text(l10n.uomCategoryArea), findsOneWidget);
      expect(find.text(l10n.uomCategoryVolume), findsOneWidget);
      expect(find.text(l10n.uomCategoryWeight), findsOneWidget);
      expect(find.text(l10n.uomCategoryCount), findsOneWidget);
      expect(find.text(l10n.uomCategoryTime), findsOneWidget);
    });

    testWidgets('Length tab shows meters by default', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await openSheet(tester);

      expect(find.text(unitDisplayName(Unit.meters, l10n)), findsOneWidget);
    });

    testWidgets('tapping a unit fires onUnitSelected with the correct Unit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Unit? captured;
      await tester.pumpWidget(makeWidget(onUnitSelected: (u) => captured = u));
      await tester.pumpAndSettle();
      await openSheet(tester);

      await tester.tap(find.text(unitDisplayName(Unit.meters, l10n)));
      await tester.pumpAndSettle();

      expect(captured, Unit.meters);
    });

    testWidgets('switching to Weight tab shows kilograms and tons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await openSheet(tester);

      await tester.ensureVisible(find.text(l10n.uomCategoryWeight));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.uomCategoryWeight));
      await tester.pumpAndSettle();

      expect(find.text(unitDisplayName(Unit.kilograms, l10n)), findsOneWidget);
      expect(find.text(unitDisplayName(Unit.tons, l10n)), findsOneWidget);
    });
  });

  group('UnitOfMeasurementField — Manually mode', () {
    testWidgets('manual text field is hidden when From list is selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      await openSheet(tester);

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
      await openSheet(tester);

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
      await openSheet(tester);

      expect(
        tester.widget<CoreButton>(find.byType(CoreButton)).isDisabled,
        isTrue,
      );
    });
  });

  group('UnitOfMeasurementField — from cost file mode', () {
    testWidgets('shows label when no unit is prefilled', (tester) async {
      await tester.pumpWidget(makeWidget(fromCostFile: true));
      await tester.pumpAndSettle();

      expect(find.text(l10n.unitOfMeasurementLabel), findsOneWidget);
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
      await openSheet(tester);

      expect(find.text(l10n.uomAddModeQuestion), findsNothing);
    });
  });
}
