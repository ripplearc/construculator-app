import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  Tape press(Tape tape, String keys) {
    var current = tape;
    for (final key in keys.split(' ')) {
      if (key.isEmpty) continue;
      current = changed(switch (key) {
        'ft' => current.pressUnit(Unit.foot),
        'in' => current.pressUnit(Unit.inch),
        'yd' => current.pressUnit(Unit.yard),
        'lbs' => current.pressUnit(Unit.pound),
        'm' => current.pressUnit(Unit.metre),
        'cm' => current.pressUnit(Unit.centimetre),
        'mm' => current.pressUnit(Unit.millimetre),
        'ton' => current.pressUnit(Unit.ton),
        'bf' => current.pressUnit(Unit.boardFoot),
        '×' => current.pressOperator(Operator.multiply),
        '÷' => current.pressOperator(Operator.divide),
        '/' => current.typeFraction(),
        '+' => current.pressOperator(Operator.add),
        '−' => current.pressOperator(Operator.subtract),
        '=' => current.pressEquals(),
        '⌫' => current.backspace(),
        _ when key.startsWith('[') => current.pressFunctionKey(
          key.substring(1, key.length - 1),
        ),
        _ => current.typeDigit(key),
      });
    }
    return current;
  }

  ValueChip activeOf(Tape tape) {
    final chip = tape.active;
    if (chip == null) throw StateError('no active chip on ${tape.chips}');
    return chip;
  }

  String calc(Tape tape) {
    if (tape.runningTotal case ChainValue(:final value, isCalculation: true)) {
      return formatter.format(value);
    }
    throw StateError('no Calc on offer: ${tape.runningTotal}');
  }

  String lastResult(Tape tape) {
    if (tape.chips.last case ResultChip(:final key, :final value)) {
      return '$key ${formatter.format(value)}';
    }
    throw StateError('the tape does not end on a result: ${tape.chips}');
  }

  group('Tape chain', () {
    group('left to right, no precedence', () {
      test('2 + 3 × 4 = 20 (S99)', () {
        final tape = press(const Tape(), '2 + 3 × 4');
        expect(calc(tape), '20');
        expect(lastResult(press(tape, '=')), 'Calc 20');
      });

      test('2 + 3 + 4 answers 9, not 7, and 3ft × 4ft × 2 answers 24ft²', () {
        expect(lastResult(press(const Tape(), '2 + 3 + 4 =')), 'Calc 9');
        expect(
          lastResult(press(const Tape(), '3 ft × 4 ft × 2 =')),
          'Calc 24ft²',
        );
      });

      test('scalar × scalar: 78 × 56 = 4,368 (S13)', () {
        expect(lastResult(press(const Tape(), '7 8 × 5 6 =')), 'Calc 4,368');
      });

      test('scalar × length: 78 × 56ft = 4368ft 0in (S14)', () {
        final tape = press(const Tape(), '7 8 × 5 6 ft');
        expect(calc(tape), '4368ft 0in');
        expect(lastResult(press(tape, '=')), 'Calc 4368ft 0in');
      });

      test('length ÷ length: 36ft ÷ 12ft = 3 (S15)', () {
        expect(lastResult(press(const Tape(), '3 6 ft ÷ 1 2 ft =')), 'Calc 3');
      });

      test('the Calc is offered as soon as both sides have a value', () {
        final tape = press(const Tape(), '2 0 0 ft × 8 0');
        expect(calc(tape), '16000ft 0in');
        expect(calc(press(tape, 'ft')), '16,000ft²');
      });

      test(
        'a tape with one value or two values and no operator offers no Calc',
        () {
          expect(
            press(const Tape(), '1 8 ft').runningTotal,
            isA<ChainValue>().having(
              (c) => c.isCalculation,
              'isCalculation',
              isFalse,
            ),
          );
          final parked = press(const Tape(), '[Length] 3 in [Width] 2 in in');
          expect(
            parked.runningTotal,
            isA<ChainValue>().having(
              (c) => c.isCalculation,
              'isCalculation',
              isFalse,
            ),
          );
        },
      );
    });

    group('continuing from a result', () {
      test('12ft × 5ft = 60ft², then × 4in = 20ft³ (S16)', () {
        final area = press(const Tape(), '1 2 ft × 5 ft =');
        expect(lastResult(area), 'Calc 60ft²');
        final volume = press(area, '× 4 in =');
        expect(lastResult(volume), 'Calc 20ft³');
        expect(volume.chips.length, 5);
      });

      test('36ft ÷ 12ft = 3, then × 89 = 267 (S17)', () {
        final tape = press(const Tape(), '3 6 ft ÷ 1 2 ft = × 8 9');
        expect(calc(tape), '267');
        expect(lastResult(press(tape, '=')), 'Calc 267');
      });

      test('an operator picks up a sealed bare number too', () {
        // The prototype refused this ("Type a value first"); rule 4.5 lets
        // a sealed value of any kind be the left-hand side.
        const sealed = Tape(
          chips: [
            ValueChip(
              entry: EntryBuffer([Token(digits: '78')]),
              isActive: false,
            ),
          ],
        );
        expect(lastResult(press(sealed, '× 2 =')), 'Calc 156');
      });

      test('an operator picks up a sealed value as its left-hand side', () {
        const sealed = Tape(
          chips: [
            ValueChip(
              entry: EntryBuffer([Token(digits: '18', unit: Unit.foot)]),
              isActive: false,
            ),
          ],
        );
        expect(lastResult(press(sealed, '× 2 =')), 'Calc 36ft 0in');
      });
    });

    group('board feet and small ratios', () {
      test('board-feet math answers in board feet (S76)', () {
        final tape = press(const Tape(), '8 bf × 2 0 =');
        expect(lastResult(tape), 'Calc 160bf');
        expect(lastResult(press(tape, '÷ 4 =')), 'Calc 40bf');
        expect(
          lastResult(press(const Tape(), '5 0 0 bf + 1 yd yd yd =')),
          'Calc 824bf',
        );
        expect(
          lastResult(press(const Tape(), '5 0 0 bf ÷ 8 bf =')),
          'Calc 62.5',
        );
      });

      test('a tiny ratio never displays as zero (S74, S83)', () {
        expect(lastResult(press(const Tape(), '1 ÷ 7 8 =')), 'Calc 0.013');
      });

      test('10in ÷ 3 lands 0ft 3-5/16in (S52)', () {
        expect(
          lastResult(press(const Tape(), '1 0 in ÷ 3 =')),
          'Calc 0ft 3-5/16in',
        );
      });
    });

    group('operators', () {
      test('change a pending operator instead of stacking two', () {
        final tape = press(const Tape(), '2 + ×');
        expect(tape.chips.length, 2);
        expect(activeOf(tape).operator, Operator.multiply);
      });

      test('with nothing before them say type a value first', () {
        expect(
          const Tape().pressOperator(Operator.multiply),
          const TapeRefused(TapeRefusal.typeAValueFirst),
        );
        expect(
          press(const Tape(), '[Length]').pressOperator(Operator.multiply),
          const TapeRefused(TapeRefusal.typeAValueFirst),
        );
        final error = const Tape().append(
          const ErrorChip(CalculationError.dimensionError),
        );
        expect(
          error.pressOperator(Operator.add),
          const TapeRefused(TapeRefusal.typeAValueFirst),
        );
      });

      test('cannot leave a number with no unit', () {
        expect(
          press(const Tape(), '[Length] 1 8 ft 8').pressOperator(Operator.add),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });
    });

    group('equals', () {
      test('on a value with no operator says nothing to compute', () {
        expect(
          press(const Tape(), '1 8 ft').pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
        expect(
          const Tape().pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('on an operator waiting for its number says nothing to compute', () {
        expect(
          press(const Tape(), '1 8 ft ×').pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('after a result says nothing to compute', () {
        expect(
          press(const Tape(), '2 + 3 =').pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('cannot finish a number with no unit', () {
        expect(
          press(const Tape(), '2 ft + 1 8 ft 8').pressEquals(),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });

      test('seals the active chip when it lands', () {
        final tape = press(const Tape(), '2 + 3 =');
        expect(tape.active, isNull);
        expect((tape.chips[1] as ValueChip).isActive, isFalse);
      });
    });

    group('errors', () {
      test('78lbs ÷ 12ft = lands a Dimension Error chip (S18)', () {
        final tape = press(const Tape(), '7 8 lbs ÷ 1 2 ft');
        expect(tape.runningTotal, isA<ChainFailed>());
        final failed = tape.runningTotal as ChainFailed;
        expect(failed.error, CalculationError.dimensionError);
        expect(failed.left, const Weight(7800, unit: Unit.pound));
        expect(failed.operator, Operator.divide);
        expect(
          failed.right,
          const Length(12 * Length.ticksPerFoot, unit: Unit.foot),
        );
        final landed = press(tape, '=');
        expect(
          landed.chips.last,
          const ErrorChip(CalculationError.dimensionError),
        );
        expect((landed.chips[1] as ValueChip).isActive, isFalse);
        expect(landed.active, isNull);
        expect(landed.runningTotal, const ChainEmpty());
        expect(
          landed.pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('a failed chain does not break the chain typed after it', () {
        final tape = press(const Tape(), '5 lbs + 1 2 ft [Width] 5 ft × 3');
        expect(calc(tape), '15ft 0in');
        expect(lastResult(press(tape, '=')), 'Calc 15ft 0in');
      });

      test('rule 4.12: = works again after an error chip', () {
        final divided = press(const Tape(), '5 ÷ 0 =');
        expect(lastResult(press(divided, '4 =')), 'Calc 1.25');
        final mismatched = press(const Tape(), '7 8 lbs ÷ 1 2 ft =');
        expect(lastResult(press(mismatched, '3 ft × 4 ft =')), 'Calc 12ft²');
      });

      test(
        'a fraction after whole inches closes as inches by itself (CA-1235)',
        () {
          final sum = press(const Tape(), '5 ft 7 in 1 / 2 + 1 8 ft 8 in =');
          expect((sum.chips.first as ValueChip).entry.text, '5ft 7-1/2in');
          expect(lastResult(sum), 'Calc 24ft 3-1/2in');
          final withInch = press(
            const Tape(),
            '5 ft 7 in 1 / 2 in + 1 8 ft 8 in =',
          );
          expect((withInch.chips.first as ValueChip).entry.text, '5ft 7-1/2in');
          expect(lastResult(withInch), 'Calc 24ft 3-1/2in');
          expect(
            lastResult(press(const Tape(), '4 ft × 0 . 7 5 =')),
            'Calc 3ft 0in',
          );
        },
      );

      test('a fraction with no unit key cannot be left (CA-1235)', () {
        const refused = TapeEntryRefused(EntryRefusal.fractionNeedsUnit);
        final alone = press(const Tape(), '4 ft × 1 / 2');
        expect(alone.pressOperator(Operator.add), refused);
        expect(alone.pressEquals(), refused);
        expect(alone.pressFunctionKey('Width'), refused);
        expect(alone.pressBracket(), refused);
        for (final keys in ['1 / 2', '5 ft 1 / 2', '7 . 5 in 1 / 2']) {
          expect(
            press(const Tape(), keys).pressOperator(Operator.add),
            refused,
            reason: keys,
          );
        }
      });

      test('a mixed chain follows the System of units setting (CA-1233)', () {
        expect(
          lastResult(press(const Tape(), '1 2 ft + 1 m =')),
          'Calc 15ft 3-3/8in',
        );
        const metric = CalculatorPreferences(system: MeasurementSystem.metric);
        expect(
          lastResult(press(const Tape(preferences: metric), '1 m + 1 2 ft =')),
          'Calc 4.66m',
        );
      });

      test('12lbs ÷ 0ft is a Dimension Error, not a division by zero', () {
        final landed = press(const Tape(), '1 2 lbs ÷ 0 ft =');
        expect(
          landed.chips.last,
          const ErrorChip(CalculationError.dimensionError),
        );
      });

      test('a metric chain answers in the unit it was typed in', () {
        // 2cm × 3cm is exactly 6cm² (CA-1190), in centimetres rather than
        // 0m².
        final landed = press(const Tape(), '2 cm × 3 cm =');
        expect(lastResult(landed), 'Calc 6cm²');
        expect(
          (landed.chips.last as ResultChip).value,
          isA<Area>().having((area) => area.unit, 'unit', Unit.centimetre),
        );
      });

      test('the mismatch is not just division: 78 + 12ft (S73)', () {
        final landed = press(const Tape(), '7 8 + 1 2 ft =');
        expect(
          landed.chips.last,
          const ErrorChip(CalculationError.dimensionError),
        );
      });

      test('a number past 19,999,999.99 cannot be typed, and a length sum past '
          '19,999,999.99 lands an out-of-range error chip', () {
        String typed(String digits) => digits.split('').join(' ');
        expect(
          press(const Tape(), typed('9999999')).typeDigit('9'),
          const TapeEntryRefused(EntryRefusal.tooLarge),
        );
        expect(
          press(const Tape(), '${typed('19999999')} ft + 1 ft =').chips.last,
          const ErrorChip(CalculationError.outOfRange),
        );
      });

      test('÷ 0 lands its own error and reopens the divisor empty', () {
        final landed = press(const Tape(), '5 ÷ 0 =');
        expect(landed.chips, const [
          ValueChip(entry: EntryBuffer([Token(digits: '5')]), isActive: false),
          ErrorChip(CalculationError.divisionByZero),
          ValueChip(operator: Operator.divide),
        ]);
        expect(landed.endsWithError, isFalse);
        expect(landed.runningTotal, const ChainEmpty());
        expect(
          landed.pressEquals(),
          const TapeRefused(TapeRefusal.nothingToCompute),
        );
      });

      test('the next number is the new divisor: 5 ÷ 0 = 2 = is Calc 2.5', () {
        final retyped = press(const Tape(), '5 ÷ 0 = 2');
        expect(calc(retyped), '2.5');
        expect(lastResult(press(retyped, '=')), 'Calc 2.5');
        expect(lastResult(press(const Tape(), '5 ÷ 0 = + 3 =')), 'Calc 8');
      });

      test('a named divisor keeps its name when it is reopened', () {
        final landed = press(const Tape(), '5 ft ÷ [Width] 0 ft =');
        expect(
          landed.active,
          const ValueChip(key: 'Width', operator: Operator.divide),
        );
      });

      test('⌫ after ÷ 0 drops the error chip and keeps the divisor open', () {
        final repaired = press(const Tape(), '5 ÷ 0 = ⌫');
        expect(repaired.chips, const [
          ValueChip(entry: EntryBuffer([Token(digits: '5')]), isActive: false),
          ValueChip(operator: Operator.divide),
        ]);
        expect(repaired.endsWithError, isFalse);
        expect(lastResult(press(repaired, '2 =')), 'Calc 2.5');
        final dividend = press(repaired, '⌫');
        expect(dividend.active!.entry.text, '5');
        expect(lastResult(press(dividend, '× 2 =')), 'Calc 10');
      });

      test('⌫ on a bare chip typed after an error chip keeps the error', () {
        final emptied = press(const Tape(), '5 ÷ 0 + 3 = 2 ⌫ ⌫');
        expect(
          emptied.chips.last,
          const ErrorChip(CalculationError.divisionByZero),
        );
      });

      test('a second 0 under the reopened divisor keeps one error chip', () {
        final again = press(const Tape(), '5 ÷ 0 = 0 =');
        expect(again.chips, const [
          ValueChip(entry: EntryBuffer([Token(digits: '5')]), isActive: false),
          ErrorChip(CalculationError.divisionByZero),
          ValueChip(operator: Operator.divide),
        ]);
        expect(lastResult(press(again, '2 =')), 'Calc 2.5');
      });

      test('an operator on the reopened divisor drops the error chip', () {
        final changedOperator = press(const Tape(), '5 ÷ 0 = ×');
        expect(changedOperator.chips, const [
          ValueChip(entry: EntryBuffer([Token(digits: '5')]), isActive: false),
          ValueChip(operator: Operator.multiply),
        ]);
        expect(lastResult(press(changedOperator, '2 =')), 'Calc 10');
      });

      test(
        'a ÷ 0 that is not the last step lands the error chip at the end',
        () {
          for (final keys in ['5 ÷ 0 + 3 =', '5 ÷ 0 ÷ 0 =']) {
            final landed = press(const Tape(), keys);
            expect(
              landed.chips.last,
              const ErrorChip(CalculationError.divisionByZero),
              reason: keys,
            );
            expect(landed.active, isNull, reason: keys);
          }
        },
      );

      test('an operator after a Dimension Error is refused', () {
        final mismatched = press(const Tape(), '7 8 lbs ÷ 1 2 ft =');
        expect(
          mismatched.pressOperator(Operator.multiply),
          const TapeRefused(TapeRefusal.typeAValueFirst),
        );
      });

      test('the repair is only for ÷ 0 and only through its own ÷', () {
        const five = ValueChip(
          entry: EntryBuffer([Token(digits: '5')]),
          isActive: false,
        );
        const afterDimensionError = Tape(
          chips: [
            five,
            ErrorChip(CalculationError.dimensionError),
            ValueChip(operator: Operator.divide),
          ],
        );
        expect(
          afterDimensionError.backspace(),
          const TapeChanged(
            Tape(chips: [five, ErrorChip(CalculationError.dimensionError)]),
          ),
        );
        expect(
          afterDimensionError.pressOperator(Operator.multiply),
          const TapeChanged(
            Tape(
              chips: [
                five,
                ErrorChip(CalculationError.dimensionError),
                ValueChip(operator: Operator.multiply),
              ],
            ),
          ),
        );
        const addedAfterDivisionByZero = Tape(
          chips: [
            five,
            ErrorChip(CalculationError.divisionByZero),
            ValueChip(operator: Operator.add),
          ],
        );
        expect(
          addedAfterDivisionByZero.backspace(),
          const TapeChanged(
            Tape(chips: [five, ErrorChip(CalculationError.divisionByZero)]),
          ),
        );
      });

      test('a bracket worth zero is not reopened', () {
        var tape = press(const Tape(), '5 ÷');
        tape = (tape.pressBracket() as TapeChanged).tape;
        tape = press(tape, '0');
        tape = (tape.pressBracket() as TapeChanged).tape;
        final landed = press(tape, '=');
        expect(
          landed.chips.last,
          const ErrorChip(CalculationError.divisionByZero),
        );
        expect(landed.chips[1], isA<BracketChip>());
      });

      test('backspace performs surgery on the error and = answers (S72)', () {
        final repaired = press(const Tape(), '7 8 lbs ÷ 1 2 ft = ⌫ ⌫');
        expect(activeOf(repaired).entry.text, '12');
        expect(calc(repaired), '6.5lbs');
        expect(lastResult(press(repaired, '=')), 'Calc 6.5lbs');
      });
    });
  });

  group('Tape very large and very small answers (CA-1236)', () {
    String landed(Tape tape) {
      if (tape.chips.last case ResultChip(:final value)) {
        return formatter.format(value);
      }
      throw StateError('the tape does not end on a result: ${tape.chips}');
    }

    test('9999999 × 9999999 = lands Too large, and ⌫ reopens the number', () {
      final typed = press(const Tape(), '9 9 9 9 9 9 9 × 9 9 9 9 9 9 9');
      expect(
        typed.runningTotal,
        const ChainFailed(
          CalculationError.outOfRange,
          left: Scalar(9999999),
          operator: Operator.multiply,
          right: Scalar(9999999),
        ),
      );
      final landed = press(typed, '=');
      expect(landed.chips.last, const ErrorChip(CalculationError.outOfRange));
      final repaired = press(landed, '⌫');
      expect(repaired.chips, typed.chips);
      expect(activeOf(repaired).entry.text, '9999999');
    });

    test('19,999,999.99 is shown, a cent more is Too large', () {
      final edge = press(const Tape(), '1 9 9 9 9 9 9 9 . 9 8 + 0 . 0 1');
      expect(calc(edge), '19,999,999.99');
      expect(
        press(const Tape(), '1 9 9 9 9 9 9 9 . 9 9 + 0 . 0 1 =').chips.last,
        const ErrorChip(CalculationError.outOfRange),
      );
    });

    test('the limit is the number the answer shows', () {
      String typed(String number) => number.split('').join(' ');
      expect(
        press(const Tape(), '${typed('19999999')} mm + 0 . 6 mm =').chips.last,
        const ErrorChip(CalculationError.outOfRange),
      );
      expect(
        landed(
          press(const Tape(), '0 − ${typed('19999999.99')} − 0 . 0 0 5 ='),
        ),
        '-19,999,999.99',
      );
    });

    test("a ton is read at the tape's ton for the limit", () {
      const keys = '1 9 0 0 0 0 0 0 ton + 0 ton =';
      expect(
        press(const Tape(), '1 9 9 9 9 9 9 9 ton + 1 ton =').chips.last,
        const ErrorChip(CalculationError.outOfRange),
      );
      expect(
        press(
          const Tape(
            preferences: CalculatorPreferences(
              tonDefinition: TonDefinition.longTon,
            ),
          ),
          keys,
        ).chips.last,
        isA<ResultChip>(),
      );
    });

    test('the limit is in the unit shown, which never changes by itself', () {
      expect(
        press(const Tape(), '1 0 0 0 0 0 0 0 ft × 2 =').chips.last,
        const ErrorChip(CalculationError.outOfRange),
      );
      expect(
        landed(press(const Tape(), '9 9 9 9 9 9 9 ft × 2 =')),
        '19999998ft 0in',
      );
      expect(
        press(const Tape(), '5 0 0 0 0 0 0 yd × 4 =').chips.last,
        const ErrorChip(CalculationError.outOfRange),
      );
    });

    test(
      'a length under the rounding reads in words, a true zero does not',
      () {
        expect(
          landed(press(const Tape(), '5 ft 1 / 6 4 in − 5 ft =')),
          'Under 1/16in',
        );
        expect(
          landed(press(const Tape(), '5 ft − 5 ft 1 / 6 4 in =')),
          'Below zero',
        );
        expect(landed(press(const Tape(), '5 ft − 5 ft =')), '0ft 0in');
      },
    );

    test(
      'Section 6: a true zero reads 0, not "Under": an area or a volume made '
      'from lengths less the same area typed is zero within float noise',
      () {
        expect(
          landed(press(const Tape(), '2 . 5 m × 2 . 5 m − 6 . 2 5 m m =')),
          '0m²',
        );
        expect(
          landed(press(const Tape(), '4 . 2 m × 3 . 1 m − 1 3 . 0 2 m m =')),
          '0m²',
        );
        expect(
          landed(
            press(const Tape(), '1 0 0 0 m × 1 0 0 0 m − 1 0 0 0 0 0 0 m m ='),
          ),
          '0m²',
        );
        expect(
          landed(press(const Tape(), '1 m × 1 m × 1 m − 1 m m m =')),
          '0m³',
        );
        expect(
          landed(
            press(const Tape(), '2 . 5 m × 2 . 5 m − 6 . 2 4 9 9 9 9 m m ='),
          ),
          'Under 0.01m²',
          reason: 'a real tiny difference still reads in words',
        );
      },
    );

    test('an area under the rounding reads in words', () {
      expect(
        landed(press(const Tape(), '1 / 8 in × 1 / 8 in =')),
        'Under 0.01ft²',
      );
    });

    test('rule 4.15: a typed difference is never rounded away: 9999999 − '
        '9999998.99999 is 0.00001, the same areas read Under, and a '
        'difference in the thirteenth decimal is kept', () {
      expect(
        landed(
          press(const Tape(), '9 9 9 9 9 9 9 − 9 9 9 9 9 9 8 . 9 9 9 9 9 ='),
        ),
        '0.00001',
      );
      expect(
        landed(
          press(
            const Tape(),
            '9 9 9 9 9 9 9 m m − 9 9 9 9 9 9 8 . 9 9 9 9 9 m m =',
          ),
        ),
        'Under 0.01m²',
      );
      final thirteenth = press(
        const Tape(),
        '1 . 0 0 0 0 0 0 0 0 0 0 0 0 1 − 1 =',
      );
      expect(
        (thirteenth.chips.last as ResultChip).value,
        isA<Scalar>().having((s) => s.value, 'value', closeTo(1e-13, 1e-15)),
      );
    });

    test('1 mm + 1 mm = is still 2mm', () {
      expect(landed(press(const Tape(), '1 mm + 1 mm =')), '2mm');
    });
  });

  group('ChainEvaluator', () {
    const evaluator = ChainEvaluator();

    test('folds nothing on an empty tape', () {
      final empty = evaluator.fold(<TapeChip>[]);
      expect(empty, const ChainEmpty());
      expect(empty.hashCode, const ChainEmpty().hashCode);
    });

    test('stops at a value that cannot be read yet', () {
      const chips = [
        ValueChip(
          entry: EntryBuffer([Token(digits: '2', unit: Unit.foot)]),
          isActive: false,
        ),
        ValueChip(
          operator: Operator.add,
          entry: EntryBuffer([
            Token(digits: '18', unit: Unit.foot),
            Token(digits: '8'),
          ]),
        ),
      ];
      expect(evaluator.fold(chips), const ChainEmpty());
    });

    test('a result restarts the count of steps', () {
      const chips = [
        ResultChip(key: 'Calc', value: Scalar(3)),
        ValueChip(
          operator: Operator.multiply,
          entry: EntryBuffer([Token(digits: '89')]),
        ),
      ];
      expect(evaluator.fold(chips), const ChainValue(Scalar(267), steps: 1));
    });

    test('a result chip carrying an operator continues the chain', () {
      const chips = [
        ValueChip(entry: EntryBuffer([Token(digits: '2')]), isActive: false),
        ResultChip(key: 'Area', value: Scalar(3), operator: Operator.add),
      ];
      expect(evaluator.fold(chips), const ChainValue(Scalar(5), steps: 1));
    });

    test('only ÷ 0 continues the chain, and only through its own ÷', () {
      const five = ValueChip(
        entry: EntryBuffer([Token(digits: '5')]),
        isActive: false,
      );
      const twoDividing = ValueChip(
        operator: Operator.divide,
        entry: EntryBuffer([Token(digits: '2')]),
      );
      const twoAdded = ValueChip(
        operator: Operator.add,
        entry: EntryBuffer([Token(digits: '2')]),
      );
      expect(
        evaluator.fold(const [
          five,
          ErrorChip(CalculationError.dimensionError),
          twoDividing,
        ]),
        const ChainValue(Scalar(2), steps: 0),
      );
      expect(
        evaluator.fold(const [
          five,
          ErrorChip(CalculationError.divisionByZero),
          twoAdded,
        ]),
        const ChainValue(Scalar(2), steps: 0),
      );
      expect(
        evaluator.fold(const [
          five,
          ErrorChip(CalculationError.divisionByZero),
          twoDividing,
        ]),
        const ChainValue(Scalar(2.5), steps: 1),
      );
    });

    test('a result after an error chip starts a new chain', () {
      const chips = [
        ValueChip(entry: EntryBuffer([Token(digits: '5')]), isActive: false),
        ErrorChip(CalculationError.divisionByZero),
        ResultChip(key: 'Area', value: Scalar(3), operator: Operator.add),
      ];
      expect(evaluator.fold(chips), const ChainValue(Scalar(3), steps: 0));
    });

    test('a failed step is the fold until a chip with no operator', () {
      const pounds = ValueChip(
        entry: EntryBuffer([Token(digits: '5', unit: Unit.pound)]),
        isActive: false,
      );
      const feet = ValueChip(
        operator: Operator.add,
        entry: EntryBuffer([Token(digits: '12', unit: Unit.foot)]),
        isActive: false,
      );
      const three = ValueChip(
        operator: Operator.multiply,
        entry: EntryBuffer([Token(digits: '3')]),
      );
      expect(evaluator.fold(const [pounds, feet, three]), isA<ChainFailed>());
      expect(
        evaluator.fold(const [pounds, feet, pounds, three]),
        const ChainValue(Weight(1500, unit: Unit.pound), steps: 1),
      );
    });

    test('outcomes compare by what they carry', () {
      final steps = int.parse('1');
      expect(
        ChainValue(const Scalar(20), steps: steps),
        const ChainValue(Scalar(20), steps: 1),
      );
      // ignore: prefer_const_constructors
      final failed = ChainFailed(
        CalculationError.dimensionError,
        left: const Scalar(1),
        operator: Operator.add,
        right: const Scalar(2),
      );
      expect(
        failed,
        const ChainFailed(
          CalculationError.dimensionError,
          left: Scalar(1),
          operator: Operator.add,
          right: Scalar(2),
        ),
      );
      expect(
        ChainEvaluator(parser: QuantityParser(poundsPerTon: int.parse('2000'))),
        evaluator,
      );
    });
  });
}
