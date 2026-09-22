import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// Reads the tokens of a finished value as a [Quantity].
///
/// This is where a typed number becomes exact: each length token is rounded
/// to whole ticks on its own and the ticks are summed, so 18ft 8in is
/// 14,336 and 1ft 1/16in is 772 whatever the floating-point value of 1/16
/// was. Metric entry is converted here too (2,519.685 ticks per metre), so
/// the tape never holds a metre as a metre (UX Design Doc Section 6,
/// "Precision and storage").
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

  /// The whole ticks one length token stands for, rounded on its own so a
  /// compound's ticks add exactly. A token whose fraction has no value
  /// (7/0) is a programming error here; [parse] answers `null` for it.
  int ticksOf(Token token) {
    if (!token.value.isFinite) {
      throw ArgumentError.value(token, 'token', 'has no finite value');
    }
    if (token.unit case final unit? when unit.dimension == Dimension.length) {
      return (token.value * unit.ticksPerUnit).round();
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
  /// of imperial tokens is spelled as the trade's ft-in.
  Quantity? parse(List<Token> tokens) {
    if (tokens.isEmpty ||
        tokens.any((token) => !token.isComplete || !token.value.isFinite)) {
      return null;
    }
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
    var ticks = 0;
    var hundredthsOfPound = 0.0;
    for (final token in tokens) {
      final tokenUnit = token.unit;
      if (tokenUnit == null ||
          tokenUnit.dimension != unit.dimension ||
          token.power > 1) {
        return null;
      }
      if (unit.dimension == Dimension.length) {
        ticks += ticksOf(token);
      } else {
        hundredthsOfPound +=
            token.value *
            tokenUnit.hundredthsOfPoundPer(poundsPerTon: poundsPerTon);
      }
    }
    if (unit.dimension == Dimension.weight) {
      return Weight(hundredthsOfPound, unit: unit);
    }
    return Length(ticks, unit: _compoundSpelling(tokens, unit));
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

  // A metric compound (1m 20cm) has no trade spelling of its own, so it keeps
  // the unit it was typed in; only an imperial compound reads as ft-in.
  Unit _compoundSpelling(List<Token> tokens, Unit first) {
    if (tokens.length == 1 || first.isMetric) return first;
    return Unit.footInch;
  }

  @override
  List<Object?> get props => [poundsPerTon];
}
