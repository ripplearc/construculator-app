import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/models/quantity.dart';

/// The forward keys of the Trigonometry group (UX Design Doc Section 3.5):
/// SIN, COS and TAN take an angle in degrees and answer a ratio. The inverse
/// keys are F1b (CA-1302).
///
/// [key] is both the chip key of a trig chip and the label of its answer,
/// and the two are told apart by an equals sign (scenario S104): "Tangent
/// 89°" asks the tangent of 89°, "Tangent = 57.289962" says what it is. The
/// port of the prototype's `trigValue` for the forward functions.
enum TrigFunction {
  /// SIN.
  sine('Sine'),

  /// COS.
  cosine('Cosine'),

  /// TAN.
  tangent('Tangent');

  /// Decimals a trig ratio keeps at display (walkthrough 16.1: Sine
  /// 0.615661); a Calc built from it rounds like any result.
  static const int ratioDecimals = 6;

  static const int _halfTurn = 180;
  static const int _quarterTurn = 90;
  static const double _quarterTurnTolerance = 1e-9;

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

  /// The ratio of [degrees], kept to [ratioDecimals] at display; `null`
  /// where the function has no value: the tangent of 90° and of every odd
  /// quarter turn, where the run is zero (Section 5.4, "The tangent of 90°
  /// is undefined"), which floating point would otherwise answer with
  /// 16,331,239,353,195,370; and a number too long to be an angle, which
  /// reads as infinity (309 digits and more) and would answer a ratio that
  /// is not a number.
  Scalar? of(double degrees) {
    if (!degrees.isFinite) return null;
    final radians = degrees * math.pi / _halfTurn;
    return switch (this) {
      sine => Scalar(math.sin(radians), decimals: ratioDecimals),
      cosine => Scalar(math.cos(radians), decimals: ratioDecimals),
      tangent =>
        _isOddQuarterTurn(degrees)
            ? null
            : Scalar(math.tan(radians), decimals: ratioDecimals),
    };
  }

  static bool _isOddQuarterTurn(double degrees) =>
      ((degrees % _halfTurn) - _quarterTurn).abs() < _quarterTurnTolerance;
}
