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

  /// The pill as the prototype spells it: "Input 8.45° as 8.45in/12in".
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

      test('S114: the question follows the angle through an operator and '
          'points behind the active chip', () {
        var tape = press(const Tape(), 'SIN 1 2 . 1 ÷ 3 . 5');
        expect(pill(tape), "Input 12.1° as 12°01'");
        expect(tape.readAsOffer!.chipIndex, 0);
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), "12°01'");
        expect(chipText(tape, 1), '3.5');
        expect(tape.active!.entry.text, '3.5');
      });

      test('S114: a bare number beside an angle is degrees, so 60° + 12°01\' '
          'is 72.02°', () {
        var tape = press(const Tape(), '0 . 5 ACOS + 1 2 . 1');
        expect(pill(tape), "Input 12.1 as 12°01'");
        tape = press(tape, 'pill =');
        expect(lastResult(tape), 'Calc 72.02°');
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

      test('S116: the pill names the number it is talking about, even once '
          'the display has moved on', () {
        final tape = press(const Tape(), 'SIN 1 2 . 1 ÷ 3 . 5');
        expect(tape.active!.entry.text, '3.5');
        expect(pill(tape), "Input 12.1° as 12°01'");
      });

      test('an answer that cannot be rebuilt is removed (Section 5.5)', () {
        var tape = press(const Tape(), '8 9 . 6 0 TAN');
        expect(lastResult(tape), 'Tangent 143.237122');
        expect(pill(tape), "Re-input 89.60° as 90°00'");
        tape = press(tape, 'pill');
        expect(tape.chips, hasLength(1));
        expect(chipText(tape, 0), "90°00'");
      });

      test('the question follows the angle through a named chip, and stops '
          'at an answer', () {
        expect(
          pill(press(const Tape(), 'SIN 1 2 . 1 × [Width] 3')),
          "Input 12.1° as 12°01'",
        );
        final answered = press(const Tape(), '1 2 . 1 SIN');
        expect(
          answered.append(const ValueChip(operator: Operator.add)).readAsOffer,
          isNull,
        );
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
