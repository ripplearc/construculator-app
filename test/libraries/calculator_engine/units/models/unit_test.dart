import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit', () {
    group('ticksPerUnit', () {
      test('counts 64 ticks to the inch and 768 to the foot', () {
        expect(Unit.inch.ticksPerUnit, 64);
        expect(Unit.foot.ticksPerUnit, 768);
        expect(Unit.footInch.ticksPerUnit, 768);
        expect(Unit.yard.ticksPerUnit, 2304);
      });

      test('a metre is 2,519.685 ticks, the exact count to the double', () {
        expect(Unit.metre.ticksPerUnit, closeTo(2519.685, 0.0001));
        expect(Unit.centimetre.ticksPerUnit, closeTo(25.19685, 0.000001));
        expect(Unit.millimetre.ticksPerUnit, closeTo(2.519685, 0.0000001));
      });
    });

    group('inchesPer', () {
      test('is exact: an inch is 25.4 mm, so a metre is 5000/127 in', () {
        expect(Unit.inch.inchesPer, const Rational(1));
        expect(Unit.foot.inchesPer, const Rational(12));
        expect(Unit.footInch.inchesPer, const Rational(12));
        expect(Unit.yard.inchesPer, const Rational(36));
        expect(Unit.metre.inchesPer, const Rational(5000, 127));
        expect(Unit.centimetre.inchesPer, const Rational(50, 127));
        expect(Unit.millimetre.inchesPer, const Rational(5, 127));
      });

      test('is a programming error on a unit that is not a length', () {
        for (final unit in [Unit.acre, Unit.pound, Unit.boardFoot]) {
          expect(() => unit.inchesPer, throwsStateError, reason: unit.name);
        }
      });

      test('is a programming error on a unit that is not a length', () {
        for (final unit in [...Unit.weightUnits, Unit.acre, Unit.boardFoot]) {
          expect(() => unit.ticksPerUnit, throwsStateError);
        }
      });
    });

    group('hundredthsOfPoundPer', () {
      test('keeps pounds canonical and reads a ton from the setting', () {
        expect(Unit.pound.hundredthsOfPoundPer(poundsPerTon: 2000), 100);
        expect(Unit.ton.hundredthsOfPoundPer(poundsPerTon: 2000), 200000);
        expect(Unit.ton.hundredthsOfPoundPer(poundsPerTon: 2240), 224000);
      });

      test('reads a kilogram and a metric ton from the SI factor', () {
        expect(
          Unit.kilogram.hundredthsOfPoundPer(poundsPerTon: 2000),
          220.462262,
        );
        expect(
          Unit.metricTon.hundredthsOfPoundPer(poundsPerTon: 2000),
          220462.262,
        );
      });

      test('is a programming error on a unit that is not a weight', () {
        for (final unit in [...Unit.lengthUnits, Unit.acre, Unit.boardFoot]) {
          expect(
            () => unit.hundredthsOfPoundPer(poundsPerTon: 2000),
            throwsStateError,
          );
        }
      });
    });

    group('isMetric', () {
      test('is true for the metric lengths and weights only', () {
        const metric = {
          Unit.metre,
          Unit.centimetre,
          Unit.millimetre,
          Unit.kilogram,
          Unit.metricTon,
        };
        for (final unit in Unit.values) {
          expect(unit.isMetric, metric.contains(unit), reason: unit.name);
        }
      });
    });

    group('compoundRank', () {
      test('orders each system from its largest unit down', () {
        expect(Unit.yard.compoundRank, greaterThan(Unit.foot.compoundRank));
        expect(Unit.foot.compoundRank, greaterThan(Unit.inch.compoundRank));
        expect(Unit.footInch.compoundRank, Unit.foot.compoundRank);
        expect(
          Unit.metre.compoundRank,
          greaterThan(Unit.centimetre.compoundRank),
        );
        expect(
          Unit.centimetre.compoundRank,
          greaterThan(Unit.millimetre.compoundRank),
        );
      });

      test('is zero for every unit that cannot compound', () {
        for (final unit in [...Unit.weightUnits, Unit.acre, Unit.boardFoot]) {
          expect(unit.compoundRank, 0, reason: unit.name);
        }
      });
    });

    group('dimension and suffix', () {
      test('names what a bare number becomes when the unit closes it', () {
        expect(Unit.inch.dimension, Dimension.length);
        expect(Unit.acre.dimension, Dimension.area);
        expect(Unit.pound.dimension, Dimension.weight);
        expect(Unit.boardFoot.dimension, Dimension.volume);
      });

      test('spells the suffix as the tape writes it', () {
        expect(Unit.foot.suffix, 'ft');
        expect(Unit.pound.suffix, 'lbs');
        expect(Unit.metricTon.suffix, ' m tons');
        expect(Unit.boardFoot.suffix, 'bf');
      });
    });

    test('lists the length keys in column order and the weight keys', () {
      expect(Unit.lengthUnits, [
        Unit.yard,
        Unit.foot,
        Unit.inch,
        Unit.metre,
        Unit.centimetre,
        Unit.millimetre,
      ]);
      expect(Unit.weightUnits, [
        Unit.pound,
        Unit.kilogram,
        Unit.ton,
        Unit.metricTon,
      ]);
    });
  });
}
