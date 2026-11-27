import 'package:construculator/libraries/calculator_engine/chain_evaluator.dart';
import 'package:construculator/libraries/calculator_engine/models/arbitration.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:equatable/equatable.dart';

/// The arbiter: the pure function that decides what the suggestion strip
/// shows after every key press (UX Design Doc term 2.8, rule 4.4;
/// requirement R5), the port of the prototype's `arbitrateCore` for its
/// first rungs. It walks the ladder and stops at the first rung with
/// something to say, and records each question in [Arbitration.trace].
///
/// Rung 1, the error state: the strip is silent while the chain holds an
/// error chip or a step it cannot compute, and while a bracket is open.
class Arbiter extends Equatable {
  /// Creates the arbiter.
  const Arbiter();

  /// What the ladder chooses for [tape].
  Arbitration arbitrate(Tape tape) {
    final silence = _silenceOf(tape);
    if (silence != null) {
      return Arbitration(
        rung: LadderRung.error,
        silence: silence,
        trace: const [LadderStep(LadderRung.error, applies: true)],
      );
    }
    return const Arbitration(
      rung: LadderRung.none,
      trace: [LadderStep(LadderRung.error, applies: false)],
    );
  }

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

  @override
  List<Object?> get props => const [];
}
