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
    'm' => unit(tape, Unit.metre),
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
    '[ACOS]' => tape.pressTrigKey(TrigFunction.arccosine),
    '[DMS]' => tape.pressDmsKey(),
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

      final retyped = press(emptied, '2');
      expect(
        texts(retyped),
        ['Arcsine2', 'Arcsine0°'],
        reason: 'no answer for 2, so the old one stands while the edit is open',
      );
      final sealed = retyped.tapChip(0);
      expect(sealed, isA<TapeChanged>());
      final TapeChanged(:tape, :notice, :removed) = sealed as TapeChanged;
      expect(texts(tape), ['Arcsine2']);
      expect(notice, TapeNotice.resultRemoved);
      expect(removed, ['Arcsine']);
      final chained = press(const Tape(), '0 . 5 [ASIN] × 2 = tap:0 ⌫ ⌫ ⌫ 2');
      final TapeChanged(tape: after, removed: gone) =
          chained.tapChip(0) as TapeChanged;
      expect(
        texts(after),
        ['Arcsine2', '×2'],
        reason:
            'the Calc computed from the removed Arcsine goes with it, never '
            'rebuilt from the 2 alone (decision tree row 274)',
      );
      expect(gone, ['Arcsine', 'Calc']);
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
      expect(removed, [pitchKey]);
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
        expect(removed, isEmpty);
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
      expect(removed, [DeterministicRules.pitchRiseKey]);
      expect(tape.editing!.index, 0);
    });

    test('an error chip after the reopened chip is rebuilt too: a repaired '
        'chain lands its Calc in its place, a chain still failing keeps its '
        'error', () {
      var tape = press(const Tape(), '7 8 lbs ÷ 1 2 ft =');
      expect(texts(tape), ['78lbs', '÷12ft', 'dimensionError']);

      tape = press(tape, 'tap:0 ✕ 2 4 ft');
      expect(texts(tape), ['24ft', '÷12ft', 'Calc2']);

      tape = press(tape, '✕ 2 4');
      expect(
        unit(tape, Unit.pound),
        const TapeRefused(TapeRefusal.unitBreaksTheChain),
        reason:
            'a unit that clashes with the chain is refused inside the '
            'edit (R2; product decision of 13 November 2026)',
      );
      expect(tape.editing!.index, 0);
      expect(texts(press(tape, 'ft tap:0')), ['24ft', '÷12ft', 'Calc2']);
    });

    test('a unit key that would make the chain fail is refused inside the '
        'edit: the number stays, the edit stays open, and a length unit then '
        'finishes it (R2; product decision of 13 November 2026)', () {
      final edited = press(const Tape(), '1 0 ft + 2 ft = tap:0 ✕ 5');
      expect(texts(edited), ['5', '+2ft', 'Calc12ft 0in']);
      expect(
        unit(edited, Unit.pound),
        const TapeRefused(TapeRefusal.unitBreaksTheChain),
      );
      expect(edited.editing!.index, 0);
      expect(texts(press(edited, 'ft')), ['5ft', '+2ft', 'Calc7ft 0in']);
      final fresh = press(const Tape(), '1 0 ft + 2');
      expect(
        unit(fresh, Unit.pound),
        isA<TapeChanged>(),
        reason: 'fresh entry is not an edit: the seal lands the error',
      );
    });

    test('a trig chip edited to a value it cannot answer takes only its own '
        'answer: a Calc from a separate chain stays (R2; Section 5.5)', () {
      final sealed = press(
        const Tape(),
        '0 . 5 [ASIN] 1 0 + 2 = tap:0 ✕ 2',
      ).tapChip(0);
      final TapeChanged(:tape, :removed) = sealed as TapeChanged;
      expect(texts(tape), ['Arcsine2', '10', '+2', 'Calc12']);
      expect(removed, ['Arcsine']);
      expect(texts(press(tape, 'tap:2 ⌫ 3 tap:2')), [
        'Arcsine2',
        '10',
        '+3',
        'Calc13',
      ]);
      final two = press(
        const Tape(),
        '0 . 5 [ASIN] 1 0 + 2 = 7 × 3 = tap:0 ✕ 2',
      ).tapChip(0);
      expect(texts((two as TapeChanged).tape), [
        'Arcsine2',
        '10',
        '+2',
        'Calc12',
        '7',
        '×3',
        'Calc21',
      ]);
      expect(two.removed, ['Arcsine']);
    });

    test('a step left after a removed result stays and = is refused until ⌫ '
        'removes it: nothing is computed from the value before the gap (R2; '
        'product decision of 13 November 2026)', () {
      const refused = TapeRefused(TapeRefusal.stepLostItsValue);
      final sealed = press(
        const Tape(),
        '5 ÷ 8 = [ACOS] × 2 = tap:0 ⌫ 9',
      ).tapChip(0);
      final TapeChanged(:tape, :removed) = sealed as TapeChanged;
      expect(texts(tape), ['9', '÷8', 'Calc1.13', '×2']);
      expect(removed, ['Arccosine', 'Calc']);
      expect(tape.pressEquals(), refused);
      expect(tape.runningTotal, const ChainEmpty());
      expect(texts(press(tape, '7')), ['9', '÷8', 'Calc1.13', '×2', '7']);
      expect(press(tape, '7').pressEquals(), refused);
      final removedStep = press(tape, '⌫');
      expect(texts(removedStep), ['9', '÷8', 'Calc1.13']);
      expect(
        removedStep.pressEquals(),
        const TapeRefused(TapeRefusal.resultAlreadyShown),
      );
      final named = press(
        land(press(const Tape(), '[Length] 3 ft [Width] 4 ft'), 'Diagonal'),
        '× 2 = tap:1 ✕ ⌫',
      );
      expect(texts(named), ['Length3ft', '×2']);
      expect(named.pressEquals(), refused);
      final tapped = press(named, 'tap:1');
      expect(tapped.editing, isNotNull);
      expect(
        tapped.editing!.index,
        1,
        reason: 'a tap still finds the marked step, a copy of the chip',
      );
      final sealedByTheTap = press(
        const Tape(),
        '5 ÷ 8 = [ACOS] × 2 = tap:0 ⌫ 9 tap:4',
      );
      expect(texts(sealedByTheTap), ['9', '÷8', 'Calc1.13', '×2']);
      expect(sealedByTheTap.editing, isNotNull);
      expect(
        sealedByTheTap.editing!.index,
        3,
        reason:
            'the tap that seals the 9 removes the answers before ×2 and marks '
            'it, and still opens the marked copy it was aimed at',
      );
      expect(
        (sealedByTheTap.chips[3] as ValueChip).followsARemovedResult,
        isTrue,
      );
      expect(texts(press(named, '⌫ + 5 ft =')), [
        'Length3ft',
        '+5ft',
        'Calc8ft 0in',
      ]);
    });

    test('a Calc that goes leaves its chain\'s value in place, so the step '
        'after it goes on from that value and is never marked: 5 + 3 = × 2 = '
        'with the +3 removed reads 5 | ×2 | Calc 10 (R2; Section 7)', () {
      final sealed = press(const Tape(), '5 + 3 = × 2 = tap:1 ✕').backspace();
      final TapeChanged(:tape, :removed) = sealed as TapeChanged;
      expect(
        texts(tape),
        ['5', '×2'],
        reason:
            'the Calc after the gap ran through the removed one, so it '
            'goes too; = brings it back from the value left in place',
      );
      expect(removed, ['Calc', 'Calc']);
      expect(texts(press(tape, '=')), ['5', '×2', 'Calc10']);
      expect(texts(press(tape, '= + 1 =')), [
        '5',
        '×2',
        'Calc10',
        '+1',
        'Calc11',
      ]);
    });

    test('an edit that makes a divisor zero acts like a typed ÷ 0: the error '
        'chip lands before the divisor, which is reopened empty, and the '
        'repair lands the Calc in the unit the user had picked (R2; product '
        'decision of 13 November 2026)', () {
      final reopened = press(const Tape(), '5 ÷ 2 = tap:1 ⌫ 0 tap:1');
      expect(texts(reopened), ['5', 'divisionByZero', '÷']);
      expect(reopened.editing!.index, 2);
      expect(texts(press(reopened, '7 =')), ['5', '÷7', 'Calc0.71']);
      final inches = press(const Tape(), '1 0 ft ÷ 2 = in');
      expect(texts(inches), ['10ft', '÷2', 'Calc60in']);
      final zero = press(inches, 'tap:1 ⌫ 0 tap:1');
      expect(texts(zero), ['10ft', 'divisionByZero', '÷']);
      expect(texts(press(zero, '4 tap:2')), ['10ft', '÷4', 'Calc30in']);
    });

    test('the error chip ÷ 0 lands before its reopened divisor is left as it '
        'is by an edit before it', () {
      final tape = press(const Tape(), '5 ÷ 0 = 2 tap:0 ⌫ 6 tap:0');

      expect(texts(tape), ['6', 'divisionByZero', '÷2']);
    });

    test('a Calc left with a lone operand after a chip is removed is no '
        'calculation, so it goes and is named', () {
      final outcome = press(const Tape(), '5 + 3 = tap:1 ✕').backspace();

      expect(outcome, isA<TapeChanged>());
      final TapeChanged(:tape, :removed) = outcome as TapeChanged;
      expect(texts(tape), ['5']);
      expect(removed, ['Calc']);
    });

    test('a Calc that fails in the middle of a chain at the seal takes every '
        'later result of the chain with it, by name: nothing is computed '
        'from part of a broken chain (B1; rule 4.8, Section 5.5)', () {
      final edited = press(
        const Tape(),
        '1 0 ft + 2 ft = + 3 ft = + 4 ft = tap:1 ⌫',
      );
      expect(texts(edited), [
        '10ft',
        '+2',
        'Calc12ft 0in',
        '+3ft',
        'Calc15ft 0in',
        '+4ft',
        'Calc19ft 0in',
      ], reason: 'while the edit is open every result stands');
      final sealed = edited.pressEquals();
      expect(sealed, isA<TapeChanged>());
      final TapeChanged(:tape, :notice, :removed) = sealed as TapeChanged;
      expect(texts(tape), ['10ft', '+2', 'dimensionError', '+3ft', '+4ft']);
      expect(notice, TapeNotice.resultRemoved);
      expect(removed, [
        'Calc',
        'Calc',
      ], reason: 'both removed results are named');
    });

    test('an error chip a seal left in the middle of a chain is rebuilt once '
        'the value is repaired, as one at the end is; only the error ÷ 0 '
        'lands before its reopened divisor stands (B2; rule 4.12)', () {
      final broken = press(
        const Tape(),
        '1 0 ft + 2 ft = + 3 ft = tap:1 ⌫ tap:1',
      );
      expect(texts(broken), ['10ft', '+2', 'dimensionError', '+3ft']);
      final repaired = press(broken, 'tap:1 ft tap:1');
      expect(texts(repaired), ['10ft', '+2ft', 'Calc12ft 0in', '+3ft']);
      expect(texts(press(repaired, '=')), [
        '10ft',
        '+2ft',
        'Calc12ft 0in',
        '+3ft',
        'Calc15ft 0in',
      ]);
      final divided = press(const Tape(), '5 ÷ 0 = 2 tap:0 ⌫ 6 tap:0');
      expect(texts(divided), ['6', 'divisionByZero', '÷2']);
    });

    test('a tap finds its chip again after the seal removed a result before '
        'it, so the tapped chip opens and nothing throws (B3)', () {
      final pitched = land(
        press(const Tape(), '[Rise] 6 in [Run] 1 2 in'),
        DeterministicRules.pitchRiseKey,
      );
      final stacked = press(
        pitched,
        '[Length] 1 0 ft [Width] 2 ft tap:1 ✕ 0 in',
      );
      expect(stacked.chips, hasLength(5));
      final width = press(stacked, 'tap:4');
      expect(texts(width), ['Rise6in', 'Run0in', 'Length10ft', 'Width2ft']);
      expect(
        width.editing,
        isA<({int index, ValueChip chip})>().having((e) => e.index, 'index', 3),
      );
      final length = press(stacked, 'tap:3');
      expect(texts(length), ['Rise6in', 'Run0in', 'Length10ft', 'Width2ft']);
      expect(
        length.editing,
        isA<({int index, ValueChip chip})>().having((e) => e.index, 'index', 2),
      );
      final chained = press(
        const Tape(),
        '1 0 ft + 2 ft = + 3 ft = + 4 ft = tap:1 ⌫ tap:5',
      );
      expect(texts(chained), ['10ft', '+2', 'dimensionError', '+3ft', '+4ft']);
      expect(
        chained.editing,
        isA<({int index, ValueChip chip})>().having((e) => e.index, 'index', 4),
      );
    });

    test('a Calc whose chain ran through a named result goes with it when '
        'that result is removed, never rebuilt with a new number from the '
        'chips left (B4; Section 5.5)', () {
      final diagonal = land(
        press(const Tape(), '[Length] 3 ft [Width] 4 ft'),
        'Diagonal',
      );
      final summed = press(diagonal, '+ 1 ft =');
      expect(texts(summed), [
        'Length3ft',
        'Width4ft',
        'Diagonal5ft',
        '+1ft',
        'Calc6ft 0in',
      ]);
      final outcome = press(summed, 'tap:1 ✕').backspace();
      expect(outcome, isA<TapeChanged>());
      final TapeChanged(:tape, :removed) = outcome as TapeChanged;
      expect(texts(tape), ['Length3ft', '+1ft']);
      expect(removed, ['Diagonal', 'Calc']);
    });

    test('a rebuilt result keeps the unit a unit key gave it and the spelling '
        'an angle was given, so a chip opened and closed unchanged leaves the '
        'tape as it was (B5; Section 7, rules 4.3 and 4.8)', () {
      final converted = press(const Tape(), '1 2 ft × 5 ft = in');
      expect(texts(converted), ['12ft', '×5ft', 'Calc8,640in²']);
      expect(texts(press(converted, 'tap:0 tap:0')), texts(converted));
      expect(texts(press(converted, 'tap:0 ⌫ ⌫ ⌫ 2 4 ft tap:0')), [
        '24ft',
        '×5ft',
        'Calc17,280in²',
      ]);
      final area = press(
        land(press(const Tape(), '[Length] 2 2 ft [Width] 1 8 ft'), 'Area'),
        'in',
      );
      expect(texts(area).last, 'Area57,024in²');
      expect(texts(press(area, 'tap:0 tap:0')), texts(area));
      final spelled = press(const Tape(), '1 2 ÷ 2 3 = [ASIN] [DMS]');
      expect(texts(spelled).last, 'Arcsine31°26\'56"');
      expect(texts(press(spelled, 'tap:0 tap:0')), texts(spelled));
    });

    test('a Calc that fails at the seal breaks the chain for a later Calc '
        'that would add up the chips after it: that Calc is removed and '
        'named, never computed from part of the chain (B1)', () {
      final outcome = press(
        const Tape(),
        '1 0 ft + 2 ft = + 3 ft + 4 ft = tap:1 ⌫',
      ).pressEquals();

      expect(outcome, isA<TapeChanged>());
      final TapeChanged(:tape, :removed) = outcome as TapeChanged;
      expect(texts(tape), ['10ft', '+2', 'dimensionError', '+3ft', '+4ft']);
      expect(texts(tape), isNot(contains('Calc7ft 0in')));
      expect(removed, ['Calc']);
    });

    test('a ÷ 0 error a seal left before a + chip is rebuilt once the '
        'divisor is repaired, unlike the ÷ 0 error that lands before its '
        'reopened divisor (B2; rule 4.12)', () {
      final broken = press(const Tape(), '1 0 ÷ 2 = + 3 = tap:1 ⌫ 0 =');
      expect(texts(broken), ['10', 'divisionByZero', '÷', '+3', 'Calc8']);
      expect(broken.editing!.index, 2);

      expect(texts(press(broken, '2 tap:2')), [
        '10',
        '÷2',
        'Calc5',
        '+3',
        'Calc8',
      ]);
      expect(texts(press(broken, '2 =')), ['10', '÷2', 'Calc5', '+3', 'Calc8']);
      expect(texts(press(const Tape(), '5 ÷ 0 = 2 tap:0 ⌫ 6 tap:0')), [
        '6',
        'divisionByZero',
        '÷2',
      ]);
    });

    test('a Calc read as degrees, minutes and seconds keeps that spelling '
        'when a chip before it is opened and closed unchanged (B5)', () {
      final spelled = press(const Tape(), '1 2 ÷ 2 3 = [ASIN] × 2 = [DMS]');
      expect(texts(spelled).last, 'Calc62°53\'53"');

      expect(texts(press(spelled, 'tap:0 tap:0')), texts(spelled));
    });

    test('⌫ on an emptied edit deletes the chip, and a result that cannot '
        'be rebuilt from what is left goes with it', () {
      final outcome = press(lengthWidthArea(), 'tap:1 ✕').backspace();

      expect(outcome, isA<TapeChanged>());
      final TapeChanged(:tape, :notice, :removed) = outcome as TapeChanged;
      expect(texts(tape), ['Length22ft']);
      expect(notice, TapeNotice.resultRemoved);
      expect(removed, ['Area']);
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
  group('Tape — what an edit leaves behind it (rule 4.8, Section 5)', () {
    test('a chain an edit broke stays broken: the steps after its error chip '
        'compute nothing, on the sealing = and on every = after it', () {
      final broken = press(
        const Tape(),
        '1 0 ft + 2 ft = + 3 ft = + 4 ft = tap:1 ⌫ =',
      );
      expect(texts(broken), ['10ft', '+2', 'dimensionError', '+3ft', '+4ft']);
      expect(broken.runningTotal, const ChainEmpty());
      expect(broken.pressEquals(), isA<TapeRefused>());
    });

    test('the = that seals an edit which removed results lands nothing in '
        'the same press, and names what went', () {
      final edited = press(
        const Tape(),
        '[Rise] 6 in [Run] 1 2 in [Pitch] × 2 = tap:1 ✕ 0 in',
      );
      final sealed = edited.pressEquals();
      expect(
        sealed,
        isA<TapeChanged>()
            .having((c) => c.notice, 'notice', TapeNotice.resultRemoved)
            .having((c) => c.removed, 'removed', hasLength(2)),
      );
      expect((sealed as TapeChanged).tape.chips.last, isNot(isA<ResultChip>()));
    });

    test('a rebuilt result reads in the unit its chain answers in, unless a '
        'unit key converted it, which the rebuild keeps', () {
      final metres = press(const Tape(), '1 0 m × 2 ft = tap:1 ✕ 2 m tap:1');
      expect(texts(metres).last, 'Calc20m²');
      final mixed = press(const Tape(), '1 0 ft + 2 ft = tap:0 ✕ 1 0 m tap:0');
      expect(
        texts(mixed).last,
        texts(press(const Tape(), '1 0 m + 2 ft =')).last,
      );
      final converted = press(
        const Tape(),
        '1 0 ft + 2 ft = m tap:0 ✕ 2 0 ft tap:0',
      );
      expect((converted.chips.last as ResultChip).readIn, Unit.metre);
      expect(texts(converted).last, startsWith('Calc6.7'));
      expect(texts(converted).last, endsWith('m'));
    });

    test('a trig answer whose operand went goes with it: 0.5 [ASIN] [SIN] '
        'with the 0.5 edited to 2 removes both answers', () {
      final edited = press(const Tape(), '0 . 5 [ASIN] [SIN] tap:0 ✕ 2');
      final sealed = edited.tapChip(0);
      expect(
        sealed,
        isA<TapeChanged>().having((c) => c.removed, 'removed', hasLength(2)),
      );
      expect((sealed as TapeChanged).tape.chips, hasLength(1));
    });

    test('an error an edit left where a result stood keeps its mark through '
        'a later edit elsewhere, so the result still comes back once the '
        'divisor is repaired', () {
      final broken = press(
        const Tape(),
        '1 0 ft + 2 ft = + 3 ft = tap:3 ⌫ tap:3',
      );
      expect(texts(broken), [
        '10ft',
        '+2ft',
        'Calc12ft 0in',
        '+3',
        'dimensionError',
      ]);
      final elsewhere = press(broken, 'tap:0 ⌫ ⌫ 2 ft tap:0');
      expect(texts(elsewhere), [
        '12ft',
        '+2ft',
        'Calc14ft 0in',
        '+3',
        'dimensionError',
      ]);
      expect(
        elsewhere.chips[4],
        const ErrorChip(CalculationError.dimensionError, replacesAResult: true),
        reason: 'rebuilt by the edit before it, the error keeps its mark',
      );
      expect(texts(press(elsewhere, 'tap:3 ft tap:3')), [
        '12ft',
        '+2ft',
        'Calc14ft 0in',
        '+3ft',
        'Calc17ft 0in',
      ]);
    });

    test('a trig answer taken on a Calc that an edit made fail goes with it: '
        '1 ÷ 2 = [ASIN] with the ÷ 2 edited to ÷ 0', () {
      final edited = press(const Tape(), '1 ÷ 2 = [ASIN] tap:1 ✕ 0');
      final sealed = edited.tapChip(1);
      expect(
        sealed,
        isA<TapeChanged>()
            .having((c) => c.removed, 'removed', isEmpty)
            .having((c) => c.notice, 'notice', isNull),
      );
      final waiting = (sealed as TapeChanged).tape;
      expect(texts(waiting), ['1', 'divisionByZero', '÷', 'Arcsine30°']);
      expect(texts(press(waiting, '4 tap:2')), [
        '1',
        '÷4',
        'Calc0.25',
        'Arcsine14.48°',
      ]);
    });

    test('an edit that makes a divisor zero removes no chip and names none, '
        'however many results follow: each waits as it was while the divisor '
        'is open and tracks the new divisor as it is typed (Section 5.5, '
        '"Edit makes a divisor zero")', () {
      final edited = press(const Tape(), '5 ÷ 2 = + 1 = × 3 = tap:1 ⌫ 0');
      for (final sealing in ['tap:1', '=']) {
        final outcome = pressOnce(edited, sealing);
        expect(
          outcome,
          isA<TapeChanged>()
              .having((c) => c.removed, 'removed', isEmpty)
              .having((c) => c.notice, 'notice', isNull),
          reason: sealing,
        );
        final waiting = (outcome as TapeChanged).tape;
        expect(texts(waiting), [
          '5',
          'divisionByZero',
          '÷',
          '+1',
          'Calc3.5',
          '×3',
          'Calc10.5',
        ], reason: sealing);
        expect(waiting.editing!.index, 2, reason: sealing);
        expect(texts(press(waiting, '4')), [
          '5',
          'divisionByZero',
          '÷4',
          '+1',
          'Calc2.25',
          '×3',
          'Calc6.75',
        ], reason: sealing);
        expect(texts(press(waiting, '4 =')), [
          '5',
          '÷4',
          'Calc1.25',
          '+1',
          'Calc2.25',
          '×3',
          'Calc6.75',
        ], reason: sealing);
      }
    });

    test('a divisor edited to 0 in the middle of the tape is reopened empty '
        'behind its error chip, the ÷ after it stays the user\'s step, and '
        'the result comes back once the divisor is repaired', () {
      final broken = press(const Tape(), '1 0 ÷ 2 = ÷ 5 = tap:1 ✕ 0 tap:1');
      expect(texts(broken), ['10', 'divisionByZero', '÷', '÷5', 'Calc1']);
      expect(broken.editing!.index, 2);
      final repaired = press(broken, '5 tap:2');
      expect(texts(repaired), ['10', '÷5', 'Calc2', '÷5', 'Calc0.4']);
      final byEquals = press(const Tape(), '1 0 ÷ 2 = ÷ 5 = tap:1 ✕ 0 = 5 =');
      expect(texts(byEquals), ['10', '÷5', 'Calc2', '÷5', 'Calc0.4']);
    });

    test('a trig answer behind the divisor a ÷ 0 edit reopened is rebuilt on '
        'the chain total as the divisor is typed, never on the divisor '
        'alone, and stands while the chain gives it no answer (rule 4.8, '
        'Section 5.5)', () {
      final waiting = press(const Tape(), '2 ÷ 4 = [ASIN] tap:1 ⌫ 0 tap:1');
      expect(texts(waiting), ['2', 'divisionByZero', '÷', 'Arcsine30°']);

      expect(
        texts(press(waiting, '8')).last,
        'Arcsine14.48°',
        reason: '2 ÷ 8 is 0.25, and 8 alone has no arcsine',
      );
      expect(texts(press(waiting, '8 =')), [
        '2',
        '÷8',
        'Calc0.25',
        'Arcsine14.48°',
      ]);
      expect(
        texts(press(waiting, '0')).last,
        'Arcsine30°',
        reason: '2 ÷ 0 has no answer yet, so the result stands',
      );
      expect(
        texts(press(waiting, '0 . 2')).last,
        'Arcsine30°',
        reason: '2 ÷ 0.2 is 10, which has no arcsine: never asin(0.2)',
      );
      final sealed = pressOnce(press(waiting, '0 . 2'), '=');
      expect(
        sealed,
        isA<TapeChanged>()
            .having((c) => texts(c.tape), 'tape', ['2', '÷0.2', 'Calc10'])
            .having((c) => c.removed, 'removed', ['Arcsine']),
      );
      expect(
        texts(press(const Tape(), '1 ÷ 2 = [ASIN] tap:1 ⌫ 0 tap:1 0 . 5')).last,
        'Arcsine30°',
        reason: '1 ÷ 0.5 is 2, which has no arcsine: never asin(0.5)',
      );
    });

    test('a result read in a picked unit recomputes live behind the divisor '
        'a ÷ 0 edit reopened, as a result with no picked unit does (rule '
        '4.8)', () {
      final waiting = press(
        const Tape(),
        '1 0 ft ÷ 2 = in + 1 in = tap:1 ⌫ 0 tap:1',
      );
      expect(texts(waiting), [
        '10ft',
        'divisionByZero',
        '÷',
        '+1in',
        'Calc5ft 1in',
      ]);

      expect(texts(press(waiting, '4')).last, 'Calc2ft 7in');
      expect(texts(press(waiting, '4 tap:2')), [
        '10ft',
        '÷4',
        'Calc30in',
        '+1in',
        'Calc2ft 7in',
      ]);
    });

    test('a second 0 into the divisor a ÷ 0 edit reopened reopens it empty '
        'again, as a typed 5 ÷ 0 = 0 = does: no chip is removed and none is '
        'named (Section 5.5, "Edit makes a divisor zero")', () {
      final again = press(const Tape(), '5 ÷ 2 = + 1 = tap:1 ⌫ 0 tap:1 0');
      for (final sealing in ['tap:2', '=']) {
        final outcome = pressOnce(again, sealing);
        expect(
          outcome,
          isA<TapeChanged>()
              .having((c) => c.removed, 'removed', isEmpty)
              .having((c) => c.notice, 'notice', isNull),
          reason: sealing,
        );
        final waiting = (outcome as TapeChanged).tape;
        expect(texts(waiting), [
          '5',
          'divisionByZero',
          '÷',
          '+1',
          'Calc3.5',
        ], reason: sealing);
        expect(waiting.editing!.index, 2, reason: sealing);
        expect(texts(press(waiting, '4 =')), [
          '5',
          '÷4',
          'Calc1.25',
          '+1',
          'Calc2.25',
        ], reason: sealing);
      }
    });

    test('⌫ on the empty divisor a ÷ 0 edit reopened removes the error chip '
        'and leaves the ÷ open with every later chip kept, as 5 ÷ 0 = ⌫ '
        'does; a second ⌫ removes the ÷ (Section 5, "Division by zero")', () {
      final waiting = press(const Tape(), '1 0 ÷ 4 = × 2 = tap:1 ⌫ 0 tap:1');
      expect(texts(waiting), ['10', 'divisionByZero', '÷', '×2', 'Calc5']);

      final outcome = waiting.backspace();
      expect(
        outcome,
        isA<TapeChanged>()
            .having((c) => c.removed, 'removed', isEmpty)
            .having((c) => c.notice, 'notice', isNull),
      );
      final open = (outcome as TapeChanged).tape;
      expect(texts(open), ['10', '÷', '×2', 'Calc5']);
      expect(open.editing!.index, 1);
      expect(texts(press(open, '5 =')), ['10', '÷5', '×2', 'Calc4']);
      expect(texts(press(open, '⌫')), ['10', '×2', 'Calc20']);
    });

    test('a tap on another chip that seals a ÷ 0 edit leaves the reopened '
        'divisor the only chip being typed, and is refused after that until '
        'a divisor is typed', () {
      final edited = press(const Tape(), '5 ÷ 2 = + 1 = tap:1 ⌫ 0');
      final waiting = press(edited, 'tap:0');

      expect(texts(waiting), ['5', 'divisionByZero', '÷', '+1', 'Calc3.5']);
      expect(waiting.editing!.index, 2);
      expect((waiting.chips[0] as ValueChip).isActive, isFalse);
      expect(
        waiting.tapChip(0),
        const TapeRefused(TapeRefusal.typeADivisorFirst),
      );
    });
  });

  group('Tape — a count is made again at the size it was made at (rule '
      '4.7, "recomputes in place"; requirement R8; G1, CA-1072)', () {
    PieceSize sheet(int width, int height) => PieceSize(
      width: Length(width * Length.ticksPerInch, unit: Unit.inch),
      height: Length(height * Length.ticksPerInch, unit: Unit.inch),
    );

    /// [tape] with the count of its counted area at [size] accepted, as a
    /// tap on the strip's chip lands it.
    Tape count(Tape tape, PieceSize size, {Trade trade = Trade.drywall}) {
      final made = const Trades().countsFor(trade, tape.countedArea!, [size]);
      return changed(
        tape.landAnswer(trade.resultKey, made.single.value, size: size),
      );
    }

    test('an accepted count carries the size it was made at, and a count '
        'with another size is another chip', () {
      final counted = count(lengthWidthArea(), sheet(48, 96));

      expect(texts(counted).last, 'Number of sheets12.83');
      expect((counted.chips.last as ResultChip).size, sheet(48, 96));
      expect(
        counted.chips.last,
        isNot(count(lengthWidthArea(), sheet(96, 48)).chips.last),
        reason: 'the same count at another size',
      );
    });

    test('editing Length from 22ft to 30ft recounts the accepted sheets at '
        '48in x 96in for the new area, in place (walkthrough 11.2)', () {
      final counted = count(lengthWidthArea(), sheet(48, 96));

      final edited = press(counted, 'tap:0 ✕ 3 0 ft tap:0');

      expect(texts(edited), [
        'Length30ft',
        'Width18ft 8in',
        'Area560ft²',
        'Number of sheets17.50',
      ]);
      expect((edited.chips.last as ResultChip).size, sheet(48, 96));
      expect(edited.editing, isNull);
    });

    test('two counts accepted from one area are each made again at their '
        'own size', () {
      final both = count(
        count(lengthWidthArea(), sheet(48, 96)),
        sheet(48, 120),
      );

      final edited = press(both, 'tap:0 ✕ 3 0 ft tap:0');

      expect(texts(edited).sublist(2), [
        'Area560ft²',
        'Number of sheets17.50',
        'Number of sheets14.00',
      ]);
    });

    test('a count follows the area as it is typed while the edit is open, '
        'and stands while the area cannot be read', () {
      final counted = count(lengthWidthArea(), sheet(48, 96));

      final cleared = press(counted, 'tap:0 ✕');
      expect(texts(cleared).last, 'Number of sheets12.83');

      final retyped = press(cleared, '3 0 ft');
      expect(retyped.editing, isNotNull);
      expect(texts(retyped).last, 'Number of sheets17.50');
    });

    test('a count of a typed area is made again when the area is retyped', () {
      final counted = count(press(const Tape(), '1 8 0 ft ft'), sheet(48, 96));
      expect(texts(counted), ['180ft²', 'Number of sheets5.63']);

      final edited = press(counted, 'tap:0 ✕ 3 6 0 ft ft tap:0');

      expect(texts(edited), ['360ft²', 'Number of sheets11.25']);
    });

    test('a count whose area is gone, or is not an area any more, goes with '
        'the seal and is named for its message', () {
      final counted = count(press(const Tape(), '1 8 0 ft ft'), sheet(48, 96));

      final sealed = pressOnce(press(counted, 'tap:0 ✕ 3 ft'), 'tap:0');

      expect(
        sealed,
        isA<TapeChanged>()
            .having((c) => texts(c.tape), 'tape', ['3ft'])
            .having((c) => c.removed, 'removed', ['Number of sheets'])
            .having((c) => c.notice, 'notice', TapeNotice.resultRemoved),
      );
    });

    test('an area brought to zero has no count: the count goes with the '
        'seal', () {
      final counted = count(press(const Tape(), '1 8 0 ft ft'), sheet(48, 96));

      final sealed = pressOnce(press(counted, 'tap:0 ✕ 0 ft ft'), 'tap:0');

      expect(
        sealed,
        isA<TapeChanged>()
            .having((c) => texts(c.tape), 'tape', ['0ft²'])
            .having((c) => c.removed, 'removed', ['Number of sheets']),
      );
    });

    test('a count accepted while a chip is being edited lands with its '
        'size too, behind the edit it closes', () {
      final area = lengthWidthArea();
      final open = press(area, 'tap:0');
      final made = const Trades().countsFor(Trade.drywall, area.countedArea!, [
        sheet(48, 96),
      ]).single;

      final landed = changed(
        open.landAnswer(
          Trade.drywall.resultKey,
          made.value,
          size: sheet(48, 96),
        ),
      );

      expect(landed.editing, isNull);
      expect((landed.chips.last as ResultChip).size, sheet(48, 96));
    });

    test('a masonry count is made again as a masonry count', () {
      final counted = count(
        lengthWidthArea(),
        sheet(8, 16),
        trade: Trade.masonry,
      );
      expect(texts(counted).last, 'Number of pieces462.00');

      final edited = press(counted, 'tap:0 ✕ 3 0 ft tap:0');

      expect(texts(edited).last, 'Number of pieces630.00');
    });

    test('a result with a size under a key no trade counts by is not made '
        'again as a count: it goes with the seal', () {
      final odd = changed(
        lengthWidthArea().landAnswer(
          'Sheets',
          const Scalar(1),
          size: sheet(48, 96),
        ),
      );

      final sealed = pressOnce(press(odd, 'tap:0 ✕ 3 0 ft'), 'tap:0');

      expect(
        sealed,
        isA<TapeChanged>().having((c) => c.removed, 'removed', ['Sheets']),
      );
    });
  });
}
