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
        '×' => current.pressOperator(Operator.multiply),
        '÷' => current.pressOperator(Operator.divide),
        '+' => current.pressOperator(Operator.add),
        '−' => current.pressOperator(Operator.subtract),
        '(' => current.pressBracket(),
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

  String lastResult(Tape tape) {
    if (tape.chips.last case ResultChip(:final key, :final value)) {
      return '$key ${formatter.format(value)}';
    }
    throw StateError('the tape does not end on a result: ${tape.chips}');
  }

  String bracketText(Tape tape) {
    for (final chip in tape.chips.reversed) {
      if (chip case final BracketChip bracket) return bracket.expression;
    }
    throw StateError('no bracket on the tape');
  }

  group('Tape brackets', () {
    group('set the priority', () {
      test('2 + (3 × 4) = 14 where 2 + 3 × 4 = 20 (12.6)', () {
        expect(lastResult(press(const Tape(), '2 + ( 3 × 4 ( =')), 'Calc 14');
        expect(lastResult(press(const Tape(), '2 + 3 × 4 =')), 'Calc 20');
      });

      test('the inside runs left to right too: 2 × (1 + 2 × 3) = 18', () {
        expect(
          lastResult(press(const Tape(), '2 × ( 1 + 2 × 3 ( =')),
          'Calc 18',
        );
      });

      test('a bracket in a chain with a unit: 4ft × (3 + 2) = 20ft (12.7)', () {
        expect(
          lastResult(press(const Tape(), '4 ft × ( 3 + 2 ( =')),
          'Calc 20ft 0in',
        );
      });

      test('a bracket closes to a value of any dimension', () {
        expect(
          lastResult(press(const Tape(), '( 3 ft + 2 ft ( × 4 ft =')),
          'Calc 20ft²',
        );
        expect(
          lastResult(
            press(const Tape(), '( 8 ft + 4 ft ( × 9 ft ÷ 3 2 ft ft ='),
          ),
          'Calc 3.38',
        );
      });

      test('a chain can hold several brackets: (1 + 2) × (3 + 4) = 21', () {
        expect(
          lastResult(press(const Tape(), '( 1 + 2 ( × ( 3 + 4 ( =')),
          'Calc 21',
        );
      });

      test('a bracket that starts a chain: (2 + 3) × 4 = 20', () {
        final tape = press(const Tape(), '( 2 + 3 (');
        expect(bracketText(tape), '(2+3)');
        expect(lastResult(press(tape, '× 4 =')), 'Calc 20');
      });

      test('a bracket keeps its exact value: (1 ÷ 3) × 3,000,000', () {
        expect(
          lastResult(press(const Tape(), '( 1 ÷ 3 ( × 3 0 0 0 0 0 0 =')),
          'Calc 1,000,000',
        );
      });

      test(
        'an operator after a closed bracket carries on: 2 + (3 × 4) × 5 = 70',
        () {
          expect(
            lastResult(press(const Tape(), '2 + ( 3 × 4 ( × 5 =')),
            'Calc 70',
          );
        },
      );
    });

    group('the bracket chip', () {
      test('grows from "+(" to "+(3×4" and closes to "+(3×4)"', () {
        var tape = press(const Tape(), '2 + (');
        expect(bracketText(tape), '+(');
        expect(tape.openBracket, isNotNull);
        tape = press(tape, '3 × 4');
        expect(bracketText(tape), '+(3×4');
        tape = press(tape, '(');
        expect(bracketText(tape), '+(3×4)');
        expect(tape.openBracket, isNull);
        expect(tape.chips.length, 2);
      });

      test('offers no Calc while open and Calc 14 once closed', () {
        final open = press(const Tape(), '2 + ( 3 × 4');
        expect(open.runningTotal, const ChainEmpty());
        final closed = press(open, '(');
        expect(closed.runningTotal, const ChainValue(Scalar(14), steps: 1));
      });

      test('= with a bracket open closes it first and lands the Calc', () {
        expect(lastResult(press(const Tape(), '2 + ( 3 × 4 =')), 'Calc 14');
      });

      test('a dangling operator inside is dropped when the bracket closes', () {
        final tape = press(const Tape(), '2 + ( 3 × (');
        expect(bracketText(tape), '+(3)');
        expect(lastResult(press(tape, '=')), 'Calc 5');
      });
    });

    group('what a bracket refuses (12.9)', () {
      test('empty brackets are removed and the operator waits again', () {
        final outcome = press(const Tape(), '2 + (').pressBracket();
        expect(outcome, isA<TapeChanged>());
        final removed = outcome as TapeChanged;
        expect(removed.notice, TapeNotice.emptyBracketsRemoved);
        expect(removed.tape.active!.operator, Operator.add);
        expect(removed.tape.active!.entry.isEmpty, isTrue);
        expect(lastResult(press(removed.tape, '3 =')), 'Calc 5');
      });

      test('= on an empty open bracket removes it and says why', () {
        final outcome = press(const Tape(), '2 + (').pressEquals();
        expect(
          (outcome as TapeChanged).notice,
          TapeNotice.emptyBracketsRemoved,
        );
        expect(outcome.tape.chips.length, 2);
      });

      test('an empty bracket after a value gives the value back, active', () {
        final closed = press(const Tape(), '2 ( (');
        expect(closed.active!.entry.text, '2');
        final continued = press(closed, '5');
        expect(continued.chips, hasLength(1));
        expect(continued.active!.entry.text, '25');
        final backspaced = press(const Tape(), '2 ( ⌫ 5');
        expect(backspaced.chips, hasLength(1));
        expect(backspaced.active!.entry.text, '25');
      });

      test('an empty bracket that started the tape leaves it empty', () {
        final outcome = press(const Tape(), '(').pressBracket();
        expect((outcome as TapeChanged).tape.isEmpty, isTrue);
      });

      test('the key closes, never nests: 2 + ( 3 ( gives 2 + (3)', () {
        final tape = press(const Tape(), '2 + ( 3 (');
        expect(bracketText(tape), '+(3)');
        expect(tape.openBracket, isNull);
      });

      test('( by another path while one is open is one bracket at a time', () {
        expect(
          press(const Tape(), '2 + ( 3').openNewBracket(),
          const TapeRefused(TapeRefusal.oneBracketAtATime),
        );
      });

      test(
        'a digit straight after a closed bracket needs an operator first',
        () {
          expect(
            press(const Tape(), '2 + ( 3 × 4 (').typeDigit('5'),
            const TapeRefused(TapeRefusal.addAnOperatorFirst),
          );
        },
      );

      test('a unit straight after a closed bracket is refused', () {
        expect(
          press(const Tape(), '2 + ( 3 × 4 (').pressUnit(Unit.foot),
          const TapeRefused(TapeRefusal.groupCannotTakeUnit),
        );
      });

      test('a refusal inside a bracket passes through unchanged', () {
        expect(
          press(const Tape(), '( 3 0 . 4').typeDigit('.'),
          const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
        );
      });

      test('a fraction types inside a bracket like anywhere else', () {
        final tape = changed(press(const Tape(), '( 7').typeFraction());
        expect(bracketText(press(tape, '1 6 in (')), '(7/16in)');
      });

      test('a function key inside a bracket is refused', () {
        expect(
          press(const Tape(), '2 + ( 3').pressFunctionKey('Length'),
          const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic),
        );
      });

      test('closing with nothing open is nothing to close', () {
        expect(
          const Tape().closeBracket(),
          const TapeRefused(TapeRefusal.noBracketToClose),
        );
      });

      test('a bracket cannot open on a number with no unit', () {
        expect(
          press(const Tape(), '1 8 ft 8').pressBracket(),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });

      test('a bracket cannot close on a number with no unit', () {
        expect(
          press(const Tape(), '( 1 8 ft 8').pressBracket(),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });

      test('an inside that cannot be read is treated as unfinished', () {
        const mixed = Tape(
          chips: [
            BracketChip(
              inner: [
                InputChip(
                  entry: EntryBuffer([
                    Token(digits: '5', unit: Unit.pound),
                    Token(digits: '3', unit: Unit.foot),
                  ]),
                ),
              ],
            ),
          ],
        );
        expect(
          mixed.closeBracket(),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });
    });

    group('an error inside a bracket (Section 5.3)', () {
      test('keeps the bracket open with everything typed and ⌫ repairs it', () {
        final open = press(const Tape(), '1 ft + ( 1 ft + 2');
        final outcome = open.pressBracket();
        expect(outcome, isA<TapeBracketFailed>());
        final failed = (outcome as TapeBracketFailed).failure;
        expect(failed.error, CalculationError.dimensionError);
        expect(failed.left, const Length(768, unit: Unit.foot));
        expect(failed.right, const Scalar(2));
        final repaired = press(open, 'ft (');
        expect(bracketText(repaired), '+(1ft+2ft)');
        expect(lastResult(press(repaired, '=')), 'Calc 4ft 0in');
      });

      test('division by zero inside keeps the bracket open too', () {
        final outcome = press(const Tape(), '( 1 ÷ 0').pressEquals();
        expect(
          (outcome as TapeBracketFailed).failure.error,
          CalculationError.divisionByZero,
        );
      });
    });

    group('⌫ and brackets', () {
      test(
        'removes the last token inside, then the bracket, and the operator waits',
        () {
          var tape = press(const Tape(), '2 + ( 3');
          tape = press(tape, '⌫');
          expect(bracketText(tape), '+(');
          tape = press(tape, '⌫');
          expect(tape.openBracket, isNull);
          expect(tape.active!.operator, Operator.add);
          expect(tape.chips.length, 2);
        },
      );

      test('straight after ) reopens the bracket in place (12.8 via ⌫)', () {
        var tape = press(const Tape(), '2 + ( 3 × 4 (');
        tape = press(tape, '⌫');
        expect(bracketText(tape), '+(3×4');
        expect(tape.openBracket, isNotNull);
        tape = press(tape, '⌫ 1 (');
        expect(bracketText(tape), '+(3×1)');
        expect(lastResult(press(tape, '× 5 =')), 'Calc 25');
      });

      test('reopening an empty closed bracket keeps it open and empty', () {
        const closed = Tape(chips: [BracketChip(isOpen: false)]);
        final reopened = changed(closed.backspace());
        expect(reopened.openBracket, isNotNull);
      });
    });

    group('brackets and other values', () {
      test('a bracket after a finished value is a separate value', () {
        final tape = press(const Tape(), '2 ( 3 (');
        expect(tape.chips.length, 2);
        expect(tape.runningTotal, const ChainValue(Scalar(3), steps: 0));
      });

      test('a function key after a closed bracket starts a new named chip', () {
        final tape = press(const Tape(), '( 3 ( [Length]');
        expect(tape.active!.key, 'Length');
        expect(tape.chips.length, 2);
      });

      test('a bracket after a result continues the chain with an operator', () {
        expect(
          lastResult(press(const Tape(), '2 + 3 = × ( 4 + 1 ( =')),
          'Calc 25',
        );
      });

      test('a bracket replaces an empty named chip', () {
        final tape = press(const Tape(), '[Length] (');
        expect(tape.chips.length, 1);
        expect(tape.openBracket, isNotNull);
      });
    });

    test('a closed bracket whose inside cannot be read folds to nothing', () {
      const broken = Tape(
        chips: [
          BracketChip(
            isOpen: false,
            inner: [
              InputChip(
                entry: EntryBuffer([
                  Token(digits: '5', unit: Unit.pound),
                  Token(digits: '3', unit: Unit.foot),
                ]),
                isActive: false,
              ),
            ],
          ),
        ],
      );
      expect(broken.runningTotal, const ChainEmpty());
    });

    test('a bracket chip copies with fields cleared or kept', () {
      const chip = BracketChip(
        operator: Operator.add,
        inner: [
          InputChip(entry: EntryBuffer([Token(digits: '3')])),
        ],
        isOpen: false,
      );
      expect(
        chip.copyWith(operator: () => null, inner: [], isOpen: true),
        const BracketChip(),
      );
      expect(chip.copyWith(), chip);
      expect(chip.expression, '+(3)');
    });

    test('outcomes compare by what they carry', () {
      final notice = TapeNotice.values[int.parse('0')];
      expect(
        TapeChanged(const Tape(), notice: notice),
        const TapeChanged(Tape(), notice: TapeNotice.emptyBracketsRemoved),
      );
      final error = CalculationError.values[int.parse('0')];
      expect(
        TapeBracketFailed(
          ChainFailed(
            error,
            left: const Scalar(1),
            operator: Operator.add,
            right: const Scalar(2),
          ),
        ),
        const TapeBracketFailed(
          ChainFailed(
            CalculationError.dimensionError,
            left: Scalar(1),
            operator: Operator.add,
            right: Scalar(2),
          ),
        ),
      );
    });
  });
}
