import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// What one step of a chain gave.
sealed class ArithmeticOutcome extends Equatable {
  const ArithmeticOutcome();
}

/// The step computed.
final class ArithmeticValue extends ArithmeticOutcome {
  /// The running total after the step.
  final Quantity value;

  const ArithmeticValue(this.value);

  @override
  List<Object?> get props => [value];
}

/// The step could not be computed and the tape gets an error chip.
final class ArithmeticFailed extends ArithmeticOutcome {
  /// Why.
  final CalculationError error;

  const ArithmeticFailed(this.error);

  @override
  List<Object?> get props => [error];
}

/// The dimension table of UX Design Doc Section 7: what the running total
/// becomes when an operator joins two quantities. The port of the
/// prototype's `opCompute`, with the ÷ rows Appendix D corrects (area ÷
/// length is a length, volume ÷ area a length, volume ÷ length an area).
///
/// Nothing here rounds except a length, which is kept to whole ticks so
/// that the tape never holds a fraction of a tick. Which unit an answer
/// wears follows the operands: a value scaled by a bare number, and a sum,
/// keep the first operand's unit (500bf ÷ 4 reads 125bf; 500bf + 1yd³ =
/// 824bf; 1yd² + 2ft² = 3yd²); a length made from lengths answers in the
/// trade compound, and an area or a volume made from lengths in feet, or
/// in metres when every length that went in was metric. A bare number
/// scales an area in either order, where the prototype refused 3 × 12ft².
class ChainArithmetic extends Equatable {
  const ChainArithmetic();

  /// [left] `operator` [right], or why it cannot be computed.
  ArithmeticOutcome combine(Quantity left, Operator operator, Quantity right) {
    final value = switch (operator) {
      Operator.multiply => _multiply(left, right),
      Operator.divide => _divide(left, right),
      Operator.add || Operator.subtract => _addOrSubtract(
        left,
        right,
        sign: operator == Operator.add ? 1 : -1,
      ),
    };
    if (value case final value?) return ArithmeticValue(value);
    if (operator == Operator.divide && _magnitude(right) == 0) {
      return const ArithmeticFailed(CalculationError.divisionByZero);
    }
    return const ArithmeticFailed(CalculationError.dimensionError);
  }

  Quantity? _multiply(Quantity left, Quantity right) => switch ((left, right)) {
    (final Length a, final Length b) => Area(
      a.ticks * b.ticks.toDouble(),
      unit: _systemUnit([a.unit, b.unit]),
    ),
    (final Area area, final Length length) => _volumeOf(area, length),
    (final Length length, final Area area) => _volumeOf(area, length),
    (final Scalar factor, _) => _map(right, (value) => value * factor.value),
    (_, final Scalar factor) => _map(left, (value) => value * factor.value),
    _ => null,
  };

  Quantity? _divide(Quantity left, Quantity right) {
    if (_magnitude(right) == 0) return null;
    return switch ((left, right)) {
      (_, final Scalar divisor) => _map(left, (value) => value / divisor.value),
      (final Area area, final Length length) => Length(
        _wholeTicks(area.squareTicks / length.ticks),
        unit: _lengthUnit([area.unit, length.unit]),
      ),
      (final Volume volume, final Area area) => Length(
        _wholeTicks(_cubicTicks(volume) / area.squareTicks),
        unit: _lengthUnit([volume.unit, area.unit]),
      ),
      (final Volume volume, final Length length) => Area(
        _cubicTicks(volume) / length.ticks,
        unit: _systemUnit([volume.unit, length.unit]),
      ),
      _ when left.dimension == right.dimension => Scalar(
        _magnitude(left) / _magnitude(right),
      ),
      _ => null,
    };
  }

  Quantity? _addOrSubtract(Quantity left, Quantity right, {required int sign}) {
    if (left.dimension != right.dimension) {
      return switch ((left, right)) {
        (final Angle angle, final Scalar degrees) => Angle(
          angle.degrees + sign * degrees.value,
        ),
        (final Scalar degrees, final Angle angle) => Angle(
          degrees.value + sign * angle.degrees,
        ),
        _ => null,
      };
    }
    final magnitude = _magnitude(left) + sign * _magnitude(right);
    return switch (left) {
      Length() => Length(
        _wholeTicks(magnitude),
        unit: _lengthUnit([left.unit, (right as Length).unit]),
      ),
      Area() => Area(magnitude, unit: left.unit),
      Volume() => Volume(magnitude, unit: left.unit),
      Weight() => Weight(magnitude, unit: left.unit),
      Angle() => Angle(magnitude),
      Scalar() => Scalar(magnitude),
    };
  }

  // A quantity scaled by a bare number keeps its dimension and its unit;
  // a length answer is re-spelled as the trade compound.
  Quantity _map(Quantity quantity, double Function(double) scale) =>
      switch (quantity) {
        Length() => Length(
          _wholeTicks(scale(quantity.ticks.toDouble())),
          unit: _lengthUnit([quantity.unit]),
        ),
        Area() => Area(scale(quantity.squareTicks), unit: quantity.unit),
        Volume() => Volume(scale(quantity.cubicFeet), unit: quantity.unit),
        Weight() => Weight(
          scale(quantity.hundredthsOfPound),
          unit: quantity.unit,
        ),
        Angle() => Angle(scale(quantity.degrees)),
        Scalar() => Scalar(scale(quantity.value)),
      };

  Volume _volumeOf(Area area, Length length) => Volume(
    area.squareFeet * length.ticks / Length.ticksPerFoot,
    unit: _systemUnit([area.unit, length.unit]),
  );

  // The canonical number of each dimension, for the rows where the
  // dimensions already match.
  double _magnitude(Quantity quantity) => switch (quantity) {
    Length() => quantity.ticks.toDouble(),
    Area() => quantity.squareTicks,
    Volume() => quantity.cubicFeet,
    Weight() => quantity.hundredthsOfPound,
    Angle() => quantity.degrees,
    Scalar() => quantity.value,
  };

  // A volume in cubic ticks, so that dividing by an area in square ticks
  // gives ticks and by a length gives square ticks.
  double _cubicTicks(Volume volume) =>
      volume.cubicFeet *
      Length.ticksPerFoot *
      Length.ticksPerFoot *
      Length.ticksPerFoot;

  // A length answer is written as the trade compound unless every length
  // that went into it was metric, in which case metres; an area or volume
  // answer in feet or metres by the same vote. Acres and board feet carry
  // no length system and do not vote.
  Unit _lengthUnit(List<Unit> units) =>
      _allMetric(units) ? Unit.metre : Unit.footInch;

  Unit _systemUnit(List<Unit> units) =>
      _allMetric(units) ? Unit.metre : Unit.foot;

  bool _allMetric(List<Unit> units) {
    final lengths = units.where((unit) => unit.compoundRank > 0);
    return lengths.isNotEmpty && lengths.every((unit) => unit.isMetric);
  }

  // JavaScript's Math.round, which the prototype applies to a length
  // answer: half rounds toward +∞.
  int _wholeTicks(double ticks) => (ticks + 0.5).floor();

  @override
  List<Object?> get props => const [];
}
