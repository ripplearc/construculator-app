import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = QuantityParser();
  const formatter = QuantityFormatter();
  const rules = DeterministicRules();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  TapeOutcome pressKey(Tape tape, String key) => switch (key) {
    'DMS' => tape.pressDmsKey(),
    'SIN' => tape.pressTrigKey(TrigFunction.sine),
    'ASIN' => tape.pressTrigKey(TrigFunction.arcsine),
    'ACOS' => tape.pressTrigKey(TrigFunction.arccosine),
    'ATAN' => tape.pressTrigKey(TrigFunction.arctangent),
    'ft' => tape.pressUnit(Unit.foot),
    'in' => tape.pressUnit(Unit.inch),
    '×' => tape.pressOperator(Operator.multiply),
    '+' => tape.pressOperator(Operator.add),
    '÷' => tape.pressOperator(Operator.divide),
    '/' => tape.typeFraction(),
    '=' => tape.pressEquals(),
    '(' => tape.pressBracket(),
    '⌫' => tape.backspace(),
    _ when key.startsWith('[') => tape.pressFunctionKey(
      key.substring(1, key.length - 1),
      keyWantsUnit: !PlainNumberKeys.all.contains(
        key.substring(1, key.length - 1),
      ),
      readsDegrees: key == '[${PlainNumberKeys.pitch}]',
    ),
    _ => tape.typeDigit(key),
  };

  Tape press(Tape tape, String keys) {
    var current = tape;
    for (final key in keys.split(' ')) {
      current = changed(pressKey(current, key));
    }
    return current;
  }

  ValueChip activeOf(Tape tape) {
    final chip = tape.active;
    if (chip == null) throw StateError('no active chip on ${tape.chips}');
    return chip;
  }

  String activeText(Tape tape) => activeOf(tape).entry.text;

  String lastResult(Tape tape) {
    if (tape.chips.last case ResultChip(:final key, :final value)) {
      return '$key ${formatter.format(value)}';
    }
    throw StateError('not a result: ${tape.chips.last}');
  }

  List<String> strip(Tape tape) => [
    for (final answer in rules.answersFor(tape.namedValues))
      '${answer.key}: ${formatter.format(answer.value)}',
  ];

  group('Tape D:M:S entry (F2a)', () {
    group('the second decimal point', () {
      test('S85: under Pitch, 23.16.45 reads 23°16\'45" and solves as '
          '23.28°', () {
        var tape = press(const Tape(), '[Pitch] 2 3 . 1 6');
        expect(activeText(tape), '23.16');
        expect(strip(tape).first, 'Pitch-degrees: 23.16°');
        tape = press(tape, '.');
        expect(activeText(tape), "23°16'");
        expect(activeOf(tape).entry.isDegreesMinutesSeconds, isTrue);
        tape = press(tape, '4 5');
        expect(activeText(tape), '23°16\'45"');
        expect(
          activeOf(tape).value(parser),
          const Angle(
            23 + 16 / 60 + 45 / 3600,
            spelling: AngleSpelling.degreesMinutesSeconds,
          ),
        );
        expect(strip(tape), [
          'Pitch-degrees: 23.28°',
          'Pitch-rise per 12in run: 5-3/16in/12in',
          'Pitch-grade: 43%',
        ]);
      });

      test('S85: a length key on an angle explains itself', () {
        final angle = press(const Tape(), '[Pitch] 2 3 . 1 6 . 4 5');
        expect(
          angle.pressUnit(Unit.inch),
          const TapeEntryRefused(EntryRefusal.alreadyAnAngle),
        );
        expect(
          press(const Tape(), '3 8 DMS 3 0').pressUnit(Unit.foot),
          const TapeEntryRefused(EntryRefusal.alreadyAnAngle),
        );
        expect(
          press(const Tape(), 'SIN 3 8 . 3 0 .').pressUnit(Unit.foot),
          const TapeEntryRefused(EntryRefusal.alreadyAnAngle),
          reason: 'already an angle, before the trig key says it takes one',
        );
      });

      test('S85: closing the minutes carries 89 into 31°29\', and the seconds '
          'land normalised', () {
        var tape = press(const Tape(), '[Pitch] 3 0 . 8 9');
        expect(activeText(tape), '30.89');
        tape = press(tape, '.');
        expect(activeText(tape), "31°29'");
        tape = press(tape, '0 0');
        expect(activeText(tape), '31°29\'00"');
      });

      test('a bare number takes the point, and the trig keys read the '
          'angle (S87): 38°30\' [SIN] is the sine of 38.5°', () {
        final angle = press(const Tape(), '3 8 . 3 0 .');
        expect(activeText(angle), "38°30'");
        expect(activeOf(angle).key, isNull);
        expect(lastResult(press(angle, 'SIN')), 'Sine 0.622515');
        expect(lastResult(press(const Tape(), '3 8 . 5 SIN')), 'Sine 0.622515');
      });

      test('a forward trig chip takes the point, an inverse one does not', () {
        expect(activeText(press(const Tape(), 'SIN 1 2 . 1 .')), "12°01'");
        expect(
          press(const Tape(), 'ASIN 0 . 5').typeDigit('.'),
          const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
        );
      });

      test('Section 5.4: under Width, Slope or Sides the point is refused '
          'and the number stays as typed', () {
        for (final key in ['[Width]', '[Slope]', '[Sides]']) {
          final typed = press(const Tape(), '$key 1 2 . 5');
          expect(
            typed.typeDigit('.'),
            const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
            reason: key,
          );
          expect(activeText(typed), '12.5', reason: key);
        }
      });

      test('a third point changes nothing: an angle has three segments', () {
        final full = press(const Tape(), '2 3 . 1 6 . 4 5');
        expect(full.typeDigit('.'), TapeChanged(full));
      });

      test('a number that continues a compound cannot become an angle', () {
        expect(
          press(const Tape(), '1 8 ft 8 . 5').typeDigit('.'),
          const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
        );
      });
    });

    group('the D:M:S key', () {
      test('walkthrough 16.3: 38 [D:M:S] 30 [D:M:S] 45 types 38°30\'45", and '
          '[SIN] answers from 38.5125°', () {
        var tape = press(const Tape(), '3 8 DMS');
        expect(activeText(tape), '38°');
        tape = press(tape, '3 0');
        expect(activeText(tape), "38°30'");
        tape = press(tape, 'DMS 4 5');
        expect(activeText(tape), '38°30\'45"');
        final full = press(tape, 'DMS');
        expect(
          full,
          tape,
          reason:
              'a fourth segment is refused without '
              'eating the third',
        );
        expect(lastResult(press(full, 'SIN')), 'Sine 0.622685');
        final operand = press(full, 'SIN').chips.first as ValueChip;
        expect(formatter.format(operand.trigOperand!), '38°30\'45"');
      });

      test('the key is the second decimal point made visible: 38.3 [D:M:S] '
          'closes the minutes', () {
        expect(activeText(press(const Tape(), '3 8 . 3 DMS')), "38°03'");
        expect(activeText(press(const Tape(), '3 8 . DMS')), '38°');
        expect(
          activeText(press(const Tape(), '[Pitch] 2 3 . 1 6 DMS 4 5')),
          '23°16\'45"',
        );
      });

      test('a point after the key opens the next segment, as the key does', () {
        expect(
          activeText(press(const Tape(), '3 8 DMS 3 0 . 4 5')),
          '38°30\'45"',
        );
        expect(
          activeText(press(const Tape(), '[Pitch] 3 8 DMS . 4 5')),
          '38°00\'45"',
        );
        final full = press(const Tape(), '3 8 DMS 3 0 DMS 4 5');
        expect(full.typeDigit('.'), TapeChanged(full));
      });

      test('S113: the padding is the seal, on the entry side', () {
        expect(activeText(press(const Tape(), '3 8 DMS 5')), "38°5'");
        expect(activeText(press(const Tape(), '3 8 DMS 5 9')), "38°59'");
        expect(activeText(press(const Tape(), '3 8 DMS 5 DMS')), "38°05'");
        expect(activeText(press(const Tape(), '3 8 DMS 5 DMS 9')), '38°05\'9"');
      });

      test('Section 5.4: on a value with a unit it is an angle format, not a '
          'length', () {
        expect(
          press(const Tape(), '3 8 ft').pressDmsKey(),
          const TapeRefused(TapeRefusal.dmsNeedsAPlainAngle),
        );
        expect(
          press(const Tape(), '1 8 ft 8').pressDmsKey(),
          const TapeRefused(TapeRefusal.dmsNeedsAPlainAngle),
        );
      });

      test('under a key that does not take an angle it is refused as the '
          'point is', () {
        expect(
          press(const Tape(), '[Width] 1 2').pressDmsKey(),
          const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
        );
        expect(
          press(const Tape(), 'ACOS 0 . 5').pressDmsKey(),
          const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
        );
      });

      test('with nothing typed it asks for a number', () {
        expect(
          const Tape().pressDmsKey(),
          const TapeRefused(TapeRefusal.typeANumberFirst),
        );
        expect(
          press(const Tape(), '[Pitch]').pressDmsKey(),
          const TapeRefused(TapeRefusal.typeANumberFirst),
        );
        expect(
          press(const Tape(), '1 2 ÷ 2 3 =').pressDmsKey(),
          const TapeRefused(TapeRefusal.typeANumberFirst),
        );
      });

      test('inside a bracket it is refused, as a function key is', () {
        expect(
          press(const Tape(), '( 3 8').pressDmsKey(),
          const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic),
        );
      });

      test('a fraction cannot be an angle', () {
        expect(
          press(const Tape(), '7 / 1 6').pressDmsKey(),
          const TapeEntryRefused(EntryRefusal.fractionNeedsUnit),
        );
        expect(
          press(const Tape(), '3 8 DMS').typeFraction(),
          const TapeEntryRefused(EntryRefusal.decimalCannotTakeFraction),
        );
      });

      test('backspace steps back through the segments to the plain number', () {
        var tape = press(const Tape(), '3 8 DMS 3 0 DMS 4 5 ⌫');
        expect(activeText(tape), '38°30\'4"');
        tape = press(tape, '⌫ ⌫ ⌫');
        expect(activeText(tape), "38°3'");
        tape = press(tape, '⌫ ⌫');
        expect(activeText(tape), '38');
        expect(activeOf(tape).value(parser), const Scalar(38));
      });
    });

    group('an angle answer converts in place', () {
      test('walkthrough 16.3: 12 ÷ 23 [ASIN] = 31.45° toggles to 31°26\'56" '
          'and back', () {
        var tape = press(const Tape(), '1 2 ÷ 2 3 ASIN');
        expect(lastResult(tape), 'Arcsine 31.45°');
        final stored = (tape.chips.last as ResultChip).value as Angle;
        tape = press(tape, 'DMS');
        expect(lastResult(tape), 'Arcsine 31°26\'56"');
        expect(
          (tape.chips.last as ResultChip).value,
          Angle(stored.degrees, spelling: AngleSpelling.degreesMinutesSeconds),
          reason: 'converted from the stored value, never the 2dp text',
        );
        tape = press(tape, 'DMS');
        expect(lastResult(tape), 'Arcsine 31.45°');
        expect((tape.chips.last as ResultChip).value, stored);
      });

      test('S107: a whole-degree answer keeps its minutes segment, and the '
          'round trip is lossless', () {
        expect(
          lastResult(press(const Tape(), '1 ACOS DMS')),
          "Arccosine 0°00'",
        );
        expect(
          lastResult(press(const Tape(), '0 . 5 ASIN DMS')),
          "Arcsine 30°00'",
        );
        final roof = press(const Tape(), '1 2 ÷ 2 3 ATAN');
        expect(lastResult(roof), 'Arctangent 27.55°');
        expect(lastResult(press(roof, 'DMS')), 'Arctangent 27°33\'10"');
        expect(lastResult(press(roof, 'DMS DMS')), 'Arctangent 27.55°');
      });

      test('Section 8: a pitch answer has no D:M:S, in any of its three '
          'spellings, and the key says why', () {
        const pitches = {
          DeterministicRules.pitchRiseKey: AngleSpelling.risePerFoot,
          DeterministicRules.pitchDegreesKey: AngleSpelling.degrees,
          DeterministicRules.pitchGradeKey: AngleSpelling.grade,
        };
        for (final MapEntry(:key, value: spelling) in pitches.entries) {
          final pitch = const Tape().append(
            ResultChip(
              key: key,
              value: Angle(26.57, spelling: spelling),
            ),
          );
          expect(
            pitch.pressDmsKey(),
            const TapeRefused(TapeRefusal.pitchHasNoDms),
            reason: key,
          );
        }
        final calc = press(const Tape(), '0 . 5 ASIN × 2 =');
        expect(lastResult(calc), 'Calc 60°');
        expect(
          lastResult(press(calc, 'DMS')),
          "Calc 60°00'",
          reason: 'an angle answer under any other key still converts',
        );
      });
    });

    group('an angle typed as D:M:S is an angle in the arithmetic', () {
      test('S114: 60° + 12°01\' = 72.02°', () {
        final tape = press(const Tape(), '0 . 5 ACOS + 1 2 . 1 . =');
        expect(lastResult(tape), 'Calc 72.02°');
      });

      test('38°30\' × 2 is 77°, and × 2ft is a Dimension Error', () {
        expect(
          lastResult(press(const Tape(), '3 8 DMS 3 0 × 2 =')),
          'Calc 77°',
        );
        final error = press(const Tape(), '3 8 DMS 3 0 × 2 ft =');
        expect(
          error.chips.last,
          const ErrorChip(CalculationError.dimensionError),
        );
      });

      test('an inverse key refuses it, since a ratio has no minutes', () {
        expect(
          press(const Tape(), '0 . 3 0 .').pressTrigKey(TrigFunction.arcsine),
          const TapeRefused(TapeRefusal.ratioOutOfRange),
        );
      });

      test('inside a bracket the point promotes a bare number too', () {
        expect(
          lastResult(press(const Tape(), '( 3 8 . 3 0 . + 1 ( =')),
          'Calc 39.5°',
        );
      });
    });
  });
}
