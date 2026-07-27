// coverage:ignore-file
part of 'calculator_bloc.dart';

class CalculatorState extends Equatable {
  final String? activeInputLabel;
  final String currentInputValue;
  final String currentNumericValue;
  final bool isTyping;
  final List<CoreCalculatorChip> completedChips;
  final Map<String, double> finalizedValues;
  final String? resultLabel;
  final String? resultValue;
  final CoreCalculatorChip? resultChip;
  final String? dependentKeyLabel;
  final String? dependentKeyValue;
  final int currentGroupIndex;
  final UnitSystem currentUnitSystem;

  const CalculatorState({
    this.activeInputLabel,
    this.currentInputValue = '',
    this.currentNumericValue = '',
    this.isTyping = false,
    this.completedChips = const [],
    this.finalizedValues = const {},
    this.resultLabel,
    this.resultValue,
    this.resultChip,
    this.dependentKeyLabel,
    this.dependentKeyValue,
    this.currentGroupIndex = 0,
    this.currentUnitSystem = UnitSystem.imperial,
  });

  factory CalculatorState.initial() => const CalculatorState();

  CalculatorState copyWith({
    String? Function()? activeInputLabel,
    String? currentInputValue,
    String? currentNumericValue,
    bool? isTyping,
    List<CoreCalculatorChip>? completedChips,
    Map<String, double>? finalizedValues,
    String? Function()? resultLabel,
    String? Function()? resultValue,
    CoreCalculatorChip? Function()? resultChip,
    String? Function()? dependentKeyLabel,
    String? Function()? dependentKeyValue,
    int? currentGroupIndex,
    UnitSystem? currentUnitSystem,
  }) {
    return CalculatorState(
      activeInputLabel:
          activeInputLabel != null ? activeInputLabel() : this.activeInputLabel,
      currentInputValue: currentInputValue ?? this.currentInputValue,
      currentNumericValue: currentNumericValue ?? this.currentNumericValue,
      isTyping: isTyping ?? this.isTyping,
      completedChips: completedChips ?? this.completedChips,
      finalizedValues: finalizedValues ?? this.finalizedValues,
      resultLabel: resultLabel != null ? resultLabel() : this.resultLabel,
      resultValue: resultValue != null ? resultValue() : this.resultValue,
      resultChip: resultChip != null ? resultChip() : this.resultChip,
      dependentKeyLabel: dependentKeyLabel != null
          ? dependentKeyLabel()
          : this.dependentKeyLabel,
      dependentKeyValue: dependentKeyValue != null
          ? dependentKeyValue()
          : this.dependentKeyValue,
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      currentUnitSystem: currentUnitSystem ?? this.currentUnitSystem,
    );
  }

  @override
  List<Object?> get props => [
        activeInputLabel,
        currentInputValue,
        currentNumericValue,
        isTyping,
        completedChips,
        finalizedValues,
        resultLabel,
        resultValue,
        resultChip,
        dependentKeyLabel,
        dependentKeyValue,
        currentGroupIndex,
        currentUnitSystem,
      ];
}
