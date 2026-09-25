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
}

/// What a key did to the tape.
sealed class TapeOutcome extends Equatable {
  const TapeOutcome();
}

/// The tape took the key.
final class TapeChanged extends TapeOutcome {
  /// The tape after the key.
  final Tape tape;

  const TapeChanged(this.tape);

  @override
  List<Object?> get props => [tape];
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
/// The tape is a value; every key returns a new tape or a refusal. Brackets
/// and the strip's other answers are not the tape's yet.
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

  /// Whether the tape ends on an answer, so that typing starts a new
  /// session (rule 4.9); the session itself is the caller's to bank.
  bool get endsWithResult => chips.isNotEmpty && chips.last is ResultChip;

  /// Whether the tape ends on an error chip. The prototype banks an error
  /// like a result when the next digit or function key arrives, so typing
  /// starts a new session here too; only ⌫ acts on the chip in place
  /// (rule 4.12).
  bool get endsWithError => chips.isNotEmpty && chips.last is ErrorChip;

  bool get _hasResult => chips.any((chip) => chip is ResultChip);

  /// A function key opens a new active chip with that name (rule 4.1); on
  /// an empty active chip it renames it instead. A chip holding a compound
  /// left open (18ft 8), a fraction without a unit (7/16) or a bare number
  /// under a function key (Length 18) cannot be left (Section 5.1, "Finish
  /// this value first"; Appendix D): the guard runs on fresh entry too. A
  /// single bare number with no key seals as a scalar.
  TapeOutcome pressFunctionKey(String key) {
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
    final chip = active ?? const ValueChip();
    return _entry(chip, chip.entry.typeDigit(digit));
  }

  /// [/] goes into the active chip.
  TapeOutcome typeFraction() {
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
      ResultChip() => true,
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
  /// place (rule 4.12, walkthrough 21.2).
  TapeOutcome backspace() {
    final chip = active;
    if (chip != null && !chip.entry.isEmpty) {
      return _entry(chip, chip.entry.backspace());
    }
    if (chips.isEmpty) return const TapeRefused(TapeRefusal.nothingToDelete);
    final remaining = chips.sublist(0, chips.length - 1);
    if (remaining.isEmpty) return TapeChanged(_with(remaining));
    if (remaining.last case final ValueChip previous) {
      return TapeChanged(
        _with([
          ...remaining.sublist(0, remaining.length - 1),
          previous.copyWith(isActive: true),
        ]),
      );
    }
    return TapeChanged(_with(remaining));
  }

  /// The tape with a chip added at the end. The active chip, if any, is
  /// sealed first, so that only the last chip can ever be active.
  Tape append(TapeChip chip) {
    final sealed = _sealed();
    return sealed._with([...sealed.chips, chip]);
  }

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
