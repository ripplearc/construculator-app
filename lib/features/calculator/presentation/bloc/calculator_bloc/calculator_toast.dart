part of 'calculator_bloc.dart';

/// What the last key left to say in a red Alert (UX Design Doc Section 5):
/// the editing guards of 5.5 — on a reopened chip and on fresh entry alike —
/// and the results an edit had to remove. The page draws it above the key
/// sheet until its ✕ or the next key closes it, and announces it every time
/// a key raises it ([CalculatorState.toastsRaised]); the words are the
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
