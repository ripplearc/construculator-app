import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

void main() {
  group('cost_items table', () {
    test(
      'has exactly the columns the server table accepts from the app, with their types',
      () {
        final columnTypes = {
          for (final column
              in schema.tables
                  .singleWhere((table) => table.name == 'cost_items')
                  .columns)
            column.name: column.type,
        };

        expect(columnTypes, {
          'estimate_id': ColumnType.text,
          'item_type': ColumnType.text,
          'item_name': ColumnType.text,
          'unit_price': ColumnType.real,
          'quantity': ColumnType.real,
          'unit_measurement': ColumnType.text,
          'calculation': ColumnType.text,
          'item_total_cost': ColumnType.real,
          'currency': ColumnType.text,
          'product_link': ColumnType.text,
          'description': ColumnType.text,
          'pricing_method': ColumnType.text,
          'duration': ColumnType.real,
          'daily_rate': ColumnType.real,
          'job_amount': ColumnType.real,
          'delivery_fee': ColumnType.real,
          'rate_status': ColumnType.text,
          'labor_calc_method': ColumnType.text,
          'labor_days': ColumnType.real,
          'labor_hours': ColumnType.real,
          'labor_unit_type': ColumnType.text,
          'labor_unit_value': ColumnType.real,
          'crew_size': ColumnType.integer,
          'waste_percent': ColumnType.real,
          'quantity_provenance': ColumnType.text,
          'calculator_formula': ColumnType.text,
          'created_at': ColumnType.text,
          'updated_at': ColumnType.text,
        });
      },
    );
  });
  group('cost_item_refusals table', () {
    final table = schema.tables.singleWhere(
      (table) => table.name == 'cost_item_refusals',
    );

    test('stays on the phone and is never uploaded', () {
      expect(table.localOnly, isTrue);
    });

    test('has the columns that keep a refused line, with their types', () {
      expect(
        {for (final column in table.columns) column.name: column.type},
        {
          'estimate_id': ColumnType.text,
          'line': ColumnType.text,
          'reason': ColumnType.text,
          'refused_at': ColumnType.text,
        },
      );
    });
  });
}
