import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const arithmetic = ChainArithmetic();
  const squareTicksPerSquareFoot =
      Area.squareTicksPerSquareInch * Area.squareInchesPerSquareFoot;

  Length feet(int feet) => Length(feet * Length.ticksPerFoot, unit: Unit.foot);
  Length inches(int inches) =>
      Length(inches * Length.ticksPerInch, unit: Unit.inch);
  Area squareFeet(double squareFeet, {Unit unit = Unit.foot}) =>
      Area(squareFeet * squareTicksPerSquareFoot, unit: unit);

  Quantity value(ArithmeticOutcome outcome) {
    if (outcome case ArithmeticValue(:final value)) return value;
    throw StateError('expected a value, got $outcome');
  }

  group('ChainArithmetic', () {
    group('×', () {
      test('length × length is an area: 3ft × 4ft = 12ft²', () {
        expect(
          arithmetic.combine(feet(3), Operator.multiply, feet(4)),
          ArithmeticValue(squareFeet(12)),
        );
      });

      test('scalar × length is a length in the trade compound: 78 × 56ft', () {
        expect(
          arithmetic.combine(const Scalar(78), Operator.multiply, feet(56)),
          ArithmeticValue(
            Length(4368 * Length.ticksPerFoot, unit: Unit.footInch),
          ),
        );
        expect(
          arithmetic.combine(feet(56), Operator.multiply, const Scalar(78)),
          ArithmeticValue(
            Length(4368 * Length.ticksPerFoot, unit: Unit.footInch),
          ),
        );
      });

      test('a bare number scales an area in either order: 3 × 12ft²', () {
        expect(
          arithmetic.combine(
            const Scalar(3),
            Operator.multiply,
            squareFeet(12),
          ),
          ArithmeticValue(squareFeet(36)),
        );
        expect(
          arithmetic.combine(
            squareFeet(12),
            Operator.multiply,
            const Scalar(3),
          ),
          ArithmeticValue(squareFeet(36)),
        );
      });

      test('acres and board feet do not vote on the system of an answer', () {
        final volume = arithmetic.combine(
          const Volume(1, unit: Unit.boardFoot),
          Operator.divide,
          const Length(2520, unit: Unit.metre),
        );
        expect((value(volume) as Area).unit, Unit.metre);
        final area = arithmetic.combine(
          const Area(1, unit: Unit.acre),
          Operator.multiply,
          const Length(2520, unit: Unit.metre),
        );
        expect((value(area) as Volume).unit, Unit.metre);
      });

      test('area × length is a volume in cubic feet: 60ft² × 4in = 20ft³', () {
        final volume = value(
          arithmetic.combine(squareFeet(60), Operator.multiply, inches(4)),
        );
        expect(volume, isA<Volume>());
        expect((volume as Volume).cubicFeet, closeTo(20, 1e-9));
        expect(volume.unit, Unit.foot);
        expect(
          value(
            arithmetic.combine(inches(4), Operator.multiply, squareFeet(60)),
          ),
          volume,
        );
      });

      test('a volume keeps its unit: 8bf × 20 = 160bf', () {
        final volume = value(
          arithmetic.combine(
            const Volume(8 / 12, unit: Unit.boardFoot),
            Operator.multiply,
            const Scalar(20),
          ),
        );
        expect((volume as Volume).unit, Unit.boardFoot);
        expect(volume.boardFeet, closeTo(160, 1e-9));
      });

      test(
        'scalar × scalar, weight × scalar, angle × scalar keep their kind',
        () {
          expect(
            arithmetic.combine(
              const Scalar(78),
              Operator.multiply,
              const Scalar(56),
            ),
            const ArithmeticValue(Scalar(4368)),
          );
          expect(
            arithmetic.combine(
              const Scalar(2),
              Operator.multiply,
              const Weight(7800, unit: Unit.pound),
            ),
            const ArithmeticValue(Weight(15600, unit: Unit.pound)),
          );
          expect(
            arithmetic.combine(
              const Angle(45),
              Operator.multiply,
              const Scalar(2),
            ),
            const ArithmeticValue(Angle(90)),
          );
        },
      );

      test('an all-metric answer keeps the first metric unit: 2cm × 3cm', () {
        const centimetres = Length(50, unit: Unit.centimetre);
        const millimetres = Length(8, unit: Unit.millimetre);
        expect(
          arithmetic.combine(
            centimetres,
            Operator.multiply,
            const Length(76, unit: Unit.centimetre),
          ),
          const ArithmeticValue(Area(3800, unit: Unit.centimetre)),
        );
        expect(
          arithmetic.combine(millimetres, Operator.multiply, const Scalar(2)),
          const ArithmeticValue(Length(16, unit: Unit.millimetre)),
        );
        expect(
          arithmetic.combine(centimetres, Operator.multiply, millimetres),
          const ArithmeticValue(Area(400, unit: Unit.centimetre)),
        );
      });

      test('metric lengths answer in metres', () {
        const metre = Length(2520, unit: Unit.metre);
        expect(
          (value(arithmetic.combine(metre, Operator.multiply, metre)) as Area)
              .unit,
          Unit.metre,
        );
        expect(
          (value(arithmetic.combine(metre, Operator.multiply, const Scalar(2)))
                  as Length)
              .unit,
          Unit.metre,
        );
        expect(
          (value(arithmetic.combine(metre, Operator.multiply, feet(1))) as Area)
              .unit,
          Unit.foot,
        );
      });

      test('pounds × feet, area × area and volume × length are refused', () {
        const error = ArithmeticFailed(CalculationError.dimensionError);
        expect(
          arithmetic.combine(
            const Weight(7800, unit: Unit.pound),
            Operator.multiply,
            feet(12),
          ),
          error,
        );
        expect(
          arithmetic.combine(squareFeet(1), Operator.multiply, squareFeet(1)),
          error,
        );
        expect(
          arithmetic.combine(const Volume(1), Operator.multiply, feet(1)),
          error,
        );
      });
    });

    group('÷', () {
      test('same ÷ same is a scalar: 36ft ÷ 12ft = 3, 500bf ÷ 8bf = 62.5', () {
        expect(
          arithmetic.combine(feet(36), Operator.divide, feet(12)),
          const ArithmeticValue(Scalar(3)),
        );
        expect(
          arithmetic.combine(
            const Volume(500 / 12, unit: Unit.boardFoot),
            Operator.divide,
            const Volume(8 / 12, unit: Unit.boardFoot),
          ),
          const ArithmeticValue(Scalar(62.5)),
        );
      });

      test('area ÷ length is a length: 12ft² ÷ 3ft = 4ft', () {
        expect(
          arithmetic.combine(squareFeet(12), Operator.divide, feet(3)),
          ArithmeticValue(Length(4 * Length.ticksPerFoot, unit: Unit.footInch)),
        );
      });

      test('volume ÷ area is a length and volume ÷ length an area', () {
        expect(
          arithmetic.combine(const Volume(20), Operator.divide, squareFeet(60)),
          ArithmeticValue(Length(4 * Length.ticksPerInch, unit: Unit.footInch)),
        );
        final area = value(
          arithmetic.combine(const Volume(20), Operator.divide, inches(4)),
        );
        expect((area as Area).squareFeet, closeTo(60, 1e-9));
        expect(area.unit, Unit.foot);
      });

      test('a quantity ÷ scalar keeps its kind: 78lbs ÷ 12 = 6.5lbs', () {
        expect(
          arithmetic.combine(
            const Weight(7800, unit: Unit.pound),
            Operator.divide,
            const Scalar(12),
          ),
          const ArithmeticValue(Weight(650, unit: Unit.pound)),
        );
        expect(
          arithmetic.combine(
            const Volume(500 / 12, unit: Unit.boardFoot),
            Operator.divide,
            const Scalar(4),
          ),
          const ArithmeticValue(Volume(125 / 12, unit: Unit.boardFoot)),
        );
        expect(
          arithmetic.combine(inches(10), Operator.divide, const Scalar(3)),
          const ArithmeticValue(Length(213, unit: Unit.footInch)),
        );
      });

      test('scalar ÷ scalar keeps every digit: 1 ÷ 78', () {
        expect(
          arithmetic.combine(
            const Scalar(1),
            Operator.divide,
            const Scalar(78),
          ),
          const ArithmeticValue(Scalar(1 / 78)),
        );
      });

      test('÷ 0 is its own error for a pair the table can divide', () {
        const error = ArithmeticFailed(CalculationError.divisionByZero);
        expect(
          arithmetic.combine(const Scalar(5), Operator.divide, const Scalar(0)),
          error,
        );
        expect(
          arithmetic.combine(feet(12), Operator.divide, const Scalar(0)),
          error,
        );
        expect(arithmetic.combine(feet(12), Operator.divide, feet(0)), error);
        expect(
          arithmetic.combine(squareFeet(12), Operator.divide, feet(0)),
          error,
        );
      });

      test('the dimensions are checked before the zero: 12lbs ÷ 0ft', () {
        const error = ArithmeticFailed(CalculationError.dimensionError);
        expect(
          arithmetic.combine(
            const Weight(1200, unit: Unit.pound),
            Operator.divide,
            feet(0),
          ),
          error,
        );
        expect(
          arithmetic.combine(
            feet(12),
            Operator.divide,
            const Weight(0, unit: Unit.pound),
          ),
          error,
        );
        expect(
          arithmetic.combine(const Scalar(5), Operator.divide, feet(0)),
          error,
        );
      });

      test(
        'a length that overflows the tick range is refused, not clamped',
        () {
          const error = ArithmeticFailed(CalculationError.outOfRange);
          expect(
            arithmetic.combine(feet(1), Operator.multiply, const Scalar(1e20)),
            error,
          );
          expect(
            arithmetic.combine(feet(1), Operator.divide, const Scalar(1e-320)),
            error,
          );
          expect(
            arithmetic.combine(
              Length(ChainArithmetic.maxTicks, unit: Unit.foot),
              Operator.add,
              feet(1),
            ),
            error,
          );
          expect(
            arithmetic.combine(
              Length(ChainArithmetic.maxTicks, unit: Unit.foot),
              Operator.subtract,
              feet(1),
            ),
            isA<ArithmeticValue>(),
          );
        },
      );

      test('a number that overflows to infinity is refused too', () {
        expect(
          arithmetic.combine(
            const Scalar(1e308),
            Operator.multiply,
            const Scalar(10),
          ),
          const ArithmeticFailed(CalculationError.outOfRange),
        );
      });

      test('pounds ÷ feet is a dimension error', () {
        expect(
          arithmetic.combine(
            const Weight(7800, unit: Unit.pound),
            Operator.divide,
            feet(12),
          ),
          const ArithmeticFailed(CalculationError.dimensionError),
        );
      });
    });

    group('+ and −', () {
      test('same dimension adds: 2 + 3, 3ft + 2ft, 2ft − 5ft', () {
        expect(
          arithmetic.combine(const Scalar(2), Operator.add, const Scalar(3)),
          const ArithmeticValue(Scalar(5)),
        );
        expect(
          arithmetic.combine(feet(3), Operator.add, feet(2)),
          ArithmeticValue(Length(5 * Length.ticksPerFoot, unit: Unit.footInch)),
        );
        expect(
          arithmetic.combine(feet(2), Operator.subtract, feet(5)),
          ArithmeticValue(
            Length(-3 * Length.ticksPerFoot, unit: Unit.footInch),
          ),
        );
      });

      test('the first operand\'s unit wins in a sum: 500bf + 1yd³ = 824bf', () {
        final sum = value(
          arithmetic.combine(
            const Volume(500 / 12, unit: Unit.boardFoot),
            Operator.add,
            const Volume(27, unit: Unit.yard),
          ),
        );
        expect((sum as Volume).unit, Unit.boardFoot);
        expect(sum.boardFeet, closeTo(824, 1e-9));
      });

      test('areas, weights and angles add in their own units', () {
        expect(
          arithmetic.combine(
            squareFeet(1, unit: Unit.yard),
            Operator.add,
            squareFeet(2),
          ),
          ArithmeticValue(squareFeet(3, unit: Unit.yard)),
        );
        expect(
          arithmetic.combine(
            const Weight(100, unit: Unit.kilogram),
            Operator.subtract,
            const Weight(40, unit: Unit.pound),
          ),
          const ArithmeticValue(Weight(60, unit: Unit.kilogram)),
        );
        expect(
          arithmetic.combine(const Angle(30), Operator.add, const Angle(15)),
          const ArithmeticValue(Angle(45)),
        );
      });

      test('a bare number joined to an angle can only be degrees', () {
        expect(
          arithmetic.combine(const Angle(30), Operator.add, const Scalar(6)),
          const ArithmeticValue(Angle(36)),
        );
        expect(
          arithmetic.combine(
            const Scalar(6),
            Operator.subtract,
            const Angle(30),
          ),
          const ArithmeticValue(Angle(-24)),
        );
      });

      test('a number + feet and an area + a length are refused', () {
        const error = ArithmeticFailed(CalculationError.dimensionError);
        expect(
          arithmetic.combine(const Scalar(78), Operator.add, feet(12)),
          error,
        );
        expect(
          arithmetic.combine(squareFeet(12), Operator.add, feet(2)),
          error,
        );
        expect(
          arithmetic.combine(
            feet(12),
            Operator.subtract,
            const Weight(1, unit: Unit.pound),
          ),
          error,
        );
      });

      test('millimetres add in millimetres: 1mm + 1mm = 2mm', () {
        const millimetre = Length(3, unit: Unit.millimetre);
        expect(
          arithmetic.combine(millimetre, Operator.add, millimetre),
          const ArithmeticValue(Length(6, unit: Unit.millimetre)),
        );
      });

      test('metric lengths add in metres', () {
        const metre = Length(2520, unit: Unit.metre);
        expect(
          arithmetic.combine(metre, Operator.add, metre),
          const ArithmeticValue(Length(5040, unit: Unit.metre)),
        );
      });
    });

    test('a length answer rounds half toward +∞, as the prototype does', () {
      expect(
        arithmetic.combine(
          const Length(1, unit: Unit.inch),
          Operator.multiply,
          const Scalar(0.5),
        ),
        const ArithmeticValue(Length(1, unit: Unit.footInch)),
      );
      expect(
        arithmetic.combine(
          const Length(-1, unit: Unit.inch),
          Operator.multiply,
          const Scalar(0.5),
        ),
        const ArithmeticValue(Length(0, unit: Unit.footInch)),
      );
    });

    test('is equal to any other table, having no state', () {
      expect(ChainArithmetic(), arithmetic);
    });

    test('outcomes compare by what they carry', () {
      final degrees = double.parse('90');
      expect(ArithmeticValue(Angle(degrees)), const ArithmeticValue(Angle(90)));
      final error = CalculationError.values[int.parse('1')];
      expect(
        ArithmeticFailed(error),
        const ArithmeticFailed(CalculationError.divisionByZero),
      );
    });
  });
}
