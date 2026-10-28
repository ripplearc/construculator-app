import 'package:construculator/libraries/calculator_engine/chain_arithmetic.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/quantity_formatter.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:construculator/libraries/calculator_engine/trig.dart';
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

/// The ratio an Arctangent chip builds across the ÷ and bare numbers typed
/// after it (UX Design Doc rule 4.11; Section 6, "Trig chips in a chain"):
/// [ATAN] 16 ÷ 12 asks the arctangent of 16 ÷ 12, and [ATAN] 32 ÷ 2 ÷ 12
/// the same. The one place the reach is walked: the chain evaluator reads
/// it to fold the chips, the tape to offer and name the answer.
///
/// ÷ and a bare number with no key join the ratio
/// ([ValueChip.dividesAnArctangentRatio]), and so does a closed bracket
/// right after ÷ that is worth a plain number, named by what it is worth:
/// [ATAN] 16 ÷ (3 + 1) is Arctangent(16 ÷ 4) 75.96° (rule 4.11). The
/// divisor ÷ 0 reopens after its error chip (Section 5, "Division by
/// zero"), so the walk steps over that one chip to the divisor typed again:
/// [ATAN] 16 ÷ 0 = then 12 = is Arctangent(16 ÷ 12) 53.13°. The walk stops
/// at anything else, a result, an open bracket, an operator or a named
/// chip included. The Arctangent chip's own operator is the chain's, not
/// the ratio's: 5 + [ATAN] 16 ÷ 12 is 5 plus the arctangent of 16 ÷ 12
/// (rule 4.6).
final class ArctangentReach {
  /// The Arctangent chip the ratio starts from.
  final ValueChip chip;

  /// The divisors, in tape order, at least one.
  final List<ArctangentDivisor> divisors;

  /// The place on the tape just past the last divisor.
  final int end;

  /// The number typed under the Arctangent chip, before any ÷: the digits
  /// the strip's Calc shows while the ratio is still the end of the tape.
  final double digits;

  const ArctangentReach._({
    required this.chip,
    required this.divisors,
    required this.end,
    required this.digits,
  });

  /// The reach from [chips] at [index], or `null` when the chip there is
  /// not an Arctangent chip with a number, or nothing divides it. A bracket
  /// divisor is worth what [evaluator] folds its inside to.
  static ArctangentReach? from(
    List<TapeChip> chips,
    int index, {
    ChainEvaluator evaluator = const ChainEvaluator(),
  }) {
    final chip = chips[index];
    if (chip is! ValueChip || chip.trigFunction != TrigFunction.arctangent) {
      return null;
    }
    final digits = chip.bareNumber;
    if (digits == null) return null;
    final divisors = <ArctangentDivisor>[];
    var end = index + 1;
    while (end < chips.length) {
      final next = _pastDivisionByZero(chips, end);
      final divisor = _divisorOf(chips[next], evaluator);
      if (divisor == null) break;
      divisors.add(divisor);
      end = next + 1;
    }
    if (divisors.isEmpty) return null;
    return ArctangentReach._(
      chip: chip,
      divisors: List.unmodifiable(divisors),
      end: end,
      digits: digits,
    );
  }

  static int _pastDivisionByZero(List<TapeChip> chips, int index) {
    if (chips[index] case ErrorChip(
      error: CalculationError.divisionByZero,
    ) when index + 1 < chips.length) {
      return index + 1;
    }
    return index;
  }

  static ArctangentDivisor? _divisorOf(
    TapeChip chip,
    ChainEvaluator evaluator,
  ) => switch (chip) {
    ValueChip(:final bareNumber?, :final entry)
        when chip.dividesAnArctangentRatio =>
      (number: bareNumber, text: entry.text),
    BracketChip(operator: Operator.divide, isOpen: false, :final inner) =>
      switch (evaluator.fold(inner)) {
        ChainValue(value: Scalar(:final value)) => (
          number: value,
          text: const QuantityFormatter().format(
            Scalar(value),
            groupThousands: false,
          ),
        ),
        ChainValue() || ChainFailed() || ChainEmpty() => null,
      },
    ValueChip() || BracketChip() || ResultChip() || ErrorChip() => null,
  };

  /// The ratio the divisors build, or `null` when one of them is 0.
  double? get ratio {
    var ratio = digits;
    for (final divisor in divisors) {
      if (divisor.number == 0) return null;
      ratio /= divisor.number;
    }
    return ratio;
  }

  /// The arctangent of the ratio, or `null` where there is no ratio.
  Quantity? get angle => switch (ratio) {
    final ratio? => TrigFunction.arctangent.of(ratio),
    null => null,
  };

  /// The ratio as the tape writes it, "16 ÷ 12", without the Arctangent
  /// chip's own operator; a bracket divisor is written as its value.
  String get spelling => [
    chip.entry.text,
    for (final divisor in divisors) '${Operator.divide.symbol} ${divisor.text}',
  ].join(' ');
}

/// One divisor of an [ArctangentReach]: the number it is worth and the text
/// the answer names it by, the digits typed or the value a bracket folds to.
typedef ArctangentDivisor = ({double number, String text});

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
/// second = has nothing to land, and 4 + 3 after the chip folds again. The
/// one exception is the divisor ÷ 0 reopens after its error chip (Section
/// 5, "Division by zero"): a chip that carries an operator straight after
/// an error chip continues the chain from the total before the error, so
/// 5 ÷ 0 = then 2 = is Calc 2.5.
///
/// A closed bracket is worth what its inside folds to, at full precision
/// and with its dimension (Section 7, "Brackets with units"), and the
/// steps worked inside it count, so (2 + 3) on its own is a calculation
/// and = lands Calc 5. An open bracket is worth nothing yet, which is why
/// no Calc is offered while it is open.
///
/// A trig chip is worth its answer, except an Arctangent whose number is
/// followed by ÷ and bare numbers with no key: the ÷ builds the ratio for
/// ATAN ([ArctangentReach]; Section 6, "Trig chips in a chain"). While that
/// ratio is the end of a tape the Arctangent starts, the chip is worth its
/// digits, so [ATAN] 16 ÷ 12 folds to Calc 1.33, the ratio whose angle the
/// tape offers beside it; once any other chip follows, or the Arctangent
/// continues a chain (5 + [ATAN] 16 ÷ 12 is 58.13°, rule 4.6), the ratio is
/// sealed into its angle, because an operator never demotes a trig chip
/// into its digits: [ATAN] 16 ÷ 12 × 2 is 106.26°.
class ChainEvaluator extends Equatable {
  /// Reads each chip's value.
  final QuantityParser parser;

  /// Combines two values under an operator.
  final ChainArithmetic arithmetic;

  /// Says when an answer shows a number too large to show (Section 5, "Too
  /// large"): that step fails with [CalculationError.outOfRange], so the
  /// strip goes silent and = lands the error chip, which ⌫ removes to
  /// reopen the number before it.
  final QuantityFormatter formatter;

  const ChainEvaluator({
    this.parser = const QuantityParser(),
    this.arithmetic = const ChainArithmetic(),
    this.formatter = const QuantityFormatter(),
  });

  /// The running total of [chips], as far as it can be computed.
  ChainOutcome fold(List<TapeChip> chips) {
    var running = _nothing;
    var index = 0;
    while (index < chips.length) {
      final chip = chips[index];
      var next = index + 1;
      switch (chip) {
        case ErrorChip():
          if (!_continuesAfter(chips, index)) running = _nothing;
        case ResultChip(:final value, :final operator):
          running = _joined(running, operator, value);
        case ValueChip(:final operator) || BracketChip(:final operator):
          final reach = ArctangentReach.from(chips, index, evaluator: this);
          final ({Quantity value, int steps})? reading;
          if (reach != null && reach.end == chips.length && operator == null) {
            reading = (value: Scalar(reach.digits), steps: 0);
          } else if (reach case ArctangentReach(:final angle?, :final end)) {
            reading = (value: angle, steps: reach.divisors.length);
            next = end;
          } else {
            reading = _readingOf(chip);
          }
          if (reading == null) return const ChainEmpty();
          running = _joined(
            running,
            operator,
            reading.value,
            stepsInside: reading.steps,
          );
      }
      index = next;
    }
    if (running.failure case final failure?) return failure;
    if (running.total case final total?) {
      return ChainValue(total, steps: running.steps);
    }
    return const ChainEmpty();
  }

  static const _RunningChain _nothing = (total: null, steps: 0, failure: null);

  bool _continuesAfter(List<TapeChip> chips, int index) =>
      chips[index] == const ErrorChip(CalculationError.divisionByZero) &&
      index + 1 < chips.length &&
      switch (chips[index + 1]) {
        ValueChip(:final operator) ||
        BracketChip(:final operator) => operator == Operator.divide,
        ResultChip() || ErrorChip() => false,
      };

  _RunningChain _joined(
    _RunningChain running,
    Operator? operator,
    Quantity value, {
    int stepsInside = 0,
  }) {
    final total = running.total;
    if (total == null || operator == null) {
      return (total: value, steps: stepsInside, failure: null);
    }
    if (running.failure != null) return running;
    final step = switch (arithmetic.combine(total, operator, value)) {
      ArithmeticValue(value: final next) when formatter.isTooLarge(next) =>
        const ArithmeticFailed(CalculationError.outOfRange),
      final ArithmeticOutcome outcome => outcome,
    };
    return switch (step) {
      ArithmeticValue(value: final next) => (
        total: next,
        steps: running.steps + 1 + stepsInside,
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

  ({Quantity value, int steps})? _readingOf(TapeChip chip) => switch (chip) {
    ValueChip() => switch (chip.value(parser)) {
      final value? => (value: value, steps: 0),
      null => null,
    },
    BracketChip(isOpen: false, :final inner) => switch (fold(inner)) {
      ChainValue(:final value, :final steps) => (value: value, steps: steps),
      ChainFailed() || ChainEmpty() => null,
    },
    BracketChip() || ResultChip() || ErrorChip() => null,
  };

  @override
  List<Object?> get props => [parser, arithmetic, formatter];
}

/// The chain being folded: its total so far, the operators applied to reach
/// it, and the step that failed, which stays until a new chain starts.
typedef _RunningChain = ({Quantity? total, int steps, ChainFailed? failure});
