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
/// engine answers today and the sheet counts the store answers for the
/// area on screen (S2a, CA-1090), with no ranking, no cost or weight, no
/// bind offers and no remembered values, which the ladder's other rungs
/// (G1 to G3) add as one more call in the same mapping. T1a (CA-1092) owns
/// the display's final shape.
class CalculatorState extends Equatable {
  /// The label the equals key reads while a chain continues from a result
  /// (rule 4.9: "only the equals key relabels to Ans while the chain is
  /// open"); never a chip's key.
  static const String ansKey = 'Ans';

  /// The label the equals key reads while a chip is reopened for edit and
  /// the tape has a result: pressing it finishes the edit and the result is
  /// worked out again, the word the value editor sheet uses (product
  /// decision of 13 November 2026). With no result yet the key shows the =
  /// sign, and the press still lands what [equalsLands] names.
  static const String updateKey = 'Update';

  /// The tape of chips, with the preferences it is rendered by.
  final Tape tape;

  /// Index into [groupOrder] of the group of function keys shown above the
  /// number pad.
  final int currentGroupIndex;

  /// The five function-key groups by id, in the order the keyboard shows
  /// them: Appendix B's until the user drags one to a new place in the
  /// "View all" sheet (Section 1.5). Kept for the screen only; the order
  /// that survives a restart is CA-1307's.
  final List<String> groupOrder;

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

  /// The ids of the result chips the last key's edit removed, in tape
  /// order, for the message of Section 5.5 ("Arcsine removed"); empty
  /// otherwise, and cleared by the next key like [notice].
  final List<String> removedResults;

  /// How many times a key has raised a message ([toast]) since the screen
  /// opened. The same guard raised twice leaves the same [toast] in the
  /// state twice over, so the page watches this count to announce it again
  /// (rule 4.12: no key is ever silently dead).
  final int toastsRaised;

  /// Whether the message's own ✕ closed it. The next keypad key clears it
  /// with [toast] (Section 5: a red Alert closes on its ✕ or the next key,
  /// never by a timer), so the page draws [toast] while this is false.
  final bool toastClosed;

  /// The unit the last key stood for while the tape refused it, so that the
  /// toast can spell it out ("Can't append yards here", Section 5.2);
  /// `null` when the tape took the key or the key was not a unit.
  final Unit? refusedUnit;

  /// How many times a closed bracket has been reopened on this screen — C
  /// starts a fresh tape, not a fresh screen — so that the "Editing this
  /// group" toast shows for the first [groupEditToastsShown] of them only
  /// (Section 5.6).
  final int groupEditsNoticed;

  /// How many reopenings of a bracket are told how to close it.
  static const int groupEditToastsShown = 3;

  /// The sheet counts the trade store last answered for the area the bloc
  /// watches (S2a, CA-1090; requirement R9), one per stored size in the
  /// user's order; empty until the store answers. Each count carries the
  /// area it was made from, so a count of an area no longer on screen is
  /// never offered while the store's next answer is on its way.
  final List<TradeCount> materialCounts;

  /// Creates a [CalculatorState].
  const CalculatorState({
    this.tape = const Tape(),
    this.currentGroupIndex = 0,
    this.groupOrder = CalculatorGroupId.defaultOrder,
    this.notice,
    this.refusal,
    this.closesCalculator = false,
    this.removedResults = const [],
    this.toastsRaised = 0,
    this.toastClosed = false,
    this.refusedUnit,
    this.groupEditsNoticed = 0,
    this.materialCounts = const [],
  });

  /// An empty tape, the first group up, nothing said.
  factory CalculatorState.initial() => const CalculatorState();

  /// A copy with the given fields replaced. [notice] and [refusal] take a
  /// `Function()?` so that `null` (clear it) and absent (keep it) are told
  /// apart.
  CalculatorState copyWith({
    Tape? tape,
    int? currentGroupIndex,
    List<String>? groupOrder,
    TapeNotice? Function()? notice,
    TapeOutcome? Function()? refusal,
    bool? closesCalculator,
    List<String>? removedResults,
    int? toastsRaised,
    bool? toastClosed,
    Unit? Function()? refusedUnit,
    int? groupEditsNoticed,
    List<TradeCount>? materialCounts,
  }) => CalculatorState(
    tape: tape ?? this.tape,
    currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
    groupOrder: groupOrder ?? this.groupOrder,
    notice: notice != null ? notice() : this.notice,
    refusal: refusal != null ? refusal() : this.refusal,
    closesCalculator: closesCalculator ?? this.closesCalculator,
    removedResults: removedResults ?? this.removedResults,
    toastsRaised: toastsRaised ?? this.toastsRaised,
    toastClosed: toastClosed ?? this.toastClosed,
    refusedUnit: refusedUnit != null ? refusedUnit() : this.refusedUnit,
    groupEditsNoticed: groupEditsNoticed ?? this.groupEditsNoticed,
    materialCounts: materialCounts ?? this.materialCounts,
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
    ValueChip() when _readsTheReopenedDivisor => CalculatorDisplayLabel(
      keyId: CalculationError.divisionByZero.name,
    ),
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
  /// digit (Section 5; decision tree rows 143, 144, 190). While that
  /// divisor is read, the label is the error's title too, "Division by
  /// zero" over Error, with no typing dots, until a digit retypes the
  /// divisor and the label goes back to Division (product decision of 13
  /// November 2026; Section 5.3).
  bool get valueReadsError => switch (_chipRead) {
    ErrorChip() => true,
    ValueChip() => _readsTheReopenedDivisor,
    _ => false,
  };

  bool get _readsTheReopenedDivisor => switch (_chipRead) {
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
  /// on offer). An area on screen earns its sheet counts first (rule 4.4:
  /// "After Area is accepted the strip shows sheet counts (2a)"; a typed
  /// area as much as a computed one, rung 5 and Section 9), the rule
  /// answers behind them (walkthrough 11.1: "the strip moves on to drywall";
  /// walkthrough 19.1 under the fold: the three counts "plus 3 more").
  /// Empty while the chain holds an error chip or a step it
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
      else ...[
        ...materialOffers,
        ...dimensions,
      ],
      if (trigAnswer != null && !trigLeads) trigAnswer,
    ];
  }

  /// The area the trade follow-ons count (rule 4.4): the finished area on
  /// the display — an accepted Area (rung 2a) or a typed 180ft² (rung 5;
  /// Section 9: "A typed area is as good as a computed one"), never a Calc,
  /// whose rung (4) offers its cost and conversions and no sheet counts —
  /// or, with a count already on the tape, the area that count was made
  /// from, so the other sizes stay on offer after one is accepted (row 218)
  /// and while a chip before them is reopened (row 219). `null` when
  /// nothing on the display is an area, which is also when a function key
  /// has just opened an empty chip (rung 6 is the memory's, G2). The bloc
  /// watches the store for this area; nothing is counted here.
  Area? get areaForCounts {
    if (_areaOf(_chipRead) case final area?) return area;
    final chips = tape.chips;
    for (var index = chips.length - 1; index > 0; index--) {
      if (chips[index] case ResultChip(:final key) when _isACountKey(key)) {
        return _areaOf(chips[index - 1]);
      }
    }
    return null;
  }

  // The finished area a chip holds: a typed 180ft², or an Area result,
  // never a Calc (rule 4.4, rung 4) and never a count or a bracket.
  Area? _areaOf(TapeChip? chip) => switch (chip) {
    final ValueChip chip => switch (chip.value(tape.parser)) {
      final Area area => area,
      _ => null,
    },
    ResultChip(value: final Area area, :final key) when key != Tape.calcKey =>
      area,
    _ => null,
  };

  /// The sheet counts of the strip (term 2.10; Section 9, "One chip per
  /// stored size"): [materialCounts] for [areaForCounts], in the store's
  /// order, each with its size inside the chip, minus a count already
  /// landed as a result chip ("the other sizes stay on the strip", row
  /// 218). Empty while the store's answer for the area on screen is still
  /// on its way.
  List<CalculatorSuggestion> get materialOffers {
    final area = areaForCounts;
    return [
      for (final count in materialCounts)
        if (count.area == area && !_hasLandedCount(count))
          CalculatorSuggestion(
            key: count.trade.offerKey,
            value: count.value,
            kind: CalculatorSuggestionKind.materialCount,
            text: tape.formatter.format(count.value),
            count: count,
            basis: tape.formatter.formatPieceSize(count.size),
          ),
    ];
  }

  static bool _isACountKey(String key) =>
      Trade.values.any((trade) => trade.resultKey == key);

  bool _hasLandedCount(TradeCount count) => tape.chips.any(
    (chip) =>
        chip is ResultChip &&
        chip.key == count.trade.resultKey &&
        chip.value == count.value,
  );

  /// The sheet table of the detail panel (Section 1.4: "sheet sizes with
  /// the count for each"; walkthrough 11.3): every count of
  /// [materialCounts] for [areaForCounts], the ones already landed
  /// included, since the table is the store and not the strip. `null`
  /// while nothing on the display is an area.
  CalculatorSizeTable? get sizeTable {
    final area = areaForCounts;
    if (area == null) return null;
    final seenSizes = <String, int>{};
    return CalculatorSizeTable(
      areaText: tape.formatter.format(area),
      rows: [
        for (final count in materialCounts)
          if (count.area == area) _sizeRow(count, seenSizes),
      ],
    );
  }

  CalculatorSizeRow _sizeRow(TradeCount count, Map<String, int> seenSizes) {
    final sizeText = tape.formatter.formatPieceSize(count.size);
    final before = seenSizes[sizeText] ?? 0;
    seenSizes[sizeText] = before + 1;
    return CalculatorSizeRow(
      id: '$sizeText#$before',
      sizeText: sizeText,
      countText: tape.formatter.format(count.value),
      count: count,
    );
  }

  /// Whether the detail panel has anything to show: dimension tiles or the
  /// sheet table.
  bool get hasDetails => dimensions.isNotEmpty || sizeTable != null;

  /// The tiles of the detail panel (Section 1.4: "Diagonal, Perimeter and
  /// the other derived values of the current inputs"): every answer the
  /// rules compute from the named values, minus the ones already landed as
  /// result chips, so that once Area 180ft² is accepted the tiles read
  /// Diagonal 21.93ft and Perimeter 58ft (walkthrough 11.3; decision tree
  /// row 224). They are read off the tape ("the dimension tiles for the
  /// current tape"), so they stay while Calc or a note takes row 1 of the
  /// strip.
  List<CalculatorSuggestion> get dimensions => [
    for (final answer in const DeterministicRules().answersFor(
      tape.namedValues,
    ))
      if (!_hasLanded(answer.key)) _answer(answer.key, answer.value),
  ];

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
  /// names an answer that pressing it would not land. While a chip is
  /// reopened for edit the key reads [updateKey] over a tape with a result
  /// and the = sign over one without (product decision of 13 November
  /// 2026), whatever the strip offers.
  String? get equalsKeyId {
    if (tape.editing != null) return _hasAResult ? updateKey : null;
    return switch (equalsLands) {
      null => null,
      CalculatorSuggestion(kind: CalculatorSuggestionKind.runningTotal)
          when _chainStartsOnAResult =>
        ansKey,
      CalculatorSuggestion(:final key) => key,
    };
  }

  bool get _hasAResult => tape.chips.any((chip) => chip is ResultChip);

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
  /// `null`: a warning first — a pitch, a slope or a Sides count the rules
  /// cannot use (Sections 5.4 and 1.8), a prefix trig chip its function
  /// cannot answer — then the D:M:S key that changed nothing on a pitch
  /// answer, which the next key closes, then the tip of a percent just
  /// pressed on + or − (CA-1376). An open bracket silences the suggestions
  /// but not that tip, which is of the bracket's own total (decision tree
  /// row 393).
  CalculatorStripNote? get stripNote {
    if (_stripIsSilent) {
      return tape.openBracket != null ? _percentTip : null;
    }
    switch (const DeterministicRules().refusalFor(tape.namedValues)) {
      case RuleRefusal.pitchOutOfRange:
        return CalculatorPitchOutOfRangeNote(
          isAtLeastARightAngle: _pitchDegrees >= DeterministicRules.rightAngle,
        );
      case RuleRefusal.flatPitchHasNoRun:
        return const CalculatorFlatPitchHasNoRunNote();
      case RuleRefusal.slopeOutOfRange:
        return const CalculatorSlopeOutOfRangeNote();
      case RuleRefusal.sidesNotWhole:
        return const CalculatorSidesNotWholeNote();
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
    return _percentTip;
  }

  /// The tip of a percent just pressed on + or −, or `null`: the chain the
  /// percent sits in (the open bracket's, or the tape's) ends on it, and no
  /// key has been refused since (Section 1.8: it closes on the next key).
  CalculatorPercentTipNote? get _percentTip {
    if (refusal != null) return null;
    final openIndex = tape.openBracketIndex;
    final chain = switch (openIndex) {
      final index? => switch (tape.chips[index]) {
        BracketChip(:final inner) => inner,
        _ => const <TapeChip>[],
      },
      null => tape.chips,
    };
    final (operator, percent) = switch (chain.lastOrNull) {
      ValueChip(:final operator, isPercent: true, :final entry) => (
        operator,
        '${entry.text}%',
      ),
      final BracketChip bracket when bracket.isPercent => (
        bracket.operator,
        _valueTextOf(bracket).substring(_lead(bracket.operator).length),
      ),
      _ => (null, ''),
    };
    if (operator != Operator.add && operator != Operator.subtract) return null;
    final evaluator = tape.evaluator;
    final before = evaluator.fold(chain.sublist(0, chain.length - 1));
    final after = evaluator.fold(chain);
    if ((before, after) case (
      ChainValue(value: final total),
      ChainValue(value: final withPercent),
    )) {
      final adds = operator == Operator.add;
      final amount = adds
          ? evaluator.arithmetic.combine(withPercent, Operator.subtract, total)
          : evaluator.arithmetic.combine(total, Operator.subtract, withPercent);
      if (amount case ArithmeticValue(:final value)) {
        return CalculatorPercentTipNote(
          addsToTheTotal: adds,
          percent: percent,
          total: tape.formatter.format(total),
          amount: tape.formatter.format(_tipAmount(value, total)),
          ofTheBracket: openIndex != null,
        );
      }
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
  /// other than an open bracket are inert — dimmed and deaf to a tap until
  /// it closes ("Chips before an open bracket are dimmed and cannot be
  /// tapped"; Section 7, "The chips after it wait, dimmed") — and a result
  /// after a reopened bracket keeps its chip but reads a dash.
  /// While a chip is being edited in place the results after it are drawn
  /// dashed (rule 4.8: "results downstream show dashed while the edit is
  /// open"); they keep their value, which recomputes as the edit goes.
  List<CoreCalculatorChip> get chipsList {
    final openIndex = tape.openBracketIndex;
    final editedIndex = tape.editing?.index;
    return [
      for (final (index, chip) in tape.chips.indexed)
        CoreCalculatorChip(
          key: ValueKey('calc_chip_$index'),
          label: switch (chip) {
            ValueChip(:final key) => key,
            ResultChip(:final key) => key,
            ErrorChip(:final error) => error.name,
            BracketChip() => null,
          },
          value: switch (chip) {
            ErrorChip() => null,
            BracketChip(isPercent: true, :final inner) =>
              '(${inner.map(_valueTextOf).join()})%',
            BracketChip(:final inner) => inner.map(_valueTextOf).join(),
            ResultChip() when openIndex != null && index > openIndex =>
              _staleResultDash,
            _ => _valueTextOf(chip),
          },
          factor: switch (chip) {
            BracketChip(:final operator?) => operatorIcons[operator],
            _ => null,
          },
          type: switch (chip) {
            ValueChip(isActive: true) => CoreCalculatorChipType.active,
            ValueChip() => CoreCalculatorChipType.editable,
            ResultChip() when editedIndex != null && index > editedIndex =>
              CoreCalculatorChipType.dashed,
            BracketChip(isOpen: true) => CoreCalculatorChipType.bracketOpen,
            // the closed-bracket chip draws its own "(…)" and has no place
            // for a % after its ")", so a percent bracket is a plain chip
            BracketChip(isPercent: true) => CoreCalculatorChipType.editable,
            BracketChip() => CoreCalculatorChipType.bracketClosed,
            ResultChip() => CoreCalculatorChipType.result,
            ErrorChip() => CoreCalculatorChipType.error,
          },
          inert: openIndex != null && index != openIndex,
        ),
    ];
  }

  // What a result after a reopened bracket reads while the bracket is open
  // (Section 7: "shows a dash, 'Calc —', so that no out-of-date number can
  // be read").
  static const String _staleResultDash = '—';

  String _valueTextOf(TapeChip chip) => switch (chip) {
    final ValueChip chip =>
      '${_lead(chip.operator)}${_entryTextOf(chip)}${_percentSign(chip.isPercent)}',
    ResultChip(:final operator, :final value) =>
      '${_lead(operator)}${tape.formatter.format(value)}',
    BracketChip(
      :final operator,
      :final inner,
      :final isOpen,
      :final isPercent,
    ) =>
      '${_lead(operator)}(${inner.map(_valueTextOf).join()}${isOpen ? '' : ')'}'
          '${_percentSign(isPercent)}',
    ErrorChip() => '',
  };

  static String _lead(Operator? operator) => operator?.symbol ?? '';

  static String _percentSign(bool isPercent) => isPercent ? '%' : '';

  // What a percent of a length total is worth, as the percent tip writes
  // it: in inches under a foot of a total in feet (decision tree row 390:
  // 5ft + 10 % "Adds 10% of the total 5ft = 6in"), else in the total's
  // own unit (10ft + 10 % adds 1ft).
  static Quantity _tipAmount(Quantity amount, Quantity total) => switch ((
    amount,
    total,
  )) {
    (Length(:final ticks), Length(unit: Unit.foot || Unit.footInch))
        when ticks.abs() < Length.ticksPerFoot =>
      Length(ticks, unit: Unit.inch),
    (Length(:final ticks), Length(:final unit)) => Length(ticks, unit: unit),
    _ => amount,
  };

  @override
  List<Object?> get props => [
    tape,
    currentGroupIndex,
    groupOrder,
    notice,
    refusal,
    closesCalculator,
    removedResults,
    refusedUnit,
    groupEditsNoticed,
    toastsRaised,
    toastClosed,
    materialCounts,
  ];

  /// What the last key left to say in a red Alert (Section 5), or `null`:
  /// the results an edit removed; the editing guard, with the incomplete
  /// number as the value row shows it, which is nothing for an empty chip;
  /// ⌫ again on the emptied first chip of a chain (rule 4.8);
  /// and the unit guards, named for the unit the key stood for — "takes a
  /// length, not `<kind>`" (one message whether the unit came first or after
  /// a finished length) and "keeps" under a dimension key on fresh entry
  /// and on a reopened chip alike, "Can't append" on a reopened compound. The
  /// key-named guards speak only while a chip under a key is being typed:
  /// the tape refuses a unit key on a result the same way (Section 5.2 has
  /// no message for that), and that refusal stays silent here. Any other
  /// refusal has no message here yet; a result, an error and a bracket chip
  /// take no tap on the page, so the tape's refusal of one never reaches a
  /// message.
  CalculatorToast? get toast {
    if (removedResults.isNotEmpty) {
      return CalculatorResultRemovedToast(keys: removedResults);
    }
    if (notice == TapeNotice.editingThisGroup &&
        groupEditsNoticed <= groupEditToastsShown) {
      return const CalculatorEditingGroupToast();
    }
    final key = tape.beingTyped?.key;
    return switch ((refusal, refusedUnit, key)) {
      (TapeRefused(reason: TapeRefusal.finishThisValueFirst), _, _) =>
        CalculatorFinishValueToast(value: valueText),
      (TapeRefused(reason: TapeRefusal.typeANewFirstValue), _, _) =>
        const CalculatorTypeNewFirstValueToast(),
      (
        TapeEntryRefused(reason: EntryRefusal.cannotAppendUnit),
        final unit?,
        _,
      ) =>
        CalculatorCannotAppendUnitToast(value: valueText, unit: unit),
      (
        TapeEntryRefused(reason: EntryRefusal.needsLength),
        final unit?,
        final key?,
      ) =>
        CalculatorNeedsLengthToast(key: key, unit: unit),
      (
        TapeEntryRefused(reason: EntryRefusal.tailNeedsLength),
        final unit?,
        final key?,
      ) =>
        CalculatorNeedsLengthToast(key: key, unit: unit),
      (
        TapeUnitRefused(
          refusal: UnitKeyRefused(reason: UnitKeyRefusal.keepsLength),
        ),
        final unit?,
        final key?,
      ) =>
        CalculatorKeepsLengthToast(key: key, unit: unit, value: valueText),
      (TapeEntryRefused(reason: EntryRefusal.partOfSixtyOrMore), _, _) =>
        const CalculatorPartUnderSixtyToast(),
      (TapeEntryRefused(reason: EntryRefusal.minutesHaveTwoDigits), _, _) =>
        const CalculatorMinutesTwoDigitsToast(),
      (TapeEntryRefused(reason: EntryRefusal.secondsHaveTwoDigits), _, _) =>
        const CalculatorSecondsTwoDigitsToast(),
      (TapeEntryRefused(reason: EntryRefusal.angleHasThreeParts), _, _) =>
        const CalculatorAngleThreePartsToast(),
      (TapeRefused(reason: TapeRefusal.nothingToCompute), _, _) =>
        _rangeWarningOnEquals,
      (TapeRefused(reason: TapeRefusal.percentNeedsANumber), _, _) =>
        CalculatorPercentNeedsANumberToast(
          operator: _lead(tape.beingTyped?.operator),
        ),
      (TapeRefused(reason: TapeRefusal.percentNeedsAnOperator), _, _) =>
        CalculatorPercentNeedsAnOperatorToast(
          insideABracket: tape.openBracket != null,
        ),
      (TapeRefused(reason: TapeRefusal.alreadyAPercent), _, _) =>
        const CalculatorAlreadyAPercentToast(),
      (TapeRefused(reason: TapeRefusal.percentTakesNoUnit), _, _) =>
        const CalculatorPercentTakesNoUnitToast(),
      (TapeRefused(reason: TapeRefusal.percentHasNoUnit), _, _) =>
        const CalculatorPercentHasNoUnitToast(),
      (TapeRefused(reason: TapeRefusal.percentDividesByZero), _, _) =>
        CalculatorPercentDividesByZeroToast(
          bracket: switch (tape.chips.lastOrNull) {
            BracketChip(:final inner) => '(${inner.map(_valueTextOf).join()})',
            _ => '',
          },
        ),
      _ => null,
    };
  }

  CalculatorToast? get _rangeWarningOnEquals => switch (stripNote) {
    CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true) =>
      const CalculatorRangeWarningToast(
        CalculatorRangeWarning.pitchUnderRightAngle,
      ),
    CalculatorPitchOutOfRangeNote() => const CalculatorRangeWarningToast(
      CalculatorRangeWarning.pitchAtLeastZero,
    ),
    CalculatorFlatPitchHasNoRunNote() => const CalculatorRangeWarningToast(
      CalculatorRangeWarning.flatPitchHasNoRun,
    ),
    CalculatorSlopeOutOfRangeNote() => const CalculatorRangeWarningToast(
      CalculatorRangeWarning.slopeAboveZero,
    ),
    _ => null,
  };
}
