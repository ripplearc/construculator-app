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
    'ASIN' => tape.pressTrigKey(TrigFunction.arcsine),
    'ACOS' => tape.pressTrigKey(TrigFunction.arccosine),
    'ATAN' => tape.pressTrigKey(TrigFunction.arctangent),
    'ft' => tape.pressUnit(Unit.foot),
    'in' => tape.pressUnit(Unit.inch),
    '×' => tape.pressOperator(Operator.multiply),
    '−' => tape.pressOperator(Operator.subtract),
    '+' => tape.pressOperator(Operator.add),
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

  String result(TapeChip chip) {
    if (chip case ResultChip(:final key, :final value)) {
      return '$key ${formatter.format(value)}';
    }
    throw StateError('not a result: $chip');
  }

  String lastResult(Tape tape) => result(tape.chips.last);

  String answerText(Tape tape) {
    final answer = offered(tape);
    return '${answer.key} ${formatter.format(answer.value)}';
  }

  String calc(Tape tape) {
    if (tape.runningTotal case ChainValue(:final value, isCalculation: true)) {
      return 'Calc ${formatter.format(value)}';
    }
    throw StateError('no Calc on ${tape.chips}');
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

  group('Tape inverse trig keys (F1b)', () {
    const outOfRange = TapeRefused(TapeRefusal.ratioOutOfRange);

    group('postfix: the key after its ratio', () {
      test('S58: a pending division is evaluated first, then the angle', () {
        final arctangent = press(const Tape(), '1 2 ÷ 2 3 ATAN');
        expect(arctangent.chips.length, 4);
        expect(result(arctangent.chips[2]), 'Calc 0.52');
        expect(lastResult(arctangent), 'Arctangent 27.55°');
        expect(arctangent.active, isNull);
        expect(
          lastResult(press(const Tape(), '1 2 ÷ 2 3 = ASIN')),
          'Arcsine 31.45°',
        );
        expect(
          lastResult(press(const Tape(), '1 2 ÷ 2 3 = ACOS')),
          'Arccosine 58.55°',
        );
        expect(
          lastResult(press(const Tape(), '1 2 ÷ 2 3 ASIN')),
          'Arcsine 31.45°',
        );
      });

      test('S70: 2 [ASIN] is refused, 0.5 [ASIN] is Arcsine 30°', () {
        final two = press(const Tape(), '2');
        expect(two.pressTrigKey(TrigFunction.arcsine), outOfRange);
        expect(two.pressTrigKey(TrigFunction.arccosine), outOfRange);
        expect(lastResult(press(two, 'ATAN')), 'Arctangent 63.43°');
        final half = press(const Tape(), '0 . 5 ASIN');
        expect(lastResult(half), 'Arcsine 30°');
        final operand = half.chips.first as ValueChip;
        expect(operand.isActive, isFalse);
        expect(operand.key, 'Arcsine');
        expect(operand.readsDegrees, isFalse);
        expect(operand.trigOperand, const Scalar(0.5));
        expect(lastResult(press(const Tape(), '1 ASIN')), 'Arcsine 90°');
        expect(lastResult(press(const Tape(), '1 ACOS')), 'Arccosine 0°');
      });

      test('rule 4.11: both orders land one tape, Arcsine · a ratio 0.5 and '
          'its answer', () {
        for (final key in ['ASIN', 'ACOS', 'ATAN']) {
          final postfix = press(const Tape(), '0 . 5 $key');
          final prefix = press(const Tape(), '$key 0 . 5');
          final landed = prefix.append(
            ResultChip(key: offered(prefix).key, value: offered(prefix).value),
          );
          expect(landed, postfix, reason: key);
        }
      });

      test('a ratio a hair past 1 in floating point is 1', () {
        expect(
          lastResult(press(const Tape(), '0 . 1 + 0 . 2 ÷ 0 . 3 ASIN')),
          'Arcsine 90°',
        );
        expect(
          press(
            const Tape(),
            '1 . 0 0 0 0 0 0 1',
          ).pressTrigKey(TrigFunction.arcsine),
          outOfRange,
        );
      });

      test('S110: a ratio over 1 is an ordinary roof for [ATAN]', () {
        expect(
          lastResult(press(const Tape(), '1 6 ÷ 1 2 ATAN')),
          'Arctangent 53.13°',
        );
        expect(
          lastResult(press(const Tape(), '1 6 ÷ 1 2 = ATAN')),
          'Arctangent 53.13°',
        );
        expect(
          press(const Tape(), '1 6 ÷ 1 2 =').pressTrigKey(TrigFunction.arcsine),
          outOfRange,
        );
      });

      test('two lengths divided give a ratio; a length is refused', () {
        expect(
          lastResult(press(const Tape(), '1 2 ft ÷ 2 3 ft ATAN')),
          'Arctangent 27.55°',
        );
        const needsARatio = TapeRefused(TapeRefusal.trigNeedsAPlainAngle);
        expect(
          press(const Tape(), '1 2 ft').pressTrigKey(TrigFunction.arctangent),
          needsARatio,
        );
        expect(
          press(const Tape(), '1 2 ft ÷ 2').pressTrigKey(TrigFunction.arcsine),
          needsARatio,
        );
      });

      test('an angle is not a ratio, typed or divided', () {
        final pitch = press(const Tape(), '[Pitch] 3 0');
        expect(pitch.pressTrigKey(TrigFunction.arctangent), outOfRange);
        expect(
          press(pitch, '÷ 2').pressTrigKey(TrigFunction.arcsine),
          outOfRange,
        );
        expect(activeOf(press(pitch, '× ACOS')).key, 'Arccosine');
      });

      test('a division that fails lands its error the way = does', () {
        final dividedByZero = press(const Tape(), '1 2 ÷ 0');
        expect(
          dividedByZero.pressTrigKey(TrigFunction.arctangent),
          dividedByZero.pressEquals(),
        );
        expect(
          press(const Tape(), '1 2 ÷ 0 ATAN').chips,
          contains(const ErrorChip(CalculationError.divisionByZero)),
        );
      });

      test('only a division builds the ratio: 12 × 23 opens Arctangent…', () {
        final tape = press(const Tape(), '1 2 × 2 3 ATAN');
        expect(
          tape.active,
          const ValueChip(key: 'Arctangent', keyWantsUnit: false),
        );
        expect(tape.chips.whereType<ResultChip>(), isEmpty);
        expect(activeOf(press(const Tape(), '[Sides] 6 ASIN')).key, 'Arcsine');
        final arcsine = press(const Tape(), 'ASIN 0 . 5 ACOS');
        expect(arcsine.chips.length, 2);
        expect(activeOf(arcsine).key, 'Arccosine');
      });
    });

    group('which answers a trig key takes', () {
      test('S96: a ratio Calc is eaten, a sine is not an angle', () {
        expect(
          lastResult(press(const Tape(), '1 2 ÷ 2 3 = ASIN')),
          'Arcsine 31.45°',
        );
        final sine = press(const Tape(), '3 8 SIN');
        final cosine = press(sine, 'COS');
        expect(sine.endsWithResult, isTrue);
        expect(
          cosine.active,
          const ValueChip(
            key: 'Cosine',
            keyWantsUnit: false,
            readsDegrees: true,
          ),
        );
        final angle = press(const Tape(), '1 2 ÷ 2 3 ATAN SIN');
        expect(result(angle.chips[3]), 'Arctangent 27.55°');
        expect(lastResult(angle), 'Sine 0.462566');
        expect(
          activeOf(press(const Tape(), 'ASIN 2')).asksAnUndefinedTrig,
          isTrue,
        );
      });

      test('S106: a trig answer is not the next trig key\'s operand', () {
        final cosine = press(const Tape(), '1 8 0 0 COS');
        expect(text((cosine.chips.first as ValueChip).trigOperand), '1,800°');
        expect(lastResult(cosine), 'Cosine 1');
        expect(activeOf(press(cosine, 'ACOS')).key, 'Arccosine');
        expect(press(cosine, 'ACOS').chips.last, isA<ValueChip>());
        expect(activeOf(press(const Tape(), '8 9 SIN ASIN')).key, 'Arcsine');
        final chained = press(const Tape(), '0 . 5 ASIN SIN');
        expect(chained.chips.length, 3);
        expect(result(chained.chips[1]), 'Arcsine 30°');
        expect(lastResult(chained), 'Sine 0.5');
      });

      test(
        'an angle answer is not a ratio, and its tangent can be undefined',
        () {
          final angle = press(const Tape(), 'ACOS 0 . 8 × 6 =');
          expect(lastResult(angle), 'Calc 221.22°');
          expect(activeOf(press(angle, 'ATAN')).key, 'Arctangent');
          expect(lastResult(press(angle, 'TAN')), 'Tangent 0.876032');
          expect(
            press(const Tape(), '0 ACOS').pressTrigKey(TrigFunction.tangent),
            const TapeRefused(TapeRefusal.tangentUndefined),
          );
          expect(
            press(const Tape(), '1 5 × 1 =').pressTrigKey(TrigFunction.sine),
            isA<TapeChanged>().having(
              (outcome) => activeOf(outcome.tape).key,
              'opens',
              'Sine',
            ),
          );
        },
      );
    });

    group('prefix: the key before its ratio', () {
      test('S100: an out-of-range ratio keeps saying why', () {
        final tape = press(const Tape(), 'ACOS 4 5');
        expect(activeOf(tape).trigOperand, const Scalar(45));
        expect(activeOf(tape).asksAnUndefinedTrig, isTrue);
        expect(tape.trigAnswer, isNull);
        const refused = TapeRefused(TapeRefusal.trigCannotAnswer);
        expect(tape.pressOperator(Operator.multiply), refused);
        expect(tape.pressOperator(Operator.divide), refused);
        expect(tape.pressEquals(), refused);
        final roof = press(const Tape(), 'ATAN 1 2 ÷ 2 3');
        expect(answerText(roof), 'Arctangent(12 ÷ 23) 27.55°');
        expect(calc(roof), 'Calc 0.52');
      });

      test('S109: a lone operand offers its answer for the caller to land', () {
        final arctangent = press(const Tape(), 'ATAN 0 . 1');
        expect(answerText(arctangent), 'Arctangent 5.71°');
        expect(
          arctangent.pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
        expect(answerText(press(const Tape(), 'ACOS 0 . 5')), 'Arccosine 60°');
        const rules = DeterministicRules();
        final pitch = rules
            .answersFor(
              press(const Tape(), '[Rise] 8 ft [Run] 6 ft').namedValues,
            )
            .firstWhere((a) => a.key == DeterministicRules.pitchRiseKey);
        expect(text(pitch.value), '16in/12in');
      });

      test('S110: [ATAN] 1.333 answers, [ASIN] 1.5 does not', () {
        expect(
          answerText(press(const Tape(), 'ATAN 1 . 3 3 3')),
          'Arctangent 53.12°',
        );
        final arcsine = press(const Tape(), 'ASIN 1 . 5');
        expect(arcsine.trigAnswer, isNull);
        expect(activeOf(arcsine).asksAnUndefinedTrig, isTrue);
      });

      test('S111: the answer names the operand it took, and = lands it', () {
        final roof = press(const Tape(), 'ATAN 1 6 ÷ 1 2');
        expect(answerText(roof), 'Arctangent(16 ÷ 12) 53.13°');
        expect(offered(roof).sources, ['Arctangent']);
        expect(calc(roof), 'Calc 1.33');
        final landed = press(roof, '=');
        expect(landed.chips.length, 3);
        expect(lastResult(landed), 'Arctangent(16 ÷ 12) 53.13°');
        expect(
          answerText(press(const Tape(), 'ATAN 3 2 ÷ 2 ÷ 1 2')),
          'Arctangent(32 ÷ 2 ÷ 12) 53.13°',
        );
        expect(answerText(press(const Tape(), 'ACOS 0 . 5')), 'Arccosine 60°');
      });

      test('S112: × seals the function, ÷ reaches only for [ATAN]', () {
        final arccosine = press(const Tape(), 'ACOS 0 . 8');
        expect(answerText(arccosine), 'Arccosine 36.87°');
        final sealed = press(arccosine, '× 6');
        expect(sealed.trigAnswer, isNull);
        expect(calc(sealed), 'Calc 221.22°');
        expect(lastResult(press(sealed, '=')), 'Calc 221.22°');
        expect(calc(press(const Tape(), 'SIN 3 0 × 6')), 'Calc 3');
        expect(calc(press(const Tape(), 'ATAN 1 × 2')), 'Calc 90°');
        final halved = press(const Tape(), 'ASIN 0 . 5 ÷ 2');
        expect(halved.trigAnswer, isNull);
        expect(calc(halved), 'Calc 15°');
        expect(calc(press(const Tape(), 'SIN 3 0 ÷ 2')), 'Calc 0.25');
      });

      test('the reach ends at anything but ÷ and a bare number', () {
        final times = press(const Tape(), 'ATAN 1 6 ÷ 1 2 × 2');
        expect(times.trigAnswer, isNull);
        expect(calc(times), 'Calc 106.26°');
        expect(
          calc(press(const Tape(), 'ATAN 1 6 ÷ 1 2 + 1')),
          calc(press(const Tape(), 'ATAN 1 6 ÷ 1 2 = + 1')),
        );
        final pitch = press(const Tape(), 'ATAN 1 6 ÷ [Pitch] 1 2');
        expect(pitch.trigAnswer, isNull);
        final sine = press(const Tape(), 'ATAN 1 6 ÷ SIN 3 0');
        expect(offered(sine).key, 'Sine');
        expect(calc(sine), 'Calc 172.85°');
        expect(press(const Tape(), 'ATAN 1 6 ÷').trigAnswer, isNull);
        final byZero = press(const Tape(), 'ATAN 1 6 ÷ 0');
        expect(byZero.trigAnswer, isNull);
        expect(byZero.runningTotal, isA<ChainFailed>());
        expect(press(const Tape(), 'ATAN 1 6 ÷ 1 2 ft').trigAnswer, isNull);
        expect(press(const Tape(), '2 ÷ 1 2').trigAnswer, isNull);
      });

      test('S102: an answer is rebuilt on the tape an edit left before it', () {
        ValueChip retyped(TapeChip chip, String digits) => (chip as ValueChip)
            .copyWith(entry: EntryBuffer([Token(digits: digits)]));
        String rebuilt(Tape before, TapeChip answer) {
          final chip = before.rebuiltTrigAnswer(answer as ResultChip);
          if (chip == null) throw StateError('$answer was not rebuilt');
          return result(chip);
        }

        final sine = press(const Tape(), '3 8 SIN');
        expect(
          rebuilt(
            Tape(chips: [retyped(sine.chips.first, '40')]),
            sine.chips.last,
          ),
          'Sine 0.642788',
        );
        final arcsine = press(const Tape(), '0 . 5 ASIN');
        expect(
          rebuilt(
            Tape(chips: [retyped(arcsine.chips.first, '0.6')]),
            arcsine.chips.last,
          ),
          'Arcsine 36.87°',
        );
        expect(
          Tape(
            chips: [retyped(arcsine.chips.first, '2')],
          ).rebuiltTrigAnswer(arcsine.chips.last as ResultChip),
          isNull,
        );
        final divided = press(const Tape(), '7 8 ÷ 8 9 ATAN');
        expect(
          rebuilt(press(const Tape(), '7 0 ÷ 8 9 ='), divided.chips.last),
          'Arctangent 38.19°',
        );
        final reach = press(const Tape(), 'ATAN 1 6 ÷ 1 2 =');
        expect(
          rebuilt(press(const Tape(), 'ATAN 1 4 ÷ 1 2'), reach.chips.last),
          'Arctangent(14 ÷ 12) 49.4°',
        );
      });

      test('a unit on a ratio is refused, and the number stays bare', () {
        final tape = press(const Tape(), 'ASIN 0 . 5');
        expect(
          tape.pressUnit(Unit.foot),
          const TapeRefused(TapeRefusal.trigTakesAnAngle),
        );
        expect(activeOf(tape).entry.text, '0.5');
      });
    });
  });
}
