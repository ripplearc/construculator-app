import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
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

  /// A unit key with nothing typed while a result is on the tape ("Units
  /// apply while typing"; the result's conversions are already on the
  /// strip).
  unitsApplyWhileTyping,

  /// Any key that would leave the active chip while it holds a compound
  /// left open (18ft 8) or a fraction without a unit (7/16) ("Finish this
  /// value first"). A single bare number seals as a scalar instead.
  finishThisValueFirst,

  /// [/] with no chip being typed.
  nothingBeingTyped,

  /// ⌫ on an empty tape.
  nothingToDelete,
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
/// The tape is a value; every key returns a new tape or a refusal. Chain
/// arithmetic, brackets and the strip's answers are not the tape's: they
/// read it and add result chips to it (A3).
class Tape extends Equatable {
  /// The chips, left to right, in the order they were made.
  final List<Chip> chips;

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

  /// Whether nothing has been typed.
  bool get isEmpty => chips.isEmpty;

  /// The chip the keyboard writes into, or `null` when the last chip is a
  /// result, an error, or a sealed value.
  InputChip? get active {
    if (chips.isEmpty) return null;
    if (chips.last case final InputChip chip when chip.isActive) return chip;
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
  /// left open (18ft 8) or a fraction without a unit (7/16) cannot be left
  /// (Section 5.1, "Finish this value first"): the guard runs on fresh
  /// entry too. A single bare number seals as a scalar.
  TapeOutcome pressFunctionKey(String key) {
    final chip = active;
    if (chip != null && chip.entry.isEmpty) {
      return _replaceLast(chip.copyWith(key: () => key));
    }
    if (chip != null && !chip.isReadable) {
      return const TapeRefused(TapeRefusal.finishThisValueFirst);
    }
    return TapeChanged(_sealed().append(InputChip(key: key)));
  }

  /// A digit or a decimal point goes into the active chip, or starts a bare
  /// one when nothing is active.
  TapeOutcome typeDigit(String digit) {
    final chip = active ?? const InputChip();
    return _entry(chip, chip.entry.typeDigit(digit));
  }

  /// [/] goes into the active chip.
  TapeOutcome typeFraction() {
    final chip = active;
    if (chip == null) return const TapeRefused(TapeRefusal.nothingBeingTyped);
    return _entry(chip, chip.entry.typeFraction());
  }

  /// A unit key closes the number being typed, or converts and raises a
  /// finished value (rule 4.3). [holdsLengthOnly] is true under a key that
  /// can only hold a length.
  TapeOutcome pressUnit(Unit unit, {bool holdsLengthOnly = false}) {
    final chip = active;
    if (chip == null || chip.entry.isEmpty) {
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
      UnitKeyRaised(:final value, :final tokens) => _replaceLast(
        chip.copyWith(entry: EntryBuffer(tokens), exact: () => value),
      ),
      UnitKeyRefused() => TapeUnitRefused(outcome),
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
    if (remaining.last case final InputChip previous) {
      return TapeChanged(
        _with([
          ...remaining.sublist(0, remaining.length - 1),
          previous.copyWith(isActive: true),
        ]),
      );
    }
    return TapeChanged(_with(remaining));
  }

  /// The tape with a chip added at the end.
  Tape append(Chip chip) => _with([...chips, chip]);

  // Applies an entry outcome to the active chip. A split seals the chip on
  // its typed value and starts the new one beside it (rule 4.5). Editing a
  // typed entry drops the exact quantity a conversion kept, because the
  // digits are the value again.
  TapeOutcome _entry(InputChip chip, EntryOutcome outcome) => switch (outcome) {
    EntryChanged(:final buffer) => _replaceLast(
      chip.copyWith(entry: buffer, exact: () => null),
    ),
    EntrySplit(:final finished, :final started) => TapeChanged(
      _replaceActive(
        chip.copyWith(entry: finished, exact: () => null, isActive: false),
      ).append(InputChip(entry: started)),
    ),
    EntryRefused(:final reason) => TapeEntryRefused(reason),
  };

  // Marks the active chip editable; an incomplete one has already been
  // refused by the caller.
  Tape _sealed() {
    final chip = active;
    if (chip == null) return this;
    return _replaceActive(chip.copyWith(isActive: false));
  }

  TapeOutcome _replaceLast(InputChip chip) => TapeChanged(_replaceActive(chip));

  Tape _replaceActive(InputChip chip) {
    if (active == null) return append(chip);
    return _with([...chips.sublist(0, chips.length - 1), chip]);
  }

  Tape _with(List<Chip> chips) =>
      Tape(chips: chips, poundsPerTon: poundsPerTon);

  @override
  List<Object?> get props => [chips, poundsPerTon];
}
