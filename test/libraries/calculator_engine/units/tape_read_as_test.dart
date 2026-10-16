import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();
  const rules = DeterministicRules();

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
    '⌫' => tape.backspace(),
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
        NumberReading.grade || NumberReading.ratio => '%',
        NumberReading.risePerFoot => '/12in',
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

  List<String> strip(Tape tape) => [
    for (final answer in rules.answersFor(tape.namedValues))
      '${answer.key}: ${formatter.format(answer.value)}',
  ];

  group('Tape Read-as pill (F2b)', () {
    group('under Pitch (walkthrough 17.4)', () {
      test('S86: every reading reachable, none guessed, and a full lap comes '
          'home to what was typed', () {
        var tape = press(const Tape(), '[Pitch] 8');
        expect(pill(tape), 'Input 8° as 8in/12in');
        tape = press(tape, '.');
        expect(pill(tape), "Input 8. as 8°00'");
        tape = press(tape, '4 5');
        expect(chipText(tape, 0), '8.45');
        expect(pill(tape), 'Input 8.45° as 8.45in/12in');
        expect(strip(tape).first, 'Pitch-degrees: 8.45°');

        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '8.45in');
        expect(strip(tape).first, 'Pitch-degrees: 35.16°');
        expect(pill(tape), "Input 8.45in/12in as 8°45'");

        tape = press(tape, 'pill');
        expect(chipText(tape, 0), "8°45'");
        expect(strip(tape).first, 'Pitch-degrees: 8.75°');
        expect(pill(tape), "Input 8°45' as 8.45°");

        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '8.45');
        expect(pill(tape), 'Input 8.45° as 8.45in/12in');
        expect(tape, press(const Tape(), '[Pitch] 8 . 4 5'));
      });

      test('S86: the over-60 carry is previewed, and the way back returns '
          'the digits untouched', () {
        var tape = press(const Tape(), '[Pitch] 8 . 8 9');
        expect(pill(tape), 'Input 8.89° as 8.89in/12in');
        tape = press(tape, 'pill');
        expect(pill(tape), "Input 8.89in/12in as 9°29'");
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), "9°29'");
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '8.89');
      });

      test('a D:M:S typed in full is settled, and so is one with its '
          'minutes typed', () {
        expect(
          press(const Tape(), '[Pitch] 2 3 . 1 6 . 4 5').readAsOffer,
          isNull,
        );
        expect(press(const Tape(), '[Pitch] 3 8 DMS 3').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 3 8 DMS').readAsOffer, isNull);
      });

      test('S88: a bare 6 is 6°, and the pill offers the six-and-twelve a '
          'roofer meant', () {
        var tape = press(const Tape(), '[Pitch] 6');
        expect(strip(tape), [
          'Pitch-degrees: 6°',
          'Pitch-rise per 12in run: 1-1/4in/12in',
          'Pitch-grade: 10.5%',
        ]);
        expect(pill(tape), 'Input 6° as 6in/12in');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '6in');
        expect(strip(tape), contains('Pitch-degrees: 26.57°'));
        expect(pill(tape), 'Input 6in/12in as 6°');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '6');
        tape = press(tape, '.');
        expect(pill(tape), "Input 6. as 6°00'");
        tape = press(tape, '5');
        expect(pill(tape), 'Input 6.5° as 6.5in/12in');
        final twelve = press(const Tape(), '[Pitch] 1 2');
        expect(pill(twelve), 'Input 12° as 12in/12in');
        expect(strip(press(twelve, 'pill')), contains('Pitch-degrees: 45°'));
      });

      test('S115: the pill only offers a roof someone could frame', () {
        expect(
          pill(press(const Tape(), '[Pitch] 2 4')),
          'Input 24° as 24in/12in',
        );
        expect(
          pill(press(const Tape(), '[Pitch] 2 4 . 5')),
          "Input 24.5° as 24°05'",
        );
        expect(
          pill(press(const Tape(), '[Pitch] 3 0 . 4 5')),
          "Input 30.45° as 30°45'",
        );
        expect(press(const Tape(), '[Pitch] 1 0 0').readAsOffer, isNull);
        expect(
          pill(press(const Tape(), '[Pitch] 0 . 5')),
          'Input 0.5° as 0.5in/12in',
        );
        expect(
          ReadAsOffer.largestRisePerFoot,
          QuantityFormatter.inchesPerFootOfRun * ReadAsOffer.largestSlopeRatio,
          reason: 'both keys draw the line at the same roof',
        );
      });

      test('a length in feet, a fraction and a whole number ask nothing', () {
        expect(press(const Tape(), '[Pitch] 8 ft').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 7 / 1 6').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 0').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch]').readAsOffer, isNull);
      });

      test('a 30.45in pitch typed with [Inch] is past the band, so the pill '
          'walks the two readings left', () {
        var tape = press(const Tape(), '[Pitch] 3 0 . 4 5 in');
        expect(pill(tape), 'Input 30.45in/12in as 30.45°');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '30.45');
        expect(pill(tape), "Input 30.45° as 30°45'");
      });
    });

    group('under Slope (S92)', () {
      test('a percent by default, a ratio on request, and the way back', () {
        var tape = press(const Tape(), '[Slope] 0 . 6 5');
        expect(strip(tape)[1], 'Pitch-degrees: 0.37°');
        expect(pill(tape), 'Input 0.65% as 65%');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '65');
        expect(strip(tape)[1], 'Pitch-degrees: 33.02°');
        expect(pill(tape), 'Input 65% as 0.65%');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '0.65');
        expect(tape, press(const Tape(), '[Slope] 0 . 6 5'));
      });

      test('the band ends at 2, and a plain 7% grade is never asked about', () {
        expect(pill(press(const Tape(), '[Slope] 2')), 'Input 2% as 200%');
        expect(press(const Tape(), '[Slope] 2 . 1').readAsOffer, isNull);
        expect(press(const Tape(), '[Slope] 7').readAsOffer, isNull);
        expect(press(const Tape(), '[Slope] 0').readAsOffer, isNull);
        expect(press(const Tape(), '[Slope] 0 .').readAsOffer, isNull);
        expect(press(const Tape(), '[Slope] 1 .').readAsOffer, isNull);
      });

      test('the digits are shifted, never multiplied', () {
        expect(
          pill(press(const Tape(), '[Slope] 0 . 0 7')),
          'Input 0.07% as 7%',
        );
        expect(
          pill(press(const Tape(), '[Slope] 1 . 2 3 4')),
          'Input 1.234% as 123.4%',
        );
        expect(pill(press(const Tape(), '[Slope] 0 . 5')), 'Input 0.5% as 50%');
      });

      test('the way back belongs to the digits it was made from', () {
        final ratio = press(const Tape(), '[Slope] 0 . 6 5 pill');
        expect(press(ratio, '0').readAsOffer, isNull);
        expect(
          pill(press(const Tape(), '[Slope] 0 . 1 2 pill ⌫')),
          'Input 1% as 100%',
          reason: '⌫ changes the digits, so the way back is gone',
        );
      });
    });

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

      test('S116: the same wording on every pill that changes a number', () {
        expect(
          pill(press(const Tape(), 'SIN 1 2 . 1 ÷ 3 . 5')),
          "Input 12.1° as 12°01'",
        );
        expect(pill(press(const Tape(), '[Pitch] 6')), 'Input 6° as 6in/12in');
        expect(
          pill(press(const Tape(), '[Slope] 0 . 6 5')),
          'Input 0.65% as 65%',
        );
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
          to: NumberReading.risePerFoot,
          next: next,
        ),
        const ReadAsOffer(
          chipIndex: 0,
          from: NumberReading.degrees,
          to: NumberReading.risePerFoot,
          next: next,
        ),
      );
      expect(
        const ReadAsOffer(
          chipIndex: 0,
          from: NumberReading.degrees,
          to: NumberReading.risePerFoot,
          next: next,
        ),
        isNot(
          const ReadAsOffer(
            chipIndex: 0,
            from: NumberReading.degrees,
            to: NumberReading.risePerFoot,
            next: next,
            rebuildsAnAnswer: true,
          ),
        ),
      );
    });
  });
}
