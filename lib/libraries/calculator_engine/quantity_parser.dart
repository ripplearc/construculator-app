import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/rational.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// Reads the tokens of a finished value as a [Quantity].
///
/// This is where a typed number becomes a value, and it stays exactly what
/// was typed (UX Design Doc Section 6, "Precision and storage"): each
/// length token is an exact [Rational] of inches — 17.32 ft is 5196/25 in,
/// 1/16 in is 1/16 in, 1 mm is 5/127 in — and a compound is their exact
/// sum, so 18ft 8in is 224 in and 1ft 1/16in is 193/16 in whatever the
/// floating-point value of 1/16 was. Nothing here rounds to a tick; the
/// tick count is a view the [Length] computes.
///
/// The parser is a value, not a service: two parsers with the same ton
/// definition read every token list the same way.
class QuantityParser extends Equatable {
  /// Pounds in a ton when the "Pounds per ton" setting has not been changed.
  static const int defaultPoundsPerTon = 2000;

  /// How many pounds a [Unit.ton] token stands for. A setting rather than a
  /// constant because the long ton (2,240 lb) is a display-time choice that
  /// also decides what a typed "78 ton" weighs.
  final int poundsPerTon;

  const QuantityParser({this.poundsPerTon = defaultPoundsPerTon});

  /// The exact inches one length token stands for. A token whose number
  /// cannot be kept exactly — a fraction over zero, or more digits than a
  /// [Rational] holds — is a programming error here; [parse] answers `null`
  /// for it.
  Rational inchesOf(Token token) {
    final exact = _exactValueOf(token);
    if (exact == null) {
      throw ArgumentError.value(token, 'token', 'has no exact value');
    }
    if (token.unit case final unit? when unit.dimension == Dimension.length) {
      return exact * unit.inchesPer;
    }
    throw ArgumentError.value(token, 'token', 'is not a length');
  }

  /// The quantity the tokens spell, or `null` while any token is still open
  /// or the tokens cannot be one value (a length beside a weight, a raised
  /// unit inside a compound, a fraction over zero).
  ///
  /// A single token pressed twice or three times is an area or a volume in
  /// that unit; a single board-foot token is a volume; weight tokens add up
  /// in hundredths of a pound; length tokens add up in ticks and a compound
  /// of imperial tokens is spelled as the trade's ft-in, while a metric
  /// compound (1m 20cm) has no trade spelling of its own and keeps the unit
  /// it was typed in.
  Quantity? parse(List<Token> tokens) {
    if (tokens.isEmpty ||
        tokens.any((token) => !token.isComplete || !token.value.isFinite)) {
      return null;
    }
    if (tokens.any((token) => _exactValueOf(token) == null)) return null;
    final first = tokens.first;
    final unit = first.unit;
    if (unit == null) return null;
    if (tokens.length == 1 && first.power > 1) return _raised(first, unit);
    if (tokens.length == 1 && unit == Unit.boardFoot) {
      return Volume(
        first.value / Volume.boardFeetPerCubicFoot,
        unit: Unit.boardFoot,
      );
    }
    if (unit.dimension != Dimension.length &&
        unit.dimension != Dimension.weight) {
      return null;
    }
    var inches = Rational.zero;
    var hundredthsOfPound = 0.0;
    for (final token in tokens) {
      final tokenUnit = token.unit;
      if (tokenUnit == null ||
          tokenUnit.dimension != unit.dimension ||
          token.power > 1) {
        return null;
      }
      if (unit.dimension == Dimension.length) {
        inches += inchesOf(token);
      } else {
        hundredthsOfPound +=
            token.value *
            tokenUnit.hundredthsOfPoundPer(poundsPerTon: poundsPerTon);
      }
    }
    if (unit.dimension == Dimension.weight) {
      return Weight(hundredthsOfPound, unit: unit);
    }
    return Length.exact(
      inches,
      unit: _footInchForImperialCompound(tokens, unit),
    );
  }

  Rational? _exactValueOf(Token token) {
    final numerator = Rational.tryParse(token.digits);
    if (numerator == null) return null;
    final denominator = token.denominator;
    if (denominator == null) return numerator;
    final divisor = Rational.tryParse(denominator);
    if (divisor == null || divisor.isZero) return null;
    return numerator / divisor;
  }

  Quantity? _raised(Token token, Unit unit) {
    if (unit.dimension != Dimension.length) return null;
    final ticksPerUnit = unit.ticksPerUnit;
    if (token.power == 2) {
      return Area(token.value * ticksPerUnit * ticksPerUnit, unit: unit);
    }
    final feetPerUnit = ticksPerUnit / Length.ticksPerFoot;
    return Volume(
      token.value * feetPerUnit * feetPerUnit * feetPerUnit,
      unit: unit,
    );
  }

  Unit _footInchForImperialCompound(List<Token> tokens, Unit first) {
    if (tokens.length == 1 || first.isMetric) return first;
    return Unit.footInch;
  }

  @override
  List<Object?> get props => [poundsPerTon];
}
