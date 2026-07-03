import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_item_tile_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const Size size = Size(390.0, 200.0);
  const double ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  group('CostItemTileWidget Screenshot Tests', () {
    Future<void> pumpTile({
      required WidgetTester tester,
      required CostItem item,
      Size tileSize = size,
    }) async {
      tester.view.physicalSize = tileSize;
      tester.view.devicePixelRatio = ratio;

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Material(
                color: context.colorTheme.pageBackground,
                // Align gives the tile loose constraints so it sizes to its
                // natural height rather than being forced to fill the screen.
                child: Align(
                  alignment: Alignment.topCenter,
                  child: CostItemTileWidget(item: item),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders material item correctly', (tester) async {
      final item = MaterialCostItem(
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

      await pumpTile(tester: tester, item: item);

      await expectLater(
        find.byType(CostItemTileWidget),
        matchesGoldenFile(
          'goldens/cost_item_tile_widget/${size.width}x${size.height}/material_item.png',
        ),
      );
    });

    testWidgets('renders equipment item correctly', (tester) async {
      final item = EquipmentCostItem(
        id: 'item-2',
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

      await pumpTile(tester: tester, item: item);

      await expectLater(
        find.byType(CostItemTileWidget),
        matchesGoldenFile(
          'goldens/cost_item_tile_widget/${size.width}x${size.height}/equipment_item.png',
        ),
      );
    });

    testWidgets('renders labor per-hour item correctly', (tester) async {
      final item = LaborCostItem(
        id: 'item-3',
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

      await pumpTile(tester: tester, item: item);

      await expectLater(
        find.byType(CostItemTileWidget),
        matchesGoldenFile(
          'goldens/cost_item_tile_widget/${size.width}x${size.height}/labor_per_hour_item.png',
        ),
      );
    });

    testWidgets('renders material item with long name correctly', (
      tester,
    ) async {
      final item = MaterialCostItem(
        id: 'item-4',
        estimateId: 'estimate-1',
        itemName: 'High-Strength Structural Bonding Adhesive Premium Grade',
        calculation: {'unitPrice': 200.0, 'quantity': 100},
        itemTotalCost: 20000.0,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        currency: 'USD',
        unitPrice: const Money(amount: 200.0),
        quantity: const Quantity(value: 100, unit: Unit.liters),
      );

      await pumpTile(
        tester: tester,
        item: item,
        tileSize: const Size(390.0, 220.0),
      );

      await expectLater(
        find.byType(CostItemTileWidget),
        matchesGoldenFile(
          'goldens/cost_item_tile_widget/390.0x220.0/material_long_name.png',
        ),
      );
    });

    testWidgets('renders material item with decimal quantity correctly', (
      tester,
    ) async {
      final item = MaterialCostItem(
        id: 'item-5',
        estimateId: 'estimate-1',
        itemName: 'ISO 1-1/2" Pipe',
        calculation: {'unitPrice': 65.0, 'quantity': 410.67},
        itemTotalCost: 26650.0,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        currency: 'USD',
        unitPrice: const Money(amount: 65.0),
        quantity: const Quantity(value: 410.67, unit: Unit.squareMeters),
      );

      await pumpTile(tester: tester, item: item);

      await expectLater(
        find.byType(CostItemTileWidget),
        matchesGoldenFile(
          'goldens/cost_item_tile_widget/${size.width}x${size.height}/material_decimal_qty.png',
        ),
      );
    });
  });
}
