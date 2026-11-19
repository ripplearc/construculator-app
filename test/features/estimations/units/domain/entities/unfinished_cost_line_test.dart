import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/unfinished_cost_line.dart';
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

    test('writes no unit while none is picked', () {
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
    UnfinishedCostLine copy({String note = 'Two coats'}) => UnfinishedCostLine(
      category: line.category,
      estimateId: line.estimateId,
      itemName: line.itemName,
      quantity: line.quantity,
      unit: line.unit,
      rate: line.rate,
      wastePercent: line.wastePercent,
      note: note,
      updatedAt: line.updatedAt,
    );

    test('lines with the same fields are equal', () {
      expect(copy(), line);
    });

    test('lines that differ in one field are not equal', () {
      expect(copy(note: 'One coat'), isNot(line));
    });
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

  group('UnfinishedCostLine.fromJson', () {
    test('reads back what toJson wrote', () {
      expect(UnfinishedCostLine.fromJson(line.toJson()), line);
    });

    test('reads a whole-number quantity written as an int', () {
      final json = {...line.toJson(), 'quantity': 12, 'rate': 14};

      expect(
        UnfinishedCostLine.fromJson(json),
        _lineWith('rate', (l) => l.rate, 14.0),
      );
    });

    test('reads a time written in UTC back as the same local time', () {
      final json = {...line.toJson(), 'updatedAt': '2026-11-10T09:00:00Z'};

      expect(
        UnfinishedCostLine.fromJson(json),
        _lineWith(
          'updatedAt',
          (l) => l.updatedAt,
          DateTime.utc(2026, 11, 10, 9).toLocal(),
        ),
      );
    });

    test('reads an unknown unit as no unit', () {
      final json = {...line.toJson(), 'unit': 'furlongs'};

      expect(
        UnfinishedCostLine.fromJson(json),
        _lineWith('unit', (l) => l.unit, isNull),
      );
    });

    test('reads back the saved line id', () {
      final json = {...line.toJson(), 'costItemId': 'item-7'};

      expect(
        UnfinishedCostLine.fromJson(json),
        _lineWith('costItemId', (l) => l.costItemId, 'item-7'),
      );
    });

    for (final (name, change) in [
      ('category', <String, Object?>{'category': null}),
      ('estimate', <String, Object?>{'estimateId': 7}),
      ('change time', <String, Object?>{'updatedAt': null}),
    ]) {
      test('returns null without a usable $name', () {
        expect(
          UnfinishedCostLine.fromJson({...line.toJson(), ...change}),
          isNull,
        );
      });
    }
  });
}

Matcher _lineWith(
  String name,
  Object? Function(UnfinishedCostLine line) field,
  Object? value,
) => isA<UnfinishedCostLine>().having(field, name, value);
