// coverage:ignore-file
part of 'calculator_bloc.dart';

sealed class CalculatorEvent extends Equatable {
  const CalculatorEvent();

  @override
  List<Object?> get props => [];
}

class CalculatorKeySelected extends CalculatorEvent {
  final String label;

  const CalculatorKeySelected(this.label);

  @override
  List<Object?> get props => [label];
}

class CalculatorDigitPressed extends CalculatorEvent {
  final String digit;

  const CalculatorDigitPressed(this.digit);

  @override
  List<Object?> get props => [digit];
}

class CalculatorUnitSelected extends CalculatorEvent {
  final String unit;

  const CalculatorUnitSelected(this.unit);

  @override
  List<Object?> get props => [unit];
}

class CalculatorOperatorPressed extends CalculatorEvent {
  final String operator;

  const CalculatorOperatorPressed(this.operator);

  @override
  List<Object?> get props => [operator];
}

class CalculatorControlActioned extends CalculatorEvent {
  final ControlAction action;

  const CalculatorControlActioned(this.action);

  @override
  List<Object?> get props => [action];
}

class CalculatorGroupSelected extends CalculatorEvent {
  final int groupIndex;

  const CalculatorGroupSelected(this.groupIndex);

  @override
  List<Object?> get props => [groupIndex];
}

class CalculatorUnitSystemChanged extends CalculatorEvent {
  final UnitSystem unitSystem;

  const CalculatorUnitSystemChanged(this.unitSystem);

  @override
  List<Object?> get props => [unitSystem];
}

class CalculatorResetRequested extends CalculatorEvent {
  const CalculatorResetRequested();
}
