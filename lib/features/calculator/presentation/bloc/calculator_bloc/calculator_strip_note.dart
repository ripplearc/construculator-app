part of 'calculator_bloc.dart';

/// A strip note (UX Design Doc Section 1.8): a short message that takes
/// the place of the suggestions in the strip's row, for what the engine
/// has to say today. One shows at a time, a warning first, then a key that
/// changed nothing.
sealed class CalculatorStripNote extends Equatable {
  const CalculatorStripNote();
}

/// Pitch holds an angle the rules cannot use (Section 5.4, "A pitch has to
/// be under 90°"): 90° or more, or 0° or less. Stays while the cause stays.
final class CalculatorPitchOutOfRangeNote extends CalculatorStripNote {
  /// Whether the pitch is at or above a right angle, else at or below 0°.
  final bool isAtLeastARightAngle;

  const CalculatorPitchOutOfRangeNote({required this.isAtLeastARightAngle});

  @override
  List<Object?> get props => [isAtLeastARightAngle];
}

/// Slope holds a grade of 0% or less, which is flat (Section 5.4). Stays
/// while the cause stays.
final class CalculatorSlopeOutOfRangeNote extends CalculatorStripNote {
  const CalculatorSlopeOutOfRangeNote();

  @override
  List<Object?> get props => const [];
}

/// The D:M:S key was pressed on a pitch answer, which has no D:M:S
/// spelling (Section 5.4, "Pitch has no D:M:S"). Closes on the next key.
final class CalculatorPitchHasNoDmsNote extends CalculatorStripNote {
  const CalculatorPitchHasNoDmsNote();

  @override
  List<Object?> get props => const [];
}

/// A prefix trig chip holds an operand its function cannot take (Section
/// 5.4, "can't answer that"): Tangent 90°, Arccosine 45. Stays while the
/// cause stays.
final class CalculatorTrigCannotAnswerNote extends CalculatorStripNote {
  /// The function that has no answer.
  final TrigFunction function;

  const CalculatorTrigCannotAnswerNote(this.function);

  @override
  List<Object?> get props => [function];
}
