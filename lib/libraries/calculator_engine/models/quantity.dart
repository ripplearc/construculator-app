import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/rational.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// A finished value on the tape: a magnitude in its dimension's canonical
/// unit, plus the unit it is spelled in on screen.
///
/// Values are stored once, in canonical units, and only the display changes
/// (UX Design Doc rule 4.14): re-spelling 18ft 8in as 6.222yd keeps the same
/// [Length.ticks], so the area it belongs to stays 410.67ft² (rule 4.15).
/// The subclasses are sealed so that arithmetic and formatting can switch
/// over every dimension exhaustively.
sealed class Quantity extends Equatable {
  const Quantity();

  /// The dimension this value measures.
  Dimension get dimension;
}

/// A distance, kept exactly as it was typed (UX Design Doc Section 6,
/// "Precision and storage"): a decimal foot, a feet-inch-fraction compound
/// and a metric length are all one exact [Rational] of inches, because an
/// inch is exactly 25.4 mm. Nothing is rounded until it is displayed, so
/// 17.32 ft × 1 still reads 17.32ft and 2 cm × 3 cm is exactly 6cm². A
/// length a rule computed ([Length.computed]) is kept the same way, to the
/// nearest 1/512 of a tick, until it is displayed.
///
/// [ticks], the whole number of 1/64 in nearest the length, is the view
/// the fraction formatter, the tick limit and the prototype's rounding
/// points read; a feet-inch-fraction value is a whole number of ticks, so
/// for it the view is the value.
final class Length extends Quantity {
  /// Ticks of 1/64 inch in one inch.
  static const int ticksPerInch = 64;

  /// The largest tick count a length may reach: 2⁵³, the last whole number
  /// a double still holds exactly. The arithmetic refuses an answer past it
  /// and a rule answers nothing for one, so a computed length past it is an
  /// assertion, never a value.
  static const int maxTicks = 1 << 53;

  /// Ticks of 1/64 inch in one foot.
  static const int ticksPerFoot = 768;

  /// Parts of a tick a computed length ([Length.computed]) is kept to:
  /// 1/512, far below any rounding a display applies and the resolution a
  /// quotient of lengths is kept to.
  static const int partsPerTick = 1 << 9;

  final int _wholeTicks;
  final Rational? _exactInches;

  /// The length unit the value is written in. [Unit.footInch] is the trade
  /// compound; every other length unit renders as a decimal or a fraction.
  final Unit unit;

  /// A length of a whole number of ticks of 1/64 inch, which is every
  /// feet-inch-fraction value and the prototype's rounding points.
  const Length(int ticks, {required this.unit})
    : _wholeTicks = ticks,
      _exactInches = null,
      assert(
        unit == Unit.inch ||
            unit == Unit.foot ||
            unit == Unit.footInch ||
            unit == Unit.yard ||
            unit == Unit.metre ||
            unit == Unit.centimetre ||
            unit == Unit.millimetre,
        'a length needs a length unit',
      );

  /// A length of exactly [inches], as the parser keeps a typed value.
  const Length.exact(Rational inches, {required this.unit})
    : _wholeTicks = 0,
      _exactInches = inches,
      assert(
        unit == Unit.inch ||
            unit == Unit.foot ||
            unit == Unit.footInch ||
            unit == Unit.yard ||
            unit == Unit.metre ||
            unit == Unit.centimetre ||
            unit == Unit.millimetre,
        'a length needs a length unit',
      );

  /// A length a rule computed — a diagonal, a rise, a run — kept to the
  /// nearest [partsPerTick]th of a tick so that it is rounded once, at
  /// display (UX Design Doc Section 6, "Nothing is rounded until it is
  /// displayed"; Section 8, the formulas are computed exactly): 13ft by
  /// 13ft reads 18.38ft, where a whole tick would read 18.39ft. [ticks]
  /// must be finite and within [maxTicks]: a rule that computes a length
  /// answers nothing for a value past either, and the assert is the
  /// backstop. The reduced fraction always fits a [Rational]: a double
  /// carries 53 significant bits, so once the power of two is divided out
  /// the numerator is at most 2⁵³.
  factory Length.computed(double ticks, {required Unit unit}) {
    assert(
      ticks.isFinite && ticks.abs() <= maxTicks,
      'a computed length is finite and within range',
    );
    return Length.exact(
      Rational(
        (ticks * partsPerTick).round(),
        ticksPerInch * partsPerTick,
      ).reduced,
      unit: unit,
    );
  }

  @override
  Dimension get dimension => Dimension.length;

  /// The exact length in inches: as typed, or a computed length's value to
  /// the nearest [partsPerTick]th of a tick.
  Rational get inches => _exactInches ?? Rational(_wholeTicks, ticksPerInch);

  /// The whole number of ticks of 1/64 inch nearest the length, a half
  /// tick rounded up as the prototype's `Math.round` does.
  ///
  /// The view never throws: a length the parser keeps carries at most 2⁵³
  /// in its numerator, so 64 times it still fits an `int`, and a length
  /// past the tick limit reaches the arithmetic, which refuses it as out
  /// of range. Scaling through `Rational *` would throw
  /// [RationalOverflow] for every length between 2⁴⁷ and 2⁵³ inches.
  int get ticks {
    final exact = _exactInches;
    if (exact == null) return _wholeTicks;
    return Rational(exact.numerator * ticksPerInch, exact.denominator).round();
  }

  /// The length in ticks of 1/64 inch with its fraction of a tick, which
  /// the rules compute with: the exact inches times 64, as a double.
  double get preciseTicks {
    if (_exactInches case final exact?) {
      return exact.numerator * ticksPerInch / exact.denominator;
    }
    return _wholeTicks.toDouble();
  }

  /// The same distance written in another length unit.
  Length spelledIn(Unit unit) {
    if (_exactInches case final exact?) return Length.exact(exact, unit: unit);
    return Length(_wholeTicks, unit: unit);
  }

  /// How many [unit]s the length is, for a decimal rendering. Exact while
  /// the quotient fits a [Rational]; past that (99,999,999,999,999in in
  /// metres, where the metre's 5000/127in pushes the fraction over its
  /// limit) it is taken in double math, which still holds every digit a
  /// decimal rendering shows, so a typed length near the limit converts
  /// instead of throwing [RationalOverflow].
  double amountIn(Unit unit) {
    try {
      return (inches / unit.inchesPer).toDouble();
    } on RationalOverflow {
      return inches.toDouble() / unit.inchesPer.toDouble();
    }
  }

  @override
  List<Object?> get props => [preciseTicks, unit];
}

/// A surface. Two lengths multiplied give square ticks; the unit is the
/// length unit the area is written in (ft², yd², in², m², cm², mm²), or
/// [Unit.acre]. The ft-in compound is two tokens, not a unit that can be
/// squared, so it is refused here.
final class Area extends Quantity {
  /// Square ticks in one square inch (64 × 64).
  static const int squareTicksPerSquareInch = 4096;

  /// Square inches in one square foot.
  static const int squareInchesPerSquareFoot = 144;

  /// Square feet in one acre.
  static const int squareFeetPerAcre = 43560;

  /// The area in square ticks.
  final double squareTicks;

  /// The unit the area is written in: a length unit for its squared form, or
  /// [Unit.acre].
  final Unit unit;

  const Area(this.squareTicks, {this.unit = Unit.foot})
    : assert(
        unit == Unit.inch ||
            unit == Unit.foot ||
            unit == Unit.yard ||
            unit == Unit.metre ||
            unit == Unit.centimetre ||
            unit == Unit.millimetre ||
            unit == Unit.acre,
        'an area is written in a squared length unit or in acres',
      );

  @override
  Dimension get dimension => Dimension.area;

  /// The area in square feet, the unit results are computed in.
  double get squareFeet =>
      squareTicks / squareTicksPerSquareInch / squareInchesPerSquareFoot;

  /// The same area written in another unit.
  Area spelledIn(Unit unit) => Area(squareTicks, unit: unit);

  @override
  List<Object?> get props => [squareTicks, unit];
}

/// A solid, kept in cubic feet whatever unit it is written in: a length
/// unit for its cubed form (never the ft-in compound), or [Unit.boardFoot].
final class Volume extends Quantity {
  /// Board feet in one cubic foot: a board foot is 1/12 ft³.
  static const int boardFeetPerCubicFoot = 12;

  /// The volume in cubic feet.
  final double cubicFeet;

  /// The unit the volume is written in: a length unit for its cubed form, or
  /// [Unit.boardFoot].
  final Unit unit;

  const Volume(this.cubicFeet, {this.unit = Unit.foot})
    : assert(
        unit == Unit.inch ||
            unit == Unit.foot ||
            unit == Unit.yard ||
            unit == Unit.metre ||
            unit == Unit.centimetre ||
            unit == Unit.millimetre ||
            unit == Unit.boardFoot,
        'a volume is written in a cubed length unit or in board feet',
      );

  @override
  Dimension get dimension => Dimension.volume;

  /// The volume in board feet.
  double get boardFeet => cubicFeet * boardFeetPerCubicFoot;

  /// The same volume written in another unit.
  Volume spelledIn(Unit unit) => Volume(cubicFeet, unit: unit);

  @override
  List<Object?> get props => [cubicFeet, unit];
}

/// A mass, kept in hundredths of a pound whatever unit it is written in.
final class Weight extends Quantity {
  /// The weight in hundredths of a pound.
  final double hundredthsOfPound;

  /// The weight unit the value is written in.
  final Unit unit;

  const Weight(this.hundredthsOfPound, {this.unit = Unit.pound})
    : assert(
        unit == Unit.pound ||
            unit == Unit.kilogram ||
            unit == Unit.ton ||
            unit == Unit.metricTon,
        'a weight needs a weight unit',
      );

  @override
  Dimension get dimension => Dimension.weight;

  /// The same weight written in another weight unit.
  Weight spelledIn(Unit unit) => Weight(hundredthsOfPound, unit: unit);

  @override
  List<Object?> get props => [hundredthsOfPound, unit];
}

/// How an angle is written on screen: decimal degrees (27.55°), the way a
/// survey sheet writes it, degrees, minutes and seconds (27°33'10"), or the
/// two ways a roofer writes a pitch, inches of rise per 12 inches of run
/// (16in/12in) and a percent grade (133.3%).
///
/// Spellings of one number, not units (UX Design Doc Section 6,
/// "Conversions offered": angle answers offer their D:M:S spelling; Section
/// 8: pressing Pitch cycles the three pitch spellings), which is why it
/// sits beside the degrees the way a length's unit sits beside its ticks,
/// and why re-spelling an angle never touches them (rule 4.15).
enum AngleSpelling {
  /// Decimal degrees, to two decimals at display.
  degrees,

  /// Degrees, then minutes and seconds padded to two digits.
  degreesMinutesSeconds,

  /// The pitch as inches of rise per 12 inches of run, the trade form of
  /// Section 8 ("Right triangle"): the tangent of the angle times 12, to
  /// one decimal, so 53.13° reads 16in/12in.
  risePerFoot,

  /// The pitch as a percent grade (Section 8): the tangent of the angle
  /// times 100, to one decimal, so 53.13° reads 133.3% and 4° reads 7%.
  grade;

  /// The spelling the Pitch key moves to from this one: in/12in, then
  /// degrees, then grade, and back (Section 8: "Pressing Pitch cycles the
  /// three spellings"); a survey angle joins the cycle at degrees.
  AngleSpelling get nextPitchSpelling => switch (this) {
    risePerFoot => degrees,
    degrees || degreesMinutesSeconds => grade,
    grade => risePerFoot,
  };
}

/// A rotation in decimal degrees, whichever spelling it wears.
final class Angle extends Quantity {
  /// The angle in decimal degrees.
  final double degrees;

  /// How the angle is written; degrees unless a conversion re-spelled it.
  final AngleSpelling spelling;

  const Angle(this.degrees, {this.spelling = AngleSpelling.degrees});

  /// The angle whose tangent is [riseOverRun], in degrees (UX Design Doc
  /// Section 8, "Right triangle"): a rise of 6 over a run of 12 is 26.57°.
  factory Angle.ofRiseOverRun(double riseOverRun) =>
      Angle(math.atan(riseOverRun) * 180 / math.pi);

  /// The pitch of [inches] of rise per 12in of run, in that spelling (UX
  /// Design Doc rule 4.10; Section 8): 6in/12in is 26.57°.
  factory Angle.ofRisePerFoot(double inches) => Angle.ofRiseOverRun(
    inches / inchesPerFootOfRun,
  ).spelledAs(AngleSpelling.risePerFoot);

  /// Inches of run a pitch is quoted over: 6in/12in.
  static const int inchesPerFootOfRun = 12;

  @override
  Dimension get dimension => Dimension.angle;

  /// The same angle written the other way.
  Angle spelledAs(AngleSpelling spelling) => Angle(degrees, spelling: spelling);

  @override
  List<Object?> get props => [degrees, spelling];
}

/// A bare number with no unit: a count, a ratio or a factor.
final class Scalar extends Quantity {
  /// The number itself.
  final double value;

  /// The decimals it keeps at display when it is not a plain result: six
  /// for a trig ratio (Sine 0.615661). `null` renders it as any result.
  final int? decimals;

  const Scalar(this.value, {this.decimals});

  @override
  Dimension get dimension => Dimension.scalar;

  @override
  List<Object?> get props => [value, decimals];
}
