import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

part 'calculator_event.dart';
part 'calculator_math.dart';
part 'calculator_state.dart';

/// Manages the state of the calculator display area.
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  /// Drives the calculator's group-tab UI; each entry names a tab and lists its function keys.
  static const List<({String name, List<String> keys})> functionGroups = [
    (
      name: 'basicGeometry',
      keys: ['Width', 'Length', 'Height', 'Pitch', 'Circle', 'Rise', 'Run', 'Radius'],
    ),
    (
      name: 'materials',
      keys: ['Lbs', 'Kg', 'Tons', 'Drywall', 'Fence'],
    ),
    (
      name: 'trigonometry',
      keys: ['SIN', 'COS', 'TAN'],
    ),
  ];

  CalculatorBloc() : super(CalculatorState.initial()) {
    on<CalculatorKeySelected>(_onKeySelected);
    on<CalculatorDigitPressed>(_onDigitPressed);
    on<CalculatorUnitSelected>(_onUnitSelected);
    on<CalculatorOperatorPressed>(_onOperatorPressed);
    on<CalculatorControlActioned>(_onControlActioned);
    on<CalculatorGroupSelected>(_onGroupSelected);
    on<CalculatorUnitSystemChanged>(_onUnitSystemChanged);
    on<CalculatorResetRequested>(_onResetRequested);
  }

  void _onKeySelected(
    CalculatorKeySelected event,
    Emitter<CalculatorState> emit,
  ) {
    if (event.id == _fenceLabel) {
      final finalizedState = _finalizeCurrentInput(state);
      emit(_computeFence(finalizedState));
      return;
    }

    final finalizedState = _finalizeCurrentInput(state);

    emit(finalizedState.copyWith(
      activeInputLabel: () => event.id,
      currentInputValue: '',
      currentNumericValue: '',
      isTyping: true,
      resultLabel: () => null,
      resultValue: () => null,
      resultChip: () => null,
    ));
  }

  void _onDigitPressed(
    CalculatorDigitPressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (!state.isTyping) return;

    final newValue = state.currentInputValue + event.digit;
    final newNumericValue = state.currentNumericValue + event.digit;
    emit(state.copyWith(
      currentInputValue: newValue,
      currentNumericValue: newNumericValue,
    ));
  }

  void _onUnitSelected(
    CalculatorUnitSelected event,
    Emitter<CalculatorState> emit,
  ) {
    if (!state.isTyping) return;

    final unit = event.unit.toLowerCase() == 'feet' ? 'ft' : event.unit;
    final newValue = state.currentInputValue.isEmpty
        ? unit
        : '${state.currentInputValue} $unit';

    emit(state.copyWith(currentInputValue: newValue));
  }

  void _onOperatorPressed(
    CalculatorOperatorPressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (event.operator == '=') {
      emit(_finalizeCurrentInput(state));
    }
  }

  void _onControlActioned(
    CalculatorControlActioned event,
    Emitter<CalculatorState> emit,
  ) {
    switch (event.action) {
      case ControlAction.delete:
        if (!state.isTyping || state.currentInputValue.isEmpty) return;
        final newInput = state.currentInputValue.substring(
          0,
          state.currentInputValue.length - 1,
        );
        final newNumeric = state.currentNumericValue.isEmpty
            ? ''
            : state.currentNumericValue.substring(
                0,
                state.currentNumericValue.length - 1,
              );
        emit(state.copyWith(
          currentInputValue: newInput,
          currentNumericValue: newNumeric,
        ));
      case ControlAction.clearAll:
        emit(CalculatorState.initial());
      case ControlAction.moreOptions:
        break;
    }
  }

  void _onGroupSelected(
    CalculatorGroupSelected event,
    Emitter<CalculatorState> emit,
  ) {
    emit(state.copyWith(currentGroupIndex: event.groupIndex));
  }

  void _onUnitSystemChanged(
    CalculatorUnitSystemChanged event,
    Emitter<CalculatorState> emit,
  ) {
    emit(state.copyWith(currentUnitSystem: event.unitSystem));
  }

  void _onResetRequested(
    CalculatorResetRequested event,
    Emitter<CalculatorState> emit,
  ) {
    emit(CalculatorState.initial());
  }

  CalculatorState _finalizeCurrentInput(CalculatorState currentState) {
    final activeInputLabel = currentState.activeInputLabel;
    if (currentState.isTyping &&
        activeInputLabel != null &&
        currentState.currentInputValue.isNotEmpty) {
      final newChip = CoreCalculatorChip(
        label: activeInputLabel,
        value: currentState.currentInputValue,
        type: CoreCalculatorChipType.editable,
      );

      final updatedChips = [...currentState.completedChips, newChip];

      final updatedNumericValues =
          Map<String, double>.from(currentState.finalizedValues)
            ..[activeInputLabel] =
                double.tryParse(currentState.currentNumericValue) ?? 0.0;

      var newState = currentState.copyWith(
        isTyping: false,
        completedChips: updatedChips,
        finalizedValues: updatedNumericValues,
      );

      if (updatedNumericValues.containsKey(_riseLabel) &&
          updatedNumericValues.containsKey(_runLabel)) {
        newState = _computePitch(newState);
      }

      return newState;
    }
    return currentState;
  }
}
