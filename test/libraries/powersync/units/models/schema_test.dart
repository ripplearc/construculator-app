import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cost_items table', () {
    test('has exactly the columns the server table accepts from the app', () {
      final columns = schema.tables
          .singleWhere((table) => table.name == 'cost_items')
          .columns
          .map((column) => column.name);

      expect(
        columns,
        unorderedEquals([
          'estimate_id',
          'item_type',
          'item_name',
          'unit_price',
          'quantity',
          'unit_measurement',
          'calculation',
          'item_total_cost',
          'currency',
          'product_link',
          'description',
          'pricing_method',
          'duration',
          'daily_rate',
          'job_amount',
          'delivery_fee',
          'rate_status',
          'labor_calc_method',
          'labor_days',
          'labor_hours',
          'labor_unit_type',
          'labor_unit_value',
          'crew_size',
          'waste_percent',
          'quantity_provenance',
          'calculator_formula',
          'created_at',
          'updated_at',
        ]),
      );
    });
  });
}
