part of 'calculator_bloc.dart';

const String _riseLabel = 'Rise';
const String _runLabel = 'Run';
const String _pitchResultKey = 'pitchResult';
const String _lengthLabel = 'Length';
const String _fenceLabel = 'Fence';
const String _postsResultKey = 'postsResult';
const String _ocKey = 'oc';
const double _fenceOcSpacing = 6.0;

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
      label: _postsResultKey,
      value: postsString,
      type: CoreCalculatorChipType.disabled,
    ),
    dependentKeyLabel: () => _ocKey,
    dependentKeyValue: () => ocValueString,
  );
}
