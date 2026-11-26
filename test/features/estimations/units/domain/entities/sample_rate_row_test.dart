import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/sample_rate_row.dart';
import 'package:flutter_test/flutter_test.dart';

SampleRateRow _row({
  String id = 'row',
  String productName = 'ProClassic',
  double rate = 52,
  String? details = 'Interior · flat',
  Unit? unit = Unit.liters,
}) => SampleRateRow(
  id: id,
  productName: productName,
  rate: Money(amount: rate),
  details: details,
  unit: unit,
);

void main() {
  group('SampleRateRow equality', () {
    test('rows with the same fields are equal', () {
      expect(_row(), _row());
    });

    for (final (field, other) in [
      ('id', _row(id: 'other')),
      ('productName', _row(productName: 'Premium Plus')),
      ('rate', _row(rate: 38)),
      ('details', _row(details: null)),
      ('unit', _row(unit: null)),
    ]) {
      test('rows that differ in $field are not equal', () {
        expect(_row(), isNot(other));
      });
    }
  });

  test('noSampleRates finds nothing until the cost file is read', () {
    expect(noSampleRates('paint'), isEmpty);
  });
}
