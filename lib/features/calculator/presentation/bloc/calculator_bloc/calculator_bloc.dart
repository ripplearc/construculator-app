import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

part 'calculator_event.dart';
part 'calculator_state.dart';

/// Manages the state of the calculator display area.
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
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

  static const String _riseLabel = 'Rise';
  static const String _runLabel = 'Run';
  static const String _pitchResultKey = 'pitchResult';
  static const String _lengthLabel = 'Length';
  static const String _fenceLabel = 'Fence';
  static const String _postsResultKey = 'postsResult';
  static const String _ocKey = 'oc';
  static const double _fenceOcSpacing = 6.0;

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
    if (event.label == _fenceLabel) {
      final finalizedState = _finalizeCurrentInput(state);
      emit(_computeFence(finalizedState));
      return;
    }

    final finalizedState = _finalizeCurrentInput(state);

    emit(finalizedState.copyWith(
      activeInputLabel: () => event.label,
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
        if (state.currentInputValue.isEmpty) return;
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

      final updatedChips =
          List<CoreCalculatorChip>.from(currentState.completedChips)
            ..add(newChip);

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

  CalculatorState _computePitch(CalculatorState currentState) {
    final riseValue = currentState.finalizedValues[_riseLabel];
    final runValue = currentState.finalizedValues[_runLabel];

    if (riseValue != null && runValue != null && runValue != 0) {
      final pitchDecimal = riseValue / runValue;
      final pitchString =
          double.parse(pitchDecimal.toStringAsFixed(2)).toString();

      return currentState.copyWith(
        resultLabel: () => _pitchResultKey,
        resultValue: () => pitchString,
        resultChip: () => CoreCalculatorChip(
          label: _pitchResultKey,
          value: pitchString,
          type: CoreCalculatorChipType.disabled,
        ),
      );
    }

    return currentState;
  }

  CalculatorState _computeFence(CalculatorState currentState) {
    final length = currentState.finalizedValues[_lengthLabel];
    if (length == null) return currentState;

    final posts = (length / _fenceOcSpacing).ceil() + 1;
    final postsString = posts.toString();
    final ocValueString = '${_fenceOcSpacing.toInt()}ft';

    return currentState.copyWith(
      isTyping: false,
      activeInputLabel: () => null,
      resultLabel: () => _postsResultKey,
      resultValue: () => postsString,
      resultChip: () => CoreCalculatorChip(
        label: _fenceLabel,
        value: postsString,
        type: CoreCalculatorChipType.disabled,
      ),
      dependentKeyLabel: () => _ocKey,
      dependentKeyValue: () => ocValueString,
    );
  }
}
