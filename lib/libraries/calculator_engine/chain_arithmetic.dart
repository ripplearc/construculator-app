import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/rational.dart';
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
/// A length stays exact through a sum, a difference and a scaling by a
/// typed number (UX Design Doc Section 6, "Precision and storage"): 0.1 ft
/// added a thousand times is exactly 100 ft, and 1 mm × 1000 is exactly
/// 1 m. The scaling number is the exact decimal the bare number carries
/// ([Scalar.exact]), or, for a number that came through double math, is
/// read back from the shortest decimal spelling of its double; a number
/// with no finite spelling scales the ticks, the prototype's way. Two
/// lengths multiply as doubles, the way the design note on CA-1190 said: an area
/// is a double, and the exact product of two fractions would outgrow a
/// 64-bit `int` at sides of 2³² in where the double does not. A length made
/// from an area or a volume is kept to whole ticks, the prototype's
/// rounding point, with JavaScript's `Math.round`, so a half tick rounds
/// toward +∞. A length whose exact fraction outgrows what a [Rational]
/// holds (65085/555951ft + 81712/3171mm ÷ 48011) is kept in double math to
/// 1/512 of a tick instead, as a rule's answer is, and a real length below
/// that, too small to keep (1in ÷ 9999999 three times), is refused as
/// [CalculationError.tooSmall]. A length scaled by a number with no finite
/// decimal spelling is rounded to a whole tick and refused the same way
/// when a real length rounds to none (1in × 1e-7): on neither path is a
/// zero written that says two lengths match when they do not (Section 6).
/// A length answer beyond [maxTicks] in either
/// direction, or any answer that overflowed to infinity, is refused as
/// [CalculationError.outOfRange] rather than clamped to a wrong number.
///
/// Which unit an answer wears follows the operands. An area, a volume or a
/// weight scaled by a bare number, or summed, keeps the first operand's
/// unit (500bf ÷ 4 reads 125bf; 500bf + 1yd³ = 824bf; 1yd² + 2ft² = 3yd²).
/// A length answer, scaled, summed or made from other quantities, is
/// written as the trade compound, or in the smallest metric unit typed when
/// every length that went in was metric, whatever their order (3yd × 2 =
/// 18ft 0in; 1m + 1mm = 1,001mm, where metres would hide the millimetre);
/// an area or a volume made from lengths answers in feet, or in that
/// metric unit by the same vote (2cm × 3cm = 6cm²). A sum or difference of
/// lengths or of areas that mixes imperial and metric follows the System of
/// units setting, in either order (Section 6; owner decision of 3 October
/// 2026): 12ft + 1m reads 15ft 3-3/8in under Imperial and 4.66m under
/// Metric, and 12ft² + 1m² reads 22.76ft² or 2.11m² the same way. A product
/// or a quotient that mixes them keeps the prototype's vote and answers in
/// feet under either setting (12ft × 1m = 39.38ft²), and a volume sum keeps
/// its first operand's unit (500bf + 1yd³ = 824bf, 1yd³ + 1m³ = 2.31yd³),
/// since Section 6 decides sums of lengths and areas only. Acres and board
/// feet carry no length system and do not vote, so 1 acre × 1m answers in
/// m³.
/// A bare number scales an area in either order, where the prototype
/// refused 3 × 12ft².
///
/// A pair the table has no row for is a dimension error whatever the
/// numbers: 12lbs ÷ 0ft is refused for its dimensions, and ÷ 0 is its own
/// error only for a pair the table can divide.
///
/// Two bare numbers that are both exact — typed, or computed from typed
/// numbers without outgrowing a [Rational] — add, subtract, multiply and
/// divide exactly, as lengths do (Section 6, "Precision and storage"; owner
/// decision of 27 October 2026), so a typed difference is never rounded
/// away whatever digit it sits in: 3.00000000000001 − 3 is
/// 0.00000000000001, 19999999 + 0.00000001 − 19999999 is 0.00000001, and
/// 0.1 + 0.2 − 0.3 is 0 (rule 4.15). A typed number has at most fifteen
/// digits ([EntryBuffer.maxDigits]; Section 5.1), so it always fits a
/// [Rational]; only a step whose exact result outgrows one is taken in
/// double math instead. A ratio of two lengths is exact too (Section 6;
/// owner decision of 28 October 2026): 36ft ÷ 12ft is exactly 3, so 36ft ÷
/// 12ft = − 3.00000000000001 = is −0.00000000000001 and 10ft ÷ 3ft × 3ft =
/// is exactly 10ft, with the same fallback to doubles when the fraction
/// outgrows a [Rational].
///
/// A sum or difference of two values kept as doubles (areas, volumes,
/// weights, angles, and a bare number that came through double math: a
/// trig ratio, a product that outgrew a [Rational]) that is zero within the
/// floating-point error of its operands
/// is zero: 2.5m × 2.5m leaves a residue of a few ulps against a typed
/// 6.25m², which would otherwise read "Under 0.01m²" for a true zero
/// (Section 6, "A true zero still reads 0"). The band is two parts in 10¹⁵
/// of the operands' size, about seven times the residue a product and a
/// difference leave (under 3 × 10⁻¹⁶ across metric and imperial areas and
/// volumes). Lengths are exact and need no such rounding.
class ChainArithmetic extends Equatable {
  /// The largest tick count a length answer may reach: 2⁵³, the last whole
  /// number a double still holds exactly, so every kept length was rounded
  /// from an exact value.
  static const int maxTicks = Length.maxTicks;

  /// The System of units setting, which decides the unit of a length or
  /// area sum whose operands mix imperial and metric.
  final MeasurementSystem system;

  const ChainArithmetic({this.system = MeasurementSystem.imperial});

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
    } on _TooSmall {
      return const ArithmeticFailed(CalculationError.tooSmall);
    } on RationalOverflow {
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
      a.inches.toDouble() * b.inches.toDouble() * Area.squareTicksPerSquareInch,
      unit: _systemUnit([a.unit, b.unit]),
    ),
    (final Area area, final Length length) => _volumeOf(area, length),
    (final Length length, final Area area) => _volumeOf(area, length),
    (final Scalar factor, final other) ||
    (final other, final Scalar factor) => _scaled(
      other,
      (number) => _timesNumber(factor, number),
      (value) => value * factor.value,
      (length) => _scaledLength(length, factor),
    ),
    _ => null,
  };

  Quantity? _divide(Quantity left, Quantity right) {
    if (_magnitude(right) == 0) return null;
    return switch ((left, right)) {
      (_, final Scalar divisor) => _scaled(
        left,
        (number) => _overNumber(number, divisor),
        (value) => value / divisor.value,
        (length) => _dividedLength(length, divisor),
      ),
      (final Area area, final Length length) => _keptLength(
        area.squareTicks / _magnitude(length),
        _lengthUnit([area.unit, length.unit]),
      ),
      (final Volume volume, final Area area) => _keptLength(
        _cubicTicks(volume) / area.squareTicks,
        _lengthUnit([volume.unit, area.unit]),
      ),
      (final Volume volume, final Length length) => Area(
        _cubicTicks(volume) / _magnitude(length),
        unit: _systemUnit([volume.unit, length.unit]),
      ),
      (final Length dividend, final Length divisor) => _ratioOfLengths(
        dividend,
        divisor,
      ),
      _ when left.dimension == right.dimension => Scalar(
        _magnitude(left) / _magnitude(right),
      ),
      _ => null,
    };
  }

  Scalar _ratioOfLengths(Length dividend, Length divisor) {
    try {
      final exact = dividend.inches / divisor.inches;
      return Scalar(exact.toDouble(), exact: exact);
    } on RationalOverflow {
      return Scalar(_magnitude(dividend) / _magnitude(divisor));
    }
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
    final magnitude = _zeroWithinFloatNoise(
      _magnitude(left) + sign * _magnitude(right),
      of: _magnitude(left).abs() + _magnitude(right).abs(),
    );
    return switch (left) {
      Length() => _lengthSum(left, right as Length, sign, magnitude),
      Area() => Area(
        magnitude,
        unit: _areaSumUnit(left.unit, (right as Area).unit),
      ),
      Volume() => Volume(magnitude, unit: left.unit),
      Weight() => Weight(magnitude, unit: left.unit),
      Angle() => Angle(magnitude, spelling: _sumSpelling(left, right as Angle)),
      Scalar() =>
        _exactScalar(
              left,
              right as Scalar,
              (x, y) => sign > 0 ? x + y : x - y,
            ) ??
            Scalar(magnitude),
    };
  }

  static AngleSpelling _sumSpelling(Angle left, Angle right) =>
      left.spelling == AngleSpelling.degreesMinutesSeconds &&
          right.spelling == AngleSpelling.degreesMinutesSeconds
      ? AngleSpelling.degreesMinutesSeconds
      : AngleSpelling.degrees;

  Length _lengthSum(Length left, Length right, int sign, double ticks) =>
      _exactOrKeptLength(
        () =>
            sign > 0 ? left.inches + right.inches : left.inches - right.inches,
        () => ticks,
        _lengthSumUnit(left.unit, right.unit),
      );

  static double _zeroWithinFloatNoise(double value, {required double of}) =>
      value.abs() <= of * _floatNoise ? 0 : value;

  static const double _floatNoise = 2e-15;

  Scalar? _exactScalar(
    Scalar left,
    Scalar right,
    Rational Function(Rational, Rational) compute,
  ) {
    if ((left.exact, right.exact) case (final a?, final b?)) {
      try {
        final exact = compute(a, b);
        return Scalar(exact.toDouble(), exact: exact);
      } on RationalOverflow {
        return null;
      }
    }
    return null;
  }

  bool _canDivide(Quantity left, Quantity right) => switch ((left, right)) {
    (_, Scalar()) ||
    (Area(), Length()) ||
    (Volume(), Area()) ||
    (Volume(), Length()) => true,
    _ => left.dimension == right.dimension,
  };

  Quantity _scaled(
    Quantity quantity,
    Scalar Function(Scalar) scaleNumber,
    double Function(double) scale,
    Length Function(Length) scaleLength,
  ) => switch (quantity) {
    final Length length => scaleLength(length),
    Area() => Area(scale(quantity.squareTicks), unit: quantity.unit),
    Volume() => Volume(scale(quantity.cubicFeet), unit: quantity.unit),
    Weight() => Weight(scale(quantity.hundredthsOfPound), unit: quantity.unit),
    Angle() => Angle(scale(quantity.degrees)),
    final Scalar number => scaleNumber(number),
  };

  Scalar _timesNumber(Scalar a, Scalar b) =>
      _exactScalar(a, b, (x, y) => x * y) ?? Scalar(a.value * b.value);

  Scalar _overNumber(Scalar a, Scalar b) =>
      _exactScalar(a, b, (x, y) => x / y) ?? Scalar(a.value / b.value);

  Length _scaledLength(Length length, Scalar factor) {
    final exact = _exactNumber(factor);
    if (exact == null) {
      return _roundedLength(length.ticks * factor.value, length.unit);
    }
    return _exactOrKeptLength(
      () => length.inches * exact,
      () => length.preciseTicks * factor.value,
      _lengthUnit([length.unit]),
    );
  }

  Length _dividedLength(Length length, Scalar divisor) {
    final exact = _exactNumber(divisor);
    if (exact == null) {
      return _roundedLength(length.ticks / divisor.value, length.unit);
    }
    return _exactOrKeptLength(
      () => length.inches / exact,
      () => length.preciseTicks / divisor.value,
      _lengthUnit([length.unit]),
    );
  }

  Rational? _exactNumber(Scalar number) =>
      number.exact ?? Rational.tryParse(number.value.toString());

  Length _roundedLength(double ticks, Unit unit) {
    final whole = _wholeTicks(ticks);
    if (ticks != 0 && whole == 0) throw const _TooSmall();
    return Length(whole, unit: _lengthUnit([unit]));
  }

  Length _keptLength(double ticks, Unit unit) {
    _wholeTicks(ticks);
    if (ticks != 0 && (ticks * Length.partsPerTick).round() == 0) {
      throw const _TooSmall();
    }
    return Length.computed(ticks, unit: unit);
  }

  Length _exactOrKeptLength(
    Rational Function() exact,
    double Function() approximateTicks,
    Unit unit,
  ) {
    try {
      return _exactLength(exact(), unit);
    } on RationalOverflow {
      return _keptLength(approximateTicks(), unit);
    }
  }

  Length _exactLength(Rational inches, Unit unit) {
    final ticks = (inches * const Rational(Length.ticksPerInch)).toDouble();
    if (!ticks.isFinite || ticks.abs() > maxTicks) {
      throw const _TicksOutOfRange();
    }
    return Length.exact(inches, unit: unit);
  }

  Volume _volumeOf(Area area, Length length) => Volume(
    area.squareFeet * length.inches.toDouble() / Unit.foot.inchesPer.toDouble(),
    unit: _systemUnit([area.unit, length.unit]),
  );

  double _magnitude(Quantity quantity) => switch (quantity) {
    Length() => quantity.inches.toDouble() * Length.ticksPerInch,
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
    return lengths.reduce(_smallerUnit);
  }

  Unit _lengthSumUnit(Unit first, Unit second) => _mixesSystems(first, second)
      ? _settingUnit(Unit.footInch)
      : _lengthUnit([first, second]);

  Unit _areaSumUnit(Unit first, Unit second) =>
      _mixesSystems(first, second) ? _settingUnit(Unit.foot) : first;

  bool _mixesSystems(Unit first, Unit second) =>
      first.compoundRank > 0 &&
      second.compoundRank > 0 &&
      first.isMetric != second.isMetric;

  Unit _settingUnit(Unit imperial) =>
      system == MeasurementSystem.metric ? Unit.metre : imperial;

  Unit _smallerUnit(Unit a, Unit b) => b.ticksPerUnit < a.ticksPerUnit ? b : a;

  int _wholeTicks(double ticks) {
    final rounded = (ticks + 0.5).floorToDouble();
    if (!rounded.isFinite || rounded.abs() > maxTicks) {
      throw const _TicksOutOfRange();
    }
    return rounded.toInt();
  }

  @override
  List<Object?> get props => [system];
}

class _TicksOutOfRange implements Exception {
  const _TicksOutOfRange();
}

class _TooSmall implements Exception {
  const _TooSmall();
}
