import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:equatable/equatable.dart';

/// Writes a [Quantity] back as the tokens the tape shows after a
/// conversion: the inverse of [QuantityParser], with the decimals the UX
/// Design Doc allows a converted value (Section 6, "Display settings": up
/// to three for a length, four for board feet).
///
/// The tokens are how the value is *read*, never what it *is*: the caller
/// keeps the exact quantity beside them (rule 4.15), so 18ft 8in shown as
/// 6.222yd is still 14,336 ticks when the area is recomputed.
///
/// A ft-in compound is written as whole feet, then the leftover inches to
/// two decimals: 224in reads 18ft 8in and 1ft 1/16in re-spelled reads
/// 1ft 0.06in. Every number is rounded the way the prototype rounds,
/// `Math.round(v * 1000) / 1000`, and written without trailing zeros or a
/// trailing point, so 264 not 264.000 and 6.222 not 6.2220.
class QuantitySpeller extends Equatable {
  /// Decimals kept when a length, an area or a weight is re-spelled; an
  /// angle or a scalar, which no key converts, is spelled the same way
  /// only so that every dimension has a spelling.
  static const int lengthDecimals = 3;

  /// Decimals kept when a volume is re-spelled; board feet keep four
  /// (50.1751bf) and the cubed units follow so one rule covers them.
  static const int volumeDecimals = 4;

  /// Decimals kept for an area read in acres (0.3673acre).
  static const int acreDecimals = 4;

  /// Decimals kept for the inches of a ft-in compound.
  static const int compoundInchDecimals = 2;

  /// How many pounds make a ton, for spelling a weight in tons.
  final int poundsPerTon;

  const QuantitySpeller({
    this.poundsPerTon = QuantityParser.defaultPoundsPerTon,
  });

  /// The tokens that show [value] in the unit it wears.
  List<Token> spell(Quantity value) => switch (value) {
    Length(unit: Unit.footInch) => _wholeFeetAndDecimalInches(value.ticks),
    Length() => [
      Token(
        digits: _digitsWithoutTrailingZeros(
          value.ticks / value.unit.ticksPerUnit,
          lengthDecimals,
        ),
        unit: value.unit,
      ),
    ],
    Area(unit: Unit.acre) => [
      Token(
        digits: _digitsWithoutTrailingZeros(
          value.squareFeet / Area.squareFeetPerAcre,
          acreDecimals,
        ),
        unit: Unit.acre,
      ),
    ],
    Area() => [
      Token(
        digits: _digitsWithoutTrailingZeros(
          value.squareTicks / value.unit.ticksPerUnit / value.unit.ticksPerUnit,
          lengthDecimals,
        ),
        unit: value.unit,
        power: 2,
      ),
    ],
    Volume(unit: Unit.boardFoot) => [
      Token(
        digits: _digitsWithoutTrailingZeros(value.boardFeet, volumeDecimals),
        unit: Unit.boardFoot,
      ),
    ],
    Volume() => [
      Token(
        digits: _digitsWithoutTrailingZeros(
          value.cubicFeet * _cubicUnitsPerCubicFoot(value.unit),
          volumeDecimals,
        ),
        unit: value.unit,
        power: 3,
      ),
    ],
    Weight() => [
      Token(
        digits: _digitsWithoutTrailingZeros(
          value.hundredthsOfPound /
              value.unit.hundredthsOfPoundPer(poundsPerTon: poundsPerTon),
          lengthDecimals,
        ),
        unit: value.unit,
      ),
    ],
    Angle() => [
      Token(digits: _digitsWithoutTrailingZeros(value.degrees, lengthDecimals)),
    ],
    Scalar() => [
      Token(digits: _digitsWithoutTrailingZeros(value.value, lengthDecimals)),
    ],
  };

  List<Token> _wholeFeetAndDecimalInches(int ticks) {
    final feet = ticks ~/ Length.ticksPerFoot;
    final inches = (ticks - feet * Length.ticksPerFoot) / Length.ticksPerInch;
    return [
      Token(digits: '$feet', unit: Unit.foot),
      Token(
        digits: _digitsWithoutTrailingZeros(inches, compoundInchDecimals),
        unit: Unit.inch,
      ),
    ];
  }

  double _cubicUnitsPerCubicFoot(Unit unit) {
    final feetPerUnit = Length.ticksPerFoot / unit.ticksPerUnit;
    return feetPerUnit * feetPerUnit * feetPerUnit;
  }

  String _digitsWithoutTrailingZeros(double value, int decimals) {
    final scale = math.pow(10, decimals);
    final rounded = (value * scale).round() / scale;
    final text = rounded.toStringAsFixed(decimals);
    if (!text.contains('.')) return text;
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  List<Object?> get props => [poundsPerTon];
}
