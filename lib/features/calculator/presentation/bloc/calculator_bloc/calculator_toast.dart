part of 'calculator_bloc.dart';

/// What the last key left to say in a toast (UX Design Doc Section 5): the
/// editing guards of 5.5 and the one result an edit had to remove. The page
/// shows it every time a key raises it ([CalculatorState.toastsRaised]); the
/// words are the formatter's.
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
