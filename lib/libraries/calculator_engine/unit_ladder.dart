import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:construculator/libraries/calculator_engine/quantity_speller.dart';
import 'package:equatable/equatable.dart';

/// Why a unit key was refused on a finished value. The app turns each into
/// the toast of UX Design Doc Section 5.2.
enum UnitKeyRefusal {
  /// The same length key a fourth time: there is no ft⁴ ("Feet stop at
  /// cubic").
  stopsAtCubic,

  /// A second press would make an area or a volume of a value whose key can
  /// only hold a length ("Width keeps 22ft").
  keepsLength,

  /// A weight or board-foot key on a value already in that unit ("Already
  /// in pounds").
  alreadyInUnit,

  /// A unit of one dimension on a value of another ("Can't convert to
  /// kilograms").
  cannotConvert,
}

/// What a unit key did to a finished value.
sealed class UnitKeyOutcome extends Equatable {
  const UnitKeyOutcome();
}

/// The value was re-spelled in the unit pressed; it is the same quantity.
final class UnitKeyConverted extends UnitKeyOutcome {
  /// The value in its new unit.
  final Quantity value;

  /// The tokens the tape now shows for it.
  final List<Token> tokens;

  const UnitKeyConverted(this.value, this.tokens);

  @override
  List<Object?> get props => [value, tokens];
}

/// The same key was pressed again and raised the dimension: 4in → 4in² →
/// 4in³.
final class UnitKeyRaised extends UnitKeyOutcome {
  /// The area or volume the value became.
  final Quantity value;

  /// The one token the tape now shows, with its power raised.
  final List<Token> tokens;

  const UnitKeyRaised(this.value, this.tokens);

  @override
  List<Object?> get props => [value, tokens];
}

/// The key could not apply; the value is untouched and the press explains
/// itself.
final class UnitKeyRefused extends UnitKeyOutcome {
  /// Why the press was refused.
  final UnitKeyRefusal reason;

  /// For [UnitKeyRefusal.stopsAtCubic], the reading a different length key
  /// would give (Feet → 2,106ft³), so the toast can point at it.
  final Quantity? alternative;

  const UnitKeyRefused(this.reason, {this.alternative});

  @override
  List<Object?> get props => [reason, alternative];
}

/// What a unit key does to a value that is already finished (UX Design Doc
/// rule 4.3; Section 6, "Unit keys convert and raise").
///
/// A unit key on a finished value converts it in place: 22ft then [Inch]
/// reads 264in. The same length key pressed again raises the dimension,
/// ft → ft² → ft³, and stops at cubic. [Feet] on a value with leftover
/// inches shows the trade compound (224in → 18ft 8in) and on a compound
/// toggles back to decimal feet; a value under a foot converts to decimal
/// feet, never "0ft 4in". A fraction (7/16in then [Inch] reads 0.438in) and
/// decimal feet ([Feet] on 18.67ft shows the compound) are re-spelled, not
/// raised. Weight keys convert a weight and never raise.
///
/// The key's effect on a number still being typed — closing it, stepping a
/// compound down — is the entry grammar's (A2), not the ladder's.
class UnitLadder extends Equatable {
  /// How many pounds make a ton, shared by the parser and the speller so
  /// that a value read at 2,240 lb to the ton is never written back at
  /// 2,000.
  final int poundsPerTon;

  const UnitLadder({this.poundsPerTon = QuantityParser.defaultPoundsPerTon});

  /// Reads the raised token back as a quantity.
  QuantityParser get parser => QuantityParser(poundsPerTon: poundsPerTon);

  /// Writes a converted quantity as the tape's tokens.
  QuantitySpeller get speller => QuantitySpeller(poundsPerTon: poundsPerTon);

  /// Applies [key] to the finished [value] whose tape spelling is [tokens].
  ///
  /// [holdsLengthOnly] is true under a function key that can only hold a
  /// length (Width, Length, Height, Pitch…), which refuses the raise rather
  /// than silently making Width 22ft².
  ///
  /// A volume converts to the three cubed units the strip offers and to
  /// board feet; a raised token (2106ft³) converts with its power to any
  /// length key instead, as the prototype does.
  UnitKeyOutcome press({
    required List<Token> tokens,
    required Quantity value,
    required Unit key,
    bool holdsLengthOnly = false,
  }) {
    if (tokens.isEmpty) {
      return const UnitKeyRefused(UnitKeyRefusal.cannotConvert);
    }
    final isLengthKey = key.dimension == Dimension.length;
    final single = tokens.length == 1 ? tokens.first : null;
    if (single != null &&
        isLengthKey &&
        _raisesRatherThanRespells(single, key)) {
      return _raise(single, value, key, holdsLengthOnly: holdsLengthOnly);
    }
    if (single != null && single.power > 1 && isLengthKey) {
      if (value is Area) return _convert(value.spelledIn(key));
      if (value is Volume) return _convert(value.spelledIn(key));
    }
    if (isLengthKey && value is Length) {
      return _convert(value.spelledIn(_footInchOrKey(value, key, tokens)));
    }
    if (value is Volume && _isCubedOrBoardFootKey(key) && key != value.unit) {
      return _convert(value.spelledIn(key));
    }
    if (value is Weight &&
        key.dimension == Dimension.weight &&
        key != value.unit) {
      return _convert(value.spelledIn(key));
    }
    if (key == tokens.last.unit) {
      return const UnitKeyRefused(UnitKeyRefusal.alreadyInUnit);
    }
    return const UnitKeyRefused(UnitKeyRefusal.cannotConvert);
  }

  bool _raisesRatherThanRespells(Token token, Unit key) {
    if (token.unit != key || token.denominator != null) return false;
    if (key == Unit.foot && token.digits.contains('.') && token.power == 1) {
      return false;
    }
    return true;
  }

  UnitKeyOutcome _raise(
    Token token,
    Quantity value,
    Unit key, {
    required bool holdsLengthOnly,
  }) {
    if (token.power == 3) {
      final alternative = key == Unit.foot ? Unit.yard : Unit.foot;
      return UnitKeyRefused(
        UnitKeyRefusal.stopsAtCubic,
        alternative: value is Volume ? value.spelledIn(alternative) : null,
      );
    }
    if (holdsLengthOnly) {
      return const UnitKeyRefused(UnitKeyRefusal.keepsLength);
    }
    final raised = token.copyWith(power: token.power + 1);
    final quantity = parser.parse([raised]);
    if (quantity == null) {
      return const UnitKeyRefused(UnitKeyRefusal.cannotConvert);
    }
    return UnitKeyRaised(quantity, [raised]);
  }

  Unit _footInchOrKey(Length value, Unit key, List<Token> tokens) {
    final wasCompound = tokens.length > 1;
    final hasLeftoverInches = value.ticks % Length.ticksPerFoot != 0;
    if (key == Unit.foot &&
        !wasCompound &&
        value.ticks >= Length.ticksPerFoot &&
        hasLeftoverInches) {
      return Unit.footInch;
    }
    return key;
  }

  bool _isCubedOrBoardFootKey(Unit key) =>
      key == Unit.foot ||
      key == Unit.yard ||
      key == Unit.metre ||
      key == Unit.boardFoot;

  UnitKeyConverted _convert(Quantity value) =>
      UnitKeyConverted(value, speller.spell(value));

  @override
  List<Object?> get props => [poundsPerTon];
}
