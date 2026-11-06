import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  /// A unit under a dimension key (Length, Width) takes lengths only, as the
  /// bloc tells the tape; a bare number takes any unit.
  TapeOutcome unit(Tape tape, Unit unit) => tape.pressUnit(
    unit,
    holdsLengthOnly: LengthOnlyKeys.all.contains(tape.beingTyped?.key),
  );

  TapeOutcome pressOnce(Tape tape, String key) => switch (key) {
    'ft' => unit(tape, Unit.foot),
    'in' => unit(tape, Unit.inch),
    'yd' => unit(tape, Unit.yard),
    'lbs' => unit(tape, Unit.pound),
    '+' => tape.pressOperator(Operator.add),
    '×' => tape.pressOperator(Operator.multiply),
    '÷' => tape.pressOperator(Operator.divide),
    '=' => tape.pressEquals(),
    '/' => tape.typeFraction(),
    '⌫' => tape.backspace(),
    '✕' => tape.clearActive(),
    '(' => tape.pressBracket(),
    '[SIN]' => tape.pressTrigKey(TrigFunction.sine),
    '[ASIN]' => tape.pressTrigKey(TrigFunction.arcsine),
    _ when key.startsWith('tap:') => tape.tapChip(int.parse(key.substring(4))),
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
      if (key.isEmpty) continue;
      current = changed(pressOnce(current, key));
    }
    return current;
  }

  /// Lands the rules' answer named [key], as accepting its strip chip does.
  Tape land(Tape tape, String key) {
    final answer = const DeterministicRules()
        .answersFor(tape.namedValues)
        .firstWhere((answer) => answer.key == key);
    return changed(tape.landAnswer(key, answer.value));
  }

  List<String> texts(Tape tape) => [
    for (final chip in tape.chips)
      switch (chip) {
        ValueChip(:final key, :final operator, :final entry) =>
          '${operator?.symbol ?? ''}${key ?? ''}${entry.text}',
        ResultChip(:final key, :final value) =>
          '$key${formatter.format(value)}',
        ErrorChip(:final error) => error.name,
        BracketChip(:final expression) => expression,
      },
  ];

  /// Length 22ft, Width 18ft 8in and the Area they earn (walkthrough 11.1).
  Tape lengthWidthArea() =>
      land(press(const Tape(), '[Length] 2 2 ft [Width] 1 8 ft 8 in'), 'Area');

  group('Tape — the results after a reopened chip recompute (rule 4.8, '
      'Section 5.5)', () {
    test('✕ then a new value recomputes every result after the chip while '
        'the edit is still open (S64: Area 560ft²)', () {
      final tape = press(changed(lengthWidthArea().tapChip(0)), '✕ 3 0 ft');

      expect(texts(tape), ['Length30ft', 'Width18ft 8in', 'Area560ft²']);
      expect(tape.editing!.index, 0);
    });

    test('a unit that steps down continues the reopened compound and the '
        'result follows', () {
      final tape = press(changed(lengthWidthArea().tapChip(0)), '8 in');

      expect(texts(tape), ['Length22ft 8in', 'Width18ft 8in', 'Area423.11ft²']);
    });

    test('a valid fix lands and recomputes in place; raising a dimension key '
        'to in² is refused with the value kept a length (S65)', () {
      var tape = press(
        changed(lengthWidthArea().tapChip(1)),
        '7 8 ⌫ ⌫ ✕ 2 0 ft',
      );
      expect(texts(tape), ['Length22ft', 'Width20ft', 'Area440ft²']);

      tape = press(tape, '✕ 4 in');
      expect(texts(tape), ['Length22ft', 'Width4in', 'Area7.33ft²']);
      expect(
        pressOnce(tape, 'in'),
        const TapeUnitRefused(UnitKeyRefused(UnitKeyRefusal.keepsLength)),
      );
    });

    test('tapping again after a real edit seals the chip with the result '
        'recomputed (S66: Area 440ft²)', () {
      final tape = press(lengthWidthArea(), 'tap:1 ✕ 2 0 ft tap:1');

      expect(texts(tape), ['Length22ft', 'Width20ft', 'Area440ft²']);
      expect(tape.active, isNull);
    });

    test('a tap on a chip whose value is broken keeps the edit open and '
        'says why; the unit then lets the tap close it (S66)', () {
      final open = press(lengthWidthArea(), 'tap:1 ✕ 5');

      expect(
        pressOnce(open, 'tap:1'),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
      expect(open.editing!.index, 1);

      final closed = press(open, 'ft tap:1');
      expect(texts(closed), ['Length22ft', 'Width5ft', 'Area110ft²']);
      expect(closed.active, isNull);
    });

    test('a tap on a chip drops the empty chip a key had opened, and an '
        'emptied edit cannot be left (S67: "The value is empty")', () {
      var tape = press(lengthWidthArea(), '[Height] tap:1');
      expect(texts(tape), ['Length22ft', 'Width18ft 8in', 'Area410.67ft²']);
      expect(tape.editing!.index, 1);

      tape = press(tape, '✕');
      expect(
        pressOnce(tape, '[Height]'),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
      expect(
        pressOnce(tape, '✕'),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
        reason: '✕ on an emptied edit is not the ✕ that closes the calculator',
      );

      tape = press(tape, '2 0 ft [Height]');
      expect(texts(tape), ['Length22ft', 'Width20ft', 'Area440ft²', 'Height']);
    });

    test('a weight unit under a dimension key is refused mid-edit and the '
        'typed number survives; the length unit finishes it (S69)', () {
      final open = press(lengthWidthArea(), 'tap:1 ✕ 5');

      expect(
        pressOnce(open, 'lbs'),
        const TapeEntryRefused(EntryRefusal.needsLength),
      );
      expect(texts(open)[1], 'Width5');

      final closed = press(open, 'ft tap:1');
      expect(texts(closed), ['Length22ft', 'Width5ft', 'Area110ft²']);
    });

    test('a Calc after the reopened chip recomputes live, and = seals the '
        'edit with no second result (S82)', () {
      var tape = press(const Tape(), '1 8 ft × 4 ft =');
      expect(texts(tape), ['18ft', '×4ft', 'Calc72ft²']);

      tape = press(tape, 'tap:0 ⌫ ⌫ ⌫ 1 0 ft');
      expect(texts(tape), ['10ft', '×4ft', 'Calc40ft²']);
      expect(tape.editing!.index, 0);

      final sealed = tape.pressEquals();
      expect(sealed, isA<TapeChanged>());
      expect((sealed as TapeChanged).notice, isNull);
      expect(sealed.tape.active, isNull);
      expect(texts(sealed.tape), ['10ft', '×4ft', 'Calc40ft²']);
    });

    test('a named answer is rebuilt under its own key, not the first answer '
        'the rules give: a Diagonal stays a Diagonal', () {
      final tape = press(
        land(
          press(const Tape(), '[Length] 2 2 ft [Width] 1 8 ft 8 in'),
          'Diagonal',
        ),
        'tap:0 ✕ 3 0 ft',
      );

      final diagonal = const DeterministicRules()
          .answersFor(tape.namedValues)
          .firstWhere((answer) => answer.key == 'Diagonal');
      expect(
        tape.chips.last,
        ResultChip(key: 'Diagonal', value: diagonal.value),
      );
      expect(texts(tape)[0], 'Length30ft');
    });

    test(
      'a Calc that continues from an earlier Calc is rebuilt through it',
      () {
        final tape = press(const Tape(), '3 × 4 = × 2 = tap:0 ⌫ 5');

        expect(texts(tape), ['5', '×4', 'Calc20', '×2', 'Calc40']);
      },
    );

    test('a trig answer after the reopened operand is rebuilt on the new '
        'angle', () {
      final tape = press(const Tape(), '3 8 [SIN] tap:0 ⌫ 9');

      expect(texts(tape).first, 'Sine39');
      final answer = tape.chips.last as ResultChip;
      expect(answer.key, 'Sine');
      expect(
        (answer.value as Scalar).value,
        closeTo(math.sin(39 * math.pi / 180), 1e-9),
      );
    });

    test('a result the new value gives no answer for stands while the edit '
        'is open, and is removed and named once the edit is sealed (Section '
        '5.5, "Arcsine removed")', () {
      final reopened = press(const Tape(), '0 . 5 [ASIN] tap:0');
      expect(texts(reopened), ['Arcsine0.5', 'Arcsine30°']);

      final emptied = press(reopened, '⌫ ⌫ ⌫');
      expect(
        texts(emptied),
        ['Arcsine', 'Arcsine0°'],
        reason:
            'the answer followed the 0 the first ⌫ left, and stands '
            'while the chip is empty',
      );

      final deleted = emptied.backspace();
      expect(deleted, isA<TapeChanged>());
      final TapeChanged(:tape, :notice, :removed) = deleted as TapeChanged;
      expect(texts(tape), isEmpty);
      expect(notice, TapeNotice.resultRemoved);
      expect(removed, 'Arcsine');
    });

    test('a named answer the new value gives none for stands while the edit '
        'is open, and is removed and named once the edit is sealed', () {
      const pitchKey = DeterministicRules.pitchRiseKey;
      final pitched = land(
        press(const Tape(), '[Rise] 6 in [Run] 1 2 in'),
        pitchKey,
      );
      expect(texts(pitched).sublist(0, 2), ['Rise6in', 'Run12in']);
      final answer = pitched.chips.last;
      expect(answer, isA<ResultChip>());
      expect((answer as ResultChip).key, pitchKey);

      final edited = press(pitched, 'tap:1 ✕ 0 in');
      expect(texts(edited).sublist(0, 2), ['Rise6in', 'Run0in']);
      expect(
        edited.chips.last,
        answer,
        reason:
            'a run of nothing gives no pitch: the old one stands, '
            'dashed, until the edit is sealed',
      );

      final sealed = edited.tapChip(1);
      expect(sealed, isA<TapeChanged>());
      final TapeChanged(:tape, :notice, :removed) = sealed as TapeChanged;
      expect(texts(tape), ['Rise6in', 'Run0in']);
      expect(notice, TapeNotice.resultRemoved);
      expect(removed, pitchKey);
    });

    test('a bare number in a + chain with units fails the chain for a '
        'keystroke, and the Calc stands as it was until the unit lands '
        '(10ft + 2ft, edited to 30ft)', () {
      var tape = press(const Tape(), '1 0 ft + 2 ft =');
      expect(texts(tape), ['10ft', '+2ft', 'Calc12ft 0in']);

      tape = press(tape, 'tap:0 ⌫ ⌫ ⌫ 3');
      expect(texts(tape), ['3', '+2ft', 'Calc12ft 0in']);
      expect(tape.editing!.index, 0);

      tape = press(tape, '0 ft');
      expect(texts(tape), ['30ft', '+2ft', 'Calc32ft 0in']);
    });

    test('a chip that does not read yet — emptied, or holding a fraction '
        'still being typed — leaves the Calc after it standing', () {
      final emptied = press(const Tape(), '1 0 × 4 = tap:0 ✕');
      expect(texts(emptied), ['', '×4', 'Calc40']);

      final fraction = press(emptied, '7 / 8');
      expect(
        texts(fraction),
        ['7/8', '×4', 'Calc28'],
        reason:
            'the Calc followed the 7, and a fraction with no unit yet '
            'is not read as 0.875',
      );
      expect(texts(press(fraction, 'in')), ['7/8in', '×4', 'Calc0ft 3-1/2in']);
    });

    test('the same in a ÷ chain: the Calc stands through the keystrokes '
        'that cannot divide', () {
      final tape = press(const Tape(), '1 0 ft ÷ 2 ft = tap:0 ⌫');

      expect(texts(tape), ['10', '÷2ft', 'Calc5']);
      expect(texts(press(tape, 'ft')), ['10ft', '÷2ft', 'Calc5']);
    });

    test('sealing an edit whose chain fails lands the error chip = would in '
        'the Calc\'s place, through the second tap and through a leaving key '
        'alike', () {
      final edited = press(const Tape(), '1 0 ft + 2 ft = tap:0 ⌫ ⌫ ⌫ 3');

      for (final seal in [edited.tapChip(0), edited.pressEquals()]) {
        expect(seal, isA<TapeChanged>());
        final TapeChanged(:tape, :notice, :removed) = seal as TapeChanged;
        expect(texts(tape), ['3', '+2ft', 'dimensionError']);
        expect(notice, isNull);
        expect(removed, isNull);
      }
    });

    test('a tap on another chip seals the edit the same way, and names the '
        'result the seal removed', () {
      final pitched = land(
        press(const Tape(), '[Rise] 6 in [Run] 1 2 in'),
        DeterministicRules.pitchRiseKey,
      );
      final edited = press(pitched, 'tap:1 ✕ 0 in');

      final outcome = edited.tapChip(0);
      expect(outcome, isA<TapeChanged>());
      final TapeChanged(:tape, :removed) = outcome as TapeChanged;
      expect(texts(tape), ['Rise6in', 'Run0in']);
      expect(removed, DeterministicRules.pitchRiseKey);
      expect(tape.editing!.index, 0);
    });

    test('an error chip after the reopened chip is rebuilt too: a repaired '
        'chain lands its Calc in its place, a chain still failing keeps its '
        'error', () {
      var tape = press(const Tape(), '7 8 lbs ÷ 1 2 ft =');
      expect(texts(tape), ['78lbs', '÷12ft', 'dimensionError']);

      tape = press(tape, 'tap:0 ✕ 2 4 ft');
      expect(texts(tape), ['24ft', '÷12ft', 'Calc2']);

      tape = press(tape, '✕ 2 4 lbs tap:0');
      expect(texts(tape), ['24lbs', '÷12ft', 'dimensionError']);
      expect(tape.editing, isNull);
    });

    test('the error chip ÷ 0 lands before its reopened divisor is left as it '
        'is by an edit before it', () {
      final tape = press(const Tape(), '5 ÷ 0 = 2 tap:0 ⌫ 6 tap:0');

      expect(texts(tape), ['6', 'divisionByZero', '÷2']);
    });

    test('a Calc left with a lone operand after a chip is removed is no '
        'calculation, so it goes and is named', () {
      final outcome = press(const Tape(), '5 + 3 = tap:0 ✕').backspace();

      expect(outcome, isA<TapeChanged>());
      final TapeChanged(:tape, :removed) = outcome as TapeChanged;
      expect(texts(tape), ['+3']);
      expect(removed, 'Calc');
    });

    test('⌫ on an emptied edit deletes the chip, and a result that cannot '
        'be rebuilt from what is left goes with it', () {
      final outcome = press(lengthWidthArea(), 'tap:1 ✕').backspace();

      expect(outcome, isA<TapeChanged>());
      final TapeChanged(:tape, :notice, :removed) = outcome as TapeChanged;
      expect(texts(tape), ['Length22ft']);
      expect(notice, TapeNotice.resultRemoved);
      expect(removed, 'Area');
      expect(tape.active, isNull);
    });

    test('tapping another chip while the edited one reads seals it and '
        'reopens the other', () {
      final tape = press(lengthWidthArea(), 'tap:1 ✕ 2 0 ft tap:0');

      expect(texts(tape), ['Length22ft', 'Width20ft', 'Area440ft²']);
      expect(tape.editing!.index, 0);
      expect((tape.chips[1] as ValueChip).isActive, isFalse);
    });
  });
}
