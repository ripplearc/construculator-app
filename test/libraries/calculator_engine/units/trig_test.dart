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
}
