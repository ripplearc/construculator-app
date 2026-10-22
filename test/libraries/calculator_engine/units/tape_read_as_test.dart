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
    'COS' => tape.pressTrigKey(TrigFunction.cosine),
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
        expect(pill(tape), 'Input 8. as 8°00\'00"');
        tape = press(tape, '4 5');
        expect(chipText(tape, 0), '8.45');
        expect(pill(tape), 'Input 8.45° as 8.45in/12in');
        expect(strip(tape).first, 'Pitch-degrees: 8.45°');

        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '8.45in');
        // 8.45in is kept exactly (CA-1190): atan(8.45/12) is 35.15°, where the
        // tick-rounded 541/64in read 35.16°.
        expect(strip(tape).first, 'Pitch-degrees: 35.15°');
        expect(pill(tape), 'Input 8.45in/12in as 8°45\'00"');

        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '8°45\'00"');
        expect(strip(tape).first, 'Pitch-degrees: 8.75°');
        expect(pill(tape), 'Input 8°45\'00" as 8.45°');

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
        expect(pill(tape), 'Input 8.89in/12in as 9°29\'00"');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '9°29\'00"');
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
        expect(pill(tape), 'Input 6. as 6°00\'00"');
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
          'Input 24.5° as 24°05\'00"',
        );
        expect(
          pill(press(const Tape(), '[Pitch] 3 0 . 4 5')),
          'Input 30.45° as 30°45\'00"',
        );
        expect(press(const Tape(), '[Pitch] 1 0 0').readAsOffer, isNull);
        expect(
          pill(press(const Tape(), '[Pitch] 0 . 5')),
          'Input 0.5° as 0.5in/12in',
        );
        expect(
          ReadAsOffer.largestRisePerFoot,
          Angle.inchesPerFootOfRun * ReadAsOffer.largestSlopeRatio,
          reason: 'both keys draw the line at the same roof',
        );
      });

      test('an angle typed with the D:M:S key has one reading, so no pill '
          'offers to drop its minutes', () {
        expect(
          press(const Tape(), '[Pitch] 8 DMS 4 5 DMS').readAsOffer,
          isNull,
        );
        expect(
          press(const Tape(), '[Pitch] 1 2 DMS 3 0 DMS').readAsOffer,
          isNull,
        );
        expect(
          pill(press(const Tape(), '[Pitch] 8 . 4 5 .')),
          'Input 8°45\'00" as 8.45°',
          reason: 'typed digits exist to go back to',
        );
      });

      test('⌫ on a minutes digit after the laps drops the pill', () {
        var tape = press(const Tape(), '[Pitch] 8 . 4 5 pill pill');
        expect(pill(tape), 'Input 8°45\'00" as 8.45°');
        tape = press(tape, '⌫ ⌫ ⌫');
        expect(chipText(tape, 0), '8°');
        expect(tape.readAsOffer, isNull);
      });

      test('a digit after the tap continues the number, read by default', () {
        var tape = press(const Tape(), '[Pitch] 1 pill');
        expect(chipText(tape, 0), '1in');
        tape = press(tape, '2');
        expect(chipText(tape, 0), '12');
        expect(strip(tape).first, 'Pitch-degrees: 12°');
        expect(pill(tape), 'Input 12° as 12in/12in');
        final steep = press(const Tape(), '[Pitch] 6 pill 5');
        expect(chipText(steep, 0), '65');
        expect(strip(steep).first, 'Pitch-degrees: 65°');
        expect(
          steep.readAsOffer,
          isNull,
          reason: '65in/12in: nobody frames it',
        );
        expect(chipText(press(const Tape(), '[Pitch] 6 pill ⌫ 5'), 0), '65');
      });

      test(
        'rule 4.10: a point after the tap is the number\'s second point, so '
        'it opens D:M:S as it does without the tap, and the seconds go on',
        () {
          var tape = press(const Tape(), '[Pitch] 8 . 4 5 pill');
          expect(chipText(tape, 0), '8.45in');
          tape = press(tape, '.');
          expect(chipText(tape, 0), '8°45\'00"');
          expect(pill(tape), 'Input 8°45\'00" as 8.45°');
          tape = press(tape, '3 0');
          expect(chipText(tape, 0), '8°45\'30"');
          expect(tape.readAsOffer, isNull);
          expect(strip(tape).first, 'Pitch-degrees: 8.76°');
          expect(
            chipText(press(const Tape(), '[Pitch] 8 . 4 5 . 3 0'), 0),
            '8°45\'30"',
            reason: 'the same keys without the tap read the same',
          );
          expect(
            chipText(press(const Tape(), '[Pitch] 0 . 5 pill .'), 0),
            '0°05\'00"',
          );
          expect(chipText(press(const Tape(), '[Pitch] 6 pill .'), 0), '6.');
        },
      );

      test('a squared inch is not a rise, so the pill leaves it alone', () {
        expect(press(const Tape(), '[Pitch] 6 in in').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 6 pill in').readAsOffer, isNull);
      });

      test('rule 4.3: a square the Inch key typed on the pill\'s inch is the '
          'user\'s, so a digit after it starts a new token', () {
        final afterTheTap = press(const Tape(), '[Pitch] 6 pill in 5');
        final typed = press(const Tape(), '[Pitch] 6 in in 5');
        expect(chipText(afterTheTap, 0), '6in² 5');
        expect(chipText(typed, 0), '6in² 5');
        expect(afterTheTap.chips, hasLength(typed.chips.length));
        expect(strip(afterTheTap), isEmpty);
      });

      test('term 2.14: a rise the 1/64in rounding leaves at 0 has no answer, '
          'so its reading is not offered; the D:M:S reading still is', () {
        final tiny = press(const Tape(), '[Pitch] 0 . 0 0 1');
        expect(pill(tiny), 'Input 0.001° as 0°01\'00"');
        expect(pill(press(tiny, 'pill')), 'Input 0°01\'00" as 0.001°');
        expect(
          pill(press(const Tape(), '[Pitch] 0 . 0 0 7')),
          'Input 0.007° as 0°07\'00"',
        );
        expect(
          pill(press(const Tape(), '[Pitch] 0 . 0 0 8')),
          'Input 0.008° as 0.008in/12in',
          reason: '0.008in rounds to one tick, so the rise has an answer',
        );
        expect(
          strip(press(const Tape(), '[Pitch] 0 . 0 0 8 pill')),
          isNotEmpty,
        );
      });

      test('term 2.14: a stop the rules refuse as a pitch is skipped', () {
        expect(press(const Tape(), '[Pitch] 8 9 . 9 9').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 8 9 . 6 0').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 1 0 0 . 5').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 0 . 0').readAsOffer, isNull);
        var tape = press(const Tape(), '[Pitch] 8 . 9 9 9 9');
        expect(pill(tape), 'Input 8.9999° as 8.9999in/12in');
        tape = press(tape, 'pill');
        expect(
          pill(tape),
          'Input 8.9999in/12in as 8.9999°',
          reason: '174°39\'00" is no pitch, so the lap skips it',
        );
      });

      test('a length in feet, a fraction and a whole number ask nothing', () {
        expect(press(const Tape(), '[Pitch] 8 ft').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 7 / 1 6').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 0').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch]').readAsOffer, isNull);
      });

      test('rule 4.10: a number the Inch key made steeper than 24in/12in gets '
          'no pill', () {
        expect(press(const Tape(), '[Pitch] 3 0 . 4 5 in').readAsOffer, isNull);
        expect(press(const Tape(), '[Pitch] 2 5 in').readAsOffer, isNull);
        expect(
          pill(press(const Tape(), '[Pitch] 2 4 in')),
          'Input 24in/12in as 24°',
        );
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

      test('a fraction or a length under Slope is not a grade, so no pill', () {
        expect(press(const Tape(), '[Slope] 1 / 2').readAsOffer, isNull);
        expect(press(const Tape(), '[Slope] 2 in').readAsOffer, isNull);
        expect(press(const Tape(), '[Slope] 1 ft').readAsOffer, isNull);
      });

      test('the digits are shifted, never multiplied: 0.65 × 100 is '
          '65.00000000000001 and the pill promises the digits back', () {
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

    test('rule 4.10: the way back survives the seal: [Pitch] 8.45, pill, '
        'pill, + then ⌫ still offers 8.45°', () {
      final sealed = press(const Tape(), '[Pitch] 8 . 4 5 pill pill +');
      expect((sealed.chips.first as ValueChip).entry.text, '8°45\'00"');
      final reopened = press(sealed, '⌫');
      expect(pill(reopened), 'Input 8°45\'00" as 8.45°');
      expect(chipText(press(reopened, 'pill'), 0), '8.45');
    });

    group('a number read as degrees (walkthrough 16.4)', () {
      test('S91: an open keypad is not context; [SIN] brings the question '
          'with the answer, and the tap rebuilds it', () {
        var tape = press(const Tape(), '3 8 . 3 0');
        expect(tape.readAsOffer, isNull);
        tape = press(tape, 'SIN');
        expect(lastResult(tape), 'Sine 0.619779');
        expect(pill(tape), 'Re-input 38.30° as 38°30\'00"');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '38°30\'00"');
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
        expect(pill(tape), 'Input 12.1° as 12°01\'00"');
        tape = press(tape, 'pill');
        expect(tape.active!.entry.text, '12°01\'00"');
        expect(lastResult(press(tape, '=')), 'Calc 1.04');
        expect(
          pill(press(const Tape(), 'SIN 1 2 . 1 × COS 3 3 . 3')),
          'Input 33.3° as 33°03\'00"',
          reason: 'the number on the display is the 33.3',
        );
        expect(
          pill(press(const Tape(), '[Width] 3 ft × SIN 1 2 . 1')),
          'Input 12.1° as 12°01\'00"',
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
          'Input 12.1° as 12°01\'00"',
        );
        var tape = press(const Tape(), '1 2 . 1');
        expect(tape.readAsOffer, isNull);
        tape = press(tape, 'SIN');
        expect(pill(tape), 'Re-input 12.1° as 12°01\'00"');
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

      test(
        'a decimal with only zeros after the point has no other reading',
        () {
          for (final keys in [
            'SIN 1 2 . 0 0',
            '1 2 . 0 0 SIN',
            'SIN 0 . 0',
            'SIN 1 2 . 0',
          ]) {
            expect(press(const Tape(), keys).readAsOffer, isNull, reason: keys);
          }
          expect(
            pill(press(const Tape(), 'SIN 1 2 . 0 1')),
            startsWith("Input 12.01° as 12°01'"),
          );
          expect(
            pill(press(const Tape(), 'SIN 1 2 . 1 0')),
            startsWith("Input 12.10° as 12°10'"),
          );
        },
      );

      test('S113: the tap closes the minutes, and the spelling survives the '
          'tape and the answer', () {
        var tape = press(const Tape(), 'SIN 4 5 . 2');
        expect(pill(tape), 'Input 45.2° as 45°02\'00"');
        tape = press(tape, 'pill');
        expect(chipText(tape, 0), '45°02\'00"');
        final answer = tape.trigAnswer;
        tape = tape.append(ResultChip(key: answer!.key, value: answer.value));
        expect(lastResult(tape), 'Sine 0.707518');
        expect(chipText(tape, 0), '45°02\'00"');
      });

      test('S116: the same wording on every pill that changes a number', () {
        expect(
          pill(press(const Tape(), '5 × SIN 1 2 . 1')),
          'Input 12.1° as 12°01\'00"',
        );
        expect(pill(press(const Tape(), '[Pitch] 6')), 'Input 6° as 6in/12in');
        expect(
          pill(press(const Tape(), '[Slope] 0 . 6 5')),
          'Input 0.65% as 65%',
        );
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
          'Input 90°00\'00" as 90.00°',
        );
        expect(
          pill(press(const Tape(), 'SIN 8 9 . 5 9')),
          'Input 89.59° as 89°59\'00"',
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
        expect(pill(tape), 'Input 38°30\'00" as 38.30°');
        tape = press(tape, '⌫');
        expect(chipText(tape, 0), '38°30\'00"');
        expect(pill(tape), 'Input 38°30\'00" as 38.30°', reason: 'same digits');
        expect(
          pill(press(tape, 'DMS')),
          'Input 38°30\'00" as 38.30°',
          reason: 'the key re-closes the same digits',
        );
        tape = press(tape, '⌫');
        expect(chipText(tape, 0), '38°3\'00"');
        expect(tape.readAsOffer, isNull);
        expect(formatter.format(tape.trigAnswer!.value), '0.616349');
        expect(
          press(const Tape(), 'SIN 3 8 DMS').readAsOffer,
          isNull,
          reason:
              'a whole number read as D:M:S has no second reading to go back to',
        );
        final postfix = press(const Tape(), '3 8 . 3 0 SIN pill ⌫ ⌫ ⌫');
        expect(chipText(postfix, 0), '38°3\'00"');
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
