import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_item_tile_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('CostItemTileWidget', () {
    BuildContext? buildContext;

    Widget createWidget({required CostItem item, VoidCallback? onMenuTap, VoidCallback? onExpandTap}) {
      return MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              buildContext = context;
              return CostItemTileWidget(
                item: item,
                onMenuTap: onMenuTap,
                onExpandTap: onExpandTap,
              );
            },
          ),
        ),
      );
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

    MaterialCostItem buildMaterialItem({
      String name = 'Lap Sealant',
      double quantity = 12,
      Unit unit = Unit.pieces,
      double unitPrice = 8.0,
      double totalCost = 300.56,
    }) {
      return MaterialCostItem(
        id: 'item-123',
        estimateId: 'estimate-123',
        itemName: name,
        calculation: {'unitPrice': unitPrice, 'quantity': quantity},
        itemTotalCost: totalCost,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        currency: 'USD',
        unitPrice: Money(amount: unitPrice),
        quantity: Quantity(value: quantity, unit: unit),
      );
    }

    LaborCostItem buildLaborItem({
      String name = 'Foundation Labor',
      LaborCalculationMethodType method = LaborCalculationMethodType.perHour,
      double? laborHours = 8.0,
      double? laborDays,
      double? laborUnitValue,
      int? crewSize,
      double totalCost = 480.0,
    }) {
      return LaborCostItem(
        id: 'item-456',
        estimateId: 'estimate-123',
        itemName: name,
        calculation: {'laborRate': 60.0},
        itemTotalCost: totalCost,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        currency: 'USD',
        laborCalcMethod: method,
        laborValue: LaborValue(
          laborHours: laborHours,
          laborDays: laborDays,
          laborUnitValue: laborUnitValue,
        ),
        crewSize: crewSize,
      );
    }

    EquipmentCostItem buildEquipmentItem({
      String name = 'Concrete Mixer',
      double quantity = 2,
      Unit unit = Unit.pieces,
      double unitPrice = 500.0,
      double totalCost = 1000.0,
    }) {
      return EquipmentCostItem(
        id: 'item-789',
        estimateId: 'estimate-123',
        itemName: name,
        calculation: {'unitPrice': unitPrice, 'quantity': quantity},
        itemTotalCost: totalCost,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        currency: 'USD',
        unitPrice: Money(amount: unitPrice),
        quantity: Quantity(value: quantity, unit: unit),
      );
    }

    group('Structure', () {
      testWidgets('renders item name', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileName')), findsOneWidget);
        final nameWidget = tester.widget<Text>(find.byKey(const Key('costItemTileName')));
        expect(nameWidget.data, 'Lap Sealant');
      });

      testWidgets('renders menu button', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileMenuButton')), findsOneWidget);
      });

      testWidgets('renders expand button', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileExpandButton')), findsOneWidget);
      });

      testWidgets('renders total cost formatted as currency', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(totalCost: 300.56)));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileTotal')), findsOneWidget);
        final totalWidget = tester.widget<Text>(find.byKey(const Key('costItemTileTotal')));
        expect(totalWidget.data, DisplayFormatter.formatCurrency(300.56));
      });

      testWidgets('renders metadata section', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileMetadata')), findsOneWidget);
      });
    });

    group('Material Item', () {
      testWidgets('shows quantity label', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(quantity: 12)));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileQuantityLabel), findsWidgets);
        expect(find.text('12'), findsOneWidget);
      });

      testWidgets('shows UOM label with unit name uppercased', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(unit: Unit.rolls)));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileUomLabel), findsWidgets);
        expect(find.text(Unit.rolls.name.toUpperCase()), findsOneWidget);
      });

      testWidgets('shows unit price label with formatted currency', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(unitPrice: 8.0)));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileUnitPriceLabel), findsWidgets);
        expect(find.text(DisplayFormatter.formatCurrency(8.0)), findsOneWidget);
      });

      testWidgets('formats integer quantity without decimal point', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(quantity: 10)));
        await tester.pumpAndSettle();

        expect(find.text('10'), findsOneWidget);
        expect(find.text('10.00'), findsNothing);
      });

      testWidgets('formats decimal quantity to 2 decimal places', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(quantity: 410.67)));
        await tester.pumpAndSettle();

        expect(find.text('410.67'), findsOneWidget);
      });

      testWidgets('shows total label', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem()));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileTotalLabel), findsOneWidget);
      });
    });

    group('Equipment Item', () {
      testWidgets('shows quantity, UOM, and unit price', (tester) async {
        final item = buildEquipmentItem(quantity: 2, unit: Unit.pieces, unitPrice: 500.0);
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileQuantityLabel), findsWidgets);
        expect(find.textContaining(loc.costItemTileUomLabel), findsWidgets);
        expect(find.textContaining(loc.costItemTileUnitPriceLabel), findsWidgets);
        expect(find.text('2'), findsOneWidget);
        expect(find.text(Unit.pieces.name.toUpperCase()), findsOneWidget);
        expect(find.text(DisplayFormatter.formatCurrency(500.0)), findsOneWidget);
      });

      testWidgets('renders equipment item name correctly', (tester) async {
        final item = buildEquipmentItem(name: 'Concrete Mixer');
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();

        final nameWidget = tester.widget<Text>(find.byKey(const Key('costItemTileName')));
        expect(nameWidget.data, 'Concrete Mixer');
      });
    });

    group('Labor Item', () {
      testWidgets('shows labor method label', (tester) async {
        final item = buildLaborItem(method: LaborCalculationMethodType.perHour);
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileLaborMethodLabel), findsWidgets);
        expect(find.text(loc.costItemTileLaborMethodPerHour), findsOneWidget);
      });

      testWidgets('shows hours for per-hour method', (tester) async {
        final item = buildLaborItem(
          method: LaborCalculationMethodType.perHour,
          laborHours: 8.0,
        );
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileLaborHoursLabel), findsWidgets);
        expect(find.text('8'), findsOneWidget);
      });

      testWidgets('shows days for per-day method', (tester) async {
        final item = buildLaborItem(
          method: LaborCalculationMethodType.perDay,
          laborHours: null,
          laborDays: 3.0,
        );
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.text(loc.costItemTileLaborMethodPerDay), findsOneWidget);
        expect(find.textContaining(loc.costItemTileLaborDaysLabel), findsWidgets);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows per-unit rate for per-unit method', (tester) async {
        final item = buildLaborItem(
          method: LaborCalculationMethodType.perUnit,
          laborHours: null,
          laborUnitValue: 150.0,
        );
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.text(loc.costItemTileLaborMethodPerUnit), findsOneWidget);
        expect(find.textContaining(loc.costItemTileLaborUnitRateLabel), findsWidgets);
        expect(find.text(DisplayFormatter.formatCurrency(150.0)), findsOneWidget);
      });

      testWidgets('shows crew size when present', (tester) async {
        final item = buildLaborItem(crewSize: 4);
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileLaborCrewSizeLabel), findsWidgets);
        expect(find.text('4'), findsOneWidget);
      });

      testWidgets('does not show crew size when absent', (tester) async {
        final item = buildLaborItem(crewSize: null);
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();
        final loc = l10n();

        expect(find.textContaining(loc.costItemTileLaborCrewSizeLabel), findsNothing);
      });
    });

    group('Callbacks', () {
      testWidgets('calls onMenuTap when menu button tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(createWidget(
          item: buildMaterialItem(),
          onMenuTap: () => tapped = true,
        ));

        await tester.tap(find.byKey(const Key('costItemTileMenuButton')));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('calls onExpandTap when expand button tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(createWidget(
          item: buildMaterialItem(),
          onExpandTap: () => tapped = true,
        ));

        await tester.tap(find.byKey(const Key('costItemTileExpandButton')));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('renders without callbacks provided', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileMenuButton')), findsOneWidget);
        expect(find.byKey(const Key('costItemTileExpandButton')), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles long item name without overflow', (tester) async {
        final item = buildMaterialItem(
          name: 'Very Long Material Name That Might Overflow The Available Space',
        );
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileName')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles zero total cost', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(totalCost: 0.0)));
        await tester.pumpAndSettle();

        final totalWidget = tester.widget<Text>(find.byKey(const Key('costItemTileTotal')));
        expect(totalWidget.data, DisplayFormatter.formatCurrency(0.0));
      });

      testWidgets('handles large total cost', (tester) async {
        await tester.pumpWidget(createWidget(item: buildMaterialItem(totalCost: 1234567.89)));
        await tester.pumpAndSettle();

        final totalWidget = tester.widget<Text>(find.byKey(const Key('costItemTileTotal')));
        expect(totalWidget.data, DisplayFormatter.formatCurrency(1234567.89));
      });

      testWidgets('handles labor item with all LaborValue fields null', (tester) async {
        final item = buildLaborItem(
          method: LaborCalculationMethodType.perHour,
          laborHours: null,
          laborDays: null,
          laborUnitValue: null,
          crewSize: null,
        );
        await tester.pumpWidget(createWidget(item: item));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('costItemTileName')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
