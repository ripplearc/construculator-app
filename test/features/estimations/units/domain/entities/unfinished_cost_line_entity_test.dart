import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/unfinished_cost_line_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final line = UnfinishedCostLine(
    category: CostItemType.material,
    estimateId: 'estimate-1',
    itemName: 'Interior paint',
    quantity: 12,
    unit: Unit.liters,
    rate: 14.3,
    wastePercent: 10,
    note: 'Two coats',
    updatedAt: DateTime.utc(2026, 11, 10, 9).toLocal(),
  );

  group('UnfinishedCostLine.toJson', () {
    test('writes every field', () {
      expect(line.toJson(), {
        'category': 'material',
        'estimateId': 'estimate-1',
        'costItemId': null,
        'itemName': 'Interior paint',
        'quantity': 12.0,
        'unit': 'liters',
        'rate': 14.3,
        'wastePercent': 10.0,
        'note': 'Two coats',
        'updatedAt': '2026-11-10T09:00:00.000Z',
      });
    });

    test('writes no unit and an empty name while neither is typed', () {
      final noUnit = UnfinishedCostLine(
        category: CostItemType.labor,
        estimateId: 'estimate-1',
        updatedAt: line.updatedAt,
      );

      expect(noUnit.toJson()['unit'], isNull);
      expect(noUnit.toJson()['itemName'], '');
    });
  });

  group('UnfinishedCostLine equality', () {
    UnfinishedCostLine copy({
      CostItemType? category,
      String? estimateId,
      String? costItemId,
      String? itemName,
      double? quantity,
      Unit? unit,
      double? rate,
      double? wastePercent,
      String? note,
      DateTime? updatedAt,
    }) => UnfinishedCostLine(
      category: category ?? line.category,
      estimateId: estimateId ?? line.estimateId,
      costItemId: costItemId ?? line.costItemId,
      itemName: itemName ?? line.itemName,
      quantity: quantity ?? line.quantity,
      unit: unit ?? line.unit,
      rate: rate ?? line.rate,
      wastePercent: wastePercent ?? line.wastePercent,
      note: note ?? line.note,
      updatedAt: updatedAt ?? line.updatedAt,
    );

    test('lines with the same fields are equal', () {
      expect(copy(), line);
    });

    for (final (field, changed) in [
      ('category', copy(category: CostItemType.labor)),
      ('estimate', copy(estimateId: 'estimate-2')),
      ('saved line', copy(costItemId: 'item-7')),
      ('item name', copy(itemName: 'Primer')),
      ('quantity', copy(quantity: 13)),
      ('unit', copy(unit: Unit.gallons)),
      ('rate', copy(rate: 14.4)),
      ('waste', copy(wastePercent: 5)),
      ('note', copy(note: 'One coat')),
      ('change time', copy(updatedAt: line.updatedAt.add(_oneSecond))),
    ]) {
      test('lines that differ only in $field are not equal', () {
        expect(changed, isNot(line));
      });
    }
  });

  group('UnfinishedCostLine.isChangeToSavedLine', () {
    test('is false for a line not added yet', () {
      expect(line.isChangeToSavedLine, isFalse);
    });

    test('is true for a change to a saved line', () {
      final change = UnfinishedCostLine(
        category: CostItemType.material,
        estimateId: 'estimate-1',
        costItemId: 'item-7',
        updatedAt: line.updatedAt,
      );

      expect(change.isChangeToSavedLine, isTrue);
    });
  });
}

const _oneSecond = Duration(seconds: 1);
