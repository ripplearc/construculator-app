import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quantity', () {
    group('Length', () {
      test('stores 22ft as 16,896 ticks and reports its dimension', () {
        const length = Length(22 * Length.ticksPerFoot, unit: Unit.foot);
        expect(length.ticks, 16896);
        expect(length.dimension, Dimension.length);
      });

      test('keeps the same ticks when re-spelled in another unit', () {
        const width = Length(
          18 * Length.ticksPerFoot + 8 * Length.ticksPerInch,
          unit: Unit.footInch,
        );
        final inYards = width.spelledIn(Unit.yard);
        expect(inYards.ticks, width.ticks);
        expect(inYards.unit, Unit.yard);
        expect(inYards, isNot(equals(width)));
      });

      test('is equal to another length with the same ticks and unit', () {
        expect(
          const Length(64, unit: Unit.inch),
          const Length(Length.ticksPerInch, unit: Unit.inch),
        );
      });

      test('refuses a unit that is not a length', () {
        expect(
          () => Length(64, unit: Unit.pound),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Area', () {
      test('reads 22ft × 18ft 8in as 410.67ft²', () {
        const length = Length(22 * Length.ticksPerFoot, unit: Unit.foot);
        const width = Length(
          18 * Length.ticksPerFoot + 8 * Length.ticksPerInch,
          unit: Unit.footInch,
        );
        final area = Area(length.ticks * width.ticks.toDouble());
        expect(area.squareFeet, closeTo(410.67, 0.005));
        expect(area.dimension, Dimension.area);
        expect(area.unit, Unit.foot);
      });

      test('keeps its square ticks when re-spelled in acres', () {
        const area = Area(1);
        expect(area.spelledIn(Unit.acre), const Area(1, unit: Unit.acre));
      });

      test('refuses a unit that is neither a length nor acres', () {
        expect(
          () => Area(1, unit: Unit.boardFoot),
          throwsA(isA<AssertionError>()),
        );
      });

      test('refuses the ft-in compound, which cannot be squared', () {
        expect(
          () => Area(1, unit: Unit.footInch),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Volume', () {
      test('counts twelve board feet to the cubic foot', () {
        const volume = Volume(1);
        expect(volume.boardFeet, 12);
        expect(volume.dimension, Dimension.volume);
        expect(volume.unit, Unit.foot);
      });

      test('keeps its cubic feet when re-spelled in board feet', () {
        const volume = Volume(2106);
        expect(
          volume.spelledIn(Unit.boardFoot),
          const Volume(2106, unit: Unit.boardFoot),
        );
      });

      test('refuses a unit that is neither a length nor board feet', () {
        expect(
          () => Volume(1, unit: Unit.acre),
          throwsA(isA<AssertionError>()),
        );
      });

      test('refuses the ft-in compound, which cannot be cubed', () {
        expect(
          () => Volume(1, unit: Unit.footInch),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Weight', () {
      test('stores 78lbs as 7,800 hundredths of a pound', () {
        const weight = Weight(7800, unit: Unit.pound);
        expect(weight.hundredthsOfPound, 7800);
        expect(weight.dimension, Dimension.weight);
      });

      test('keeps its hundredths of a pound when re-spelled', () {
        const weight = Weight(7800, unit: Unit.pound);
        expect(
          weight.spelledIn(Unit.kilogram),
          const Weight(7800, unit: Unit.kilogram),
        );
      });

      test('refuses a unit that is not a weight', () {
        expect(
          () => Weight(1, unit: Unit.foot),
          throwsA(isA<AssertionError>()),
        );
      });

      test('is written in pounds unless told otherwise', () {
        expect(const Weight(7800).unit, Unit.pound);
      });
    });

    group('Length, kept exactly', () {
      test('a whole number of ticks and the same exact inches are equal', () {
        const fromTicks = Length(2520, unit: Unit.metre);
        const exact = Length.exact(Rational(315, 8), unit: Unit.metre);
        expect(fromTicks, exact);
        expect(fromTicks.inches, const Rational(315, 8));
        expect(exact.ticks, 2520);
      });

      test(
        'a typed decimal foot keeps its value and views the nearest tick',
        () {
          const typed = Length.exact(Rational(5196, 25), unit: Unit.foot);
          expect(typed.inches, const Rational(433, 25) * const Rational(12));
          expect(typed.ticks, 13302);
          expect(typed, isNot(const Length(13302, unit: Unit.foot)));
        },
      );

      test('re-spelling keeps the exact inches', () {
        const typed = Length.exact(Rational(5000, 127), unit: Unit.metre);
        expect(typed.spelledIn(Unit.inch).inches, const Rational(5000, 127));
        expect(typed.spelledIn(Unit.inch).unit, Unit.inch);
      });

      test('a half tick rounds up to the view', () {
        expect(const Length.exact(Rational(1, 128), unit: Unit.inch).ticks, 1);
        expect(const Length.exact(Rational(-1, 128), unit: Unit.inch).ticks, 0);
      });
    });

    group('Angle', () {
      test('holds decimal degrees and equals another of the same size', () {
        final degrees = double.parse('26.57');
        final angle = Angle(degrees);
        expect(angle.degrees, 26.57);
        expect(angle.dimension, Dimension.angle);
        expect(angle, const Angle(26.57));
      });
    });

    group('Scalar', () {
      test('holds a bare number and equals another of the same size', () {
        final value = double.parse('78');
        final scalar = Scalar(value);
        expect(scalar.value, 78);
        expect(scalar.dimension, Dimension.scalar);
        expect(scalar, const Scalar(78));
      });
    });

    test('a switch over the sealed class can name every dimension', () {
      const values = <Quantity>[
        Length(1, unit: Unit.inch),
        Area(1),
        Volume(1),
        Weight(1, unit: Unit.pound),
        Angle(1),
        Scalar(1),
      ];
      final dimensions = values.map(
        (quantity) => switch (quantity) {
          Length() => Dimension.length,
          Area() => Dimension.area,
          Volume() => Dimension.volume,
          Weight() => Dimension.weight,
          Angle() => Dimension.angle,
          Scalar() => Dimension.scalar,
        },
      );
      expect(dimensions, Dimension.values);
    });
  });
}
