part of 'calculator_bloc.dart';

/// The calculator as the display area reads it: the engine's tape, which
/// group of function keys is up, and what the last key press said.
///
/// The tape is the engine's own [Tape] value (UX Design Doc Sections 1.1 and
/// 4; CA-1087): every typed value, every answer and every bracket, with the
/// active chip at its end while one is being typed. The bloc never derives
/// a second copy of it. A key the tape refuses leaves the tape as it was and
/// is carried as [refusal] for the toast; a key the tape takes with a word
/// about it carries that word as [notice]. Both are those of the last key
/// only: the next key clears them. The same refusal twice in a row is one
/// state, so a listener that must speak twice listens to the key, not the
/// state (S1b).
///
/// The getters at the end are what the page renders today, read straight
/// off the tape with its formatter; T1a (CA-1092) owns the display's final
/// shape.
class CalculatorState extends Equatable {
  /// The tape of chips, with the preferences it is rendered by.
  final Tape tape;

  /// Index of the group of function keys shown above the number pad.
  final int currentGroupIndex;

  /// What the tape said when it took the last key, or `null`.
  final TapeNotice? notice;

  /// The last key's refusal, or `null` when the tape took it. Never a
  /// [TapeChanged].
  final TapeOutcome? refusal;

  /// Creates a [CalculatorState].
  const CalculatorState({
    this.tape = const Tape(),
    this.currentGroupIndex = 0,
    this.notice,
    this.refusal,
  });

  /// An empty tape, the first group up, nothing said.
  factory CalculatorState.initial() => const CalculatorState();

  /// A copy with the given fields replaced. [notice] and [refusal] take a
  /// `Function()?` so that `null` (clear it) and absent (keep it) are told
  /// apart.
  CalculatorState copyWith({
    Tape? tape,
    int? currentGroupIndex,
    TapeNotice? Function()? notice,
    TapeOutcome? Function()? refusal,
  }) => CalculatorState(
    tape: tape ?? this.tape,
    currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
    notice: notice != null ? notice() : this.notice,
    refusal: refusal != null ? refusal() : this.refusal,
  );

  /// The System of units the tape renders by, as the keyboard names it.
  UnitSystem get currentUnitSystem => switch (tape.preferences.system) {
    MeasurementSystem.imperial => UnitSystem.imperial,
    MeasurementSystem.metric => UnitSystem.metric,
  };

  /// Whether a value is being typed, inside an open bracket too.
  bool get isTyping => tape.beingTyped != null;

  /// The id the label row names: the function key of the value being typed
  /// (`null` for a bare number, as every value inside a bracket is), else
  /// the key of the last answer or the error the last chip carries, else
  /// nothing.
  String? get labelKeyId => switch (_chipRead) {
    ValueChip(:final key) => key,
    ResultChip(:final key) => key,
    ErrorChip(:final error) => error.name,
    BracketChip() || null => null,
  };

  /// The text of the value row: the value being typed, inside an open
  /// bracket too, else the last chip; an error chip has no value to show.
  String get valueText => switch (_chipRead) {
    null || ErrorChip() => '',
    final chip => _valueTextOf(chip),
  };

  TapeChip? get _chipRead => tape.beingTyped ?? tape.chips.lastOrNull;

  /// The tape as chips the display area draws: a value chip is its key over
  /// its text, an answer its key over the formatted value, a bracket its
  /// inside between parentheses, each led by the operator that joins it to
  /// the chain, as the prototype's tape reads (2 | +(3×4) | ×5 | Calc70); an
  /// error chip carries its error as the label the page titles it by.
  List<CoreCalculatorChip> get chipsList => [
    for (final chip in tape.chips)
      CoreCalculatorChip(
        label: switch (chip) {
          ValueChip(:final key) => key,
          ResultChip(:final key) => key,
          ErrorChip(:final error) => error.name,
          BracketChip() => null,
        },
        value: switch (chip) {
          ErrorChip() => null,
          _ => _valueTextOf(chip),
        },
        type: switch (chip) {
          ValueChip(isActive: true) => CoreCalculatorChipType.active,
          ValueChip() || BracketChip() => CoreCalculatorChipType.editable,
          ResultChip() || ErrorChip() => CoreCalculatorChipType.disabled,
        },
      ),
  ];

  String _valueTextOf(TapeChip chip) => switch (chip) {
    ValueChip(:final operator, :final entry) =>
      '${_lead(operator)}${entry.text}',
    ResultChip(:final operator, :final value) =>
      '${_lead(operator)}${tape.formatter.format(value)}',
    BracketChip(:final operator, :final inner, :final isOpen) =>
      '${_lead(operator)}(${inner.map(_valueTextOf).join()}${isOpen ? '' : ')'}',
    ErrorChip() => '',
  };

  static String _lead(Operator? operator) => operator?.symbol ?? '';

  @override
  List<Object?> get props => [tape, currentGroupIndex, notice, refusal];
}
