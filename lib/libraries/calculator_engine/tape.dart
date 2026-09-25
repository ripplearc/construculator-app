import 'package:construculator/libraries/calculator_engine/chain_evaluator.dart';
import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:construculator/libraries/calculator_engine/unit_ladder.dart';
import 'package:equatable/equatable.dart';

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
  /// arithmetic"), or [( )] on an empty named chip (Length then ( ), since
  /// a bracket holds numbers, units, fractions and operators only
  /// (Appendix D).
  bracketsHoldPlainArithmetic,

  /// ( by a path other than the [( )] key while a bracket is open ("One
  /// bracket at a time").
  oneBracketAtATime,

  /// [( )] to close with nothing open.
  noBracketToClose,
}

/// Something the tape did that the user should be told about, though
/// nothing was refused (Section 5.1 "Empty brackets"; Section 5.6).
enum TapeNotice {
  /// A bracket was closed, or = pressed, with nothing between ( and ), so
  /// the bracket was removed and the value or operator before it is active
  /// again. ⌫ on an empty bracket removes it the same way but silently, as
  /// the prototype does.
  emptyBracketsRemoved,

  /// A bracket reopened by ⌫ was emptied and then closed, or emptied and
  /// ⌫ pressed once more, so the edit was cancelled and the group is back
  /// as it was (Section 7, "Editing a bracket"; Section 5, "The group had
  /// nothing inside it, so your change was cancelled").
  bracketEditCancelled,

  /// = closed the open bracket, as it always does first (Section 7), but
  /// then found nothing to compute: the tape holds the closed bracket and
  /// the toast is the one for [TapeRefusal.nothingToCompute].
  bracketClosedNothingToCompute,
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
class Tape extends Equatable {
  /// The label of the result = lands.
  static const String calcKey = 'Calc';

  /// The chips, left to right, in the order they were made; only the last
  /// one can be active.
  final List<TapeChip> chips;

  /// How many pounds make a ton: the one setting the tape's reading and
  /// writing of values share, so a "78 ton" typed at 2,240 lb is never
  /// re-spelled at 2,000.
  final int poundsPerTon;

  const Tape({
    this.chips = const [],
    this.poundsPerTon = QuantityParser.defaultPoundsPerTon,
  });

  /// Reads finished entries as quantities.
  QuantityParser get parser => QuantityParser(poundsPerTon: poundsPerTon);

  /// Converts and raises finished values.
  UnitLadder get ladder => UnitLadder(poundsPerTon: poundsPerTon);

  /// Folds the chips into the running total.
  ChainEvaluator get evaluator => ChainEvaluator(parser: parser);

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

  /// A function key opens a new active chip with that name (rule 4.1); on
  /// an empty active chip it renames it instead. A chip holding a compound
  /// left open (18ft 8), a fraction without a unit (7/16) or a bare number
  /// under a function key (Length 18) cannot be left (Section 5.1, "Finish
  /// this value first"; Appendix D): the guard runs on fresh entry too. A
  /// single bare number with no key seals as a scalar.
  TapeOutcome pressFunctionKey(String key) {
    if (openBracket != null) {
      return const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic);
    }
    final chip = active;
    if (chip != null && chip.entry.isEmpty) {
      return _replaceLast(chip.copyWith(key: () => key));
    }
    if (chip != null && !chip.isReadable) {
      return const TapeRefused(TapeRefusal.finishThisValueFirst);
    }
    return TapeChanged(_sealed().append(ValueChip(key: key)));
  }

  /// A digit or a decimal point goes into the active chip, or starts a bare
  /// one when nothing is active.
  TapeOutcome typeDigit(String digit) {
    if (openBracket case final bracket?) {
      return _inside(bracket, (inner) => inner.typeDigit(digit));
    }
    if (_endsWithClosedBracket) {
      return const TapeRefused(TapeRefusal.addAnOperatorFirst);
    }
    final chip = active ?? const ValueChip();
    return _entry(chip, chip.entry.typeDigit(digit));
  }

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
  /// a key that can only hold a length.
  TapeOutcome pressUnit(Unit unit, {bool holdsLengthOnly = false}) {
    if (openBracket case final bracket?) {
      return _inside(
        bracket,
        (inner) => inner.pressUnit(unit, holdsLengthOnly: holdsLengthOnly),
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
  /// an operator chip still waiting for its number it changes the operator.
  /// After a result, or a sealed value, the operator chains off it. With
  /// nothing before it the press explains itself ("Type a value first").
  TapeOutcome pressOperator(Operator operator) {
    if (openBracket case final bracket?) {
      return _inside(bracket, (inner) => inner.pressOperator(operator));
    }
    final chip = active;
    if (chip != null) {
      if (chip.operator != null && chip.entry.isEmpty) {
        return _replaceLast(chip.copyWith(operator: () => operator));
      }
      if (chip.entry.isEmpty) {
        return const TapeRefused(TapeRefusal.typeAValueFirst);
      }
      if (!chip.isReadable) {
        return const TapeRefused(TapeRefusal.finishThisValueFirst);
      }
      return TapeChanged(_sealed().append(ValueChip(operator: operator)));
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
  /// needs; a number with no unit cannot be left.
  TapeOutcome pressEquals() {
    if (openBracket != null) {
      return switch (closeBracket()) {
        TapeChanged(:final tape, notice: null) => switch (tape.pressEquals()) {
          TapeRefused() => TapeChanged(
            tape,
            notice: TapeNotice.bracketClosedNothingToCompute,
          ),
          final TapeOutcome landed => landed,
        },
        final TapeChanged removed => removed,
        final TapeOutcome refused => refused,
      };
    }
    final chip = active;
    if (chip != null && !chip.entry.isEmpty && !chip.isReadable) {
      return const TapeRefused(TapeRefusal.finishThisValueFirst);
    }
    return switch (runningTotal) {
      ChainValue(:final value, isCalculation: true) => TapeChanged(
        append(ResultChip(key: calcKey, value: value)),
      ),
      ChainFailed(:final error) => TapeChanged(append(ErrorChip(error))),
      ChainValue() ||
      ChainEmpty() => const TapeRefused(TapeRefusal.nothingToCompute),
    };
  }

  /// ⌫ removes one token step from the active chip; with nothing left to
  /// remove it drops the last chip — a result or an error included — and
  /// makes the value before it active again, so an error is repaired in
  /// place (rule 4.12, walkthrough 21.2); a closed bracket before the
  /// dropped chip is reopened instead.
  ///
  /// Straight after ) it reopens the bracket in place, with the keypad
  /// typing into its last value again (Section 7, "Editing a bracket").
  /// Inside a bracket a chip has no name, so a bare one emptied by ⌫ has
  /// nothing left to show and is dropped, which makes the next ⌫ remove
  /// the bracket itself ("on an empty bracket it removes the bracket"); an
  /// emptied operator chip stays, since it still holds the operator. When
  /// the emptied bracket is one that ⌫ reopened, that ⌫ cancels the edit
  /// and brings the group back as it was.
  TapeOutcome backspace() {
    if (openBracket case final bracket?) {
      if (bracket.inner.isEmpty) {
        if (bracket.original != null) return _restored(bracket);
        return TapeChanged(_removeBracket(bracket));
      }
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
      return const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic);
    }
    if (chip != null && chip.entry.isEmpty) {
      return _replaceLastChip(BracketChip(operator: chip.operator));
    }
    if (chip != null && !chip.isReadable) {
      return const TapeRefused(TapeRefusal.finishThisValueFirst);
    }
    return TapeChanged(_sealed().append(const BracketChip()));
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
    var inner = _with(bracket.inner);
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
    if (inner.active case final chip? when !chip.isReadable) {
      return const TapeRefused(TapeRefusal.finishThisValueFirst);
    }
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
    EntryChanged(:final buffer) => _replaceLast(chip.copyWith(entry: buffer)),
    EntrySplit(:final finished, :final started) => TapeChanged(
      _replaceActive(
        chip.copyWith(entry: finished),
      ).append(ValueChip(entry: started)),
    ),
    EntryRefused(:final reason) => TapeEntryRefused(reason),
  };

  ValueChip _respelled(ValueChip chip, Quantity value, List<Token> tokens) {
    final spelled = EntryBuffer(List.unmodifiable(tokens));
    return chip.copyWith(
      entry: spelled,
      exact: () => (value: value, spelled: spelled),
    );
  }

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
      Tape(chips: chips, poundsPerTon: poundsPerTon);

  @override
  List<Object?> get props => [chips, poundsPerTon];
}
