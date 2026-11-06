part of 'calculator_bloc.dart';

/// What the last key left to say in a toast (UX Design Doc Section 5): the
/// editing guards of 5.5, the unit guards of 5.2 that fire on a reopened
/// chip, and the one result an edit had to remove. The page shows it every
/// time a key raises it ([CalculatorState.toastsRaised]); the words are the
/// formatter's.
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

/// "`<Key>` removed — can't recompute from the new value" (Section 5.5).
final class CalculatorResultRemovedToast extends CalculatorToast {
  /// The id of the result that was removed.
  final String key;

  const CalculatorResultRemovedToast({required this.key});

  @override
  List<Object?> get props => [key];
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
/// (Section 5.2); [tail] is the number typed after a finished length, which
/// a length unit would finish, or `null`.
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

/// "Editing this group. Press ( ) to close it. If you type nothing,
/// everything stays as it was." — a closed bracket reopened, shown the first
/// three times only (Section 5.6; Section 7, "Editing a bracket").
final class CalculatorEditingGroupToast extends CalculatorToast {
  const CalculatorEditingGroupToast();

  @override
  List<Object?> get props => const [];
}

/// "`<Key>` keeps `<value>`": [unit] pressed again under the dimension
/// [key], which cannot hold an area or a volume (Section 5.2).
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
