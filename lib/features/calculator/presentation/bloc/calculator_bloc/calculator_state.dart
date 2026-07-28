part of 'calculator_bloc.dart';

/// Represents the current state of the calculator display area.
class CalculatorState extends Equatable {
  /// The label of the input currently being entered, or `null` if idle.
  final String? activeInputLabel;

  /// The raw string value being typed by the user.
  final String currentInputValue;

  /// The numeric portion of the current input, stored separately to avoid
  /// round-trip parsing.
  final String currentNumericValue;

  /// Whether the user is currently in the middle of an input sequence.
  final bool isTyping;

  /// The list of inputs that have been finalized and converted into chips.
  final List<CoreCalculatorChip> completedChips;

  /// Map of finalized labels to their numeric values, avoiding regex parsing.
  final Map<String, double> finalizedValues;

  /// The label for the computed result (e.g. "Pitch"), or `null` if none.
  final String? resultLabel;

  /// The value for the computed result, or `null` if none.
  final String? resultValue;

  /// A standalone chip representing the final computed result.
  final CoreCalculatorChip? resultChip;

  /// Label for the dependent key shown in the display area value section.
  /// `null` means no dependent key is displayed.
  final String? dependentKeyLabel;

  /// Value for the dependent key shown in the display area value section.
  /// `null` means no dependent key is displayed.
  final String? dependentKeyValue;

  /// Index of the currently selected group of calculator keys.
  final int currentGroupIndex;

  /// The unit system (imperial or metric) currently in use.
  final UnitSystem currentUnitSystem;

  /// Creates a [CalculatorState].
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

  /// Returns the initial [CalculatorState] with all fields at their defaults.
  factory CalculatorState.initial() => const CalculatorState();

  /// Returns a copy of this state with the specified fields replaced.
  ///
  /// Nullable fields ([activeInputLabel], [resultLabel], [resultValue],
  /// [resultChip], [dependentKeyLabel], [dependentKeyValue]) use a
  /// `Function()?` wrapper to distinguish `null` (clear the field) from
  /// absent (keep the current value).
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

  List<CoreCalculatorChip> get chipsList => [
        ...completedChips,
        if (isTyping)
          if (activeInputLabel case final label?)
            CoreCalculatorChip(
              label: label,
              value: currentInputValue,
              type: CoreCalculatorChipType.active,
            ),
        if (resultChip case final chip?) chip,
      ];

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
