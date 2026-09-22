import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
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

/// A distance, exact to 1/64 inch.
final class Length extends Quantity {
  /// Ticks of 1/64 inch in one inch.
  static const int ticksPerInch = 64;

  /// Ticks of 1/64 inch in one foot.
  static const int ticksPerFoot = 768;

  /// Whole ticks of 1/64 inch. Metric entry is converted on input at
  /// 2,519.685 ticks per metre, so a metre is exact to the nearest tick.
  final int ticks;

  /// The length unit the value is written in. [Unit.footInch] is the trade
  /// compound; every other length unit renders as a decimal or a fraction.
  final Unit unit;

  const Length(this.ticks, {required this.unit})
    : assert(
        unit == Unit.inch ||
            unit == Unit.foot ||
            unit == Unit.footInch ||
            unit == Unit.yard ||
            unit == Unit.metre ||
            unit == Unit.centimetre ||
            unit == Unit.millimetre,
        'a length needs a length unit',
      );

  @override
  Dimension get dimension => Dimension.length;

  /// The same distance written in another length unit.
  Length spelledIn(Unit unit) => Length(ticks, unit: unit);

  @override
  List<Object?> get props => [ticks, unit];
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

  const Weight(this.hundredthsOfPound, {required this.unit})
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

/// A rotation in decimal degrees. Degrees:minutes:seconds is a spelling of
/// the same number, not a different unit.
final class Angle extends Quantity {
  /// The angle in decimal degrees.
  final double degrees;

  const Angle(this.degrees);

  @override
  Dimension get dimension => Dimension.angle;

  @override
  List<Object?> get props => [degrees];
}

/// A bare number with no unit: a count, a ratio or a factor.
final class Scalar extends Quantity {
  /// The number itself.
  final double value;

  const Scalar(this.value);

  @override
  Dimension get dimension => Dimension.scalar;

  @override
  List<Object?> get props => [value];
}
