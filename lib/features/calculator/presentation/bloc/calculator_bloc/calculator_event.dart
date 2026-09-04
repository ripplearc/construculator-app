// coverage:ignore-file
part of 'calculator_bloc.dart';

/// Base class for events handled by [CalculatorBloc].
sealed class CalculatorEvent extends Equatable {
  const CalculatorEvent();

  @override
  List<Object?> get props => [];
}

/// A calculator key (e.g. a labeled input) was selected.
class CalculatorKeySelected extends CalculatorEvent {
  /// The stable, locale-independent id of the selected key — never its
  /// displayed label, which changes with locale.
  final String id;

  const CalculatorKeySelected(this.id);

  @override
  List<Object?> get props => [id];
}

/// A digit key was pressed on the calculator keypad.
class CalculatorDigitPressed extends CalculatorEvent {
  /// The digit that was pressed.
  final String digit;

  const CalculatorDigitPressed(this.digit);

  @override
  List<Object?> get props => [digit];
}

/// A unit was selected for the current input.
class CalculatorUnitSelected extends CalculatorEvent {
  /// The selected unit.
  final String unit;

  const CalculatorUnitSelected(this.unit);

  @override
  List<Object?> get props => [unit];
}

/// An arithmetic operator key was pressed.
class CalculatorOperatorPressed extends CalculatorEvent {
  /// The operator that was pressed.
  final String operator;

  const CalculatorOperatorPressed(this.operator);

  @override
  List<Object?> get props => [operator];
}

/// A control action (e.g. clear, delete) was triggered.
class CalculatorControlActioned extends CalculatorEvent {
  /// The control action that was triggered.
  final ControlAction action;

  const CalculatorControlActioned(this.action);

  @override
  List<Object?> get props => [action];
}

/// A different group of calculator keys was selected.
class CalculatorGroupSelected extends CalculatorEvent {
  /// Index of the newly selected group.
  final int groupIndex;

  const CalculatorGroupSelected(this.groupIndex);

  @override
  List<Object?> get props => [groupIndex];
}

/// The active unit system (imperial or metric) was changed.
class CalculatorUnitSystemChanged extends CalculatorEvent {
  /// The newly selected unit system.
  final UnitSystem unitSystem;

  const CalculatorUnitSystemChanged(this.unitSystem);

  @override
  List<Object?> get props => [unitSystem];
}

/// The calculator state should be reset to its initial defaults.
class CalculatorResetRequested extends CalculatorEvent {
  const CalculatorResetRequested();
}
