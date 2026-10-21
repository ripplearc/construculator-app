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
    'COS' => tape.pressTrigKey(TrigFunction.cosine),
    'TAN' => tape.pressTrigKey(TrigFunction.tangent),
    'ASIN' => tape.pressTrigKey(TrigFunction.arcsine),
    'ATAN' => tape.pressTrigKey(TrigFunction.arctangent),
    'ft' => tape.pressUnit(Unit.foot),
    '×' => tape.pressOperator(Operator.multiply),
    '+' => tape.pressOperator(Operator.add),
    '−' => tape.pressOperator(Operator.subtract),
    '÷' => tape.pressOperator(Operator.divide),
    '=' => tape.pressEquals(),
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

  // Lands the answer a prefix trig chip offers, as = does for the caller.
  Tape landed(Tape tape) {
    final answer = tape.trigAnswer;
    if (answer == null) throw StateError('no trig answer on ${tape.chips}');
    return tape.append(ResultChip(key: answer.key, value: answer.value));
  }

  List<String> texts(Tape tape) => [
    for (final chip in tape.chips)
      switch (chip) {
        ValueChip(:final key, :final entry) => '${key ?? ''}${entry.text}',
        ResultChip(:final key, :final value) =>
          '$key ${formatter.format(value)}',
        ErrorChip(:final error) => error.name,
        BracketChip(:final expression) => expression,
      },
  ];

  RememberedAngle? newest(AngleMemory memory, String key) =>
      memory.offeredFor(key, rowHasAnswers: true).firstOrNull;

  List<String> strip(Tape tape) => [
    for (final answer in rules.answersFor(tape.namedValues))
      '${answer.key}: ${formatter.format(answer.value)}',
  ];

  group('AngleMemory (F2b, rule 4.16)', () {
    test('S118: an angle typed under Sine is offered back to Pitch, D:M:S '
        'spelling intact', () {
      final sine = landed(press(const Tape(), 'SIN 3 8 DMS 0 3'));
      expect(texts(sine), ["Sine38°03'", 'Sine 0.616349']);
      final memory = const AngleMemory().filed(sine.chips.first as ValueChip);
      final offered = newest(memory, PlainNumberKeys.pitch);
      expect(offered!.entry.text, "38°03'");
      expect(memory.remembered, hasLength(1), reason: 'one chip, never a menu');

      final pitch = changed(press(const Tape(), '[Pitch]').recall(offered));
      expect(texts(pitch), ["Pitch38°03'"]);
      expect(
        activeOf(pitch).value(parser),
        const Angle(38 + 3 / 60, spelling: AngleSpelling.degreesMinutesSeconds),
      );
      expect(strip(pitch).first, 'Pitch-degrees: 38.05°');
    });

    test('rule 4.16: an angle answer is filed when it renders and offered '
        'back at full precision', () {
      final roof = press(const Tape(), 'ATAN 1 6 ÷ 1 2 =');
      expect(texts(roof).last, 'Arctangent(16 ÷ 12) 53.13°');
      final answer = (roof.chips.last as ResultChip).value as Angle;
      final memory = const AngleMemory().filedAnswer(
        answer,
        formatter: formatter,
      );
      final offered = newest(memory, PlainNumberKeys.pitch);
      expect(offered!.entry.text, '53.13');

      final pitch = changed(press(const Tape(), '[Pitch]').recall(offered));
      expect(texts(pitch), ['Pitch53.13']);
      expect(activeOf(pitch).value(parser), answer);
      expect(strip(pitch), [
        'Pitch-degrees: 53.13°',
        'Pitch-rise per 12in run: 16in/12in',
        'Pitch-grade: 133.3%',
      ]);
    });

    test('an answer spelled as D:M:S comes back spelled that way', () {
      final angle =
          (press(const Tape(), '1 2 ÷ 2 3 ASIN DMS').chips.last as ResultChip)
                  .value
              as Angle;
      final memory = const AngleMemory().filedAnswer(
        angle,
        formatter: formatter,
      );
      expect(newest(memory, 'Sine')!.entry.text, '31°26\'56"');
      final whole = const AngleMemory().filedAnswer(
        const Angle(30, spelling: AngleSpelling.degreesMinutesSeconds),
        formatter: formatter,
      );
      expect(newest(whole, 'Sine')!.entry.text, "30°00'");
      final big = const AngleMemory().filedAnswer(
        const Angle(1234.5),
        formatter: formatter,
      );
      expect(newest(big, 'Sine')!.entry.text, '1234.5');
    });

    test('a pitch answer is filed in degrees, and a recalled angle is '
        're-filed at its exact value', () {
      final pitch = const AngleMemory().filedAnswer(
        const Angle(53.1301, spelling: AngleSpelling.risePerFoot),
        formatter: formatter,
      );
      final offered = newest(pitch, PlainNumberKeys.pitch)!;
      expect(offered.entry.text, '53.13');
      expect(offered.value, const Angle(53.1301));
      final grade = const AngleMemory().filedAnswer(
        const Angle(4, spelling: AngleSpelling.grade),
        formatter: formatter,
      );
      expect(newest(grade, 'Sine')!.entry.text, '4');

      final recalled = activeOf(
        changed(press(const Tape(), '[Pitch]').recall(offered)),
      );
      expect(recalled.typedAngle, const Angle(53.1301));
      expect(
        newest(const AngleMemory().filed(recalled), 'Sine')!.value,
        const Angle(53.1301),
      );
    });

    test('Section 6: a recalled angle under a forward trig key stays the '
        'function\'s operand, so × 10 after it is the sine times ten', () {
      final sine = landed(press(const Tape(), 'SIN 4 5'));
      final memory = const AngleMemory().filed(sine.chips.first as ValueChip);
      final remembered = newest(memory, 'Sine')!;
      for (final (key, product) in [
        ('SIN', 'Calc 7.07'),
        ('COS', 'Calc 7.07'),
        ('TAN', 'Calc 10'),
      ]) {
        final recalled = changed(press(const Tape(), key).recall(remembered));
        expect(texts(press(recalled, '× 1 0 =')).last, product, reason: key);
        expect(
          texts(press(recalled, '× 1 0 =')).last,
          texts(press(const Tape(), '$key 4 5 × 1 0 =')).last,
          reason: 'the same as typing $key 45 by hand',
        );
      }
      final thirty = newest(
        const AngleMemory().filedAnswer(const Angle(30), formatter: formatter),
        'Sine',
      )!;
      final sum = changed(press(const Tape(), 'SIN').recall(thirty));
      expect(texts(press(sum, '+ 1 =')).last, 'Calc 1.5');
      final pitch = changed(
        press(const Tape(), '[Pitch]').recall(
          newest(
            const AngleMemory().filedAnswer(
              const Angle(53.1301),
              formatter: formatter,
            ),
            PlainNumberKeys.pitch,
          )!,
        ),
      );
      expect(texts(press(pitch, '× 2 =')).last, 'Calc 106.26°');
    });

    test('a recalled answer computes from its exact value, not from the two '
        'decimals on screen', () {
      final roof = press(const Tape(), 'ATAN 1 6 ÷ 1 2 =');
      final answer = (roof.chips.last as ResultChip).value as Angle;
      final memory = const AngleMemory().filedAnswer(
        answer,
        formatter: formatter,
      );
      for (final (key, name, ratio) in [
        ('SIN', 'Sine', '0.8'),
        ('COS', 'Cosine', '0.6'),
        ('TAN', 'Tangent', '1.333333'),
      ]) {
        final recalled = changed(
          press(const Tape(), key).recall(newest(memory, name)!),
        );
        expect(texts(recalled), ['${name}53.13'], reason: key);
        expect(
          formatter.format(recalled.trigAnswer!.value),
          ratio,
          reason: key,
        );
      }
    });

    test('rule 4.16: a recalled angle is a finished value: no Read-as pill '
        'under any key, and the D:M:S key converts it in place at its exact '
        'value', () {
      const answer = Angle(53.13010235415598);
      final remembered = newest(
        const AngleMemory().filedAnswer(answer, formatter: formatter),
        'Sine',
      )!;
      final sine = changed(press(const Tape(), 'SIN').recall(remembered));
      expect(sine.readAsOffer, isNull);
      expect(landed(sine).readAsOffer, isNull);
      expect(
        changed(press(const Tape(), '[Pitch]').recall(remembered)).readAsOffer,
        isNull,
      );
      final dms = changed(sine.pressDmsKey());
      expect(activeOf(dms).entry.text, '53°07\'48"');
      expect(
        activeOf(dms).exactValue,
        Angle(answer.degrees, spelling: AngleSpelling.degreesMinutesSeconds),
      );
      expect(dms.readAsOffer, isNull);
      expect(texts(landed(dms)).last, 'Sine 0.8');
      final back = changed(dms.pressDmsKey());
      expect(activeOf(back).entry.text, '53.13');
      expect(activeOf(back).exactValue, answer);
    });

    test('rule 4.16: Pitch refuses a recalled angle of 90° or more at the '
        'tap, takes 89.99°, and a forward trig key takes 90°', () {
      RememberedAngle filed(double degrees) => newest(
        const AngleMemory().filedAnswer(Angle(degrees), formatter: formatter),
        'Sine',
      )!;
      final pitch = press(const Tape(), '[Pitch]');
      expect(
        pitch.recall(filed(90)),
        const TapeRefused(TapeRefusal.pitchNeedsAnAngleUnderARightAngle),
      );
      expect(
        pitch.recall(filed(120)),
        const TapeRefused(TapeRefusal.pitchNeedsAnAngleUnderARightAngle),
      );
      expect(activeOf(changed(pitch.recall(filed(89.99)))).entry.text, '89.99');
      expect(
        activeOf(
          changed(press(const Tape(), 'SIN').recall(filed(90))),
        ).entry.text,
        '90',
      );
    });

    test('rule 4.16: the drawer keeps the minus sign, a forward trig key '
        'takes the angle, and Pitch refuses it at the tap', () {
      final arcsine = press(const Tape(), '1 − 1 . 5 = ASIN');
      expect(texts(arcsine).last, 'Arcsine -30°');
      final answer = (arcsine.chips.last as ResultChip).value as Angle;
      final degrees = const AngleMemory().filedAnswer(
        answer,
        formatter: formatter,
      );
      expect(newest(degrees, 'Sine')!.entry.text, '-30');
      final dms = const AngleMemory().filedAnswer(
        answer.spelledAs(AngleSpelling.degreesMinutesSeconds),
        formatter: formatter,
      );
      final remembered = newest(dms, 'Sine')!;
      expect(remembered.entry.text, "-30°00'");
      expect(remembered.entry.tokens.single.value, -30);
      expect(
        remembered.value,
        answer.spelledAs(AngleSpelling.degreesMinutesSeconds),
      );
      final halved = const AngleMemory().filedAnswer(
        const Angle(-30.5, spelling: AngleSpelling.degreesMinutesSeconds),
        formatter: formatter,
      );
      expect(newest(halved, 'Sine')!.entry.text, "-30°30'");
      expect(newest(halved, 'Sine')!.entry.tokens.single.value, -30.5);

      final sine = changed(press(const Tape(), 'SIN').recall(remembered));
      expect(texts(sine), ["Sine-30°00'"]);
      expect(formatter.format(sine.trigAnswer!.value), '-0.5');
      final pitch = press(const Tape(), '[Pitch]');
      expect(
        pitch.recall(remembered),
        const TapeRefused(TapeRefusal.pitchNeedsAnAngleAboveZero),
      );
      expect(
        pitch.recall(
          newest(
            const AngleMemory().filedAnswer(
              const Angle(0),
              formatter: formatter,
            ),
            PlainNumberKeys.pitch,
          )!,
        ),
        const TapeRefused(TapeRefusal.pitchNeedsAnAngleAboveZero),
        reason: 'above 0°, so 0° is refused too',
      );
      expect(
        dms.offeredFor(PlainNumberKeys.pitch, rowHasAnswers: false),
        [remembered],
        reason: 'offered to Pitch, refused at the tap',
      );
    });

    test('Section 1.2: three are offered on an empty row, one beside the '
        'answers of a live row, none to a key that takes no angle', () {
      var memory = const AngleMemory();
      for (final degrees in ['3 0', '4 5', '6 0']) {
        memory = memory.filed(
          activeOf(press(const Tape(), '[Pitch] $degrees')),
        );
      }
      List<String> offered(String key, {required bool rowHasAnswers}) => [
        for (final angle in memory.offeredFor(
          key,
          rowHasAnswers: rowHasAnswers,
        ))
          angle.entry.text,
      ];
      expect(offered(PlainNumberKeys.pitch, rowHasAnswers: false), [
        '60',
        '45',
        '30',
      ]);
      expect(offered('Sine', rowHasAnswers: true), ['60']);
      expect(offered('Arcsine', rowHasAnswers: false), isEmpty);
      expect(offered('Width', rowHasAnswers: false), isEmpty);
    });

    test('rule 4.16: a typed 38°03\' and the answer 38.05° rendered as D:M:S '
        'are one entry', () {
      final answer = const Angle(
        38.05,
        spelling: AngleSpelling.degreesMinutesSeconds,
      );
      final chip = activeOf(press(const Tape(), '[Pitch] 3 8 DMS 0 3'));
      final memory = const AngleMemory()
          .filed(chip)
          .filedAnswer(answer, formatter: formatter);
      expect(memory.remembered, hasLength(1));
      expect(memory.remembered.single.entry.text, "38°03'");
      expect(
        memory.remembered.single.entry.tokens.single,
        isNot(chip.entry.tokens.single),
        reason:
            'the tokens differ (the answer has empty seconds); the text '
            'is what makes them one value',
      );
    });

    test('a D:M:S answer is filed as the formatter writes it: rounded to the '
        'second, the degrees never cut', () {
      String filed(double degrees) => newest(
        const AngleMemory().filedAnswer(
          Angle(degrees, spelling: AngleSpelling.degreesMinutesSeconds),
          formatter: formatter,
        ),
        'Sine',
      )!.entry.text;
      expect(filed(38.5), "38°30'");
      expect(filed(59.99999), "60°00'");
      expect(filed(31.4542), '31°27\'15"');
      expect(filed(1234.5), "1234°30'");
      final grade = newest(
        const AngleMemory().filedAnswer(
          const Angle(4, spelling: AngleSpelling.grade),
          formatter: formatter,
        ),
        'Sine',
      )!;
      expect(grade.value, const Angle(4), reason: 'respelled in degrees');
    });

    test('a drawer built from a list keeps the rules: three deep, no two '
        'reading the same, and a copy of the list', () {
      RememberedAngle angle(String digits) => RememberedAngle(
        entry: EntryBuffer([Token(digits: digits)]),
        value: Angle(double.parse(digits)),
      );
      final source = [
        angle('1'),
        angle('2'),
        angle('2'),
        angle('3'),
        angle('4'),
        angle('5'),
      ];
      final memory = AngleMemory.of(source);
      expect(
        [for (final kept in memory.remembered) kept.entry.text],
        ['1', '2', '3'],
      );
      source.clear();
      expect(memory.remembered, hasLength(3));
      expect(() => memory.remembered.add(angle('9')), throwsUnsupportedError);
    });

    test('inverse trig keys never offer an angle, nor does a length key', () {
      final memory = const AngleMemory().filedAnswer(
        const Angle(53.13),
        formatter: formatter,
      );
      expect(newest(memory, 'Arcsine'), isNull);
      expect(newest(memory, 'Arctangent'), isNull);
      expect(newest(memory, 'Width'), isNull);
      expect(newest(memory, 'Sine'), isNotNull);
      expect(newest(memory, 'Cosine'), isNotNull);
      expect(newest(memory, 'Tangent'), isNotNull);
      expect(newest(const AngleMemory(), PlainNumberKeys.pitch), isNull);
    });

    test('a count, a grade, a length and a ratio are not angles and are '
        'not filed', () {
      const memory = AngleMemory();
      for (final keys in [
        '6',
        '[Sides] 6',
        '[Slope] 7',
        '[Width] 8 ft',
        'ASIN 0 . 5',
      ]) {
        final chip = activeOf(press(const Tape(), keys));
        expect(memory.filed(chip), memory, reason: keys);
        expect(chip.typedAngle, isNull, reason: keys);
      }
      expect(
        activeOf(press(const Tape(), '[Pitch] 3 0')).typedAngle,
        const Angle(30),
      );
      expect(
        activeOf(press(const Tape(), '3 8 . 3 0 .')).typedAngle,
        const Angle(38.5, spelling: AngleSpelling.degreesMinutesSeconds),
      );
    });

    test('newest first, three deep, no duplicates; re-filing moves a value '
        'to the front', () {
      var memory = const AngleMemory();
      for (final degrees in ['3 0', '4 5', '6 0', '7 5']) {
        memory = memory.filed(
          activeOf(press(const Tape(), '[Pitch] $degrees')),
        );
      }
      expect(
        [for (final angle in memory.remembered) angle.entry.text],
        ['75', '60', '45'],
      );
      expect(newest(memory, PlainNumberKeys.pitch)!.entry.text, '75');
      memory = memory.filed(activeOf(press(const Tape(), '[Pitch] 4 5')));
      expect(
        [for (final angle in memory.remembered) angle.entry.text],
        ['45', '75', '60'],
      );
      memory = memory.filed(activeOf(press(const Tape(), '[Pitch] 4 5')));
      expect(memory.remembered, hasLength(3));
      var two = const AngleMemory();
      for (final degrees in ['3 0', '4 5', '3 0']) {
        two = two.filed(activeOf(press(const Tape(), '[Pitch] $degrees')));
      }
      expect(
        [for (final angle in two.remembered) angle.entry.text],
        ['30', '45'],
        reason: 'a value enters the drawer once',
      );
      expect(
        memory.filedAnswer(const Angle(45), formatter: formatter).remembered,
        hasLength(3),
        reason: 'an answer that spells like a typed value is the same value',
      );
    });

    test('a recalled angle needs an empty chip under a key that takes one', () {
      final remembered = newest(
        const AngleMemory().filedAnswer(const Angle(45), formatter: formatter),
        PlainNumberKeys.pitch,
      )!;
      for (final tape in [
        const Tape(),
        press(const Tape(), '[Pitch] 3'),
        press(const Tape(), '[Width]'),
        press(const Tape(), '[Slope]'),
        press(const Tape(), 'ASIN'),
        press(const Tape(), '3 0'),
      ]) {
        expect(
          tape.recall(remembered),
          const TapeRefused(TapeRefusal.noChipToRecallInto),
          reason: '${tape.chips}',
        );
      }
      final sine = changed(press(const Tape(), 'SIN').recall(remembered));
      expect(texts(sine), ['Sine45']);
      expect(formatter.format(sine.trigAnswer!.value), '0.707107');
    });

    test('rule 4.16: a recalled value is finished, so a digit after it '
        'starts a chip of its own and never joins it', () {
      final remembered = newest(
        const AngleMemory().filedAnswer(
          const Angle(53.1301),
          formatter: formatter,
        ),
        PlainNumberKeys.pitch,
      )!;
      final pitch = changed(press(const Tape(), '[Pitch]').recall(remembered));
      expect(activeOf(pitch).value(parser), const Angle(53.1301));
      final typed = press(pitch, '5');
      expect(texts(typed), ['Pitch53.13', '5']);
      expect(
        typed.chips.first,
        isA<ValueChip>().having((c) => c.isActive, 'isActive', isFalse),
      );
      expect(
        (typed.chips.first as ValueChip).value(parser),
        const Angle(53.1301),
      );
      final sine = changed(press(const Tape(), 'SIN').recall(remembered));
      expect(texts(press(sine, '2')), ['Sine53.13', '2']);
    });

    test('drawers and remembered angles compare by what they carry', () {
      const angle = RememberedAngle(
        entry: EntryBuffer([Token(digits: '45')]),
        value: Angle(45),
      );
      expect(AngleMemory.of([angle]), AngleMemory.of([angle]));
      expect(AngleMemory.of([angle]), isNot(const AngleMemory()));
      expect(
        angle,
        isNot(
          const RememberedAngle(
            entry: EntryBuffer([Token(digits: '45')]),
            value: Angle(45.5),
          ),
        ),
      );
    });
  });
}
