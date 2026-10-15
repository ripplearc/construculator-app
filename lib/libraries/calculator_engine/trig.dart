import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';

/// The six functions of the Trigonometry group (UX Design Doc Section 3.5):
/// SIN, COS and TAN take an angle in degrees and answer a ratio; ASIN, ACOS
/// and ATAN take a ratio and answer an angle.
///
/// [key] is both the chip key of a trig chip and the label of its answer,
/// and the two are told apart by an equals sign (scenario S104): "Tangent
/// 89°" asks the tangent of 89°, "Tangent = 57.289962" says what it is. The
/// port of the prototype's `trigValue`.
enum TrigFunction {
  /// SIN.
  sine('Sine'),

  /// COS.
  cosine('Cosine'),

  /// TAN.
  tangent('Tangent'),

  /// ASIN.
  arcsine('Arcsine'),

  /// ACOS.
  arccosine('Arccosine'),

  /// ATAN.
  arctangent('Arctangent');

  /// Decimals a trig ratio keeps at display (walkthrough 16.1: Sine
  /// 0.615661); a Calc built from it rounds like any result.
  static const int ratioDecimals = 6;

  static const int _halfTurn = 180;
  static const int _quarterTurn = 90;
  static const double _quarterTurnTolerance = 1e-9;

  // 0.1 + 0.2 ÷ 0.3 is 1.0000000000000002 in floating point and reads 1;
  // refusing it would say "1 isn't one" (Section 5.4 wants a true reason).
  static const double _ratioTolerance = 1e-9;

  /// The chip key a trig chip is named by, and the label of its answer.
  final String key;

  const TrigFunction(this.key);

  /// The function a chip key names, or `null` for any other key.
  static TrigFunction? named(String? key) {
    for (final function in values) {
      if (function.key == key) return function;
    }
    return null;
  }

  /// Whether the function takes a ratio and answers an angle.
  bool get isInverse => switch (this) {
    sine || cosine || tangent => false,
    arcsine || arccosine || arctangent => true,
  };

  /// The answer of the function at [operand], degrees for SIN, COS and TAN
  /// and a ratio for the inverse keys: a ratio kept to [ratioDecimals] at
  /// display, or an angle. `null` where the function has no value: the
  /// tangent of 90° and of every odd quarter turn, where the run is zero
  /// (Section 5.4, "The tangent of 90° is undefined"), which floating point
  /// would otherwise answer with 16,331,239,353,195,370; and the arcsine or
  /// arccosine of a ratio beyond ±1, one side over a hypotenuse no side is
  /// longer than (Section 5.4, "Ratio out of range"); a ratio within 1e-9
  /// of ±1 is ±1. ATAN takes any ratio.
  Quantity? of(double operand) {
    final radians = operand * math.pi / _halfTurn;
    return switch (this) {
      sine => Scalar(math.sin(radians), decimals: ratioDecimals),
      cosine => Scalar(math.cos(radians), decimals: ratioDecimals),
      tangent =>
        _isOddQuarterTurn(operand)
            ? null
            : Scalar(math.tan(radians), decimals: ratioDecimals),
      arcsine => switch (_ratio(operand)) {
        final ratio? => _angle(math.asin(ratio)),
        null => null,
      },
      arccosine => switch (_ratio(operand)) {
        final ratio? => _angle(math.acos(ratio)),
        null => null,
      },
      arctangent => _angle(math.atan(operand)),
    };
  }

  /// The answer of the function to a finished [operand]: an angle or a
  /// bare number for SIN, COS and TAN, a bare number for the inverse keys;
  /// `null` for any other kind of value or where [of] has none.
  Quantity? answerTo(Quantity operand) => switch ((isInverse, operand)) {
    (false, Angle(:final degrees)) => of(degrees),
    (_, Scalar(:final value)) => of(value),
    _ => null,
  };

  /// The trig answer [answer] rebuilt on [operand], the value an edit
  /// behind it left standing before it, so that the answer survives the
  /// edit (scenario S102: 78 ÷ 89 [ATAN] is 41.23°, and making the 78 a 70
  /// rebuilds it to 38.19°); an angle keeps the spelling it was read in, so
  /// 43°38'58" rebuilds to 49°25'40", not 49.43°. `null` when [answer] is
  /// not a trig answer or [operand] has no answer, and the chip is removed
  /// (Section 5.5, "A result that can no longer be computed").
  /// The tape's `rebuiltTrigAnswer` finds [operand]: a trig operand
  /// chip is worth its answer, so its operand is its
  /// [ValueChip.trigOperand], not its value.
  static ResultChip? rebuilt(ResultChip answer, Quantity operand) {
    final value = named(answer.key)?.answerTo(operand);
    if (value == null) return null;
    final kept = switch ((value, answer.value)) {
      (final Angle angle, Angle(:final spelling)) => angle.spelledAs(spelling),
      _ => value,
    };
    return ResultChip(key: answer.key, value: kept, operator: answer.operator);
  }

  static bool _isOddQuarterTurn(double degrees) =>
      ((degrees % _halfTurn) - _quarterTurn).abs() < _quarterTurnTolerance;

  static double? _ratio(double operand) {
    if (operand.abs() <= 1) return operand;
    if (operand.abs() - 1 < _ratioTolerance) return operand.sign;
    return null;
  }

  static Angle _angle(double radians) => Angle(radians * _halfTurn / math.pi);
}
