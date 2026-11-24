import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();

  TapeOutcome pressKey(Tape tape, String key) => switch (key) {
    '%' => tape.pressPercent(),
    '+' => tape.pressOperator(Operator.add),
    '−' => tape.pressOperator(Operator.subtract),
    '×' => tape.pressOperator(Operator.multiply),
    '÷' => tape.pressOperator(Operator.divide),
    '=' => tape.pressEquals(),
    '(' || ')' => tape.pressBracket(),
    '⌫' => tape.backspace(),
    '✕' => tape.clearActive(),
    'ft' => tape.pressUnit(Unit.foot),
    'in' => tape.pressUnit(Unit.inch),
    'DMS' => tape.pressDmsKey(),
    '/' => tape.typeFraction(),
    'SIN' => tape.pressTrigKey(TrigFunction.sine),
    _ when key.startsWith('tap') => tape.tapChip(int.parse(key.substring(3))),
    _ when key.startsWith('[') => tape.pressFunctionKey(
      key.substring(1, key.length - 1),
      keyWantsUnit: !PlainNumberKeys.all.contains(
        key.substring(1, key.length - 1),
      ),
    ),
    _ => tape.typeDigit(key),
  };

  Tape press(Tape tape, String keys) {
    var current = tape;
    for (final key in keys.split(' ')) {
      final outcome = pressKey(current, key);
      if (outcome case TapeChanged(:final tape)) {
        current = tape;
      } else {
        throw StateError('"$key" in "$keys" was refused: $outcome');
      }
    }
    return current;
  }

  TapeOutcome refusalOf(String keys, String key) =>
      pressKey(press(const Tape(), keys), key);

  String calc(String keys) {
    final tape = press(const Tape(), '$keys =');
    if (tape.chips.last case ResultChip(:final value)) {
      return formatter.format(value);
    }
    throw StateError('no result: ${tape.chips.last}');
  }

  String lastChipText(Tape tape) => switch (tape.chips.last) {
    ValueChip(:final operator, :final text) => '${operator?.symbol ?? ''}$text',
    BracketChip(:final expression) => expression,
    final TapeChip chip => '$chip',
  };

  String chipText(Tape tape, int index) => switch (tape.chips[index]) {
    ValueChip(:final operator, :final text) => '${operator?.symbol ?? ''}$text',
    BracketChip(:final expression) => expression,
    final TapeChip chip => '$chip',
  };

  group('the % key (CA-1376; UX Design Doc Section 7, "Percent")', () {
    group('after + or −, a percent of the running total', () {
      test('rows 350 and 386: 50 + 10 % = is 55, 1,000 + 500 + 10 % = is '
          '1,650, and the chip reads "+10%"', () {
        expect(calc('5 0 + 1 0 %'), '55');
        expect(calc('1 0 0 0 + 5 0 0 + 1 0 %'), '1,650');
        expect(
          lastChipText(press(const Tape(), '1 0 0 0 + 5 0 0 + 1 0 %')),
          '+10%',
        );
      });

      test('row 387: 1,000 − 10 % = is 900, the chip "−10%"', () {
        expect(calc('1 0 0 0 − 1 0 %'), '900');
        expect(lastChipText(press(const Tape(), '1 0 0 0 − 1 0 %')), '−10%');
      });

      test('row 389: each % works on the running total at that point, so '
          '50 + 10 % + 10 % = is 60.5', () {
        expect(calc('5 0 + 1 0 % + 1 0 %'), '60.5');
      });

      test('row 390: the percent is a plain number and the total keeps its '
          'unit: 5 Feet + 10 % = is 5ft 6in', () {
        expect(calc('5 ft + 1 0 %'), '5ft 6in');
      });

      test('row 393: inside an open bracket the percent is of the bracket\'s '
          'own total', () {
        expect(calc('2 0 0 + ( 1 0 0 0 + 5 0 0 + 1 0 %'), '1,850');
      });
    });

    group('after × or ÷, the number ÷ 100', () {
      test('row 388: 200 ÷ 10 % = is 2,000 and 200 × 10 % = is 20, the chips '
          '"÷10%" and "×10%"', () {
        expect(calc('2 0 0 ÷ 1 0 %'), '2,000');
        expect(calc('2 0 0 × 1 0 %'), '20');
        expect(lastChipText(press(const Tape(), '2 0 0 ÷ 1 0 %')), '÷10%');
      });

      test('row 391: the chain is worked left to right, so 2 + 3 × 10 % = '
          'is 0.5', () {
        expect(calc('2 + 3 × 1 0 %'), '0.5');
      });
    });

    group('a closed bracket an operator leads', () {
      test('takes the percent, worth the percent of what it folds to', () {
        expect(calc('2 0 0 + ( 5 + 5 ) %'), '220');
        expect(calc('2 0 0 × ( 5 + 5 ) %'), '20');
        expect(
          lastChipText(press(const Tape(), '2 0 0 + ( 5 + 5 ) %')),
          '+(5+5)%',
        );
      });

      test('5 ÷ ( 2 − 2 ) then % is refused: it would divide by zero', () {
        expect(
          refusalOf('5 ÷ ( 2 − 2 )', '%'),
          const TapeRefused(TapeRefusal.percentDividesByZero),
        );
        expect(
          refusalOf('5 + ( 2 − 2 )', '%'),
          isA<TapeChanged>(),
          reason: 'only a ÷ divides by it',
        );
      });

      test('a bracket that starts the chain, holds a unit, or is already a '
          'percent is refused', () {
        expect(
          refusalOf('( 5 + 5 )', '%'),
          const TapeRefused(TapeRefusal.percentNeedsAnOperator),
        );
        expect(
          refusalOf('2 ft + ( 5 ft + 5 ft )', '%'),
          const TapeRefused(TapeRefusal.percentHasNoUnit),
        );
        expect(
          refusalOf('2 0 0 + ( 5 + 5 ) %', '%'),
          const TapeRefused(TapeRefusal.alreadyAPercent),
        );
      });
    });

    group('refused with the tape unchanged (rule 4.12)', () {
      test('12 + then %: no number after the operator', () {
        expect(
          refusalOf('1 2 +', '%'),
          const TapeRefused(TapeRefusal.percentNeedsANumber),
        );
      });

      test('( 12 then %, a number on its own, an empty tape, and a named '
          'number: no operator leads it', () {
        expect(
          refusalOf('( 1 2', '%'),
          const TapeRefused(TapeRefusal.percentNeedsAnOperator),
        );
        expect(
          refusalOf('1 2', '%'),
          const TapeRefused(TapeRefusal.percentNeedsAnOperator),
        );
        expect(
          const Tape().pressPercent(),
          const TapeRefused(TapeRefusal.percentNeedsAnOperator),
        );
        expect(
          refusalOf('[Sides] 6', '%'),
          const TapeRefused(TapeRefusal.percentNeedsAnOperator),
        );
        expect(
          refusalOf('2 + 3 =', '%'),
          const TapeRefused(TapeRefusal.percentNeedsAnOperator),
        );
      });

      test('200 × 10 % then %: already a percent; 50 + 10 % + 10 % is not '
          'refused', () {
        expect(
          refusalOf('2 0 0 × 1 0 %', '%'),
          const TapeRefused(TapeRefusal.alreadyAPercent),
        );
        expect(press(const Tape(), '5 0 + 1 0 % + 1 0 %'), isA<Tape>());
      });

      test('row 394: 5 Feet + 10 Feet then %: a percent has no unit, nor '
          'does an angle', () {
        expect(
          refusalOf('5 ft + 1 0 ft', '%'),
          const TapeRefused(TapeRefusal.percentHasNoUnit),
        );
        expect(
          refusalOf('5 + 3 0 DMS 1 5', '%'),
          const TapeRefused(TapeRefusal.percentHasNoUnit),
        );
      });

      test('row 394: 50 + 10 % then Feet: that number is a percent; a digit, '
          'a point, D:M:S, a fraction, a function or trig key after it is '
          'refused as already a percent', () {
        expect(
          refusalOf('5 0 + 1 0 %', 'ft'),
          const TapeRefused(TapeRefusal.percentTakesNoUnit),
        );
        for (final key in const ['5', '.', 'DMS', '/', '[Length]', 'SIN']) {
          expect(
            refusalOf('5 0 + 1 0 %', key),
            const TapeRefused(TapeRefusal.alreadyAPercent),
            reason: key,
          );
        }
        expect(
          refusalOf('2 0 0 + ( 5 + 1 0 %', 'ft'),
          const TapeRefused(TapeRefusal.percentTakesNoUnit),
          reason: 'inside a bracket too',
        );
      });
    });

    test('a named number after an operator and a fraction with no unit are '
        'refused too', () {
      expect(
        refusalOf('2 + [Sides] 6', '%'),
        const TapeRefused(TapeRefusal.percentNeedsAnOperator),
      );
      expect(
        refusalOf('5 + 1 / 2', '%'),
        const TapeEntryRefused(EntryRefusal.fractionNeedsUnit),
      );
    });

    group('a percent reopened by a tap', () {
      test('is still finished: a digit, a point, D:M:S and a fraction are '
          'refused with "Already a percent" and a unit with "That number is '
          'a percent", and the answer stands (B1; rule 4.12)', () {
        for (final keys in ['1 0 0 0 + 1 0 % = tap1', '5 0 + 1 0 % + 2 tap1']) {
          final reopened = press(const Tape(), keys);
          for (final key in ['3', '.', 'DMS', '/']) {
            expect(
              pressKey(reopened, key),
              const TapeRefused(TapeRefusal.alreadyAPercent),
              reason: '$keys then $key',
            );
          }
          expect(
            pressKey(reopened, 'ft'),
            const TapeRefused(TapeRefusal.percentTakesNoUnit),
            reason: keys,
          );
          expect(chipText(reopened, 1), '+10%', reason: keys);
        }
        expect(calc('1 0 0 0 + 1 0 % = tap1'), '1,100');
        expect(calc('5 0 + 1 0 % + 2 tap1'), '57');
      });

      test('⌫ takes only the % off, and then the number is edited as any '
          'chip is and takes the % again (N8; Section 7, "One ⌫ removes only '
          'the %")', () {
        final plain = press(const Tape(), '5 0 + 1 0 % + 5 tap1 ⌫');
        expect(chipText(plain, 1), '+10');
        expect(plain.editing, isNotNull);
        expect(calc('5 0 + 1 0 % + 5 tap1 ⌫'), '65');

        final again = press(plain, '0 %');
        expect(chipText(again, 1), '+100%');
        expect(calc('5 0 + 1 0 % + 5 tap1 ⌫ 0 %'), '105');
      });

      test('% is judged against the chip that was reopened, so the reason '
          'fits it (N1)', () {
        final marked = press(const Tape(), '5 0 + 1 0 + 2 tap1 %');
        expect(chipText(marked, 1), '+10%');
        expect(calc('5 0 + 1 0 + 2 tap1 %'), '57');
        expect(
          refusalOf('5 0 + 1 0 % + 2 tap1', '%'),
          const TapeRefused(TapeRefusal.alreadyAPercent),
        );
        expect(
          refusalOf('5 0 + 1 0 + 2 tap0', '%'),
          const TapeRefused(TapeRefusal.percentNeedsAnOperator),
        );
      });
    });

    test('a percent that is not a plain number is never folded in silence: '
        'the step fails with a dimension error (B1)', () {
      final angle = press(const Tape(), '1 0 0 0 + 1 0 DMS');
      final chips = [
        angle.chips.first,
        (angle.chips.last as ValueChip).copyWith(isPercent: true),
      ];
      expect(
        const ChainEvaluator().fold(chips),
        isA<ChainFailed>().having(
          (failed) => failed.error,
          'error',
          CalculationError.dimensionError,
        ),
      );
    });

    test('a percent step that fails shows its own error, never a dimension '
        'error from the bare number (N3)', () {
      for (final keys in [
        '5 ft + 9 9 9 9 9 9 9 9 9 9 9 % + 9 9 9 9 9 9 9 9 9 9 9 %',
        '5 ft × 9 9 9 9 9 9 9 9 9 9 9 + 9 9 9 9 9 9 9 9 9 9 9 %',
        '1 9 9 9 9 9 9 9 ft × 1 0 0 0 + 1 9 9 9 9 9 9 9 %',
      ]) {
        expect(
          press(const Tape(), '$keys =').chips.last,
          isA<ErrorChip>().having(
            (chip) => chip.error,
            'error',
            CalculationError.outOfRange,
          ),
          reason: keys,
        );
      }
    });

    test(
      'a reopened percent bracket hides its % while it is open, so it '
      'never reads as a percent inside it, and shows it again closed (N5)',
      () {
        final closed = press(const Tape(), '2 0 0 + ( 5 + 5 ) %');
        expect(lastChipText(closed), '+(5+5)%');
        final reopened = press(closed, 'tap1');
        expect(lastChipText(reopened), '+(5+5');
        expect(lastChipText(press(reopened, ')')), '+(5+5)%');
      },
    );

    test('a chip that ÷ 0 or ✕ empties loses its percent mark, so the next '
        'digit types a new number (N7; rule 4.12)', () {
      expect(calc('2 0 0 ÷ 0 % = 5'), '40');
      expect(calc('5 ft ÷ 0 % = 2'), '2ft 6in');
      final cleared = press(const Tape(), '5 0 + 1 0 % ✕ 5');
      expect(lastChipText(cleared), '+5');
      expect(calc('5 0 + 1 0 % ✕ 5'), '55');
      expect(calc('2 0 0 ÷ 5 = tap1 ⌫ 0 % = 5'), '40');
    });

    test('row 391: one ⌫ removes only the %, on a number and on a bracket', () {
      final tape = press(const Tape(), '5 0 + 1 0 % ⌫');
      expect(tape, press(const Tape(), '5 0 + 1 0'));
      expect(lastChipText(tape), '+10');
      expect(
        press(const Tape(), '2 0 0 + ( 5 + 5 ) % ⌫'),
        press(const Tape(), '2 0 0 + ( 5 + 5 )'),
      );
    });

    test('= and an operator take a percent as any sealed number', () {
      expect(calc('5 0 + 1 0 % × 2'), '110');
      expect(
        press(const Tape(), '5 0 + 1 0 % +').chips[1],
        isA<ValueChip>().having((chip) => chip.isPercent, 'isPercent', isTrue),
      );
    });
  });
}
