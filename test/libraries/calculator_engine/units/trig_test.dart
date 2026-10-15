import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();

  String ratio(TrigFunction function, double degrees) {
    final answer = function.of(degrees);
    if (answer == null) throw StateError('$function has no value at $degrees');
    return formatter.format(answer);
  }

  group('TrigFunction', () {
    test('S57: 38° reads Sine 0.615661, Cosine 0.788011, Tangent 0.781286', () {
      expect(ratio(TrigFunction.sine, 38), '0.615661');
      expect(ratio(TrigFunction.cosine, 38), '0.788011');
      expect(ratio(TrigFunction.tangent, 38), '0.781286');
    });

    test('S104 and S105: Tangent 89° and Cosine 98° keep six decimals', () {
      expect(ratio(TrigFunction.tangent, 89), '57.289962');
      expect(ratio(TrigFunction.cosine, 98), '-0.139173');
      expect(ratio(TrigFunction.sine, 30), '0.5');
      expect(ratio(TrigFunction.sine, 0), '0');
    });

    test('S94: the tangent of every odd quarter turn has no value', () {
      for (final degrees in [90.0, 270.0, -90.0, 450.0]) {
        expect(TrigFunction.tangent.of(degrees), isNull, reason: '$degrees');
      }
      expect(ratio(TrigFunction.tangent, 180), '0');
      expect(ratio(TrigFunction.tangent, 89.999), isNot('0'));
      expect(TrigFunction.sine.of(90), const Scalar(1, decimals: 6));
      expect(TrigFunction.cosine.of(90), isNotNull);
    });

    test('a number that reads as infinity has no ratio', () {
      for (final function in TrigFunction.values) {
        for (final degrees in [double.infinity, double.negativeInfinity]) {
          expect(function.of(degrees), isNull, reason: '$function $degrees');
        }
        expect(function.of(double.nan), isNull, reason: '$function NaN');
      }
    });

    test('names the function its chip key stands for', () {
      expect(TrigFunction.named('Sine'), TrigFunction.sine);
      expect(TrigFunction.named('Cosine'), TrigFunction.cosine);
      expect(TrigFunction.named('Tangent'), TrigFunction.tangent);
      expect(TrigFunction.named('Width'), isNull);
      expect(TrigFunction.named(null), isNull);
    });

    test('a ratio carries its six decimals, a Calc built from it does not', () {
      expect(
        TrigFunction.sine.of(89),
        isA<Scalar>().having(
          (ratio) => ratio.decimals,
          'decimals',
          TrigFunction.ratioDecimals,
        ),
      );
      expect(const Scalar(1), isNot(const Scalar(1, decimals: 6)));
      expect(formatter.format(const Scalar(55.991486)), '55.99');
    });
  });

  group('TrigFunction inverse keys (F1b)', () {
    String rebuiltText(ResultChip answer, Quantity operand) {
      final rebuilt = TrigFunction.rebuilt(answer, operand);
      if (rebuilt == null) throw StateError('$answer was not rebuilt');
      return formatter.format(rebuilt.value);
    }

    String angle(TrigFunction function, double ratio) {
      final answer = function.of(ratio);
      if (answer == null) throw StateError('$function has no value at $ratio');
      return formatter.format(answer);
    }

    test('S58: 12 ÷ 23 is 27.55°, 31.45° and 58.55°', () {
      expect(angle(TrigFunction.arctangent, 12 / 23), '27.55°');
      expect(angle(TrigFunction.arcsine, 12 / 23), '31.45°');
      expect(angle(TrigFunction.arccosine, 12 / 23), '58.55°');
    });

    test('S70 and S110: ASIN and ACOS stop at ±1, ATAN takes any ratio', () {
      expect(angle(TrigFunction.arcsine, 1), '90°');
      expect(angle(TrigFunction.arcsine, -1), '-90°');
      expect(angle(TrigFunction.arccosine, -1), '180°');
      expect(angle(TrigFunction.arccosine, 1), '0°');
      for (final ratio in [2.0, -1.5, 1.0000001]) {
        expect(TrigFunction.arcsine.of(ratio), isNull, reason: '$ratio');
        expect(TrigFunction.arccosine.of(ratio), isNull, reason: '$ratio');
      }
      expect(angle(TrigFunction.arctangent, 16 / 12), '53.13°');
      expect(angle(TrigFunction.arctangent, -1), '-45°');
      expect(
        TrigFunction.arcsine.of(0.5),
        isA<Angle>().having((a) => a.degrees, 'degrees', closeTo(30, 1e-9)),
      );
    });

    test('names and sorts the six functions', () {
      expect(TrigFunction.named('Arcsine'), TrigFunction.arcsine);
      expect(TrigFunction.named('Arccosine'), TrigFunction.arccosine);
      expect(TrigFunction.named('Arctangent'), TrigFunction.arctangent);
      expect(TrigFunction.named('Arctangent(16 ÷ 12)'), isNull);
      expect(
        [for (final function in TrigFunction.values) function.isInverse],
        [false, false, false, true, true, true],
      );
    });

    test('answers a finished value of the kind it takes', () {
      expect(
        TrigFunction.sine.answerTo(const Angle(30)),
        TrigFunction.sine.of(30),
      );
      expect(
        TrigFunction.sine.answerTo(const Scalar(30)),
        TrigFunction.sine.of(30),
      );
      expect(
        TrigFunction.arcsine.answerTo(const Scalar(0.5)),
        TrigFunction.arcsine.of(0.5),
      );
      expect(TrigFunction.arcsine.answerTo(const Angle(0.5)), isNull);
      expect(
        TrigFunction.sine.answerTo(const Length(64, unit: Unit.inch)),
        isNull,
      );
      expect(
        TrigFunction.arcsine.answerTo(const Length(64, unit: Unit.inch)),
        isNull,
      );
    });

    test('S102: an answer is rebuilt on the value an edit left before it', () {
      const answer = ResultChip(key: 'Arctangent', value: Angle(41.23));
      expect(
        TrigFunction.rebuilt(answer, const Scalar(70 / 89)),
        isA<ResultChip>().having((chip) => chip.key, 'key', 'Arctangent'),
      );
      expect(rebuiltText(answer, const Scalar(70 / 89)), '38.19°');
      const read = ResultChip(
        key: 'Arccosine',
        value: Angle(43.65, spelling: AngleSpelling.degreesMinutesSeconds),
        operator: Operator.add,
      );
      expect(rebuiltText(read, const Scalar(89 / 123)), "43°38'58\"");
      expect(rebuiltText(read, const Scalar(80 / 123)), "49°25'40\"");
      expect(
        TrigFunction.rebuilt(read, const Scalar(80 / 123)),
        isA<ResultChip>().having(
          (chip) => chip.operator,
          'operator',
          Operator.add,
        ),
      );
      const sine = ResultChip(key: 'Sine', value: Scalar(0.5, decimals: 6));
      expect(
        TrigFunction.rebuilt(sine, const Angle(90)),
        const ResultChip(key: 'Sine', value: Scalar(1, decimals: 6)),
      );
    });

    test('an answer that can no longer be computed is not rebuilt', () {
      const answer = ResultChip(key: 'Arccosine', value: Angle(51.32));
      expect(TrigFunction.rebuilt(answer, const Scalar(9 / 8)), isNull);
      const calc = ResultChip(key: 'Calc', value: Scalar(2));
      expect(TrigFunction.rebuilt(calc, const Scalar(0.5)), isNull);
    });
  });
}
