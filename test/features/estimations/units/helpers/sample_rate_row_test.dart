import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/sample_rate_row.dart';
import 'package:flutter_test/flutter_test.dart';

SampleRateRow _row({
  double rate = 52,
  double? coverage = 400,
  Unit? coverageUnit = Unit.squareMeters,
}) => SampleRateRow(
  id: 'row',
  productName: 'ProClassic',
  rate: Money(amount: rate),
  coverage: coverage,
  coverageUnit: coverageUnit,
);

void main() {
  group('SampleRateRow.pricePerCoverageUnit', () {
    test('is the price divided by the coverage', () {
      expect(_row(rate: 52, coverage: 400).pricePerCoverageUnit, 0.13);
    });

    test('is null without a coverage', () {
      expect(_row(coverage: null).pricePerCoverageUnit, isNull);
    });

    test('is null for a coverage of zero, never a division by zero', () {
      expect(_row(coverage: 0).pricePerCoverageUnit, isNull);
    });
  });

  group('SampleRateRow.sharedCoverageUnit', () {
    test('is the unit every row shares when all state a coverage', () {
      expect(
        SampleRateRow.sharedCoverageUnit([_row(), _row(coverage: 250)]),
        Unit.squareMeters,
      );
    });

    test('is null when any row lacks a coverage', () {
      expect(
        SampleRateRow.sharedCoverageUnit([_row(), _row(coverage: null)]),
        isNull,
      );
    });

    test('is null when any row lacks a takeoff unit', () {
      expect(
        SampleRateRow.sharedCoverageUnit([_row(), _row(coverageUnit: null)]),
        isNull,
      );
    });

    test('is null when the rows mix takeoff units', () {
      expect(
        SampleRateRow.sharedCoverageUnit([
          _row(),
          _row(coverageUnit: Unit.meters),
        ]),
        isNull,
      );
    });

    test('is null without rows', () {
      expect(SampleRateRow.sharedCoverageUnit(const []), isNull);
    });
  });

  group('SampleRateRow.materialNameAfter', () {
    test('appends the product to the typed name', () {
      expect(
        _row().materialNameAfter('Interior paint '),
        'Interior paint · ProClassic',
      );
    });

    test('is the product alone while nothing is typed', () {
      expect(_row().materialNameAfter('  '), 'ProClassic');
    });
  });

  group('SampleRateRow equality', () {
    test('rows with the same fields are equal', () {
      expect(_row(), _row());
    });

    for (final (field, other) in [
      ('rate', _row(rate: 60)),
      ('coverage', _row(coverage: 250)),
      ('takeoff unit', _row(coverageUnit: Unit.meters)),
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
