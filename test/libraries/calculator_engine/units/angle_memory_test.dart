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
    'ATAN' => tape.pressTrigKey(TrigFunction.arctangent),
    'ft' => tape.pressUnit(Unit.foot),
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

  /// Lands the answer a prefix trig chip offers, as = does for the caller.
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
      final offered = memory.newestFor(PlainNumberKeys.pitch);
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
      final offered = memory.newestFor(PlainNumberKeys.pitch);
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
      expect(memory.newestFor('Sine')!.entry.text, '31°26\'56"');
      final whole = const AngleMemory().filedAnswer(
        const Angle(30, spelling: AngleSpelling.degreesMinutesSeconds),
        formatter: formatter,
      );
      expect(whole.newestFor('Sine')!.entry.text, "30°00'");
      final big = const AngleMemory().filedAnswer(
        const Angle(1234.5),
        formatter: formatter,
      );
      expect(big.newestFor('Sine')!.entry.text, '1234.5');
    });

    test('a pitch answer is filed in degrees, and a recalled angle is '
        're-filed at its exact value', () {
      final pitch = const AngleMemory().filedAnswer(
        const Angle(53.1301, spelling: AngleSpelling.risePerFoot),
        formatter: formatter,
      );
      final offered = pitch.newestFor(PlainNumberKeys.pitch)!;
      expect(offered.entry.text, '53.13');
      expect(offered.value, const Angle(53.1301));
      final grade = const AngleMemory().filedAnswer(
        const Angle(4, spelling: AngleSpelling.grade),
        formatter: formatter,
      );
      expect(grade.newestFor('Sine')!.entry.text, '4');

      final recalled = activeOf(
        changed(press(const Tape(), '[Pitch]').recall(offered)),
      );
      expect(recalled.typedAngle, const Angle(53.1301));
      expect(
        const AngleMemory().filed(recalled).newestFor('Sine')!.value,
        const Angle(53.1301),
      );
    });

    test('inverse trig keys never offer an angle, nor does a length key', () {
      final memory = const AngleMemory().filedAnswer(
        const Angle(53.13),
        formatter: formatter,
      );
      expect(memory.newestFor('Arcsine'), isNull);
      expect(memory.newestFor('Arctangent'), isNull);
      expect(memory.newestFor('Width'), isNull);
      expect(memory.newestFor('Sine'), isNotNull);
      expect(memory.newestFor('Cosine'), isNotNull);
      expect(memory.newestFor('Tangent'), isNotNull);
      expect(const AngleMemory().newestFor(PlainNumberKeys.pitch), isNull);
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
      expect(memory.newestFor(PlainNumberKeys.pitch)!.entry.text, '75');
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
      final remembered = const AngleMemory()
          .filedAnswer(const Angle(45), formatter: formatter)
          .newestFor(PlainNumberKeys.pitch)!;
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

    test('a recalled angle is the digits again once they are edited', () {
      final remembered = const AngleMemory()
          .filedAnswer(const Angle(53.1301), formatter: formatter)
          .newestFor(PlainNumberKeys.pitch)!;
      final pitch = changed(press(const Tape(), '[Pitch]').recall(remembered));
      expect(activeOf(pitch).value(parser), const Angle(53.1301));
      final edited = press(pitch, '5');
      expect(activeOf(edited).value(parser), const Angle(53.135));
    });

    test('drawers and remembered angles compare by what they carry', () {
      const angle = RememberedAngle(
        entry: EntryBuffer([Token(digits: '45')]),
        value: Angle(45),
      );
      expect(const AngleMemory([angle]), const AngleMemory([angle]));
      expect(const AngleMemory([angle]), isNot(const AngleMemory()));
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
