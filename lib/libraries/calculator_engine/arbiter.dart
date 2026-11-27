import 'package:construculator/libraries/calculator_engine/chain_evaluator.dart';
import 'package:construculator/libraries/calculator_engine/deterministic_rules.dart';
import 'package:construculator/libraries/calculator_engine/models/arbitration.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/trade_stores.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';
import 'package:equatable/equatable.dart';

/// The arbiter: the pure function that decides what the suggestion strip
/// shows after every key press (UX Design Doc term 2.8, rule 4.4;
/// requirement R5), the port of the prototype's `arbitrateCore` for its
/// first rungs. It walks the ladder and stops at the first rung with
/// something to say, and records each question in [Arbitration.trace].
///
/// Rung 1, the error state: the strip is silent while the chain holds an
/// error chip or a step it cannot compute, and while a bracket is open.
/// Rung 2, the trade follow-ons: an area on the display — an accepted Area
/// or a typed one, never a Calc — earns a drywall count for every stored
/// sheet size, the rule answers behind them; once a count is accepted the
/// row holds the other sizes alone. Rung 3, the rules: a trig chip's
/// answer leads when the chip stands alone or builds its own ratio, the
/// running total takes the row while an operator has values on both sides,
/// and otherwise the named values earn the answers not yet landed.
class Arbiter extends Equatable {
  final DeterministicRules _rules;
  final Trades _trades;

  /// Creates the arbiter over the geometry rules and the material rules.
  const Arbiter({
    this._rules = const DeterministicRules(),
    this._trades = const Trades(),
  });

  /// The strip [tape] earns over [stores].
  Arbitration arbitrate(Tape tape, TradeStores stores) {
    final area = tape.countedArea;
    final counts = area == null
        ? const <TradeCount>[]
        : _trades.countsFor(
            Trade.drywall,
            area,
            stores.sizesFor(Trade.drywall),
          );
    final silence = _silenceOf(tape);
    if (silence != null) {
      return Arbitration(
        rung: LadderRung.error,
        silence: silence,
        countedArea: area,
        counts: counts,
        trace: const [LadderStep(LadderRung.error, applies: true)],
      );
    }
    final accepted = tape.acceptedCounts;
    final runningTotal = switch (tape.runningTotal) {
      ChainValue(:final value, isCalculation: true) => StripOffer(
        key: Tape.calcKey,
        value: value,
        kind: StripOfferKind.runningTotal,
      ),
      _ => null,
    };
    final trigAnswer = switch (tape.trigAnswer) {
      final answer? => _answer(answer),
      null => null,
    };
    final trigLeads = trigAnswer != null && !tape.trigAnswerContinuesAChain;
    final countOffers = runningTotal != null
        ? const <StripOffer>[]
        : _notYetAccepted(counts, accepted);
    final ruleOffers = runningTotal != null || accepted.isNotEmpty
        ? const <StripOffer>[]
        : ruleAnswersFor(tape);
    final follows = accepted.isNotEmpty || countOffers.isNotEmpty;
    final answers =
        trigAnswer != null || runningTotal != null || ruleOffers.isNotEmpty;
    return Arbitration(
      rung: follows
          ? LadderRung.tradeFollowOn
          : (answers ? LadderRung.rules : LadderRung.none),
      offers: [
        if (trigLeads) trigAnswer,
        ?runningTotal,
        ...countOffers,
        ...ruleOffers,
        if (trigAnswer != null && !trigLeads) trigAnswer,
      ],
      countedArea: area,
      counts: counts,
      trace: [
        const LadderStep(LadderRung.error, applies: false),
        LadderStep(LadderRung.tradeFollowOn, applies: follows),
        if (!follows) LadderStep(LadderRung.rules, applies: answers),
      ],
    );
  }

  /// The answers the rules compute from the named values of [tape], minus
  /// the ones already landed as result chips: the rule answers of row 1,
  /// and the tiles of the detail panel, which stay while Calc or a count
  /// takes the row.
  List<StripOffer> ruleAnswersFor(Tape tape) => [
    for (final answer in _rules.answersFor(tape.namedValues))
      if (!tape.chips.any(
        (chip) => chip is ResultChip && chip.key == answer.key,
      ))
        _answer(answer),
  ];

  static StripOffer _answer(Answer answer) => StripOffer(
    key: answer.key,
    value: answer.value,
    kind: StripOfferKind.answer,
  );

  static StripSilence? _silenceOf(Tape tape) {
    if (tape.openBracket != null) return StripSilence.openBracket;
    final fails = switch (tape.runningTotal) {
      ChainFailed() => true,
      ChainValue(isCalculation: true) => false,
      ChainValue() || ChainEmpty() => _chainHoldsAnError(tape),
    };
    return fails ? StripSilence.chainFailed : null;
  }

  static bool _chainHoldsAnError(Tape tape) {
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

  // An accepted count hides one offer of its value and no more, so two
  // stored sizes that count the same do not leave together.
  static List<StripOffer> _notYetAccepted(
    List<TradeCount> counts,
    List<ResultChip> accepted,
  ) {
    final landed = [for (final chip in accepted) (chip.key, chip.value)];
    return [
      for (final count in counts)
        if (!landed.remove((count.trade.resultKey, count.value)))
          StripOffer(
            key: count.trade.offerKey,
            value: count.value,
            kind: StripOfferKind.materialCount,
            count: count,
          ),
    ];
  }

  @override
  List<Object?> get props => [_rules, _trades];
}
