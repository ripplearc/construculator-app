// coverage:ignore-file
part of 'calculator_bloc.dart';

/// What the keyboard and the display area ask of the tape (UX Design Doc
/// Section 1.3). Every event names a key; the bloc presses it on the tape
/// and the tape decides what it means.
sealed class CalculatorEvent extends Equatable {
  const CalculatorEvent();

  @override
  List<Object?> get props => [];
}

/// A function key was tapped, on the strip or in the "View all" sheet.
class CalculatorKeySelected extends CalculatorEvent {
  /// The stable, locale-independent id of the key — never its displayed
  /// label, which changes with locale.
  final String id;

  const CalculatorKeySelected(this.id);

  @override
  List<Object?> get props => [id];
}

/// A digit or the decimal point was pressed.
class CalculatorDigitPressed extends CalculatorEvent {
  /// The digit, or `.`.
  final String digit;

  const CalculatorDigitPressed(this.digit);

  @override
  List<Object?> get props => [digit];
}

/// The fraction key `/` was pressed: 1 [Feet] 1 [/] 16 [Inch] is 1ft 1/16in.
class CalculatorFractionPressed extends CalculatorEvent {
  const CalculatorFractionPressed();
}

/// A unit key of the keyboard's unit column was pressed.
class CalculatorUnitSelected extends CalculatorEvent {
  /// The unit the key stands for.
  final Unit unit;

  const CalculatorUnitSelected(this.unit);

  @override
  List<Object?> get props => [unit];
}

/// An arithmetic operator key was pressed.
class CalculatorOperatorPressed extends CalculatorEvent {
  /// The operator the key stands for.
  final Operator operator;

  const CalculatorOperatorPressed(this.operator);

  @override
  List<Object?> get props => [operator];
}

/// The equals key was pressed.
class CalculatorEqualsPressed extends CalculatorEvent {
  const CalculatorEqualsPressed();
}

/// A control key was pressed: ⌫, C or the bracket key.
class CalculatorControlActioned extends CalculatorEvent {
  /// The control that was pressed.
  final ControlAction action;

  const CalculatorControlActioned(this.action);

  @override
  List<Object?> get props => [action];
}

/// A chip of the suggestion strip was tapped (Section 1.2): its answer
/// lands on the tape, or its conversion re-spells the value in place.
class CalculatorSuggestionAccepted extends CalculatorEvent {
  /// The chip that was tapped, as the state offered it.
  final CalculatorSuggestion suggestion;

  const CalculatorSuggestionAccepted(this.suggestion);

  @override
  List<Object?> get props => [suggestion];
}

/// The Read-as pill was tapped (term 2.14): the number is re-read the
/// other way, and a trig answer after it is rebuilt.
class CalculatorReadAsAccepted extends CalculatorEvent {
  const CalculatorReadAsAccepted();
}

/// The "Shown as" pill under a pitch answer was tapped (Section 8): the
/// answer is re-spelled in the next of its three spellings.
class CalculatorPitchSpellingCycled extends CalculatorEvent {
  const CalculatorPitchSpellingCycled();
}

/// The display's ✕ was tapped: it clears the value being typed.
class CalculatorActiveValueCleared extends CalculatorEvent {
  const CalculatorActiveValueCleared();
}

/// A different group of function keys was selected.
class CalculatorGroupSelected extends CalculatorEvent {
  /// Index of the newly selected group.
  final int groupIndex;

  const CalculatorGroupSelected(this.groupIndex);

  @override
  List<Object?> get props => [groupIndex];
}

/// The System of units toggle was switched.
class CalculatorUnitSystemChanged extends CalculatorEvent {
  /// The newly selected system.
  final UnitSystem unitSystem;

  const CalculatorUnitSystemChanged(this.unitSystem);

  @override
  List<Object?> get props => [unitSystem];
}

/// The calculator should start again with an empty tape.
class CalculatorResetRequested extends CalculatorEvent {
  const CalculatorResetRequested();
}
