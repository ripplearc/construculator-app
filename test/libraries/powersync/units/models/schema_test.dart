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
  group('calculator_sessions table', () {
    final table = schema.tables.singleWhere(
      (table) => table.name == 'calculator_sessions',
    );

    test('stays on the phone and is never uploaded', () {
      expect(table.localOnly, isTrue);
    });

    test('has the columns a history card reads, with their types, and is '
        'indexed by when the tape was last banked', () {
      expect(
        {for (final column in table.columns) column.name: column.type},
        {
          'creator_user_id': ColumnType.text,
          'title': ColumnType.text,
          'result_text': ColumnType.text,
          'result_value': ColumnType.real,
          'result_dimension': ColumnType.text,
          'result_unit': ColumnType.text,
          'created_at': ColumnType.text,
          'updated_at': ColumnType.text,
          'last_calculation_at': ColumnType.text,
        },
      );
      expect(
        [
          for (final index in table.indexes)
            '${index.name}: ${index.columns.map((c) => c.column).join(',')}',
        ],
        ['by_recent: last_calculation_at'],
      );
    });
  });
  group('calculator_tapes table', () {
    final table = schema.tables.singleWhere(
      (table) => table.name == 'calculator_tapes',
    );

    test('stays on the phone and is never uploaded', () {
      expect(table.localOnly, isTrue);
    });

    test('has the columns that keep a tape as JSON with its version, and is '
        'indexed by session', () {
      expect(
        {for (final column in table.columns) column.name: column.type},
        {
          'session_id': ColumnType.text,
          'computation': ColumnType.text,
          'schema_version': ColumnType.integer,
          'created_at': ColumnType.text,
        },
      );
      expect(
        [
          for (final index in table.indexes)
            '${index.name}: ${index.columns.map((c) => c.column).join(',')}',
        ],
        ['by_session: session_id'],
      );
    });
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
