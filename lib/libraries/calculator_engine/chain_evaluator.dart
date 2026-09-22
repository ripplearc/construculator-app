import 'package:construculator/libraries/calculator_engine/chain_arithmetic.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:equatable/equatable.dart';

/// What a tape folds to.
sealed class ChainOutcome extends Equatable {
  const ChainOutcome();
}

/// The tape folds to one value.
final class ChainValue extends ChainOutcome {
  /// The running total.
  final Quantity value;

  /// How many operators were applied to reach it. Zero means the tape holds
  /// a value but no calculation, so there is no Calc to offer.
  final int steps;

  const ChainValue(this.value, {required this.steps});

  /// Whether an operator with values on both sides has been applied, which
  /// is when the strip offers "Calc" and the equals key reads it.
  bool get isCalculation => steps > 0;

  @override
  List<Object?> get props => [value, steps];
}

/// A step of the tape cannot be computed.
final class ChainFailed extends ChainOutcome {
  /// Why.
  final CalculationError error;

  /// The running total the step started from, named in the toast.
  final Quantity left;

  /// The operator that failed.
  final Operator operator;

  /// The value the step tried to join, named in the toast.
  final Quantity right;

  const ChainFailed(
    this.error, {
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  List<Object?> get props => [error, left, operator, right];
}

/// The tape holds nothing that can be folded: no chips, nothing after its
/// last error chip, or a value still being typed.
final class ChainEmpty extends ChainOutcome {
  const ChainEmpty();

  @override
  List<Object?> get props => const [];
}

/// Folds the tape left to right with no precedence (UX Design Doc rule
/// 4.6, Section 7): 2 + 3 × 4 = 20, the way the handheld calculators work
/// and the only order the tape can be read in. The port of the prototype's
/// `operandBefore`.
///
/// A chip with no operator starts a chain; a result chip is already the
/// fold of everything before it, so the chain restarts there unless it
/// carries the operator that leads into it; a value that cannot be read yet
/// leaves nothing to fold. A step that fails ends its own chain: the
/// failure is what the tape folds to until a chip with no operator starts
/// a new chain, so 5lbs + 12ft then Width 5ft × 3 still lands Calc 15ft 0in.
/// An error chip ends its chain the same way, wherever it sits: once the
/// failed step has landed on the tape the strip goes silent (rule 4.12), a
/// second = has nothing to land, and 4 + 3 after the chip folds again.
class ChainEvaluator extends Equatable {
  /// Reads each chip's value.
  final QuantityParser parser;

  /// Combines two values under an operator.
  final ChainArithmetic arithmetic;

  const ChainEvaluator({
    this.parser = const QuantityParser(),
    this.arithmetic = const ChainArithmetic(),
  });

  /// The running total of [chips], as far as it can be computed.
  ChainOutcome fold(List<TapeChip> chips) {
    var running = _nothing;
    for (final chip in chips) {
      switch (chip) {
        case ErrorChip():
          running = _nothing;
        case ResultChip(:final value, :final operator):
          running = _joined(running, operator, value);
        case ValueChip(:final operator) || BracketChip(:final operator):
          final value = _valueOf(chip);
          if (value == null) return const ChainEmpty();
          running = _joined(running, operator, value);
      }
    }
    if (running.failure case final failure?) return failure;
    if (running.total case final total?) {
      return ChainValue(total, steps: running.steps);
    }
    return const ChainEmpty();
  }

  static const _RunningChain _nothing = (total: null, steps: 0, failure: null);

  _RunningChain _joined(
    _RunningChain running,
    Operator? operator,
    Quantity value,
  ) {
    final total = running.total;
    if (total == null || operator == null) {
      return (total: value, steps: 0, failure: null);
    }
    if (running.failure != null) return running;
    return switch (arithmetic.combine(total, operator, value)) {
      ArithmeticValue(value: final next) => (
        total: next,
        steps: running.steps + 1,
        failure: null,
      ),
      ArithmeticFailed(:final error) => (
        total: total,
        steps: running.steps,
        failure: ChainFailed(
          error,
          left: total,
          operator: operator,
          right: value,
        ),
      ),
    };
  }

  // A closed bracket is worth what its inside folds to, at full precision
  // and with its dimension (Section 7, "Brackets with units"); an open one
  // is worth nothing yet, which is why no Calc is offered while it is open.
  Quantity? _valueOf(TapeChip chip) => switch (chip) {
    ValueChip() => chip.value(parser),
    BracketChip(isOpen: false, :final inner) => switch (fold(inner)) {
      ChainValue(:final value) => value,
      ChainFailed() || ChainEmpty() => null,
    },
    BracketChip() || ResultChip() || ErrorChip() => null,
  };

  @override
  List<Object?> get props => [parser, arithmetic];
}

/// The chain being folded: its total so far, the operators applied to reach
/// it, and the step that failed, which stays until a new chain starts.
typedef _RunningChain = ({Quantity? total, int steps, ChainFailed? failure});
