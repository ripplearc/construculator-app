part of 'calculator_bloc.dart';

/// The icon the display draws for each operator: a bracket chip carries the
/// operator that leads into it as its factor, and the label formatter reads
/// the operator back from the icon through the same map, so the two can
/// never disagree.
const Map<Operator, CoreIconData> operatorIcons = {
  Operator.add: CoreIcons.addOperator,
  Operator.subtract: CoreIcons.subtractOperator,
  Operator.multiply: CoreIcons.multiplyOperator,
  Operator.divide: CoreIcons.divide,
};

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

  /// Whether the last key was ✕ with no value in progress, which closes the
  /// calculator and returns to Home (Section 1.1; Section 5, "Closes the
  /// calculator"). Only that key sets it: the tape refuses `/` with the same
  /// word ([TapeRefusal.nothingBeingTyped]) and `/` closes nothing, so this
  /// is not read off [refusal]. The next key clears it, as it does [notice]
  /// and [refusal].
  final bool closesCalculator;

  /// Creates a [CalculatorState].
  const CalculatorState({
    this.tape = const Tape(),
    this.currentGroupIndex = 0,
    this.notice,
    this.refusal,
    this.closesCalculator = false,
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
    bool? closesCalculator,
  }) => CalculatorState(
    tape: tape ?? this.tape,
    currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
    notice: notice != null ? notice() : this.notice,
    refusal: refusal != null ? refusal() : this.refusal,
    closesCalculator: closesCalculator ?? this.closesCalculator,
  );

  /// The System of units the tape renders by, as the keyboard names it.
  UnitSystem get currentUnitSystem => switch (tape.preferences.system) {
    MeasurementSystem.imperial => UnitSystem.imperial,
    MeasurementSystem.metric => UnitSystem.metric,
  };

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
  /// bracket too, with the reading of a bare number written after it (30°,
  /// 7%, 8in/12in) and without the operator that leads it, which the label
  /// names ("Addition" over 12); else the last chip — a closed bracket is
  /// worth its inside's value (Section 7: "Addition · (3×4)" over 12); an
  /// error chip has no value of its own: the row reads "Error" under its
  /// title (Section 5, "Dimension Error", "Division by zero"), a word the
  /// page supplies when [valueReadsError] is true.
  String get valueText => switch (_chipRead) {
    null || ErrorChip() || BracketChip(isOpen: true) => '',
    final ValueChip chip => _entryTextOf(chip),
    BracketChip(isOpen: false, :final inner) => switch (Tape(
      chips: inner,
      preferences: tape.preferences,
    ).runningTotal) {
      ChainValue(:final value) => tape.formatter.format(value),
      ChainFailed() || ChainEmpty() => '',
    },
    final chip => _valueTextOf(chip),
  };

  /// What the label row names for the chip on the display (Section 1.1):
  /// the key, the operator of a chip with no key, or a bare value ("Value"
  /// over a finished 12ft as over a 12 still typed, term 2.6: the label
  /// shows always); the reading of a bare number (rule 4.10); the inside
  /// of a closed bracket (Section 7); and whether the value is still being
  /// typed. `null` when there is no chip to read: an empty tape, or a
  /// bracket just opened with nothing in it (Section 7: "Label and value
  /// are empty").
  CalculatorDisplayLabel? get displayLabel => switch (_chipRead) {
    null => null,
    final ValueChip chip => CalculatorDisplayLabel(
      keyId: chip.key,
      operator: chip.operator,
      reading: _readingOf(chip),
      isTyping: _isStillTyping(chip),
    ),
    ResultChip(:final key) => CalculatorDisplayLabel(keyId: key),
    ErrorChip(:final error) => CalculatorDisplayLabel(keyId: error.name),
    BracketChip(isOpen: true) => null,
    BracketChip(:final operator, :final inner) => CalculatorDisplayLabel(
      operator: operator,
      bracketExpression: inner.map(_valueTextOf).join(),
    ),
  };

  /// Whether the value row reads "Error": the chip read is an error chip,
  /// or the empty divisor that ÷ 0 reopened after its Division by zero
  /// chip, so there is no number to write under the title until the next
  /// digit (Section 5; decision tree rows 143, 144, 190).
  bool get valueReadsError => switch (_chipRead) {
    ErrorChip() => true,
    ValueChip(
      entry: EntryBuffer(isEmpty: true),
      operator: Operator.divide,
      key: null,
    ) =>
      tape.openBracket == null &&
          tape.chips.length > 1 &&
          tape.chips[tape.chips.length - 2] ==
              const ErrorChip(CalculationError.divisionByZero),
    _ => false,
  };

  /// The pills under the value (Section 1.1): the Read-as offer the tape
  /// makes for the number on the display (term 2.14). A pitch answer
  /// carries no pill: the strip lists its other two readings and Pitch
  /// cycles them (Section 8, "There is no 'Pitch written as' pill").
  List<CalculatorDependentKey> get dependentKeys => [
    if (tape.readAsOffer case final offer?)
      if (tape.chips[offer.chipIndex] case final ValueChip chip)
        CalculatorReadAsPill(
          offer: offer,
          sourceText: _entryTextOf(chip),
          targetText: _withReadingSuffix(offer.next.text, offer.to),
        ),
  ];

  TapeChip? get _chipRead => tape.beingTyped ?? tape.chips.lastOrNull;

  NumberReading? _readingOf(ValueChip chip) {
    if (chip.trigFunction case final function?) {
      if (function.isInverse) return NumberReading.ratio;
      return chip.entry.isDegreesMinutesSeconds
          ? NumberReading.degreesMinutesSeconds
          : NumberReading.degrees;
    }
    if (chip.entry.isDegreesMinutesSeconds) {
      return NumberReading.degreesMinutesSeconds;
    }
    return switch (chip.key) {
      PlainNumberKeys.pitch => switch (chip.value(tape.parser)) {
        Angle(spelling: AngleSpelling.risePerFoot) ||
        Length(unit: Unit.inch) => NumberReading.risePerFoot,
        Angle() => NumberReading.degrees,
        _ => null,
      },
      PlainNumberKeys.slope when chip.bareNumber != null => NumberReading.grade,
      _ => null,
    };
  }

  bool _isStillTyping(ValueChip chip) =>
      !chip.entry.isComplete &&
      !(chip.key == null &&
          chip.trigFunction == null &&
          chip.operator != null &&
          chip.bareNumber != null);

  String _entryTextOf(ValueChip chip) {
    final reading = _readingOf(chip);
    if (reading == NumberReading.risePerFoot &&
        _isAFinishedRiseFraction(chip)) {
      return switch (chip.value(tape.parser)) {
        final value? => tape.formatter.format(value),
        null => chip.entry.text,
      };
    }
    if (reading == null || !_writesItsReading(chip, reading)) {
      return chip.entry.text;
    }
    return _withReadingSuffix(chip.entry.text, reading);
  }

  static bool _isAFinishedRiseFraction(ValueChip chip) =>
      !chip.isActive &&
      switch (chip.entry.tokens) {
        [Token(denominator: _?, unit: null)] => true,
        _ => false,
      };

  static bool _writesItsReading(ValueChip chip, NumberReading reading) =>
      switch (reading) {
        NumberReading.degrees || NumberReading.grade => chip.bareNumber != null,
        NumberReading.risePerFoot => switch (chip.entry.tokens) {
          [Token(unit: Unit.inch)] => true,
          _ => false,
        },
        NumberReading.ratio || NumberReading.degreesMinutesSeconds => false,
      };

  static String _withReadingSuffix(String text, NumberReading reading) {
    if (text.isEmpty || text.endsWith('.')) return text;
    return switch (reading) {
      NumberReading.degrees => '$text°',
      NumberReading.degreesMinutesSeconds => text,
      NumberReading.risePerFoot => '$text/${Angle.inchesPerFootOfRun}in',
      NumberReading.grade || NumberReading.ratio => '$text%',
    };
  }

  /// Row 1 of the strip (Section 1.2), in a fixed order with no ranking: a
  /// pending trig chip's answer leads (rule 4.4) when the chip stands alone
  /// or builds its own ratio across ÷ ([ATAN] 16 ÷ 12, walkthrough 23.3).
  /// While an operator has values on both sides the running total is
  /// offered as Calc, in place of the rule answers, so that the user always
  /// sees the running total before the next operator and = lands it (term
  /// 2.15; walkthrough 12.3, "Multiplication 2. Strip: Calc: 8ft 0in"); a
  /// trig chip that continues the chain (5 × [SIN] 30) follows Calc, since
  /// = banks the running total (rule 4.6). Otherwise the rule answers the
  /// named values earn, minus the ones already landed as result chips
  /// (Section 8: after Pitch-rise is accepted the other two spellings stay
  /// on offer). Empty while the chain holds an error chip or a step it
  /// cannot compute ("after an error the area stays empty on purpose";
  /// ÷ 0 before and after its =, doc line 771) and while a bracket is open
  /// (Section 7: no preview until the group closes).
  List<CalculatorSuggestion> get suggestions {
    if (_stripIsSilent || stripNote != null) return const [];
    final trigAnswer = switch (tape.trigAnswer) {
      final answer? => _answer(answer.key, answer.value),
      null => null,
    };
    final runningTotal = switch (tape.runningTotal) {
      ChainValue(:final value, isCalculation: true) => CalculatorSuggestion(
        key: Tape.calcKey,
        value: value,
        kind: CalculatorSuggestionKind.runningTotal,
        text: tape.formatter.format(value),
      ),
      _ => null,
    };
    final trigLeads = trigAnswer != null && !tape.trigAnswerContinuesAChain;
    return [
      if (trigLeads) trigAnswer,
      if (runningTotal != null)
        runningTotal
      else
        for (final answer in const DeterministicRules().answersFor(
          tape.namedValues,
        ))
          if (!_hasLanded(answer.key)) _answer(answer.key, answer.value),
      if (trigAnswer != null && !trigLeads) trigAnswer,
    ];
  }

  /// Row 2 of the strip: the value on screen in its other units (term
  /// 2.12; Section 6, "Where conversions show"), as plain values with no
  /// label. The value being typed once it is complete, else the answer the
  /// tape ends on; a typed angle is left to the Read-as pill (term 2.14),
  /// so is any number under Pitch (8in under Pitch is a rise per 12in, not
  /// a length to convert), and an angle answer offers its other spelling,
  /// except a pitch: D:M:S
  /// is not a pitch reading (Section 8), and row 1 lists its other two
  /// readings. Empty while the chain holds an error and while a bracket is
  /// open, as row 1 is, and while a note shows, since the note takes the
  /// place of both rows (Section 1.8) and the display draws it only when
  /// the strip has nothing else to show.
  List<CalculatorSuggestion> get conversions {
    if (_stripIsSilent || stripNote != null) return const [];
    final value = switch (_chipRead) {
      ValueChip(key: PlainNumberKeys.pitch) => null,
      final ValueChip chip => switch (chip.value(tape.parser)) {
        Angle() || Scalar() || null => null,
        final value => value,
      },
      ResultChip(:final key, :final value) =>
        DeterministicRules.isPitchKey(key) ? null : value,
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

  /// The suggestion = lands (Section 1.2): the first one on the strip,
  /// unless the tape ends on a result or on an operator still waiting for
  /// its number, where = says why instead of landing anything.
  CalculatorSuggestion? get equalsLands =>
      tape.endsWithResult || tape.endsWithOperator
      ? null
      : suggestions.firstOrNull;

  /// The id the equals key is named by: the key of the suggestion = lands
  /// ([equalsLands]; term 2.15: "the equals key takes the name of the first
  /// suggestion"; whether the name fits on the key is the page's call),
  /// [ansKey] when that suggestion is the Calc of a chain continuing from
  /// a result (rule 4.9; a chip with no operator starts a chain and a result
  /// chip restarts it, Section 7), `null` for the = sign, so the key never
  /// names an answer that pressing it would not land.
  String? get equalsKeyId => switch (equalsLands) {
    null => null,
    CalculatorSuggestion(kind: CalculatorSuggestionKind.runningTotal)
        when _chainStartsOnAResult =>
      ansKey,
    CalculatorSuggestion(:final key) => key,
  };

  bool get _stripIsSilent =>
      tape.openBracket != null ||
      switch (tape.runningTotal) {
        ChainFailed() => true,
        ChainValue(isCalculation: true) => false,
        ChainValue() || ChainEmpty() => _chainHoldsAnError,
      };

  bool get _chainHoldsAnError {
    for (final chip in tape.chips.reversed) {
      switch (chip) {
        case ErrorChip():
          return true;
        case ResultChip():
          return false;
        case ValueChip(:final operator) || BracketChip(:final operator):
          if (operator == null) return false;
      }
    }
    return false;
  }

  /// The note that takes the place of the suggestions (Section 1.8), or
  /// `null`: a warning first — a pitch or a slope the rules cannot use
  /// (Section 5.4), a prefix trig chip its function cannot answer — then
  /// the D:M:S key that changed nothing on a pitch answer, which the next
  /// key closes.
  CalculatorStripNote? get stripNote {
    if (_stripIsSilent) return null;
    switch (const DeterministicRules().refusalFor(tape.namedValues)) {
      case RuleRefusal.pitchOutOfRange:
        return CalculatorPitchOutOfRangeNote(
          isAtLeastARightAngle: _pitchDegrees >= DeterministicRules.rightAngle,
        );
      case RuleRefusal.flatPitchHasNoRun:
        return const CalculatorFlatPitchHasNoRunNote();
      case RuleRefusal.slopeOutOfRange:
        return const CalculatorSlopeOutOfRangeNote();
      case null:
        break;
    }
    if (tape.beingTyped case ValueChip(
      asksAnUndefinedTrig: true,
      :final trigFunction?,
    )) {
      return CalculatorTrigCannotAnswerNote(trigFunction);
    }
    if (refusal == const TapeRefused(TapeRefusal.pitchHasNoDms)) {
      return const CalculatorPitchHasNoDmsNote();
    }
    return null;
  }

  double get _pitchDegrees => switch (tape.namedValues[DimensionKey.pitch.id]) {
    Angle(:final degrees) => degrees,
    Scalar(:final value) => value,
    final Length rise => Angle.ofRiseOverRun(
      rise.preciseTicks / Length.ticksPerInch / Angle.inchesPerFootOfRun,
    ).degrees,
    _ => 0,
  };

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
  /// its text, an answer its key over the formatted value, each led by the
  /// operator that joins it to the chain, as the prototype's tape reads
  /// (2 | +(3×4) | ×5 | Calc70); an error chip carries its error as the
  /// label the page titles it by. A bracket is one chip in the face of its
  /// state (term 2.22): open while the keypad types inside it, closed once
  /// it has its ")"; it holds what was typed inside — the chip draws the
  /// parentheses — and the operator that leads it is its factor. The chips
  /// before an open bracket are inert: dimmed and deaf to a tap until it
  /// closes ("Chips before an open bracket are dimmed and cannot be tapped").
  List<CoreCalculatorChip> get chipsList {
    final waitsOnOpenBracket = tape.openBracket != null;
    return [
      for (final (index, chip) in tape.chips.indexed)
        CoreCalculatorChip(
          label: switch (chip) {
            ValueChip(:final key) => key,
            ResultChip(:final key) => key,
            ErrorChip(:final error) => error.name,
            BracketChip() => null,
          },
          value: switch (chip) {
            ErrorChip() => null,
            BracketChip(:final inner) => inner.map(_valueTextOf).join(),
            _ => _valueTextOf(chip),
          },
          factor: switch (chip) {
            BracketChip(:final operator?) => operatorIcons[operator],
            _ => null,
          },
          type: switch (chip) {
            ValueChip(isActive: true) => CoreCalculatorChipType.active,
            ValueChip() => CoreCalculatorChipType.editable,
            BracketChip(isOpen: true) => CoreCalculatorChipType.bracketOpen,
            BracketChip() => CoreCalculatorChipType.bracketClosed,
            ResultChip() => CoreCalculatorChipType.result,
            ErrorChip() => CoreCalculatorChipType.error,
          },
          inert: waitsOnOpenBracket && index < tape.chips.length - 1,
        ),
    ];
  }

  String _valueTextOf(TapeChip chip) => switch (chip) {
    final ValueChip chip => '${_lead(chip.operator)}${_entryTextOf(chip)}',
    ResultChip(:final operator, :final value) =>
      '${_lead(operator)}${tape.formatter.format(value)}',
    BracketChip(:final operator, :final inner, :final isOpen) =>
      '${_lead(operator)}(${inner.map(_valueTextOf).join()}${isOpen ? '' : ')'}',
    ErrorChip() => '',
  };

  static String _lead(Operator? operator) => operator?.symbol ?? '';

  @override
  List<Object?> get props => [
    tape,
    currentGroupIndex,
    notice,
    refusal,
    closesCalculator,
  ];
}
