import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  Tape press(Tape tape, String keys) {
    var current = tape;
    for (final key in keys.split(' ')) {
      if (key.isEmpty) continue;
      current = changed(switch (key) {
        'ft' => current.pressUnit(Unit.foot),
        'in' => current.pressUnit(Unit.inch),
        'yd' => current.pressUnit(Unit.yard),
        'lbs' => current.pressUnit(Unit.pound),
        'cm' => current.pressUnit(Unit.centimetre),
        'bf' => current.pressUnit(Unit.boardFoot),
        '×' => current.pressOperator(Operator.multiply),
        '÷' => current.pressOperator(Operator.divide),
        '+' => current.pressOperator(Operator.add),
        '−' => current.pressOperator(Operator.subtract),
        '=' => current.pressEquals(),
        '⌫' => current.backspace(),
        _ when key.startsWith('[') => current.pressFunctionKey(
          key.substring(1, key.length - 1),
        ),
        _ => current.typeDigit(key),
      });
    }
    return current;
  }

  String calc(Tape tape) {
    if (tape.runningTotal case ChainValue(:final value, isCalculation: true)) {
      return formatter.format(value);
    }
    throw StateError('no Calc on offer: ${tape.runningTotal}');
  }

  String lastResult(Tape tape) {
    if (tape.chips.last case ResultChip(:final key, :final value)) {
      return '$key ${formatter.format(value)}';
    }
    throw StateError('the tape does not end on a result: ${tape.chips}');
  }

  group('Tape chain', () {
    group('left to right, no precedence', () {
      test('2 + 3 × 4 = 20 (S99)', () {
        final tape = press(const Tape(), '2 + 3 × 4');
        expect(calc(tape), '20');
        expect(lastResult(press(tape, '=')), 'Calc 20');
      });

      test('2 + 3 + 4 answers 9, not 7, and 3ft × 4ft × 2 answers 24ft²', () {
        expect(lastResult(press(const Tape(), '2 + 3 + 4 =')), 'Calc 9');
        expect(
          lastResult(press(const Tape(), '3 ft × 4 ft × 2 =')),
          'Calc 24ft²',
        );
      });

      test('scalar × scalar: 78 × 56 = 4,368 (S13)', () {
        expect(lastResult(press(const Tape(), '7 8 × 5 6 =')), 'Calc 4,368');
      });

      test('scalar × length: 78 × 56ft = 4368ft 0in (S14)', () {
        final tape = press(const Tape(), '7 8 × 5 6 ft');
        expect(calc(tape), '4368ft 0in');
        expect(lastResult(press(tape, '=')), 'Calc 4368ft 0in');
      });

      test('length ÷ length: 36ft ÷ 12ft = 3 (S15)', () {
        expect(lastResult(press(const Tape(), '3 6 ft ÷ 1 2 ft =')), 'Calc 3');
      });

      test('the Calc is offered as soon as both sides have a value', () {
        final tape = press(const Tape(), '2 0 0 ft × 8 0');
        expect(calc(tape), '16000ft 0in');
        expect(calc(press(tape, 'ft')), '16,000ft²');
      });

      test(
        'a tape with one value or two values and no operator offers no Calc',
        () {
          expect(
            press(const Tape(), '1 8 ft').runningTotal,
            isA<ChainValue>().having(
              (c) => c.isCalculation,
              'isCalculation',
              isFalse,
            ),
          );
          final parked = press(const Tape(), '[Length] 3 in [Width] 2 in in');
          expect(
            parked.runningTotal,
            isA<ChainValue>().having(
              (c) => c.isCalculation,
              'isCalculation',
              isFalse,
            ),
          );
        },
      );
    });

    group('continuing from a result', () {
      test('12ft × 5ft = 60ft², then × 4in = 20ft³ (S16)', () {
        final area = press(const Tape(), '1 2 ft × 5 ft =');
        expect(lastResult(area), 'Calc 60ft²');
        final volume = press(area, '× 4 in =');
        expect(lastResult(volume), 'Calc 20ft³');
        expect(volume.chips.length, 5);
      });

      test('36ft ÷ 12ft = 3, then × 89 = 267 (S17)', () {
        final tape = press(const Tape(), '3 6 ft ÷ 1 2 ft = × 8 9');
        expect(calc(tape), '267');
        expect(lastResult(press(tape, '=')), 'Calc 267');
      });

      test('an operator picks up a sealed bare number too', () {
        // The prototype refused this ("Type a value first"); rule 4.5 lets
        // a sealed value of any kind be the left-hand side.
        const sealed = Tape(
          chips: [
            ValueChip(
              entry: EntryBuffer([Token(digits: '78')]),
              isActive: false,
            ),
          ],
        );
        expect(lastResult(press(sealed, '× 2 =')), 'Calc 156');
      });

      test('an operator picks up a sealed value as its left-hand side', () {
        const sealed = Tape(
          chips: [
            ValueChip(
              entry: EntryBuffer([Token(digits: '18', unit: Unit.foot)]),
              isActive: false,
            ),
          ],
        );
        expect(lastResult(press(sealed, '× 2 =')), 'Calc 36ft 0in');
      });
    });

    group('board feet and small ratios', () {
      test('board-feet math answers in board feet (S76)', () {
        final tape = press(const Tape(), '8 bf × 2 0 =');
        expect(lastResult(tape), 'Calc 160bf');
        expect(lastResult(press(tape, '÷ 4 =')), 'Calc 40bf');
        expect(
          lastResult(press(const Tape(), '5 0 0 bf + 1 yd yd yd =')),
          'Calc 824bf',
        );
        expect(
          lastResult(press(const Tape(), '5 0 0 bf ÷ 8 bf =')),
          'Calc 62.5',
        );
      });

      test('a tiny ratio never displays as zero (S74, S83)', () {
        expect(lastResult(press(const Tape(), '1 ÷ 7 8 =')), 'Calc 0.013');
      });

      test('10in ÷ 3 lands 0ft 3-5/16in (S52)', () {
        expect(
          lastResult(press(const Tape(), '1 0 in ÷ 3 =')),
          'Calc 0ft 3-5/16in',
        );
      });
    });

    group('operators', () {
      test('change a pending operator instead of stacking two', () {
        final tape = press(const Tape(), '2 + ×');
        expect(tape.chips.length, 2);
        expect(tape.active!.operator, Operator.multiply);
      });

      test('with nothing before them say type a value first', () {
        expect(
          const Tape().pressOperator(Operator.multiply),
          const TapeRefused(TapeRefusal.typeAValueFirst),
        );
        expect(
          press(const Tape(), '[Length]').pressOperator(Operator.multiply),
          const TapeRefused(TapeRefusal.typeAValueFirst),
        );
        final error = const Tape().append(
          const ErrorChip(CalculationError.dimensionError),
        );
        expect(
          error.pressOperator(Operator.add),
          const TapeRefused(TapeRefusal.typeAValueFirst),
        );
      });

      test('cannot leave a number with no unit', () {
        expect(
          press(const Tape(), '[Length] 1 8 ft 8').pressOperator(Operator.add),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });
    });

    group('equals', () {
      test('on a value with no operator says nothing to compute', () {
        expect(
          press(const Tape(), '1 8 ft').pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
        expect(
          const Tape().pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('on an operator waiting for its number says nothing to compute', () {
        expect(
          press(const Tape(), '1 8 ft ×').pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('after a result says nothing to compute', () {
        expect(
          press(const Tape(), '2 + 3 =').pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('cannot finish a number with no unit', () {
        expect(
          press(const Tape(), '2 ft + 1 8 ft 8').pressEquals(),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });

      test('seals the active chip when it lands', () {
        final tape = press(const Tape(), '2 + 3 =');
        expect(tape.active, isNull);
        expect((tape.chips[1] as ValueChip).isActive, isFalse);
      });
    });

    group('errors', () {
      test('78lbs ÷ 12ft = lands a Dimension Error chip (S18)', () {
        final tape = press(const Tape(), '7 8 lbs ÷ 1 2 ft');
        expect(tape.runningTotal, isA<ChainFailed>());
        final failed = tape.runningTotal as ChainFailed;
        expect(failed.error, CalculationError.dimensionError);
        expect(failed.left, const Weight(7800, unit: Unit.pound));
        expect(failed.operator, Operator.divide);
        expect(
          failed.right,
          const Length(12 * Length.ticksPerFoot, unit: Unit.foot),
        );
        final landed = press(tape, '=');
        expect(
          landed.chips.last,
          const ErrorChip(CalculationError.dimensionError),
        );
        expect((landed.chips[1] as ValueChip).isActive, isFalse);
        expect(landed.active, isNull);
        expect(landed.runningTotal, const ChainEmpty());
        expect(
          landed.pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('a failed chain does not break the chain typed after it', () {
        final tape = press(const Tape(), '5 lbs + 1 2 ft [Width] 5 ft × 3');
        expect(calc(tape), '15ft 0in');
        expect(lastResult(press(tape, '=')), 'Calc 15ft 0in');
      });

      test('rule 4.12: = works again after an error chip', () {
        final divided = press(const Tape(), '5 ÷ 0 =');
        expect(
          divided.chips.last,
          const ErrorChip(CalculationError.divisionByZero),
        );
        expect(lastResult(press(divided, '4 + 3 =')), 'Calc 7');
        final mismatched = press(const Tape(), '7 8 lbs ÷ 1 2 ft =');
        expect(lastResult(press(mismatched, '3 ft × 4 ft =')), 'Calc 12ft²');
      });

      test('a metric chain answers in the unit it was typed in', () {
        // 2cm and 3cm are whole ticks on the tape (50 and 76), so the area
        // reads 5.99cm², in centimetres rather than 0m².
        final landed = press(const Tape(), '2 cm × 3 cm =');
        expect(lastResult(landed), 'Calc 5.99cm²');
        expect(
          (landed.chips.last as ResultChip).value,
          const Area(3800, unit: Unit.centimetre),
        );
      });

      test('the mismatch is not just division: 78 + 12ft (S73)', () {
        final landed = press(const Tape(), '7 8 + 1 2 ft =');
        expect(
          landed.chips.last,
          const ErrorChip(CalculationError.dimensionError),
        );
      });

      test('÷ 0 lands its own error', () {
        final landed = press(const Tape(), '5 ÷ 0 =');
        expect(
          landed.chips.last,
          const ErrorChip(CalculationError.divisionByZero),
        );
      });

      test('backspace performs surgery on the error and = answers (S72)', () {
        final repaired = press(const Tape(), '7 8 lbs ÷ 1 2 ft = ⌫ ⌫');
        expect(repaired.active!.entry.text, '12');
        expect(calc(repaired), '6.5lbs');
        expect(lastResult(press(repaired, '=')), 'Calc 6.5lbs');
      });
    });
  });

  group('ChainEvaluator', () {
    const evaluator = ChainEvaluator();

    test('folds nothing on an empty tape', () {
      final empty = evaluator.fold(List<TapeChip>.empty());
      expect(empty, const ChainEmpty());
      expect(empty.hashCode, const ChainEmpty().hashCode);
    });

    test('stops at a value that cannot be read yet', () {
      const chips = [
        ValueChip(
          entry: EntryBuffer([Token(digits: '2', unit: Unit.foot)]),
          isActive: false,
        ),
        ValueChip(
          operator: Operator.add,
          entry: EntryBuffer([
            Token(digits: '18', unit: Unit.foot),
            Token(digits: '8'),
          ]),
        ),
      ];
      expect(evaluator.fold(chips), const ChainEmpty());
    });

    test('a result restarts the count of steps', () {
      const chips = [
        ResultChip(key: 'Calc', value: Scalar(3)),
        ValueChip(
          operator: Operator.multiply,
          entry: EntryBuffer([Token(digits: '89')]),
        ),
      ];
      expect(evaluator.fold(chips), const ChainValue(Scalar(267), steps: 1));
    });

    test('a result chip carrying an operator continues the chain', () {
      const chips = [
        ValueChip(entry: EntryBuffer([Token(digits: '2')]), isActive: false),
        ResultChip(key: 'Area', value: Scalar(3), operator: Operator.add),
      ];
      expect(evaluator.fold(chips), const ChainValue(Scalar(5), steps: 1));
    });

    test('a failed step is the fold until a chip with no operator', () {
      const pounds = ValueChip(
        entry: EntryBuffer([Token(digits: '5', unit: Unit.pound)]),
        isActive: false,
      );
      const feet = ValueChip(
        operator: Operator.add,
        entry: EntryBuffer([Token(digits: '12', unit: Unit.foot)]),
        isActive: false,
      );
      const three = ValueChip(
        operator: Operator.multiply,
        entry: EntryBuffer([Token(digits: '3')]),
      );
      expect(evaluator.fold(const [pounds, feet, three]), isA<ChainFailed>());
      expect(
        evaluator.fold(const [pounds, feet, pounds, three]),
        const ChainValue(Weight(1500, unit: Unit.pound), steps: 1),
      );
    });

    test('outcomes compare by what they carry', () {
      final steps = int.parse('1');
      expect(
        ChainValue(const Scalar(20), steps: steps),
        const ChainValue(Scalar(20), steps: 1),
      );
      // ignore: prefer_const_constructors
      final failed = ChainFailed(
        CalculationError.dimensionError,
        left: const Scalar(1),
        operator: Operator.add,
        right: const Scalar(2),
      );
      expect(
        failed,
        const ChainFailed(
          CalculationError.dimensionError,
          left: Scalar(1),
          operator: Operator.add,
          right: Scalar(2),
        ),
      );
      expect(
        ChainEvaluator(parser: QuantityParser(poundsPerTon: int.parse('2000'))),
        evaluator,
      );
    });
  });
}
