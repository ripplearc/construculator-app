import 'package:construculator/libraries/calculator_engine/chain_arithmetic.dart';
import 'package:construculator/libraries/calculator_engine/chain_evaluator.dart';
import 'package:construculator/libraries/calculator_engine/deterministic_rules.dart';
import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/read_as_offer.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/calculator_engine/quantity_formatter.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:construculator/libraries/calculator_engine/trig.dart';
import 'package:construculator/libraries/calculator_engine/unit_ladder.dart';
import 'package:equatable/equatable.dart';

/// The function keys whose number is complete without a unit (Section 5.1:
/// "A bare number under a key that takes a plain number … is complete"), by
/// the id a [ValueChip.key] carries. The one list the screen and the tests
/// read to pass [Tape.pressFunctionKey] its `keyWantsUnit` and
/// `readsDegrees` and [Tape.pressUnit] its `takesAGrade`.
abstract final class PlainNumberKeys {
  /// A bare number under Pitch is degrees (rule 4.10).
  static const String pitch = 'Pitch';

  /// A bare number under Slope is a percent grade (rule 4.10).
  static const String slope = 'Slope';

  /// Sides takes a count.
  static const String sides = 'Sides';

  /// Every key that takes a plain number.
  static const Set<String> all = {pitch, slope, sides};
}

/// Why a key could not apply to the tape as a whole (Section 5.1). Refusals
/// of the number being typed are [EntryRefusal]s and of a finished value
/// [UnitKeyRefusal]s; these are the ones only the tape can see.
enum TapeRefusal {
  /// A unit key with nothing typed on an empty or sealed tape ("Type a
  /// number first").
  typeANumberFirst,

  /// A unit key with nothing typed while a result with no unit (Calc 156)
  /// ends the tape, or a result sits earlier on it ("Units apply while
  /// typing"; the result's conversions are already on the strip). A result
  /// with a unit converts in place instead (Appendix D).
  unitsApplyWhileTyping,

  /// Any key that would leave the active chip while it holds a compound
  /// left open (18ft 8) or a fraction without a unit (7/16) ("Finish this
  /// value first"). A single bare number seals as a scalar instead.
  finishThisValueFirst,

  /// [/] with no chip being typed.
  nothingBeingTyped,

  /// ⌫ on an empty tape.
  nothingToDelete,

  /// An operator with no value before it ("Type a value first").
  typeAValueFirst,

  /// A length unit on a number under Slope (Section 5.4, "A slope is a %
  /// grade, not a length": "[Slope] takes a bare number — 7 means a 7%
  /// grade").
  slopeTakesAGrade,

  /// A trig key on a value with a unit (38ft [SIN], 12ft ÷ 2 [ATAN]): "Sine
  /// needs a plain angle, not a length", "Arctangent needs a ratio, not a
  /// length" (Section 5.4). The caller names the function and the value
  /// from the tape.
  trigNeedsAPlainAngle,

  /// A unit key on the number of a trig chip ([SIN] 38 [Feet]): "Sine takes
  /// an angle, not a length", "Arcsine takes a ratio, not a length"
  /// (Section 5.4); the number stays bare.
  trigTakesAnAngle,

  /// The D:M:S key on a value with a unit (38ft [D:M:S], 18ft 8 [D:M:S]):
  /// "D:M:S is an angle format, not a length" (Section 5.4); nothing
  /// changes. The caller names the value from the tape.
  dmsNeedsAPlainAngle,

  /// ASIN or ACOS on a ratio beyond ±1 (2 [ASIN]): "Arcsine needs a ratio
  /// between −1 and 1 — 2 isn't one" (Section 5.4, "Ratio out of range");
  /// nothing lands and the number stays as typed. An inverse key on an
  /// angle still being typed under its key (Pitch 30°) or on an angle
  /// reached by a division is refused the same way (rule 4.11). The caller
  /// names the function and the value.
  ratioOutOfRange,

  /// [TAN] on an odd quarter turn (90 [TAN], 270 [TAN]): "The tangent of
  /// 90° is undefined" (Section 5.4); nothing lands and the number keeps
  /// no degree badge. The caller names the angle the user typed.
  tangentUndefined,

  /// An operator, =, a function key or the bracket key on a trig chip whose
  /// function has no value at its angle (Tangent 90°): "Tangent can't
  /// answer that" (Section 5.4); the digits are never used in its place.
  trigCannotAnswer,

  /// = with no operator to apply and no value waiting for one ("Nothing to
  /// compute yet"); the strip's top suggestion, if any, is the caller's to
  /// land instead. After a result or an error chip the prototype stays
  /// quiet (rule 4.12): [Tape.endsWithResult] and [Tape.endsWithError] tell
  /// the caller when to.
  nothingToCompute,

  /// A digit straight after a closed bracket ("Add an operator first").
  addAnOperatorFirst,

  /// A unit key straight after a closed bracket ("A group cannot take a
  /// unit yet").
  groupCannotTakeUnit,

  /// A function key while a bracket is open ("Brackets hold plain
  /// arithmetic").
  bracketsHoldPlainArithmetic,

  /// [( )] on an empty named chip (Length then ( )): a bracket holds
  /// numbers, units, fractions and operators only (Appendix D).
  bracketCannotTakeName,

  /// ( by a path other than the [( )] key while a bracket is open ("One
  /// bracket at a time").
  oneBracketAtATime,

  /// [( )] to close with nothing open.
  noBracketToClose,

  /// The Read-as pill tapped while the tape offers no other reading; the
  /// pill shows only while [Tape.readAsOffer] has one.
  nothingToReInput,
}

/// Something the tape did that the user should be told about, though
/// nothing was refused (Section 5.1 "Empty brackets"; Section 5.6; Section
/// 6, a carried compound part).
enum TapeNotice {
  /// A unit key closed a part as large as the unit above it and carried it
  /// up: 18ft 13in reads 19ft 1in (Section 6; owner decision of 3 October
  /// 2026). The notice carries no text: the caller names both spellings
  /// from the tapes it holds, the typed one as the active chip's text before
  /// the key plus the key's unit (18ft 13 then [Inch]), the carried one as
  /// the active chip's text after it.
  carriedOver,

  /// A bracket was closed, or = pressed, with nothing between ( and ), so
  /// the bracket was removed and the value or operator before it is active
  /// again. ⌫ on an empty bracket removes it the same way but silently, as
  /// the prototype does.
  emptyBracketsRemoved,

  /// A bracket reopened by ⌫ was emptied and then closed, so the edit was
  /// cancelled and the group is back as it was (Section 7, "Editing a
  /// bracket"; Section 5, "The group had nothing inside it, so your change
  /// was cancelled"). = brings the group back the same way, and then lands
  /// the Calc.
  bracketEditCancelled,

  /// = closed the open bracket, as it always does first (Section 7), but
  /// then found nothing to compute: the tape holds the closed bracket and
  /// the toast is the one for [TapeRefusal.nothingToCompute].
  bracketClosedNothingToCompute,

  /// = closed a fraction typed right after whole inches as inches, as every
  /// leaving key does (Section 6), but then found nothing to compute: the
  /// tape holds 7-1/2in and the toast is the one for
  /// [TapeRefusal.nothingToCompute], in the prototype's order (close, then
  /// refuse).
  fractionClosedNothingToCompute,
}

/// What a key did to the tape.
sealed class TapeOutcome extends Equatable {
  const TapeOutcome();
}

/// The tape took the key.
final class TapeChanged extends TapeOutcome {
  /// The tape after the key.
  final Tape tape;

  /// What the user should be told, when the change is not what the key
  /// usually does.
  final TapeNotice? notice;

  const TapeChanged(this.tape, {this.notice});

  @override
  List<Object?> get props => [tape, notice];
}

/// Closing a bracket was refused because its inside cannot be computed; the
/// bracket stays open with everything typed in it, and ⌫ repairs it
/// (Section 5.3, "An error inside a bracket").
final class TapeBracketFailed extends TapeOutcome {
  /// The step that failed, with both operands for the toast.
  final ChainFailed failure;

  const TapeBracketFailed(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// The key was refused by the tape and nothing changed.
final class TapeRefused extends TapeOutcome {
  /// Why.
  final TapeRefusal reason;

  const TapeRefused(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// The key was refused by the number being typed and nothing changed.
final class TapeEntryRefused extends TapeOutcome {
  /// Why.
  final EntryRefusal reason;

  const TapeEntryRefused(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// A unit key was refused on the finished value and nothing changed.
final class TapeUnitRefused extends TapeOutcome {
  /// Why, with the alternative reading a fourth press points at.
  final UnitKeyRefused refusal;

  const TapeUnitRefused(this.refusal);

  @override
  List<Object?> get props => [refusal];
}

/// The row of chips at the top of the display (term 2.1) and what the entry
/// keys do to it: a function key opens a named chip, digits and units fill
/// the active one, and ⌫ steps back through what was typed and then through
/// the chips themselves.
///
/// A new number typed straight after a finished value seals the chip on
/// its typed value and starts the new one beside it (rule 4.5). A converted
/// chip keeps its exact quantity for as long as its digits are still the
/// conversion's spelling, so 6.222yd stays 14,336 ticks through that split,
/// or through a digit typed and deleted again (rule 4.15).
///
/// Operators chain left to right (rule 4.6): an operator seals the active
/// chip and opens the next one under it, the running total is offered as
/// Calc after every operator with values on both sides, and = lands it as a
/// result chip or, when the dimension table refuses the step, as an error
/// chip (Section 5.3).
///
/// Brackets set the priority (Section 7): [( )] opens a bracket chip whose
/// inside is a tape of its own, every key types into it until [( )] closes
/// it, and the closed bracket takes one place in the chain with the exact
/// value its inside folds to. One level only: while one is open the key
/// closes it and [openNewBracket] is refused before any key is routed
/// inside, so the inner tape never sees a bracket.
///
/// The tape is a value; every key returns a new tape or a refusal. The
/// strip's answers are not the tape's.
///
/// The tape carries the calculator settings (Appendix C) so that one value
/// decides how its chips are read, re-spelled and rendered: the ton
/// definition is what a typed "78 ton" weighs when it is typed and what a
/// weight re-spells at, and every setting is what [formatter] renders a
/// chip by. A setting never changes a stored value (rule 4.14): a typed
/// ton remembers the definition it was typed under, and [withPreferences]
/// is the same chips under new settings, which the caller re-renders.
class Tape extends Equatable {
  /// The label of the result = lands.
  static const String calcKey = 'Calc';

  /// The chips, left to right, in the order they were made; only the last
  /// one can be active.
  final List<TapeChip> chips;

  /// The settings the chips are read, re-spelled and rendered by.
  final CalculatorPreferences preferences;

  const Tape({
    this.chips = const [],
    this.preferences = CalculatorPreferences.defaults,
  });

  /// How many pounds make a ton, as the parser and the ladder read a ton
  /// typed now. A ton typed earlier keeps the definition it was typed under
  /// ([ValueChip.poundsPerTon]), so a "78 ton" typed at 2,240 lb is never
  /// re-read at 2,000.
  int get poundsPerTon => preferences.poundsPerTon;

  /// Reads finished entries as quantities.
  QuantityParser get parser => QuantityParser(poundsPerTon: poundsPerTon);

  /// Renders a chip's value under the settings.
  QuantityFormatter get formatter =>
      QuantityFormatter(preferences: preferences);

  /// The same chips under new settings; a setting never changes a stored
  /// value (rule 4.14). A result keeps its value and renders anew: 22.28
  /// ton reads 19.89 ton under the long ton, the weight unchanged. A typed
  /// ton keeps the definition it was typed under ([ValueChip.poundsPerTon]):
  /// a 78 ton typed at 2,000 lb still weighs 156,000 lb under 2,240, with
  /// or without a digit still open after it, and only a ton typed after the
  /// change reads the new definition, a ton a split starts included (78ton
  /// 5 then [Ton] stamps the 5ton with the setting it was typed under). A
  /// ton converted from pounds keeps its exact weight while its digits are
  /// still the conversion's spelling (rule 4.15): 2000lbs then [Ton] reads
  /// 1ton worth 2,000 lb, and ⌫ then [Ton] after a change to the long ton
  /// still reads 2,000 lb, because the chip is still that conversion; a
  /// digit typed into it makes it a typed ton under the new setting. The
  /// chips are untouched, so going back to the first setting gives the
  /// first tape. The text stays as
  /// typed (Appendix C: "your entries keep their typed units"); whether it
  /// should re-spell to 69.64 ton is the doc owner's call.
  Tape withPreferences(CalculatorPreferences preferences) =>
      Tape(chips: chips, preferences: preferences);

  /// Converts and raises finished values.
  UnitLadder get ladder => UnitLadder(poundsPerTon: poundsPerTon);

  /// Folds the chips into the running total.
  ChainEvaluator get evaluator => ChainEvaluator(
    parser: parser,
    arithmetic: ChainArithmetic(system: preferences.system),
  );

  /// Whether nothing has been typed.
  bool get isEmpty => chips.isEmpty;

  /// The chip the keyboard writes into, or `null` when the last chip is a
  /// result, an error, or a sealed value.
  ValueChip? get active {
    if (chips.isEmpty) return null;
    if (chips.last case final ValueChip chip when chip.isActive) return chip;
    return null;
  }

  /// Whether the tape ends on an answer, so that a digit, a function key
  /// or the bracket key starts a new session (rule 4.9); the session itself
  /// is the caller's to bank. A bracket opened here without banking starts
  /// a chain of its own beside the result.
  bool get endsWithResult => chips.isNotEmpty && chips.last is ResultChip;

  /// Whether the tape ends on an error chip. The prototype banks an error
  /// like a result when the next digit, function key or bracket key
  /// arrives, so typing starts a new session here too; only ⌫ acts on the
  /// chip in place (rule 4.12). A bracket opened here without banking still
  /// folds, because an error chip ends only its own chain.
  bool get endsWithError => chips.isNotEmpty && chips.last is ErrorChip;

  bool get _hasResult => chips.any((chip) => chip is ResultChip);

  /// The bracket the keypad types into, or `null` when none is open.
  BracketChip? get openBracket {
    if (chips.isEmpty) return null;
    if (chips.last case final BracketChip bracket when bracket.isOpen) {
      return bracket;
    }
    return null;
  }

  bool get _endsWithClosedBracket =>
      chips.isNotEmpty && chips.last is BracketChip && openBracket == null;

  /// The value under each function key, by chip key: the last readable
  /// value typed under the key wins, a bare number has no key, and a value
  /// still being typed is not a value yet. What the deterministic rules
  /// read (the prototype's `getDims`).
  Map<String, Quantity> get namedValues => {
    for (final chip in chips)
      if (chip case ValueChip(
        :final key?,
      ) when chip.isReadable && chip.trigFunction == null)
        key: ?chip.value(parser),
  };

  /// The answer a trig chip still being typed offers ([SIN] 38 offers Sine
  /// 0.615661, scenario S95; [ACOS] 0.5 offers Arccosine 60°): accepting it
  /// is landing it as a result chip with [append], which leaves the same
  /// tape as 38 [SIN] would (rule 4.11). `null` when no trig chip is
  /// active, before its number is typed, or when its function has no value
  /// there ([ValueChip.asksAnUndefinedTrig]).
  ///
  /// ÷ builds the ratio for ATAN (rule 4.11; Section 6, "Trig chips in a
  /// chain"; [ArctangentReach]): the operand of an Arctangent chip reaches across every ÷ and
  /// bare number typed after it, and the answer names the operand it took,
  /// so [ATAN] 16 ÷ 12 offers Arctangent(16 ÷ 12) 53.13° beside the Calc
  /// 1.33 of the same digits (scenario S111; walkthrough 23.3). A divisor
  /// of 0 leaves no ratio.
  Answer? get trigAnswer {
    if (active == null) return null;
    final question = _trigQuestionAsked;
    if (question == null) return null;
    final (:function, :operand, :key) = question;
    final answer = function.of(operand);
    if (answer == null) return null;
    return Answer(key: key, value: answer, sources: [function.key]);
  }

  /// [answer], a trig answer an edit behind it left standing, rebuilt on
  /// this tape, the chips before it, so that it survives the edit (rule
  /// 4.8; scenario S102). It is rebuilt on the operand chip both orders
  /// land (Sine · degrees 40° rebuilds Sine 0.642788), on the Calc a
  /// postfix key answered (making the 78 of 78 ÷ 89 [ATAN] a 70 rebuilds
  /// Arctangent 38.19°), or on the ratio an Arctangent builds across ÷,
  /// named for its new digits (Arctangent(14 ÷ 12) 49.4°). `null` when the
  /// edit leaves no answer, and the chip is removed (Section 5.5, "A result
  /// that can no longer be computed").
  ResultChip? rebuiltTrigAnswer(ResultChip answer) {
    if (_trigQuestionAsked case (
      :final function,
      :final operand,
      :final key,
    ) when key != function.key) {
      final rebuilt = TrigFunction.rebuilt(
        ResultChip(
          key: function.key,
          value: answer.value,
          operator: answer.operator,
        ),
        Scalar(operand),
      );
      if (rebuilt == null) return null;
      return ResultChip(
        key: key,
        value: rebuilt.value,
        operator: rebuilt.operator,
      );
    }
    final operand = switch (chips.lastOrNull) {
      final ValueChip chip when chip.trigFunction != null => chip.trigOperand,
      final ValueChip chip => chip.value(parser),
      ResultChip(:final value) => value,
      _ => null,
    };
    if (operand == null) return null;
    return TrigFunction.rebuilt(answer, operand);
  }

  ({TrigFunction function, double operand, String key})?
  get _trigQuestionAsked {
    final question = _trigQuestion;
    if (question == null) return null;
    final (:chip, :reach) = question;
    final function = chip.trigFunction;
    final number = chip.bareNumber;
    if (function == null || number == null) return null;
    if (reach == null) {
      return (function: function, operand: number, key: function.key);
    }
    final ratio = reach.ratio;
    if (ratio == null) return null;
    return (
      function: function,
      operand: ratio,
      key: '${function.key}(${reach.spelling})',
    );
  }

  /// The trig chip the tape ends on, with the ratio it reaches across ÷
  /// ([ArctangentReach]) when it does; `null` when the tape ends on
  /// anything else.
  ({ValueChip chip, ArctangentReach? reach})? get _trigQuestion {
    for (var index = chips.length - 1; index >= 0; index--) {
      final chip = chips[index];
      if (chip is! ValueChip) return null;
      if (chip.trigFunction == null) continue;
      if (index == chips.length - 1) return (chip: chip, reach: null);
      final reach = ArctangentReach.from(chips, index);
      if (reach == null || reach.end != chips.length) return null;
      return (chip: chip, reach: reach);
    }
    return null;
  }

  /// A trig key (Section 3.5; rule 4.11), pressed after its number or
  /// before it.
  ///
  /// After a bare number with no key (38 [SIN]) it answers at once: the
  /// number becomes the trig chip [SIN] 38 would have opened, sealed, and
  /// the answer lands beside it as a result chip labelled by
  /// [TrigFunction.key] (scenario S57). Both orders land that one tape: the
  /// operand chip carries its unit, Sine · degrees 38°, and the result
  /// follows it (rule 4.11, which the prototype's S105 does not follow). On a
  /// value with a unit it is refused ([TapeRefusal.trigNeedsAPlainAngle]),
  /// and [TAN] on an odd quarter turn is refused with nothing landed
  /// ([TapeRefusal.tangentUndefined], scenario S94).
  ///
  /// Anywhere else it opens a trig chip the way a function key opens a
  /// named one ([SIN] then 38, scenario S95): on an empty chip it renames
  /// it, keeping its operator, so 5 × [SIN] 30 = is 2.5; a filled chip is
  /// sealed first, a named bare number (Sides 6) included; a fresh trig
  /// chip after a result starts a new calculation the caller banks, as a
  /// digit does (scenario S98; [endsWithResult]). The chip offers its
  /// answer as [trigAnswer], an operator seals it into the chain at its
  /// answer (Sine 89° × 56 = 55.99, scenarios S97 and S101), and a unit key
  /// on its number is refused ([TapeRefusal.trigTakesAnAngle]). Inside a
  /// bracket the key is refused, as a function key is.
  ///
  /// ASIN, ACOS and ATAN take a ratio and answer an angle. After a bare
  /// number they answer at once, and the number becomes the trig chip the
  /// prefix order lands, Arcsine · a ratio 0.5, so both orders land one
  /// tape (0.5 [ASIN] is Arcsine 30°, scenario S70; rule 4.11); after
  /// a division still being typed they land its Calc first and answer from
  /// it, 12 ÷ 23 [ATAN] is Calc 0.52 then Arctangent 27.55° (walkthroughs
  /// 16.2 and 16.3); on a finished tape they take a Calc that is a ratio,
  /// 12 ÷ 23 = [ASIN] is Arcsine 31.45° (Section 3.5). ASIN and ACOS
  /// refuse a ratio beyond ±1, and every inverse key refuses an angle,
  /// such as Pitch 30° still being typed ([TapeRefusal.ratioOutOfRange]).
  ///
  /// A forward key takes an angle the tape has answered (0.5 [ASIN] [SIN]
  /// is Sine 0.5, scenario S106). A trig key never takes the wrong kind of
  /// answer, nor the ratio a forward key answered: 38 [SIN] [COS] and 1800
  /// [COS] [ACOS] open a fresh chip instead (scenarios S96, S106), which
  /// the caller banks the tape for, as for any fresh chip after a result.
  /// When the key takes the answer the tape goes on.
  TapeOutcome pressTrigKey(TrigFunction function) {
    if (openBracket != null) {
      return const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic);
    }
    final chip = active;
    if (chip != null && chip.entry.isEmpty) {
      return _replaceLast(_asTrigChip(chip, function));
    }
    if (chip == null) {
      if (_answerTheKeyTakes(function) case final operand?) {
        return _answeredOn(this, function, operand);
      }
    } else if (function.isInverse) {
      if (_inverseKeyOn(chip, function) case final outcome?) return outcome;
    } else if (chip.key == null && chip.operator == null) {
      switch (chip.value(parser)) {
        case Scalar(value: final degrees) || Angle(:final degrees):
          return _answeredAfter(chip, function, degrees);
        case final Quantity _:
          return const TapeRefused(TapeRefusal.trigNeedsAPlainAngle);
        case null:
          break;
      }
    }
    final tape = _withFractionClosedAsInches();
    if (tape._unfinished case final refusal?) return refusal;
    return TapeChanged(
      tape._sealed().append(_asTrigChip(const ValueChip(), function)),
    );
  }

  ValueChip _asTrigChip(ValueChip chip, TrigFunction function) => chip.copyWith(
    key: () => function.key,
    keyWantsUnit: false,
    readsDegrees: !function.isInverse,
  );

  Quantity? _answerTheKeyTakes(TrigFunction function) {
    if (chips.isEmpty || chips.last is! ResultChip) return null;
    final ResultChip(:key, :value) = chips.last as ResultChip;
    return switch (value) {
      Scalar() when function.isInverse && TrigFunction.named(key) == null =>
        value,
      Angle() when !function.isInverse => value,
      _ => null,
    };
  }

  TapeOutcome? _inverseKeyOn(ValueChip chip, TrigFunction function) {
    if (chip.operator == Operator.divide && chip.isReadable) {
      return switch (runningTotal) {
        ChainValue(value: final ratio, isCalculation: true) => _answeredOn(
          append(ResultChip(key: calcKey, value: ratio)),
          function,
          ratio,
        ),
        ChainFailed() => pressEquals(),
        ChainValue() || ChainEmpty() => null,
      };
    }
    if (chip.trigFunction != null) return null;
    final value = chip.value(parser);
    if (value is Angle) return const TapeRefused(TapeRefusal.ratioOutOfRange);
    if (chip.key != null || chip.operator != null || value == null) {
      return null;
    }
    return _answeredOn(
      _replaceActive(_asTrigChip(chip, function)),
      function,
      value,
    );
  }

  static TapeOutcome _answeredOn(
    Tape tape,
    TrigFunction function,
    Quantity operand,
  ) {
    if (function.answerTo(operand) case final answer?) {
      return TapeChanged(
        tape.append(ResultChip(key: function.key, value: answer)),
      );
    }
    if (operand is! Scalar && operand is! Angle) {
      return const TapeRefused(TapeRefusal.trigNeedsAPlainAngle);
    }
    return TapeRefused(
      function.isInverse
          ? TapeRefusal.ratioOutOfRange
          : TapeRefusal.tangentUndefined,
    );
  }

  TapeOutcome _answeredAfter(
    ValueChip chip,
    TrigFunction function,
    double degrees,
  ) {
    final answer = function.of(degrees);
    if (answer == null) {
      return const TapeRefused(TapeRefusal.tangentUndefined);
    }
    return TapeChanged(
      _replaceActive(
        _asTrigChip(chip, function),
      ).append(ResultChip(key: function.key, value: answer)),
    );
  }

  /// A function key opens a new active chip with that name (rule 4.1); on
  /// an empty active chip it renames it instead. A chip holding a compound
  /// left open (18ft 8), a fraction without a unit (7/16) or a bare number
  /// under a function key (Length 18) cannot be left (Section 5.1, "Finish
  /// this value first"; Appendix D): the guard runs on fresh entry too. A
  /// single bare number with no key seals as a scalar, and so does one under
  /// a key that takes a plain number — [keyWantsUnit] is false under Pitch,
  /// Slope and Sides (Section 5.1: "A bare number under a key that takes a
  /// plain number … is complete"), the caller's call the way [pressUnit]
  /// takes [holdsLengthOnly]. [readsDegrees] is true under Pitch, whose
  /// plain number is an angle (rule 4.10).
  ///
  /// Every key that leaves the chip — a function key, an operator, =, the
  /// bracket key — first closes a fraction typed right after whole inches as
  /// inches (5ft 7in 1/2 reads 5ft 7-1/2in) and refuses a fraction still
  /// waiting for its unit key with "Finish the fraction. Press a unit key"
  /// (Section 6; owner decisions of 4 October 2026).
  TapeOutcome pressFunctionKey(
    String key, {
    bool keyWantsUnit = true,
    bool readsDegrees = false,
  }) {
    if (openBracket != null) {
      return const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic);
    }
    final chip = active;
    if (chip != null && chip.entry.isEmpty) {
      return _replaceLast(
        chip.copyWith(
          key: () => key,
          keyWantsUnit: keyWantsUnit,
          readsDegrees: readsDegrees,
        ),
      );
    }
    final tape = _withFractionClosedAsInches();
    if (tape._unfinished case final refusal?) return refusal;
    return TapeChanged(
      tape._sealed().append(
        ValueChip(
          key: key,
          keyWantsUnit: keyWantsUnit,
          readsDegrees: readsDegrees,
        ),
      ),
    );
  }

  Tape _withFractionClosedAsInches() {
    final chip = active;
    if (chip == null || !chip.entry.endsWithFractionAfterWholeInches) {
      return this;
    }
    return switch (chip.entry.closeWith(Unit.inch)) {
      EntryChanged(:final buffer) => _replaceActive(
        chip.copyWith(entry: buffer),
      ),
      EntryOutcome() => this,
    };
  }

  TapeOutcome? get _unfinished {
    final chip = active;
    if (chip != null && chip.asksAnUndefinedTrig) {
      return const TapeRefused(TapeRefusal.trigCannotAnswer);
    }
    if (chip == null || chip.isReadable) return null;
    if (chip.entry.endsWithUnitlessFraction) {
      return const TapeEntryRefused(EntryRefusal.fractionNeedsUnit);
    }
    return const TapeRefused(TapeRefusal.finishThisValueFirst);
  }

  /// A digit or a decimal point goes into the active chip, or starts a bare
  /// one when nothing is active. A second decimal point types degrees,
  /// minutes and seconds (rule 4.10: 23.16.45 is 23°16'45") where the chip
  /// takes an angle ([ValueChip.takesAnAngle]), and is refused under a key
  /// that does not (Section 5.4, "A second decimal point makes an angle").
  TapeOutcome typeDigit(String digit) {
    if (openBracket case final bracket?) {
      return _inside(bracket, (inner) => inner.typeDigit(digit));
    }
    if (_endsWithClosedBracket) {
      return const TapeRefused(TapeRefusal.addAnOperatorFirst);
    }
    final chip = active ?? const ValueChip();
    return _entry(
      chip,
      chip.entry.typeDigit(digit, readsAngles: chip.takesAnAngle),
    );
  }

  /// The D:M:S key (Section 3.5), one segment per press: 38 [D:M:S] 30
  /// [D:M:S] 45 types 38°30'45", the second decimal point made visible
  /// (walkthrough 16.3). It reads the number being typed under the same
  /// keys the point does ([ValueChip.takesAnAngle]); a value with a unit is
  /// refused ([TapeRefusal.dmsNeedsAPlainAngle]: "D:M:S is an angle format,
  /// not a length"), and with nothing typed the key asks for a number.
  ///
  /// On a finished angle answer the same key converts: Arcsine 31.45° reads
  /// 31°26'56" and back, the value untouched (Section 6, "Conversions
  /// offered": angle answers offer their D:M:S spelling). A pitch answer
  /// keeps its own cycle and is left as it is. Inside a bracket the key is
  /// refused, as a function key is.
  TapeOutcome pressDmsKey() {
    if (openBracket != null) {
      return const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic);
    }
    final chip = active;
    if (chip == null) {
      return switch (chips.lastOrNull) {
        ResultChip(value: final Angle angle, :final key, :final operator) =>
          _replaceLastChip(
            ResultChip(
              key: key,
              value: _respelledAngle(angle),
              operator: operator,
            ),
          ),
        _ => const TapeRefused(TapeRefusal.typeANumberFirst),
      };
    }
    if (chip.entry.isEmpty) {
      return const TapeRefused(TapeRefusal.typeANumberFirst);
    }
    if (chip.entry.tokens.any((token) => token.unit != null)) {
      return const TapeRefused(TapeRefusal.dmsNeedsAPlainAngle);
    }
    if (!chip.takesAnAngle) {
      return const TapeEntryRefused(EntryRefusal.secondDecimalPoint);
    }
    return _entry(chip, chip.entry.closeDegreesMinutesSeconds());
  }

  /// The Read-as pill (term 2.14; rule 4.10): the other reading of a bare
  /// number that could reasonably be read two ways, or `null` when nothing
  /// asks. The pill shows the reading the calculator chose and names where
  /// the next tap goes; [reInput] takes it.
  ///
  /// A number being read as degrees offers its D:M:S reading, 38.30 as
  /// 38°30' (walkthrough 16.4): the number under a forward trig key, that
  /// number once ÷ or another operator has moved on from it ([SIN] 12.1 ÷
  /// 3.5 still offers the 12.1, S114), a bare number added to an angle
  /// answer (60° + 12.1, which reads as degrees), and the number a postfix
  /// trig key answered, where the pill reads "Re-input" because the answer
  /// is rebuilt (S91). An open keypad is not context: a bare 38.30 with no
  /// key offers nothing, and an inverse trig key never asks, since a ratio
  /// has no minutes. A D:M:S reading offers the way back while its seconds
  /// are still empty; once they are typed the reading is settled. The
  /// offers under Pitch and Slope are CA-1303's second PR.
  ReadAsOffer? get readAsOffer {
    if (openBracket != null) return null;
    if (_chipReadAsDegrees case (:final index, :final chip)) {
      return _angleOffer(index, chip);
    }
    return null;
  }

  /// Takes the Read-as pill ([readAsOffer]): the chip is re-read from the
  /// digits as they were typed, never converted (30.45 becomes 30°45', a
  /// different angle, not 30°27'), so a full lap comes home to exactly what
  /// was typed. A trig answer standing after the chip was computed from
  /// the old reading and is rebuilt on the new one (38.30 [SIN] 0.619779
  /// becomes 0.622515), or removed when it cannot be (Section 5.5).
  TapeOutcome reInput() {
    final offer = readAsOffer;
    if (offer == null) return const TapeRefused(TapeRefusal.nothingToReInput);
    final index = offer.chipIndex;
    if (chips[index] case final ValueChip chip) {
      final before = _with([
        ...chips.sublist(0, index),
        chip.copyWith(
          entry: offer.next,
          exact: () => null,
          poundsPerTon: () => null,
        ),
      ]);
      final after = chips.sublist(index + 1);
      if (offer.rebuildsAnAnswer) {
        if (after.firstOrNull case final ResultChip answer) {
          return TapeChanged(
            _with([
              ...before.chips,
              ?before.rebuiltTrigAnswer(answer),
              ...after.sublist(1),
            ]),
          );
        }
      }
      return TapeChanged(_with([...before.chips, ...after]));
    }
    return const TapeRefused(TapeRefusal.nothingToReInput);
  }

  ({int index, ValueChip chip})? get _chipReadAsDegrees {
    final chip = active;
    if (chip == null) {
      if (chips.length < 2 || !_answersForwardTrig(chips.length - 1)) {
        return null;
      }
      return switch (chips[chips.length - 2]) {
        final ValueChip operand when _isSoloForwardTrig(operand) => (
          index: chips.length - 2,
          chip: operand,
        ),
        _ => null,
      };
    }
    final index = chips.length - 1;
    if (chip.operator == null) {
      return _isSoloForwardTrig(chip) ? (index: index, chip: chip) : null;
    }
    final addsToAnAngle =
        chip.key == null &&
        _isSolo(chip) &&
        (chip.operator == Operator.add || chip.operator == Operator.subtract);
    if (addsToAnAngle && index > 0) {
      if (chips[index - 1] case ResultChip(value: Angle())) {
        return (index: index, chip: chip);
      }
    }
    for (var behind = index - 1; behind >= 0; behind--) {
      final earlier = chips[behind];
      if (earlier is! ValueChip) return null;
      if (_isSoloForwardTrig(earlier)) return (index: behind, chip: earlier);
      if (earlier.key != null) return null;
    }
    return null;
  }

  bool _isSoloForwardTrig(ValueChip chip) =>
      _isSolo(chip) && chip.trigFunction?.isInverse == false;

  bool _answersForwardTrig(int index) =>
      index < chips.length &&
      switch (chips[index]) {
        ResultChip(:final key) => switch (TrigFunction.named(key)) {
          TrigFunction(isInverse: false) => true,
          _ => false,
        },
        _ => false,
      };

  static bool _isSolo(ValueChip chip) =>
      chip.entry.tokens.length == 1 &&
      chip.entry.tokens.single.unit == null &&
      chip.entry.tokens.single.denominator == null &&
      chip.entry.tokens.single.digits.isNotEmpty;

  ReadAsOffer? _angleOffer(int index, ValueChip chip) {
    final token = chip.entry.tokens.single;
    final rebuilds = _answersForwardTrig(index + 1);
    if (token.isDegreesMinutesSeconds) {
      if (token.typedAs case final typed?) {
        return ReadAsOffer(
          chipIndex: index,
          from: NumberReading.degreesMinutesSeconds,
          to: NumberReading.degrees,
          next: _plain(typed),
          rebuildsAnAnswer: rebuilds,
        );
      }
      return null;
    }
    if (token.digits.endsWith('.')) return null;
    final promoted = _readAsDegreesMinutesSeconds(token.digits);
    if (promoted == null) return null;
    return ReadAsOffer(
      chipIndex: index,
      from: NumberReading.degrees,
      to: NumberReading.degreesMinutesSeconds,
      next: promoted,
      rebuildsAnAnswer: rebuilds,
    );
  }

  static EntryBuffer _plain(String digits) =>
      EntryBuffer(List.unmodifiable([Token(digits: digits)]));

  static EntryBuffer? _readAsDegreesMinutesSeconds(String digits) {
    if (!digits.contains('.')) return null;
    return switch (_plain(digits).typeDigit('.', readsAngles: true)) {
      EntryChanged(:final buffer) => buffer,
      EntryOutcome() => null,
    };
  }

  Angle _respelledAngle(Angle angle) => switch (angle.spelling) {
    AngleSpelling.degrees => angle.spelledAs(
      AngleSpelling.degreesMinutesSeconds,
    ),
    AngleSpelling.degreesMinutesSeconds => angle.spelledAs(
      AngleSpelling.degrees,
    ),
    AngleSpelling.risePerFoot || AngleSpelling.grade => angle,
  };

  /// [/] goes into the active chip.
  TapeOutcome typeFraction() {
    if (openBracket case final bracket?) {
      return _inside(bracket, (inner) => inner.typeFraction());
    }
    final chip = active;
    if (chip == null) return const TapeRefused(TapeRefusal.nothingBeingTyped);
    return _entry(chip, chip.entry.typeFraction());
  }

  /// A unit key closes the number being typed, or converts and raises a
  /// finished value (rule 4.3). Straight after a result with a unit it
  /// converts the result in place, and keeps its dimension: Calc 10ft then
  /// [Feet] is refused rather than raised. [holdsLengthOnly] is true under
  /// a key that can only hold a length. [takesAGrade] is true under
  /// Slope, whose bare number is a % grade: a length unit there is refused
  /// (Section 5.4, "A slope is a % grade, not a length"), so [Slope] 6
  /// [Feet] cannot become a length the solver never reads. Pitch takes a
  /// length as inches of rise per 12in of run (rule 4.10). An angle typed
  /// as degrees, minutes and seconds is refused a unit under any key
  /// (Section 5.4, "That value is already an angle").
  TapeOutcome pressUnit(
    Unit unit, {
    bool holdsLengthOnly = false,
    bool takesAGrade = false,
  }) {
    if (openBracket case final bracket?) {
      return _inside(
        bracket,
        (inner) => inner.pressUnit(
          unit,
          holdsLengthOnly: holdsLengthOnly,
          takesAGrade: takesAGrade,
        ),
      );
    }
    if (_endsWithClosedBracket) {
      return const TapeRefused(TapeRefusal.groupCannotTakeUnit);
    }
    final chip = active;
    if (chip == null || chip.entry.isEmpty) {
      final last = chips.isEmpty ? null : chips.last;
      if (chip == null && last is ResultChip && last.value is! Scalar) {
        return _convertResult(last, unit);
      }
      return TapeRefused(
        _hasResult
            ? TapeRefusal.unitsApplyWhileTyping
            : TapeRefusal.typeANumberFirst,
      );
    }
    if (chip.entry.isDegreesMinutesSeconds) {
      return const TapeEntryRefused(EntryRefusal.alreadyAnAngle);
    }
    if (chip.trigFunction != null) {
      return const TapeRefused(TapeRefusal.trigTakesAnAngle);
    }
    if (takesAGrade && unit.dimension == Dimension.length) {
      return const TapeRefused(TapeRefusal.slopeTakesAGrade);
    }
    if (chip.entry.isOpen) {
      return _entry(
        chip,
        chip.entry.closeWith(unit, holdsLengthOnly: holdsLengthOnly),
      );
    }
    final value = chip.value(parser);
    if (value == null) {
      return const TapeUnitRefused(
        UnitKeyRefused(UnitKeyRefusal.cannotConvert),
      );
    }
    final outcome = ladder.press(
      tokens: chip.entry.tokens,
      value: value,
      key: unit,
      holdsLengthOnly: holdsLengthOnly,
    );
    return switch (outcome) {
      UnitKeyConverted(:final value, :final tokens) ||
      UnitKeyRaised(
        :final value,
        :final tokens,
      ) => _replaceLast(_respelled(chip, value, tokens)),
      UnitKeyRefused() => TapeUnitRefused(outcome),
    };
  }

  /// The running total of the tape as far as it can be computed: the Calc
  /// the strip offers when it is a calculation, the error the strip goes
  /// silent for, or nothing.
  ChainOutcome get runningTotal => evaluator.fold(chips);

  /// An operator seals the active chip and opens the next one under it; on
  /// an operator chip still waiting for its number it changes the operator,
  /// and on the divisor ÷ 0 reopened it also drops the error chip, since the
  /// division that failed is gone (5 ÷ 0 = × 2 = is Calc 10 on a clean
  /// tape, where the prototype refuses the key). After a result, or a
  /// sealed value, the operator chains off it. With nothing before it the
  /// press explains itself ("Type a value first").
  TapeOutcome pressOperator(Operator operator) {
    if (openBracket case final bracket?) {
      return _inside(bracket, (inner) => inner.pressOperator(operator));
    }
    final chip = active;
    if (chip != null) {
      if (chip.operator != null && chip.entry.isEmpty) {
        return (_withDivisorRepaired ?? this)._replaceLast(
          chip.copyWith(operator: () => operator),
        );
      }
      if (chip.entry.isEmpty) {
        return const TapeRefused(TapeRefusal.typeAValueFirst);
      }
      final tape = _withFractionClosedAsInches();
      if (tape._unfinished case final refusal?) return refusal;
      return TapeChanged(tape._sealed().append(ValueChip(operator: operator)));
    }
    final last = chips.isEmpty ? null : chips.last;
    final hasLeftHandSide = switch (last) {
      ResultChip() || BracketChip() => true,
      ValueChip() => last.isReadable,
      ErrorChip() || null => false,
    };
    if (!hasLeftHandSide) {
      return const TapeRefused(TapeRefusal.typeAValueFirst);
    }
    return TapeChanged(append(ValueChip(operator: operator)));
  }

  /// = lands the running total as a Calc result chip, or a Dimension Error
  /// (or Division by zero) chip when a step is refused. With no operator
  /// applied, or an operator still waiting for its number, it says what it
  /// needs; a number with no unit cannot be left. With a bracket open it
  /// closes the bracket first (Section 7) and then lands the Calc: a
  /// reopened bracket the edit emptied is brought back as it was and the
  /// Calc lands on the restored group, with the notice kept.
  ///
  /// ÷ 0 as the last step lands its error chip and reopens the divisor
  /// empty after it, keeping its operator (Section 5, "Division by zero";
  /// Appendix D): the next number typed is the new divisor and = computes
  /// the chain, because only the last chip can be active. A second 0 under
  /// the reopened divisor keeps the one error chip (5 ÷ 0 = 0 = is still
  /// 5 | Division by zero | ÷ _), so the tape never holds two in a row. A
  /// ÷ 0 earlier in the chain, or a bracket worth zero, lands the error chip
  /// at the end the way a Dimension Error does.
  ///
  /// An Arctangent that starts the tape and reaches across a ÷ lands its
  /// angle, not the Calc of its digits: [ATAN] 16 ÷ 12 = is Arctangent(16 ÷
  /// 12) 53.13° (walkthrough 23.3; [trigAnswer]). One that continues a
  /// chain lands the chain, with the ratio sealed into its angle (rule
  /// 4.6): 5 + [ATAN] 16 ÷ 12 = is Calc 58.13°.
  TapeOutcome pressEquals() {
    if (openBracket != null) {
      return switch (closeBracket()) {
        TapeChanged(:final tape, notice: null) => _landedAfterClose(tape),
        TapeChanged(:final tape, notice: TapeNotice.bracketEditCancelled) =>
          _landedAfterClose(tape, notice: TapeNotice.bracketEditCancelled),
        final TapeChanged removed => removed,
        final TapeOutcome refused => refused,
      };
    }
    final tape = _withFractionClosedAsInches();
    if (tape.active case final chip? when !chip.entry.isEmpty) {
      if (tape._unfinished case final refusal?) return refusal;
    }
    if (tape._trigQuestion case (
      chip: ValueChip(operator: null),
      reach: ArctangentReach(),
    )) {
      if (tape.trigAnswer case final answer?) {
        return TapeChanged(
          tape.append(ResultChip(key: answer.key, value: answer.value)),
        );
      }
    }
    return switch (tape.runningTotal) {
      ChainValue(:final value, isCalculation: true) => TapeChanged(
        tape.append(ResultChip(key: calcKey, value: value)),
      ),
      ChainFailed(error: CalculationError.divisionByZero)
          when tape._endsOnTheFailedDivisor =>
        TapeChanged(tape._withDivisorReopened()),
      ChainFailed(:final error) => TapeChanged(tape.append(ErrorChip(error))),
      ChainValue() || ChainEmpty() when !identical(tape, this) => TapeChanged(
        tape,
        notice: TapeNotice.fractionClosedNothingToCompute,
      ),
      ChainValue() ||
      ChainEmpty() => const TapeRefused(TapeRefusal.nothingToCompute),
    };
  }

  bool get _endsOnTheFailedDivisor {
    if (chips.last case ValueChip(operator: Operator.divide)) {
      return evaluator.fold(chips.sublist(0, chips.length - 1)) is! ChainFailed;
    }
    return false;
  }

  Tape _withDivisorReopened() {
    final divisor = chips.last as ValueChip;
    final before = chips.sublist(0, chips.length - 1);
    return _with([
      ...before,
      if (before.last is! ErrorChip)
        const ErrorChip(CalculationError.divisionByZero),
      divisor.copyWith(
        entry: const EntryBuffer(),
        exact: () => null,
        poundsPerTon: () => null,
        isActive: true,
      ),
    ]);
  }

  Tape? get _withDivisorRepaired {
    if (chips.length < 2 || chips[chips.length - 2] is! ErrorChip) return null;
    if (active case ValueChip(operator: null) || null) return null;
    return _with([...chips.sublist(0, chips.length - 2), chips.last]);
  }

  TapeOutcome _landedAfterClose(Tape closed, {TapeNotice? notice}) =>
      switch (closed.pressEquals()) {
        TapeChanged(:final tape) => TapeChanged(tape, notice: notice),
        TapeOutcome() => TapeChanged(
          closed,
          notice: notice ?? TapeNotice.bracketClosedNothingToCompute,
        ),
      };

  /// ⌫ removes one token step from the active chip; with nothing left to
  /// remove it drops the last chip — a result or an error included — and
  /// makes the value before it active again, so an error is repaired in
  /// place (rule 4.12, walkthrough 21.2); a closed bracket before the
  /// dropped chip is reopened instead. On the divisor ÷ 0 reopened it drops
  /// the error chip and keeps the divisor open (5 ÷ 0 = ⌫ is 5 | ÷ _, as
  /// the prototype has it), and a second ⌫ reopens the dividend.
  ///
  /// Straight after ) it reopens the bracket in place, with the keypad
  /// typing into its last value again (Section 7, "Editing a bracket").
  /// Inside a bracket a chip has no name, so a bare one emptied by ⌫ has
  /// nothing left to show and is dropped, which makes the next ⌫ remove
  /// the bracket itself ("on an empty bracket it removes the bracket"),
  /// one that ⌫ reopened included; an emptied operator chip stays, since
  /// it still holds the operator.
  TapeOutcome backspace() {
    if (openBracket case final bracket?) {
      if (bracket.inner.isEmpty) return TapeChanged(_removeBracket(bracket));
      return _inside(bracket, (inner) => inner._backspaceInsideBracket());
    }
    if (chips.isNotEmpty) {
      if (chips.last case final BracketChip closed) {
        return _replaceLastChip(_reopened(closed));
      }
    }
    final chip = active;
    if (chip != null && !chip.entry.isEmpty) {
      return _entry(chip, chip.entry.backspace());
    }
    if (chips.isEmpty) return const TapeRefused(TapeRefusal.nothingToDelete);
    if (_withDivisorRepaired case final repaired?) return TapeChanged(repaired);
    final remaining = chips.sublist(0, chips.length - 1);
    if (remaining.isEmpty) return TapeChanged(_with(remaining));
    final before = remaining.sublist(0, remaining.length - 1);
    return TapeChanged(switch (remaining.last) {
      final ValueChip previous => _with([
        ...before,
        previous.copyWith(isActive: true),
      ]),
      final BracketChip closed => _with([...before, _reopened(closed)]),
      ResultChip() || ErrorChip() => _with(remaining),
    });
  }

  TapeOutcome _backspaceInsideBracket() {
    final outcome = backspace();
    if (outcome case TapeChanged(:final tape)) {
      if (tape.active case final chip?
          when chip.entry.isEmpty && chip.operator == null) {
        return TapeChanged(_with(tape.chips.sublist(0, tape.chips.length - 1)));
      }
    }
    return outcome;
  }

  /// [( )]: one key opens a bracket and, pressed again, closes it, so the
  /// keypad can never nest one.
  TapeOutcome pressBracket() =>
      openBracket == null ? openNewBracket() : closeBracket();

  /// Opens a bracket. An operator waiting for its number takes the bracket
  /// as its value ("+("); a finished value is sealed and the bracket starts
  /// beside it as a value of its own, since two values never combine (rule
  /// 4.5), and drops out of the Calc the way any value beside another does.
  /// An empty named chip refuses the key, because a bracket holds numbers,
  /// units, fractions and operators only (Appendix D). While one is open a
  /// second is refused ("One bracket at a time").
  TapeOutcome openNewBracket() {
    if (openBracket != null) {
      return const TapeRefused(TapeRefusal.oneBracketAtATime);
    }
    final chip = active;
    if (chip != null && chip.entry.isEmpty && chip.key != null) {
      return const TapeRefused(TapeRefusal.bracketCannotTakeName);
    }
    if (chip != null && chip.entry.isEmpty) {
      return _replaceLastChip(BracketChip(operator: chip.operator));
    }
    final tape = _withFractionClosedAsInches();
    if (tape._unfinished case final refusal?) return refusal;
    return TapeChanged(tape._sealed().append(const BracketChip()));
  }

  /// Closes the open bracket: an operator left without a value at the end
  /// is dropped, the inside is folded to one value of whatever dimension
  /// it comes to, and the chip turns solid. Nothing between ( and ) removes
  /// the bracket with a notice, and the tape is what it was before ( was
  /// pressed: the operator before it waits again as an empty operator
  /// chip, and a value before it is active again, so a digit continues it.
  /// Closing empty a bracket that ⌫ reopened cancels the edit instead and
  /// brings the group back as it was. An inside that cannot be computed
  /// keeps the bracket open (Section 5.3).
  TapeOutcome closeBracket() {
    final bracket = openBracket;
    if (bracket == null) return const TapeRefused(TapeRefusal.noBracketToClose);
    var inner = _with(bracket.inner)._withFractionClosedAsInches();
    if (inner.active case final chip? when chip.entry.isEmpty) {
      inner = _with(inner.chips.sublist(0, inner.chips.length - 1));
    }
    if (inner.isEmpty) {
      if (bracket.original != null) return _restored(bracket);
      return TapeChanged(
        _removeBracket(bracket),
        notice: TapeNotice.emptyBracketsRemoved,
      );
    }
    if (inner._unfinished case final refusal?) return refusal;
    final total = inner.runningTotal;
    if (total case final ChainFailed failure) return TapeBracketFailed(failure);
    if (total is ChainEmpty) {
      return const TapeRefused(TapeRefusal.finishThisValueFirst);
    }
    return _replaceLastChip(
      bracket.copyWith(
        inner: inner._sealed().chips,
        isOpen: false,
        original: () => null,
      ),
    );
  }

  TapeOutcome _restored(BracketChip bracket) => TapeChanged(
    _replaceLastWith(
      bracket.copyWith(
        inner: bracket.original,
        isOpen: false,
        original: () => null,
      ),
    ),
    notice: TapeNotice.bracketEditCancelled,
  );

  /// The tape with a chip added at the end. The active chip, if any, is
  /// sealed first, so that only the last chip can ever be active.
  Tape append(TapeChip chip) {
    final sealed = _sealed();
    return sealed._with([...sealed.chips, chip]);
  }

  TapeOutcome _inside(
    BracketChip bracket,
    TapeOutcome Function(Tape inner) key,
  ) {
    return switch (key(_with(bracket.inner))) {
      TapeChanged(:final tape, :final notice) => TapeChanged(
        _replaceLastWith(bracket.copyWith(inner: tape.chips)),
        notice: notice,
      ),
      final TapeOutcome refused => refused,
    };
  }

  BracketChip _reopened(BracketChip closed) {
    final inner = closed.inner;
    final reopened = closed.copyWith(
      isOpen: true,
      original: () => closed.inner,
    );
    if (inner.isNotEmpty) {
      if (inner.last case final ValueChip last) {
        return reopened.copyWith(
          inner: [
            ...inner.sublist(0, inner.length - 1),
            last.copyWith(isActive: true),
          ],
        );
      }
    }
    return reopened;
  }

  Tape _removeBracket(BracketChip bracket) {
    final before = chips.sublist(0, chips.length - 1);
    if (bracket.operator case final operator?) {
      return _with([...before, ValueChip(operator: operator)]);
    }
    if (before.isNotEmpty && before.last is ValueChip) {
      final previous = before.last as ValueChip;
      return _with([
        ...before.sublist(0, before.length - 1),
        previous.copyWith(isActive: true),
      ]);
    }
    return _with(before);
  }

  TapeOutcome _replaceLastChip(TapeChip chip) =>
      TapeChanged(_replaceLastWith(chip));

  Tape _replaceLastWith(TapeChip chip) =>
      _with([...chips.sublist(0, chips.length - 1), chip]);

  TapeOutcome _entry(ValueChip chip, EntryOutcome outcome) => switch (outcome) {
    EntryChanged(:final buffer) => _replaceLast(
      chip.copyWith(
        entry: buffer,
        exact: buffer.isEmpty ? () => null : null,
        poundsPerTon: () => _tonTypedUnder(chip, buffer),
      ),
    ),
    EntryCarried(:final buffer) => TapeChanged(
      _replaceActive(
        chip.copyWith(
          entry: buffer,
          poundsPerTon: () => _tonTypedUnder(chip, buffer),
        ),
      ),
      notice: TapeNotice.carriedOver,
    ),
    EntrySplit(:final finished, :final started) => TapeChanged(
      _replaceActive(chip.copyWith(entry: finished)).append(
        ValueChip(
          entry: started,
          poundsPerTon: _tonTypedUnder(const ValueChip(), started),
        ),
      ),
    ),
    EntryRefused(:final reason) => TapeEntryRefused(reason),
  };

  ValueChip _respelled(ValueChip chip, Quantity value, List<Token> tokens) {
    final spelled = EntryBuffer(List.unmodifiable(tokens));
    return chip.copyWith(
      entry: spelled,
      exact: () => (value: value, spelled: spelled),
      poundsPerTon: () => _tonTypedUnder(chip, spelled),
    );
  }

  int? _tonTypedUnder(ValueChip chip, EntryBuffer buffer) {
    final tons = _tonTokens(buffer);
    if (tons == 0) return null;
    return tons > _tonTokens(chip.entry) ? poundsPerTon : chip.poundsPerTon;
  }

  int _tonTokens(EntryBuffer entry) =>
      entry.tokens.where((token) => token.unit == Unit.ton).length;

  TapeOutcome _convertResult(ResultChip result, Unit unit) {
    final outcome = ladder.press(
      tokens: ladder.speller.spell(result.value),
      value: result.value,
      key: unit,
    );
    return switch (outcome) {
      UnitKeyConverted(:final value) => TapeChanged(
        _with([
          ...chips.sublist(0, chips.length - 1),
          ResultChip(key: result.key, value: value, operator: result.operator),
        ]),
      ),
      UnitKeyRaised() => const TapeUnitRefused(
        UnitKeyRefused(UnitKeyRefusal.keepsLength),
      ),
      UnitKeyRefused() => TapeUnitRefused(outcome),
    };
  }

  Tape _sealed() {
    final chip = active;
    if (chip == null) return this;
    return _replaceActive(chip.copyWith(isActive: false));
  }

  TapeOutcome _replaceLast(ValueChip chip) => TapeChanged(_replaceActive(chip));

  Tape _replaceActive(ValueChip chip) {
    if (active == null) return append(chip);
    return _with([...chips.sublist(0, chips.length - 1), chip]);
  }

  Tape _with(List<TapeChip> chips) =>
      Tape(chips: chips, preferences: preferences);

  @override
  List<Object?> get props => [chips, preferences];
}
