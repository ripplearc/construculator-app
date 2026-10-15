import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = QuantityParser();
  const formatter = QuantityFormatter();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  TapeOutcome pressKey(Tape tape, String key) => switch (key) {
    'SIN' => tape.pressTrigKey(TrigFunction.sine),
    'COS' => tape.pressTrigKey(TrigFunction.cosine),
    'TAN' => tape.pressTrigKey(TrigFunction.tangent),
    'ft' => tape.pressUnit(Unit.foot),
    'in' => tape.pressUnit(Unit.inch),
    '×' => tape.pressOperator(Operator.multiply),
    '−' => tape.pressOperator(Operator.subtract),
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

  String text(Quantity? value) {
    if (value == null) throw StateError('no value');
    return formatter.format(value);
  }

  ValueChip activeOf(Tape tape) {
    final chip = tape.active;
    if (chip == null) throw StateError('no active chip on ${tape.chips}');
    return chip;
  }

  Answer offered(Tape tape) {
    final answer = tape.trigAnswer;
    if (answer == null) throw StateError('no trig answer on ${tape.chips}');
    return answer;
  }

  String lastResult(Tape tape) {
    if (tape.chips.last case ResultChip(:final key, :final value)) {
      return '$key ${formatter.format(value)}';
    }
    throw StateError('the tape does not end on a result: ${tape.chips}');
  }

  group('Tape trig keys (F1a)', () {
    group('postfix: the key after its number', () {
      test('S57: 38 [SIN], [COS], [TAN] answer at once', () {
        expect(lastResult(press(const Tape(), '3 8 SIN')), 'Sine 0.615661');
        expect(lastResult(press(const Tape(), '3 8 COS')), 'Cosine 0.788011');
        expect(lastResult(press(const Tape(), '3 8 TAN')), 'Tangent 0.781286');
      });

      test('rule 4.11: the number the key ate is the chip Cosine · degrees '
          '98°, then its answer', () {
        final tape = press(const Tape(), '9 8 COS');
        final operand = tape.chips.first as ValueChip;
        expect(operand.isActive, isFalse);
        expect(operand.key, 'Cosine');
        expect(operand.readsDegrees, isTrue);
        expect(operand.entry.text, '98');
        expect(text(operand.trigOperand), '98°');
        expect(lastResult(tape), 'Cosine -0.139173');
        expect(tape.active, isNull);
      });

      test('S94: a length is refused, and so is the tangent of 90°', () {
        final length = press(const Tape(), '3 8 ft');
        expect(
          length.pressTrigKey(TrigFunction.sine),
          const TapeRefused(TapeRefusal.trigNeedsAPlainAngle),
        );
        final upright = press(const Tape(), '9 0');
        expect(
          upright.pressTrigKey(TrigFunction.tangent),
          const TapeRefused(TapeRefusal.tangentUndefined),
        );
        expect(activeOf(upright).key, isNull);
        expect(activeOf(upright).readsDegrees, isFalse);
        expect(lastResult(press(const Tape(), '8 9 TAN')), 'Tangent 57.289962');
      });

      test('the tangent is refused only within 1e-9° of a quarter turn', () {
        expect(
          lastResult(press(const Tape(), '8 9 . 9 9 9 9 TAN')),
          'Tangent 572,957.795104',
        );
        expect(
          press(
            const Tape(),
            '8 9 . 9 9 9 9 9 9 9 9 9 9',
          ).pressTrigKey(TrigFunction.tangent),
          const TapeRefused(TapeRefusal.tangentUndefined),
        );
      });

      test('a fraction with no unit still wants its unit key', () {
        expect(
          press(const Tape(), '7 / 1 6').pressTrigKey(TrigFunction.sine),
          const TapeEntryRefused(EntryRefusal.fractionNeedsUnit),
        );
      });
    });

    group('prefix: the key before its number', () {
      test('S95: [SIN] opens Sine…, 38 offers the answer postfix lands', () {
        final opened = press(const Tape(), 'SIN');
        expect(
          opened.active,
          const ValueChip(key: 'Sine', keyWantsUnit: false, readsDegrees: true),
        );
        expect(opened.trigAnswer, isNull);
        final typed = press(opened, '3 8');
        expect(activeOf(typed).trigOperand, const Angle(38));
        final answer = offered(typed);
        expect(answer.key, 'Sine');
        expect(answer.sources, ['Sine']);
        expect(text(answer.value), '0.615661');
        final accepted = typed.append(
          ResultChip(key: 'Sine', value: answer.value),
        );
        expect(accepted.chips, press(const Tape(), '3 8 SIN').chips);
      });

      test('rule 4.11: both orders land one tape, Sine · degrees 38° and its '
          'answer', () {
        final postfix = press(const Tape(), '3 8 SIN');
        final prefix = press(const Tape(), 'SIN 3 8');
        final landed = prefix.append(
          ResultChip(key: 'Sine', value: offered(prefix).value),
        );
        expect(landed, postfix);
        expect(
          postfix.chips.first,
          const ValueChip(
            key: 'Sine',
            entry: EntryBuffer([Token(digits: '38')]),
            keyWantsUnit: false,
            readsDegrees: true,
            isActive: false,
          ),
        );
        expect(text((postfix.chips.first as ValueChip).trigOperand), '38°');
        expect(lastResult(postfix), 'Sine 0.615661');
      });

      test('S97 and S101: an operator seals Sine 89° at its answer', () {
        final tape = press(const Tape(), 'SIN 8 9 × 5 6');
        expect((tape.chips.first as ValueChip).entry.text, '89');
        expect(
          tape.chips.first,
          isA<ValueChip>().having((chip) => chip.key, 'key', 'Sine'),
        );
        expect(lastResult(press(tape, '=')), 'Calc 55.99');
      });

      test('S98: Sine 54° − 56 = is Calc −55.19; [SIN] then opens Sine…', () {
        final landed = press(const Tape(), 'SIN 5 4 − 5 6 =');
        expect(lastResult(landed), 'Calc -55.19');
        expect(landed.endsWithResult, isTrue);
        final next = press(landed, 'SIN');
        expect(
          next.active,
          const ValueChip(key: 'Sine', keyWantsUnit: false, readsDegrees: true),
        );
      });

      test('S103: the chain is worth the angle on the chip, Sine 80° × 56', () {
        expect(
          lastResult(press(const Tape(), 'SIN 8 0 × 5 6 =')),
          'Calc 55.15',
        );
      });

      test(
        'an empty chip takes the key and keeps its operator: 5 × sin 30°',
        () {
          final tape = press(const Tape(), '5 × SIN 3 0');
          expect(activeOf(tape).operator, Operator.multiply);
          expect(activeOf(tape).key, 'Sine');
          expect(lastResult(press(tape, '=')), 'Calc 2.5');
          expect(activeOf(press(const Tape(), '[Width] SIN')).key, 'Sine');
        },
      );

      test('a filled chip is sealed before the next trig chip opens', () {
        final tape = press(const Tape(), 'SIN 3 8 COS');
        expect(tape.chips.length, 2);
        expect((tape.chips.first as ValueChip).isActive, isFalse);
        expect(activeOf(tape).key, 'Cosine');
        final named = press(const Tape(), '[Sides] 6 SIN');
        expect(
          named.chips.first,
          isA<ValueChip>().having((chip) => chip.key, 'key', 'Sides'),
        );
        expect(activeOf(named).key, 'Sine');
        expect((named.chips.first as ValueChip).value(parser), const Scalar(6));
        final chained = press(const Tape(), '5 × 3 SIN');
        expect(
          chained.chips.sublist(0, 2).whereType<ValueChip>(),
          hasLength(2),
        );
        expect(
          chained.active,
          const ValueChip(key: 'Sine', keyWantsUnit: false, readsDegrees: true),
        );
      });

      test('a unit on its number is refused, and the number stays bare', () {
        final tape = press(const Tape(), 'SIN 3 8');
        expect(
          tape.pressUnit(Unit.foot),
          const TapeRefused(TapeRefusal.trigTakesAnAngle),
        );
        expect(activeOf(tape).entry.text, '38');
      });

      test('Tangent 90° answers nothing and no key reads its digits', () {
        final tape = press(const Tape(), 'TAN 9 0');
        expect(activeOf(tape).asksAnUndefinedTrig, isTrue);
        expect(tape.trigAnswer, isNull);
        const refused = TapeRefused(TapeRefusal.trigCannotAnswer);
        expect(tape.pressOperator(Operator.multiply), refused);
        expect(tape.pressEquals(), refused);
        expect(tape.pressFunctionKey('Width'), refused);
        expect(tape.pressTrigKey(TrigFunction.sine), refused);
        expect(
          activeOf(press(const Tape(), 'SIN 9 0')).asksAnUndefinedTrig,
          isFalse,
        );
        expect(const ValueChip(key: 'Width').asksAnUndefinedTrig, isFalse);
      });

      test('a trig chip is not a named value for the rules', () {
        final tape = press(const Tape(), '[Width] 1 2 ft SIN 3 0 ×');
        expect(tape.namedValues.keys, ['Width']);
      });

      test('inside a bracket the key is refused', () {
        expect(
          press(const Tape(), '( 3').pressTrigKey(TrigFunction.sine),
          const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic),
        );
      });
    });
  });
}
