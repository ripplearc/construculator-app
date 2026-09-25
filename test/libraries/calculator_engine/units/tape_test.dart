import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = QuantityParser();

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
        'cm' => current.pressUnit(Unit.centimetre),
        'lbs' => current.pressUnit(Unit.pound),
        '/' => current.typeFraction(),
        '⌫' => current.backspace(),
        _ when key.startsWith('[') => current.pressFunctionKey(
          key.substring(1, key.length - 1),
        ),
        _ => current.typeDigit(key),
      });
    }
    return current;
  }

  List<String> texts(Tape tape) => [
    for (final chip in tape.chips)
      switch (chip) {
        ValueChip(:final key, :final entry) => '${key ?? ''}${entry.text}',
        ResultChip(:final key) => key,
        ErrorChip(:final error) => error.name,
        BracketChip(:final expression) => expression,
      },
  ];

  group('Tape', () {
    group('the entry order: function key, digits, unit', () {
      test(
        '[Length] 22 [Feet] makes Length 22ft, active until the next key',
        () {
          final tape = press(const Tape(), '[Length] 2 2 ft');
          expect(texts(tape), ['Length22ft']);
          expect(tape.active, isNotNull);
          expect(
            tape.active!.value(parser),
            const Length(16896, unit: Unit.foot),
          );
        },
      );

      test('a bare 8ft on its own is an unnamed chip', () {
        final tape = press(const Tape(), '8 ft');
        expect(texts(tape), ['8ft']);
        expect(tape.active!.key, isNull);
      });

      test('a function key seals the active chip and opens the next', () {
        final tape = press(const Tape(), '[Length] 2 2 ft [Width] 1 8 ft 8 in');
        expect(texts(tape), ['Length22ft', 'Width18ft 8in']);
        final first = tape.chips.first as ValueChip;
        expect(first.isActive, isFalse);
        expect(tape.active!.key, 'Width');
      });

      test('a function key on an empty active chip renames it', () {
        final tape = press(const Tape(), '[Length] [Width]');
        expect(texts(tape), ['Width']);
      });

      test('a bare number seals as a value when a function key follows', () {
        final tape = press(const Tape(), '7 8 [Length]');
        expect(texts(tape), ['78', 'Length']);
        final bare = tape.chips.first as ValueChip;
        expect(bare.value(parser), const Scalar(78));
      });

      test('a number with no unit cannot be left: finish this value first', () {
        final tape = press(const Tape(), '[Length] 1 8 ft 8');
        expect(
          tape.pressFunctionKey('Width'),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
        expect(
          press(const Tape(), '7 / 1 6').pressFunctionKey('Width'),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
      });

      test('Length 18 then [Width] is refused the same way (Appendix D)', () {
        final tape = press(const Tape(), '[Length] 1 8');
        expect(
          tape.pressFunctionKey('Width'),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
        );
        expect(tape.active!.isReadable, isFalse);
        expect(tape.active!.value(parser), isNull);
      });

      test('a new number after a finished value is its own chip', () {
        final tape = press(const Tape(), '[Length] 1 2 ft [Width] 1 0 ft');
        final sealed = changed(tape.pressFunctionKey('Height'));
        final parked = press(changed(sealed.backspace()), '8 ft');
        expect(texts(parked), ['Length12ft', 'Width10ft', '8ft']);
      });

      test('a digit after a sealed chip starts a bare chip', () {
        const sealed = Tape(
          chips: [
            ValueChip(
              entry: EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
              isActive: false,
            ),
          ],
        );
        expect(texts(press(sealed, '5')), ['22ft', '5']);
      });
    });

    group('unit keys on the active chip', () {
      test('close the open number and convert the finished one', () {
        final tape = press(const Tape(), '[Length] 2 2 ft in');
        expect(texts(tape), ['Length264in']);
        expect(tape.active!.exactValue, const Length(16896, unit: Unit.inch));
      });

      test('walkthrough 14.3: 18ft 8in → in → ft → yd keeps the ticks', () {
        var tape = press(const Tape(), '[Width] 1 8 ft 8 in');
        final steps = <String>[];
        for (final unit in [Unit.inch, Unit.foot, Unit.yard]) {
          tape = changed(tape.pressUnit(unit));
          steps.add(tape.active!.entry.text);
          expect(
            tape.active!.value(parser),
            isA<Length>().having((l) => l.ticks, 'ticks', 14336),
          );
        }
        expect(steps, ['224in', '18ft 8in', '6.222yd']);
      });

      test('the same key again raises, and a fourth press is refused', () {
        var tape = press(const Tape(), '2 in in in');
        expect(tape.active!.entry.text, '2in³');
        expect(tape.active!.value(parser), isA<Volume>());
        final refused = tape.pressUnit(Unit.inch);
        expect(refused, isA<TapeUnitRefused>());
        expect(
          (refused as TapeUnitRefused).refusal.reason,
          UnitKeyRefusal.stopsAtCubic,
        );
        tape = changed(tape.backspace());
        expect(tape.active!.entry.text, '2in²');
      });

      test(
        'a cubic value never becomes a compound: 45in starts its own chip',
        () {
          final tape = press(const Tape(), '2 5 1 1 ft ft ft 4 5 in');
          expect(texts(tape), ['2511ft³', '45in']);
          expect((tape.chips.first as ValueChip).isActive, isFalse);
          expect(tape.active!.entry.text, '45in');
        },
      );

      test('a unit with nothing typed says type a number first', () {
        expect(
          const Tape().pressUnit(Unit.foot),
          const TapeRefused(TapeRefusal.typeANumberFirst),
        );
        expect(
          press(const Tape(), '[Length]').pressUnit(Unit.foot),
          const TapeRefused(TapeRefusal.typeANumberFirst),
        );
      });

      test(
        'a unit with a result on the tape says units apply while typing',
        () {
          final tape = const Tape()
              .append(const ResultChip(key: 'Calc', value: Scalar(1)))
              .append(const ValueChip(key: 'Width'));
          expect(
            tape.pressUnit(Unit.foot),
            const TapeRefused(TapeRefusal.unitsApplyWhileTyping),
          );
        },
      );

      test('a unit straight after a result says units apply while typing', () {
        final tape = const Tape().append(
          const ResultChip(key: 'Calc', value: Scalar(156)),
        );
        expect(
          tape.pressUnit(Unit.foot),
          const TapeRefused(TapeRefusal.unitsApplyWhileTyping),
        );
      });

      test('a unit straight after a result with a unit converts it', () {
        const squareTicks = 72.0 * Length.ticksPerFoot * Length.ticksPerFoot;
        final tape = const Tape().append(
          const ResultChip(
            key: 'Calc',
            value: Area(squareTicks),
            operator: Operator.add,
          ),
        );
        final converted = changed(tape.pressUnit(Unit.yard));
        expect(
          converted.chips.single,
          const ResultChip(
            key: 'Calc',
            value: Area(squareTicks, unit: Unit.yard),
            operator: Operator.add,
          ),
        );
        expect(converted.active, isNull);
      });

      test(
        'a result keeps its dimension: Calc 10ft then [Feet] is refused',
        () {
          final tape = const Tape().append(
            const ResultChip(
              key: 'Calc',
              value: Length(7680, unit: Unit.foot),
            ),
          );
          expect(
            tape.pressUnit(Unit.foot),
            const TapeUnitRefused(UnitKeyRefused(UnitKeyRefusal.keepsLength)),
          );
          expect(
            (tape.pressUnit(Unit.kilogram) as TapeUnitRefused).refusal.reason,
            UnitKeyRefusal.cannotConvert,
          );
        },
      );

      test('a refusal from the number being typed is passed through', () {
        expect(
          press(const Tape(), '7 /').pressUnit(Unit.inch),
          const TapeEntryRefused(EntryRefusal.finishTheFraction),
        );
        expect(
          press(const Tape(), '5').pressUnit(Unit.pound, holdsLengthOnly: true),
          const TapeEntryRefused(EntryRefusal.needsLength),
        );
      });

      test('a length-only key refuses the raise on its finished value', () {
        final tape = press(const Tape(), '[Width] 2 2 ft');
        final refused = tape.pressUnit(Unit.foot, holdsLengthOnly: true);
        expect(
          (refused as TapeUnitRefused).refusal.reason,
          UnitKeyRefusal.keepsLength,
        );
      });

      test('an entry the parser cannot read cannot be converted', () {
        const mixed = Tape(
          chips: [
            ValueChip(
              entry: EntryBuffer([
                Token(digits: '5', unit: Unit.pound),
                Token(digits: '3', unit: Unit.foot),
              ]),
            ),
          ],
        );
        expect(
          mixed.pressUnit(Unit.inch),
          const TapeUnitRefused(UnitKeyRefused(UnitKeyRefusal.cannotConvert)),
        );
      });

      test('reads and re-spells a ton by the tape\'s one definition', () {
        final tape = press(const Tape(poundsPerTon: 2240), '2 2 4 0 lbs');
        expect(changed(tape.pressUnit(Unit.ton)).active!.entry.text, '1ton');
      });
    });

    group('digits and fractions', () {
      test('editing a converted value reads the digits again', () {
        final converted = press(const Tape(), '2 2 ft in');
        expect(converted.active!.exactValue, isNotNull);
        final edited = press(converted, '⌫ 5');
        expect(edited.active!.entry.text, '2645');
        expect(edited.active!.exactValue, isNull);
        expect(edited.active!.value(parser), const Scalar(2645));
      });

      test('a digit typed and deleted leaves the exact quantity in place', () {
        final converted = press(const Tape(), '[Width] 1 8 ft 8 in yd');
        expect(converted.active!.entry.text, '6.222yd');
        final restored = press(converted, '5 ⌫');
        expect(restored.active!.entry.text, '6.222yd');
        expect(
          restored.active!.value(parser),
          const Length(14336, unit: Unit.yard),
        );
      });

      test('rule 4.15: the next value typed never changes a converted one', () {
        final tape = press(const Tape(), '[Length] 1 8 ft 8 in yd 3 cm');
        expect(texts(tape), ['Length6.222yd', '3cm']);
        final converted = tape.chips.first as ValueChip;
        expect(converted.isActive, isFalse);
        expect(converted.value(parser), const Length(14336, unit: Unit.yard));
      });

      test('[/] with nothing being typed is refused', () {
        expect(
          const Tape().typeFraction(),
          const TapeRefused(TapeRefusal.nothingBeingTyped),
        );
        expect(
          press(const Tape(), '7 .').typeFraction(),
          const TapeEntryRefused(EntryRefusal.decimalCannotTakeFraction),
        );
      });

      test('a second decimal point is refused', () {
        expect(
          press(const Tape(), '3 0 . 4').typeDigit('.'),
          const TapeEntryRefused(EntryRefusal.secondDecimalPoint),
        );
      });
    });

    group('backspace', () {
      test(
        'walkthrough 21.2: removes the error chip and reopens the value before it',
        () {
          final tape = const Tape()
              .append(
                const ValueChip(
                  entry: EntryBuffer([Token(digits: '78', unit: Unit.pound)]),
                  isActive: false,
                ),
              )
              .append(
                const ValueChip(
                  operator: Operator.divide,
                  entry: EntryBuffer([Token(digits: '12', unit: Unit.foot)]),
                  isActive: false,
                ),
              )
              .append(const ErrorChip(CalculationError.dimensionError));
          expect(tape.active, isNull);
          final reopened = changed(tape.backspace());
          expect(texts(reopened), ['78lbs', '12ft']);
          expect(reopened.active!.entry.text, '12ft');
          expect(reopened.active!.operator, Operator.divide);
          final repaired = changed(reopened.backspace());
          expect(repaired.active!.entry.text, '12');
          expect(repaired.active!.value(parser), const Scalar(12));
        },
      );

      test('append seals the active chip, so only the last chip is active', () {
        final tape = press(
          const Tape(),
          '[Length] 2 2 ft',
        ).append(const ResultChip(key: 'Calc', value: Scalar(1)));
        expect((tape.chips.first as ValueChip).isActive, isFalse);
        expect(tape.active, isNull);
      });

      test('removes a result chip and reactivates the input before it', () {
        final tape = press(
          const Tape(),
          '[Length] 2 2 ft',
        ).append(const ResultChip(key: 'Calc', value: Scalar(1)));
        final reopened = changed(tape.backspace());
        expect(texts(reopened), ['Length22ft']);
        expect(reopened.active, isNotNull);
      });

      test('empties the active chip before removing it', () {
        var tape = press(const Tape(), '[Length] 2 2 ft [Width] 8');
        tape = changed(tape.backspace());
        expect(texts(tape), ['Length22ft', 'Width']);
        expect(tape.active!.entry.isEmpty, isTrue);
        tape = changed(tape.backspace());
        expect(texts(tape), ['Length22ft']);
        expect(tape.active!.entry.text, '22ft');
      });

      test('removes an error that follows a result and leaves the result', () {
        final tape = const Tape()
            .append(const ResultChip(key: 'Calc', value: Scalar(14)))
            .append(const ErrorChip(CalculationError.dimensionError));
        expect(texts(changed(tape.backspace())), ['Calc']);
      });

      test('an error at the head of the tape leaves it empty', () {
        final tape = const Tape().append(
          const ErrorChip(CalculationError.divisionByZero),
        );
        expect(changed(tape.backspace()).isEmpty, isTrue);
      });

      test('has nothing to delete on an empty tape', () {
        expect(
          const Tape().backspace(),
          const TapeRefused(TapeRefusal.nothingToDelete),
        );
      });
    });

    test('knows when it ends on a result', () {
      expect(const Tape().endsWithResult, isFalse);
      expect(
        const Tape()
            .append(const ResultChip(key: 'Calc', value: Scalar(1)))
            .endsWithResult,
        isTrue,
      );
    });

    test('knows when it ends on an error, which also ends the session', () {
      expect(const Tape().endsWithError, isFalse);
      final failed = const Tape().append(
        const ErrorChip(CalculationError.dimensionError),
      );
      expect(failed.endsWithError, isTrue);
      expect(failed.endsWithResult, isFalse);
    });

    test('outcomes compare by what they carry', () {
      final digit = int.parse('5').toString();
      expect(
        const Tape().typeDigit(digit),
        const TapeChanged(
          Tape(
            chips: [
              ValueChip(entry: EntryBuffer([Token(digits: '5')])),
            ],
          ),
        ),
      );
      // ignore: prefer_const_constructors
      final refused = TapeRefused(TapeRefusal.typeANumberFirst);
      expect(refused, const TapeRefused(TapeRefusal.typeANumberFirst));
      // ignore: prefer_const_constructors
      final entryRefused = TapeEntryRefused(
        EntryRefusal.fractionNeedsNumerator,
      );
      expect(
        entryRefused,
        const TapeEntryRefused(EntryRefusal.fractionNeedsNumerator),
      );
      // ignore: prefer_const_constructors
      final unitRefused = TapeUnitRefused(
        // ignore: prefer_const_constructors
        UnitKeyRefused(UnitKeyRefusal.stopsAtCubic),
      );
      expect(
        unitRefused,
        const TapeUnitRefused(UnitKeyRefused(UnitKeyRefusal.stopsAtCubic)),
      );
    });
  });

  group('Chip', () {
    test('an input chip copies with fields cleared or kept', () {
      const chip = ValueChip(
        key: 'Length',
        operator: Operator.add,
        entry: EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
        exact: (
          value: Length(16896, unit: Unit.foot),
          spelled: EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
        ),
      );
      final cleared = chip.copyWith(
        key: () => null,
        operator: () => null,
        exact: () => null,
        isActive: false,
      );
      expect(
        cleared,
        const ValueChip(
          entry: EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
          isActive: false,
        ),
      );
      expect(chip.copyWith(), chip);
    });

    test('a result chip and an error chip compare by what they carry', () {
      final key = 'Calc${int.parse('0') == 0 ? '' : 'x'}';
      expect(
        ResultChip(key: key, value: const Scalar(14), operator: Operator.add),
        const ResultChip(
          key: 'Calc',
          value: Scalar(14),
          operator: Operator.add,
        ),
      );
      // ignore: prefer_const_constructors
      final error = ErrorChip(CalculationError.divisionByZero);
      expect(error, const ErrorChip(CalculationError.divisionByZero));
    });

    test('operators spell the four glyphs', () {
      expect(Operator.values.map((o) => o.symbol), ['×', '÷', '+', '−']);
    });
  });
}
