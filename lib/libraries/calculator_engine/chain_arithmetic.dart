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
/// that the tape never holds a fraction of a tick; the rounding is the
/// prototype's, JavaScript's `Math.round`, so a half tick rounds toward +∞.
/// A length answer beyond [maxTicks] in either direction, or any answer
/// that overflowed to infinity, is refused as [CalculationError.outOfRange]
/// rather than clamped to a wrong number.
///
/// Which unit an answer wears follows the operands. An area, a volume or a
/// weight scaled by a bare number, or summed, keeps the first operand's
/// unit (500bf ÷ 4 reads 125bf; 500bf + 1yd³ = 824bf; 1yd² + 2ft² = 3yd²).
/// A length answer, scaled, summed or made from other quantities, is
/// written as the trade compound, or in the first metric length's unit when
/// every length that went in was metric (3yd × 2 = 18ft 0in; 1mm + 1mm =
/// 2mm); an area or a volume made from lengths answers in feet, or in that
/// metric unit by the same vote (2cm × 3cm = 6cm²). Acres and board feet
/// carry no length system and do not vote, so 1 acre × 1m answers in m³.
/// A bare number scales an area in either order, where the prototype
/// refused 3 × 12ft².
///
/// A pair the table has no row for is a dimension error whatever the
/// numbers: 12lbs ÷ 0ft is refused for its dimensions, and ÷ 0 is its own
/// error only for a pair the table can divide.
class ChainArithmetic extends Equatable {
  /// The largest tick count a length answer may reach: 2⁵³, the last whole
  /// number a double still holds exactly, so every kept length was rounded
  /// from an exact value.
  static const int maxTicks = 1 << 53;

  const ChainArithmetic();

  /// [left] `operator` [right], or why it cannot be computed.
  ArithmeticOutcome combine(Quantity left, Operator operator, Quantity right) {
    final Quantity? value;
    try {
      value = switch (operator) {
        Operator.multiply => _multiply(left, right),
        Operator.divide => _divide(left, right),
        Operator.add || Operator.subtract => _addOrSubtract(
          left,
          right,
          sign: operator == Operator.add ? 1 : -1,
        ),
      };
    } on _TicksOutOfRange {
      return const ArithmeticFailed(CalculationError.outOfRange);
    }
    if (value case final value?) {
      if (!_magnitude(value).isFinite) {
        return const ArithmeticFailed(CalculationError.outOfRange);
      }
      return ArithmeticValue(value);
    }
    if (operator == Operator.divide &&
        _magnitude(right) == 0 &&
        _canDivide(left, right)) {
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
    (final Scalar factor, _) => _scaled(right, (value) => value * factor.value),
    (_, final Scalar factor) => _scaled(left, (value) => value * factor.value),
    _ => null,
  };

  Quantity? _divide(Quantity left, Quantity right) {
    if (_magnitude(right) == 0) return null;
    return switch ((left, right)) {
      (_, final Scalar divisor) => _scaled(
        left,
        (value) => value / divisor.value,
      ),
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

  bool _canDivide(Quantity left, Quantity right) => switch ((left, right)) {
    (_, Scalar()) ||
    (Area(), Length()) ||
    (Volume(), Area()) ||
    (Volume(), Length()) => true,
    _ => left.dimension == right.dimension,
  };

  Quantity _scaled(Quantity quantity, double Function(double) scale) =>
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

  double _magnitude(Quantity quantity) => switch (quantity) {
    Length() => quantity.ticks.toDouble(),
    Area() => quantity.squareTicks,
    Volume() => quantity.cubicFeet,
    Weight() => quantity.hundredthsOfPound,
    Angle() => quantity.degrees,
    Scalar() => quantity.value,
  };

  double _cubicTicks(Volume volume) =>
      volume.cubicFeet *
      Length.ticksPerFoot *
      Length.ticksPerFoot *
      Length.ticksPerFoot;

  Unit _lengthUnit(List<Unit> units) => _metricUnitOf(units) ?? Unit.footInch;

  Unit _systemUnit(List<Unit> units) => _metricUnitOf(units) ?? Unit.foot;

  Unit? _metricUnitOf(List<Unit> units) {
    final lengths = units.where((unit) => unit.compoundRank > 0);
    if (lengths.isEmpty || !lengths.every((unit) => unit.isMetric)) {
      return null;
    }
    return lengths.first;
  }

  int _wholeTicks(double ticks) {
    final rounded = (ticks + 0.5).floorToDouble();
    if (!rounded.isFinite || rounded.abs() > maxTicks) {
      throw const _TicksOutOfRange();
    }
    return rounded.toInt();
  }

  @override
  List<Object?> get props => const [];
}

/// Raised inside a row when a length answer has no whole tick count, so
/// that [ChainArithmetic.combine] can refuse the step instead of clamping.
class _TicksOutOfRange implements Exception {
  const _TicksOutOfRange();
}
