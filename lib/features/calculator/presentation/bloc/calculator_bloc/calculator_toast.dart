part of 'calculator_bloc.dart';

/// What the last key left to say in a red Alert (UX Design Doc Section 5):
/// the editing guards of 5.5 and the unit guards of 5.2 — "Finish this value
/// first", "needs a length" and "keeps" on a reopened chip and on fresh
/// entry alike, "Can't append" on a reopened chip only — and the results an
/// edit had to remove. The page draws it above the key sheet until its ✕ or
/// the next key closes it, and announces it every time a key raises it
/// ([CalculatorState.toastsRaised]); the words are the formatter's.
sealed class CalculatorToast extends Equatable {
  const CalculatorToast();
}

/// "Finish this value first" over [value], the incomplete number as the
/// value row shows it, or `''` for an empty chip.
final class CalculatorFinishValueToast extends CalculatorToast {
  /// The incomplete number, or `''` for an empty chip.
  final String value;

  const CalculatorFinishValueToast({required this.value});

  @override
  List<Object?> get props => [value];
}

/// "Type a new first value, or press C to start again": ⌫ again on the
/// emptied first chip of a chain, which nothing before it can stand in for
/// (rule 4.8).
final class CalculatorTypeNewFirstValueToast extends CalculatorToast {
  const CalculatorTypeNewFirstValueToast();

  @override
  List<Object?> get props => const [];
}

/// "`<Key>` removed — can't recompute from the new value" (Section 5.5);
/// two results are both named, and more than two the first and how many
/// more.
final class CalculatorResultRemovedToast extends CalculatorToast {
  /// The ids of the results that were removed, in tape order; never empty.
  final List<String> keys;

  const CalculatorResultRemovedToast({required this.keys});

  @override
  List<Object?> get props => [keys];
}

/// "Can't append `<unit>` here": [unit] cannot continue the reopened
/// compound [value] (Section 5.2). The doc's other sentence there, for a
/// unit on a squared or cubed value, has no toast: a unit key on one
/// converts it instead (Section 5.2, "`<Unit>` stops at cubic"), so the
/// tape never refuses it this way.
final class CalculatorCannotAppendUnitToast extends CalculatorToast {
  /// The compound as the value row shows it.
  final String value;

  /// The unit that was refused.
  final Unit unit;

  const CalculatorCannotAppendUnitToast({
    required this.value,
    required this.unit,
  });

  @override
  List<Object?> get props => [value, unit];
}

/// "`<Key>` takes a length, not `<kind>`": the [unit] that is not a length
/// under the dimension [key] (Section 5.2), on fresh entry as on a reopened
/// chip, and after a finished length (Width 18 [Feet] 8 [Lbs]) alike: one
/// message for both key orders, whose title names the kind of the unit
/// pressed, weight, area, volume or board feet (product decision of 13
/// November 2026).
final class CalculatorNeedsLengthToast extends CalculatorToast {
  /// The id of the dimension key.
  final String key;

  /// The unit that was refused.
  final Unit unit;

  const CalculatorNeedsLengthToast({required this.key, required this.unit});

  @override
  List<Object?> get props => [key, unit];
}

/// "Pitch cannot use `<kind>`": a weight or the lumber [unit] pressed under
/// the Pitch key, which is a rise per 12in of run or an angle and never a
/// length (rule 4.10). The body names the two keys that finish the [value]
/// typed: Inch for a rise, = for degrees.
final class CalculatorPitchUnitToast extends CalculatorToast {
  /// The unit that was refused.
  final Unit unit;

  /// The number under Pitch as it was typed, without the degree sign the
  /// value row reads it with.
  final String value;

  const CalculatorPitchUnitToast({required this.unit, required this.value});

  @override
  List<Object?> get props => [unit, value];
}
/// "Editing this group. Press ( ) to close it. If you type nothing,
/// everything stays as it was." — a closed bracket reopened, shown the first
/// three times only (Section 5.6; Section 7, "Editing a bracket").
final class CalculatorEditingGroupToast extends CalculatorToast {
  const CalculatorEditingGroupToast();

  @override
  List<Object?> get props => const [];
}

/// "`<Key>` keeps `<value>`": [unit] pressed again under the dimension
/// [key], which cannot hold an area or a volume (Section 5.2), on fresh
/// entry as on a reopened chip.
final class CalculatorKeepsLengthToast extends CalculatorToast {
  /// The id of the dimension key.
  final String key;

  /// The unit that was pressed again.
  final Unit unit;

  /// The length as the value row shows it.
  final String value;

  const CalculatorKeepsLengthToast({
    required this.key,
    required this.unit,
    required this.value,
  });

  @override
  List<Object?> get props => [key, unit, value];
}

/// "Minutes must be under 60" / "Press ⌫ and type the minutes again.": the
/// digit, or the point closing the minutes, that would make the minutes or
/// the seconds of an angle 60 or more (rule 4.10; decision tree rows 172,
/// 177 and 370; CA-1372). The chip stays as it was.
final class CalculatorPartUnderSixtyToast extends CalculatorToast {
  const CalculatorPartUnderSixtyToast();

  @override
  List<Object?> get props => const [];
}

/// "Minutes have two digits" / "Press . to type the seconds, or = to finish
/// the angle.": a third digit typed into the minutes (rule 4.10; row 173).
final class CalculatorMinutesTwoDigitsToast extends CalculatorToast {
  const CalculatorMinutesTwoDigitsToast();

  @override
  List<Object?> get props => const [];
}

/// "Seconds have two digits" / "Press = or an operator to finish the
/// angle.": a third digit typed into the seconds (rule 4.10; row 174).
final class CalculatorSecondsTwoDigitsToast extends CalculatorToast {
  const CalculatorSecondsTwoDigitsToast();

  @override
  List<Object?> get props => const [];
}

/// "An angle has three parts" / "Press = or an operator to finish the
/// angle.": a point, or the D:M:S key, once the seconds are open (rule
/// 4.10; row 176).
final class CalculatorAngleThreePartsToast extends CalculatorToast {
  const CalculatorAngleThreePartsToast();

  @override
  List<Object?> get props => const [];
}
