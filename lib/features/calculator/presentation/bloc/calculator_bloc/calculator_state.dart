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
/// The getters at the end are what the page renders, read straight off the
/// tape with its formatter: the label and value rows, the chips, and the
/// strip (CA-1088, S1b) in the fixed order of Section 1.2 — what the
/// engine answers today, with no ranking, no trade follow-ons, no bind
/// offers and no remembered values, which the ladder's rungs (G1 to G3)
/// add as one more call in the same mapping. T1a (CA-1092) owns the
/// display's final shape.
class CalculatorState extends Equatable {
  /// The label the equals key reads while a chain continues from a result
  /// (rule 4.9: "only the equals key relabels to Ans while the chain is
  /// open"); never a chip's key.
  static const String ansKey = 'Ans';

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

  /// Row 1 of the strip (Section 1.2), in a fixed order with no ranking: a
  /// pending trig chip's answer leads (rule 4.4). While an operator has
  /// values on both sides the running total follows it as Calc, in place of
  /// the rule answers, so that the user always sees the running total
  /// before the next operator and = lands it (term 2.15; walkthrough 12.3,
  /// "Multiplication 2. Strip: Calc: 8ft 0in"). Otherwise the rule answers
  /// the named values earn, minus the ones already landed as result chips
  /// (Section 8: after Pitch-rise is accepted the other two spellings stay
  /// on offer). Empty after an error chip ("after an error the area stays
  /// empty on purpose") and while a bracket is open (Section 7: no preview
  /// until the group closes).
  List<CalculatorSuggestion> get suggestions {
    if (_stripIsSilent) return const [];
    return [
      if (tape.trigAnswer case final answer?) _answer(answer.key, answer.value),
      if (tape.runningTotal case ChainValue(:final value, isCalculation: true))
        CalculatorSuggestion(
          key: Tape.calcKey,
          value: value,
          kind: CalculatorSuggestionKind.runningTotal,
          text: tape.formatter.format(value),
        )
      else
        for (final answer in const DeterministicRules().answersFor(
          tape.namedValues,
        ))
          if (!_hasLanded(answer.key)) _answer(answer.key, answer.value),
    ];
  }

  /// Row 2 of the strip: the value on screen in its other units (term
  /// 2.12; Section 6, "Where conversions show"), as plain values with no
  /// label. The value being typed once it is complete, else the answer the
  /// tape ends on; a typed angle is left to the Read-as pill (term 2.14),
  /// and an angle answer offers its other spelling. Empty after an error
  /// and while a bracket is open, as row 1 is.
  List<CalculatorSuggestion> get conversions {
    if (_stripIsSilent) return const [];
    final value = switch (_chipRead) {
      final ValueChip chip when chip.trigFunction == null => switch (chip.value(
        tape.parser,
      )) {
        Angle() || Scalar() || null => null,
        final value => value,
      },
      ResultChip(:final value) => value,
      _ => null,
    };
    if (value == null) return const [];
    return [
      for (final spelling in const UnitConverter().offersFor(value))
        CalculatorSuggestion(
          key: null,
          value: spelling,
          kind: CalculatorSuggestionKind.conversion,
          text: tape.formatter.format(spelling),
        ),
    ];
  }

  /// The id the equals key is named by: the first suggestion's key when
  /// there is one (term 2.15: "the equals key takes the name of the first
  /// suggestion"; whether the name fits on the key is the page's call),
  /// [ansKey] when that suggestion is the Calc of a chain continuing from
  /// a result (rule 4.9; a chip with no operator starts a chain and a result
  /// chip restarts it, Section 7), `null` for the = sign.
  String? get equalsKeyId => switch (suggestions.firstOrNull) {
    null => null,
    CalculatorSuggestion(kind: CalculatorSuggestionKind.runningTotal)
        when _chainStartsOnAResult =>
      ansKey,
    CalculatorSuggestion(:final key) => key,
  };

  bool get _stripIsSilent => tape.endsWithError || tape.openBracket != null;

  CalculatorSuggestion _answer(String key, Quantity value) =>
      CalculatorSuggestion(
        key: key,
        value: value,
        kind: CalculatorSuggestionKind.answer,
        text: tape.formatter.format(value),
      );

  bool _hasLanded(String key) =>
      tape.chips.any((chip) => chip is ResultChip && chip.key == key);

  bool get _chainStartsOnAResult {
    for (final chip in tape.chips.reversed) {
      final operator = switch (chip) {
        ValueChip(:final operator) => operator,
        ResultChip(:final operator) => operator,
        BracketChip(:final operator) => operator,
        ErrorChip() => null,
      };
      if (operator == null) return chip is ResultChip;
    }
    return false;
  }

  /// The tape as chips the display area draws: a value chip is its key over
  /// its text, an answer its key over the formatted value, a bracket its
  /// inside between parentheses, each led by the operator that joins it to
  /// the chain, as the prototype's tape reads (2 | +(3×4) | ×5 | Calc70); an
  /// error chip carries its error as the label the page titles it by.
  // TODO: [CA-1092] draw a bracket with the bracketOpen and bracketClosed
  // types and its operator as the factor.
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
          ResultChip() => CoreCalculatorChipType.result,
          ErrorChip() => CoreCalculatorChipType.error,
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
