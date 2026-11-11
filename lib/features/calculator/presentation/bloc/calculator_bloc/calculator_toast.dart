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

/// "`<Key>` needs a length": the weight [unit] under the dimension [key]
/// (Section 5.2), on fresh entry as on a reopened chip; [tail] is the number
/// typed after a finished length, which a length unit would finish, whole
/// with its fraction, or `null`.
final class CalculatorNeedsLengthToast extends CalculatorToast {
  /// The id of the dimension key.
  final String key;

  /// The weight unit that was refused.
  final Unit unit;

  /// The digits typed after the finished length, or `null`.
  final String? tail;

  const CalculatorNeedsLengthToast({
    required this.key,
    required this.unit,
    this.tail,
  });

  @override
  List<Object?> get props => [key, unit, tail];
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
