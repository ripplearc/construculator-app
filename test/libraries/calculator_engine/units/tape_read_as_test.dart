import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  TapeOutcome pressKey(Tape tape, String key) => switch (key) {
    'DMS' => tape.pressDmsKey(),
    'SIN' => tape.pressTrigKey(TrigFunction.sine),
    'COS' => tape.pressTrigKey(TrigFunction.cosine),
    'TAN' => tape.pressTrigKey(TrigFunction.tangent),
    'ASIN' => tape.pressTrigKey(TrigFunction.arcsine),
    'ACOS' => tape.pressTrigKey(TrigFunction.arccosine),
    'ATAN' => tape.pressTrigKey(TrigFunction.arctangent),
    'pill' => tape.reInput(),
    'ft' => tape.pressUnit(Unit.foot),
    'in' => tape.pressUnit(Unit.inch),
    '×' => tape.pressOperator(Operator.multiply),
    '+' => tape.pressOperator(Operator.add),
    '−' => tape.pressOperator(Operator.subtract),
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

  String suffixOf(NumberReading reading, String text, ValueChip chip) =>
      switch (reading) {
        NumberReading.degrees when text.endsWith('.') => '',
        NumberReading.degrees =>
          chip.readsDegrees || chip.trigFunction != null ? '°' : '',
        NumberReading.degreesMinutesSeconds => '',
      };

  String? pill(Tape tape) {
    final offer = tape.readAsOffer;
    if (offer == null) return null;
    final chip = tape.chips[offer.chipIndex] as ValueChip;
    final verb = offer.rebuildsAnAnswer ? 'Re-input' : 'Input';
    final current = chip.entry.text;
    final next = offer.next.text;
    return '$verb $current${suffixOf(offer.from, current, chip)} '
        'as $next${suffixOf(offer.to, next, chip)}';
  }

  String chipText(Tape tape, int index) =>
      (tape.chips[index] as ValueChip).entry.text;

  String lastResult(Tape tape) {
    if (tape.chips.last case ResultChip(:final key, :final value)) {
      return '$key ${formatter.format(value)}';
    }
    throw StateError('not a result: ${tape.chips.last}');
  }

  group('Tape Read-as pill (F2b)', () {
    group('a number read as degrees (walkthrough 16.4)', () {
      test('S91: an open keypad is not context; [SIN] brings the question '
          'with the answer, and the tap rebuilds it', () {
        var tape = press(const Tape(), '3 8 . 3 0');
        expect(tape.readAsOffer, isNull);
        tape = press(tape, 'SIN');
        expect(lastResult(tape), 'Sine 0.619779');
        expect(pill(tape), "Re-input 38.30° as 38°30'");
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), "38°30'");
        expect(lastResult(tape), 'Sine 0.622515');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '38.30');
        expect(lastResult(tape), 'Sine 0.619779');
      });

      test('a pending division is not an angle', () {
        expect(press(const Tape(), '1 2 . 5 ÷ 3').readAsOffer, isNull);
      });

      test('a bare number beside a plain result is a plain number', () {
        expect(press(const Tape(), '3 × 4 = + 1 2 . 1').readAsOffer, isNull);
        expect(press(const Tape(), '3 × 4 = − 1 2 . 1').readAsOffer, isNull);
      });

      test('term 2.14: the pill offers readings only for the number on the '
          'display, so an operator that moves on from the angle ends it', () {
        final moved = press(const Tape(), 'SIN 1 2 . 1 ÷ 3 . 5');
        expect(moved.active!.entry.text, '3.5');
        expect(moved.readAsOffer, isNull);
        expect(press(const Tape(), 'SIN 1 2 . 1 ÷').readAsOffer, isNull);
      });

      test('term 2.14: a number under a trig key after an operator gets the '
          'pill like any other', () {
        var tape = press(const Tape(), '5 × SIN 1 2 . 1');
        expect(pill(tape), "Input 12.1° as 12°01'");
        tape = press(tape, 'pill');
        expect(tape.active!.entry.text, "12°01'");
        expect(lastResult(press(tape, '=')), 'Calc 1.04');
        expect(
          pill(press(const Tape(), 'SIN 1 2 . 1 × COS 3 3 . 3')),
          "Input 33.3° as 33°03'",
          reason: 'the number on the display is the 33.3',
        );
        expect(
          pill(press(const Tape(), '[Width] 3 ft × SIN 1 2 . 1')),
          "Input 12.1° as 12°01'",
        );
      });

      test('term 2.14: a plain number added to an angle answer gets no pill, '
          'because it can only be degrees', () {
        final sum = press(const Tape(), '0 . 5 ACOS + 1 2 . 1');
        expect(sum.readAsOffer, isNull);
        expect(lastResult(press(sum, '=')), 'Calc 72.1°');
        expect(press(const Tape(), '0 . 5 ACOS − 1 2 . 1').readAsOffer, isNull);
      });

      test('S114: the prefix order asks while typing, the postfix order '
          'once the key lands', () {
        expect(
          pill(press(const Tape(), 'SIN 1 2 . 1')),
          "Input 12.1° as 12°01'",
        );
        var tape = press(const Tape(), '1 2 . 1');
        expect(tape.readAsOffer, isNull);
        tape = press(tape, 'SIN');
        expect(pill(tape), "Re-input 12.1° as 12°01'");
        expect(lastResult(tape), 'Sine 0.209619');
        expect(lastResult(press(tape, 'pill')), 'Sine 0.208196');
      });

      test('inverse trig is never asked: a ratio has no minutes', () {
        expect(press(const Tape(), 'ASIN 0 . 5').readAsOffer, isNull);
        expect(press(const Tape(), '0 . 5 ASIN').readAsOffer, isNull);
      });

      test('a whole number, a trailing point and a D:M:S with seconds typed '
          'ask nothing', () {
        expect(press(const Tape(), 'SIN 3 8').readAsOffer, isNull);
        expect(press(const Tape(), 'SIN 3 8 .').readAsOffer, isNull);
        expect(press(const Tape(), 'SIN 3 8 . 3 0 . 4').readAsOffer, isNull);
      });

      test('S113: the tap closes the minutes, and the spelling survives the '
          'tape and the answer', () {
        var tape = press(const Tape(), 'SIN 4 5 . 2');
        expect(pill(tape), "Input 45.2° as 45°02'");
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), "45°02'");
        final answer = tape.trigAnswer;
        tape = tape.append(ResultChip(key: answer!.key, value: answer.value));
        expect(lastResult(tape), 'Sine 0.707518');
        expect(chipText(tape, 0), "45°02'");
      });

      test('S116: the pill goes with the display: once it shows 3.5 nothing '
          'names the 12.1', () {
        final tape = press(const Tape(), 'SIN 1 2 . 1 ÷ 3 . 5');
        expect(tape.active!.entry.text, '3.5');
        expect(tape.readAsOffer, isNull);
      });

      test('term 2.14: no pill whose reading gives no answer under the key, '
          'and no message says so', () {
        final answered = press(const Tape(), '8 9 . 6 0 TAN');
        expect(lastResult(answered), 'Tangent 143.237122');
        expect(answered.readAsOffer, isNull);
        expect(
          answered.reInput(),
          const TapeRefused(TapeRefusal.nothingToReInput),
        );
        expect(press(const Tape(), 'TAN 8 9 . 6 0').readAsOffer, isNull);
        expect(press(const Tape(), 'TAN 8 9 . 6 0 ÷ 2').readAsOffer, isNull);
        expect(
          press(const Tape(), 'SIN 8 9 . 6 0').readAsOffer,
          isNull,
          reason: 'a reading of 90° or more is never offered, under any key',
        );
        expect(press(const Tape(), 'COS 8 9 . 6 0').readAsOffer, isNull);
        expect(press(const Tape(), 'SIN 9 0 . 3 0').readAsOffer, isNull);
        expect(
          press(const Tape(), 'TAN 9 0 . 0 0 .').readAsOffer,
          isNull,
          reason: 'the way back to 90.00 has no tangent either',
        );
        expect(
          pill(press(const Tape(), 'SIN 9 0 . 0 0 .')),
          "Input 90°00' as 90.00°",
        );
        expect(
          pill(press(const Tape(), 'SIN 8 9 . 5 9')),
          "Input 89.59° as 89°59'",
        );
      });

      test('a named chip being typed is not an angle, and an answer ends the '
          'question', () {
        expect(
          press(const Tape(), 'SIN 1 2 . 1 × [Width] 3').readAsOffer,
          isNull,
        );
        final answered = press(const Tape(), '1 2 . 1 SIN');
        expect(
          answered.append(const ValueChip(operator: Operator.add)).readAsOffer,
          isNull,
        );
      });

      test('the offer names its readings the right way round, and the way '
          'back the other', () {
        var tape = press(const Tape(), 'SIN 3 8 . 3 0');
        var offer = tape.readAsOffer!;
        expect(offer.from, NumberReading.degrees);
        expect(offer.to, NumberReading.degreesMinutesSeconds);
        tape = press(tape, 'pill');
        offer = tape.readAsOffer!;
        expect(offer.from, NumberReading.degreesMinutesSeconds);
        expect(offer.to, NumberReading.degrees);
        expect(offer.next.text, '38.30');
      });

      test('the way back belongs to the digits it was made from: ⌫ on a '
          'segment digit removes the pill, reopening a segment keeps it', () {
        var tape = press(const Tape(), 'SIN 3 8 . 3 0 pill');
        expect(pill(tape), "Input 38°30' as 38.30°");
        tape = press(tape, '⌫');
        expect(chipText(tape, 0), "38°30'");
        expect(pill(tape), "Input 38°30' as 38.30°", reason: 'same digits');
        expect(
          pill(press(tape, 'DMS')),
          "Input 38°30' as 38.30°",
          reason: 'the key re-closes the same digits',
        );
        tape = press(tape, '⌫');
        expect(chipText(tape, 0), "38°3'");
        expect(tape.readAsOffer, isNull);
        expect(formatter.format(tape.trigAnswer!.value), '0.616349');
        expect(
          press(const Tape(), 'SIN 3 8 DMS').readAsOffer,
          isNull,
          reason:
              'a whole number read as D:M:S has no second reading to go back to',
        );
        final postfix = press(const Tape(), '3 8 . 3 0 SIN pill ⌫ ⌫ ⌫');
        expect(chipText(postfix, 0), "38°3'");
        expect(postfix.readAsOffer, isNull);
      });
    });

    test('the pill tapped with nothing to re-input is refused, and inside a '
        'bracket nothing asks', () {
      expect(
        const Tape().reInput(),
        const TapeRefused(TapeRefusal.nothingToReInput),
      );
      expect(
        press(const Tape(), '[Width] 8 . 4 5').reInput(),
        const TapeRefused(TapeRefusal.nothingToReInput),
      );
      expect(press(const Tape(), '( 8 . 4 5').readAsOffer, isNull);
    });

    test('offers compare by what they carry', () {
      const next = EntryBuffer([Token(digits: '8')]);
      expect(
        const ReadAsOffer(
          chipIndex: 0,
          from: NumberReading.degrees,
          to: NumberReading.degreesMinutesSeconds,
          next: next,
        ),
        const ReadAsOffer(
          chipIndex: 0,
          from: NumberReading.degrees,
          to: NumberReading.degreesMinutesSeconds,
          next: next,
        ),
      );
      expect(
        const ReadAsOffer(
          chipIndex: 0,
          from: NumberReading.degrees,
          to: NumberReading.degreesMinutesSeconds,
          next: next,
        ),
        isNot(
          const ReadAsOffer(
            chipIndex: 0,
            from: NumberReading.degrees,
            to: NumberReading.degreesMinutesSeconds,
            next: next,
            rebuildsAnAnswer: true,
          ),
        ),
      );
    });
  });
}
