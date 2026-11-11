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

  group('Tape — a chip reopened by a tap (rule 4.8, Section 5.5)', () {
    test('a tap on a finished chip reopens it in place with its old value, '
        'and the chips after it stay (S64)', () {
      final tape = changed(lengthWidthArea().tapChip(0));

      expect(texts(tape), ['Length22ft', 'Width18ft 8in', 'Area410.67ft²']);
      expect(tape.editing!.index, 0);
      expect(tape.active!.key, 'Length');
      expect(tape.beingTyped!.key, 'Length');
      expect((tape.chips[1] as ValueChip).isActive, isFalse);
    });

    test('a chip being typed at the end is entry, not an edit', () {
      final tape = press(const Tape(), '[Length] 2 2 ft');

      expect(tape.editing, isNull);
      expect(tape.active, isNotNull);
    });

    test('the reopened last chip of the tape is an edit too: a unit that '
        'cannot continue it is refused in place and never split into a new '
        'chip, and neither ✕ twice nor a tap on another chip abandons it '
        '(rule 4.8; doc lines 726 and 3552)', () {
      final width = press(
        const Tape(),
        '[Length] 2 2 ft [Width] 1 8 ft 8 in tap:1 tap:1',
      );
      expect(
        width.editing,
        isA<({int index, ValueChip chip})>().having((e) => e.index, 'index', 1),
      );
      expect(width.active, isNotNull);
      final seven = press(width, '7');
      expect(
        unit(seven, Unit.yard),
        const TapeEntryRefused(EntryRefusal.cannotAppendUnit),
      );
      expect(texts(seven), ['Length22ft', 'Width18ft 8in 7']);
      final emptied = press(width, '✕');
      expect(texts(emptied), ['Length22ft', 'Width']);
      expect(
        emptied.clearActive(),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
      expect(
        emptied.tapChip(0),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
        reason: 'the emptied Width is an edit, not a chip a key just opened',
      );
      final middle = press(
        const Tape(),
        '[Length] 2 2 ft [Width] 1 8 ft [Height] 8 ft tap:1 ✕',
      );
      expect(
        middle.tapChip(0),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
        reason: 'mid-tape the same tap is refused the same way',
      );
      expect(texts(press(emptied, '2 0 ft tap:1')), [
        'Length22ft',
        'Width20ft',
      ]);
    });

    test('✕ twice on a reopened chip, mid-tape or the last, refuses the '
        'second time with "Finish this value first" and keeps the edit '
        'open (Section 5.5)', () {
      for (final keys in [
        '2 ft + 3 ft + 4 ft = tap:1 ✕',
        '2 ft + 3 ft + 4 ft tap:2 tap:2 ✕',
      ]) {
        final emptied = press(const Tape(), keys);
        expect(emptied.editing, isNotNull, reason: keys);
        expect(
          emptied.clearActive(),
          const TapeRefused(TapeRefusal.finishThisValueFirst),
          reason: keys,
        );
      }
    });

    test('a chip ⌫ reopens at the end of the tape is entry again, once an '
        'edit of it has sealed', () {
      final tape = press(const Tape(), '1 8 ft × 4 ft tap:0 tap:0 ⌫');
      expect(texts(tape), ['18ft']);
      expect(tape.active, isNotNull);
      expect(tape.editing, isNull);
      expect(
        changed(tape.clearActive()).clearActive(),
        const TapeRefused(TapeRefusal.nothingBeingTyped),
      );
    });

    test('an edit that leaves a trig chip with a value it cannot answer '
        'seals all the same, so the result after it can be removed and '
        'named (B2; Section 5.5 "Arcsine removed"; decision tree row 274)', () {
      final edited = press(const Tape(), '0 . 5 [ASIN] × 2 = tap:0 ⌫ ⌫ ⌫ 2');
      expect(
        edited.editing,
        isA<({int index, ValueChip chip})>().having((e) => e.index, 'index', 0),
      );
      final sealed = changed(edited.tapChip(0));
      expect(sealed.editing, isNull);
      expect(sealed.active, isNull);
      expect(texts(sealed)[0], 'Arcsine2');
      expect(
        press(const Tape(), '[ASIN] 0 . 5 × 2 = tap:0 ⌫ ⌫ ⌫ 2').pressEquals(),
        isA<TapeChanged>(),
      );
      expect(
        press(const Tape(), '[ASIN] 2').pressOperator(Operator.multiply),
        const TapeRefused(TapeRefusal.trigCannotAnswer),
        reason: 'on fresh entry the chip still says why it cannot answer',
      );
    });

    test('⌫ on the emptied first chip of a chain is refused and the empty '
        'chip stays, since a tape never starts with an operator; a value '
        'typed into it fills it (N1; rule 4.8 "Deleting the first value of '
        'a chain")', () {
      const refused = TapeRefused(TapeRefusal.typeANewFirstValue);
      final emptied = press(const Tape(), '1 2 ft + 5 ft = tap:0 ✕');
      expect(texts(emptied), ['', '+5ft', 'Calc17ft 0in']);
      expect(emptied.backspace(), refused);
      expect(emptied.backspace(), refused, reason: 'and again');
      expect(texts(press(emptied, '1 2 ft')), ['12ft', '+5ft', 'Calc17ft 0in']);
      final named = press(lengthWidthArea(), 'tap:0 ✕');
      expect(named.backspace(), refused);
      expect(texts(press(named, '3 0 ft tap:0'))[0], 'Length30ft');
      final alone = press(const Tape(), '1 2 ft tap:0 tap:0 ✕ ⌫');
      expect(alone.isEmpty, isTrue, reason: 'nothing follows, so it goes');
    });

    test('= during an edit finishes the edit and lands the Calc when the '
        'tape has no result yet (N3; rule 4.8)', () {
      final tape = press(const Tape(), '1 8 ft × 4 ft tap:0');
      expect(
        tape.editing,
        isA<({int index, ValueChip chip})>().having((e) => e.index, 'index', 0),
      );
      final landed = changed(tape.pressEquals());
      expect(texts(landed), ['18ft', '×4ft', 'Calc72ft²']);
      expect(landed.active, isNull);
      final named = press(const Tape(), '[Length] 1 2 ft [Width] 5 ft tap:0');
      final sealed = changed(named.pressEquals());
      expect(texts(sealed), ['Length12ft', 'Width5ft']);
      expect(
        sealed.active,
        isNull,
        reason: 'nothing to compute, so = only seals',
      );
    });

    test('a unit key on an emptied edit says type a number first, not units '
        'apply while typing (N4; Section 5.1; decision tree row 162)', () {
      final emptied = press(const Tape(), '1 2 ft + 5 ft = tap:0 ✕');
      expect(
        unit(emptied, Unit.foot),
        const TapeRefused(TapeRefusal.typeANumberFirst),
      );
    });

    test('digits typed into a reopened compound append to it, and the '
        'result after it stands as it was until the value reads (S65)', () {
      final tape = press(changed(lengthWidthArea().tapChip(1)), '7 8');

      expect(texts(tape), ['Length22ft', 'Width18ft 8in 78', 'Area410.67ft²']);
      expect(tape.editing!.index, 1);
    });

    test('a unit that cannot continue the compound is refused in place, '
        'never split into a new chip (S65: "Can\'t append yards here")', () {
      final tape = press(changed(lengthWidthArea().tapChip(1)), '7 8');

      expect(
        pressOnce(tape, 'yd'),
        const TapeEntryRefused(EntryRefusal.cannotAppendUnit),
      );
      expect(texts(tape), hasLength(3));
    });

    test('tapping the reopened chip again finishes the edit: nothing '
        'changed, nothing recomputed (S66)', () {
      final tape = press(lengthWidthArea(), 'tap:1 tap:1');

      expect(texts(tape), ['Length22ft', 'Width18ft 8in', 'Area410.67ft²']);
      expect(tape.editing, isNull);
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
      expect(texts(closed)[1], 'Width5ft');
      expect(closed.active, isNull);
    });

    test(
      'no exit key abandons a broken edit: a function key, an operator '
      'and a tap on another chip are refused and nothing is removed (S67)',
      () {
        final tape = press(lengthWidthArea(), 'tap:1 5');

        for (final key in ['[Height]', '+', 'tap:0', '=', '(', '[SIN]']) {
          expect(
            pressOnce(tape, key),
            const TapeRefused(TapeRefusal.finishThisValueFirst),
            reason: key,
          );
        }
        expect(texts(tape), ['Length22ft', 'Width18ft 8in 5', 'Area410.67ft²']);
        expect(tape.editing!.index, 1);
      },
    );

    test('once the value reads the same key exits: the chip seals, the '
        'result stands and the new chip opens at the end (S67)', () {
      final tape = press(lengthWidthArea(), 'tap:1 5 ⌫ [Height]');

      expect(texts(tape), [
        'Length22ft',
        'Width18ft 8in',
        'Area410.67ft²',
        'Height',
      ]);
      expect(tape.editing, isNull);
      expect(tape.active!.key, 'Height');
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
      expect(texts(tape)[1], 'Width20ft');
      expect(tape.active!.key, 'Height');
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
      expect(texts(closed)[1], 'Width5ft');
      expect(closed.active, isNull);
    });

    test('= seals an edit with no second result, and is refused on a broken '
        'one like every other exit (S82)', () {
      final tape = press(const Tape(), '1 8 ft × 4 ft = tap:0');
      expect(tape.editing!.index, 0);

      final sealed = tape.pressEquals();
      expect(sealed, isA<TapeChanged>());
      expect((sealed as TapeChanged).notice, isNull);
      expect(sealed.tape.active, isNull);
      expect(texts(sealed.tape), ['18ft', '×4ft', 'Calc72ft²']);

      expect(
        press(tape, '⌫ ⌫ ⌫').pressEquals(),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
    });

    test('⌫ on an emptied edit deletes the chip', () {
      final tape = press(lengthWidthArea(), 'tap:1 ✕ ⌫');

      expect(texts(tape)[0], 'Length22ft');
      expect(tape.chips.whereType<ValueChip>(), hasLength(1));
      expect(tape.active, isNull);
      expect(tape.editing, isNull);
    });

    test('⌫ while a chip before a closed bracket is edited steps through the '
        'chip, and does not reopen the bracket', () {
      final tape = press(const Tape(), '2 + ( 3 × 4 ( tap:0 ⌫');

      expect(texts(tape), ['', '+(3×4)']);
      expect(tape.editing!.index, 0);
      expect(tape.openBracket, isNull);
    });

    test('tapping another chip while the edited one reads seals it and '
        'reopens the other', () {
      final tape = press(lengthWidthArea(), 'tap:1 ✕ 2 0 ft tap:0');

      expect(texts(tape).sublist(0, 2), ['Length22ft', 'Width20ft']);
      expect(tape.editing!.index, 0);
      expect((tape.chips[1] as ValueChip).isActive, isFalse);
    });

    test('an operator after a readable edit seals it and chains off the end '
        'of the tape', () {
      final tape = press(lengthWidthArea(), 'tap:1 +');

      expect(texts(tape), [
        'Length22ft',
        'Width18ft 8in',
        'Area410.67ft²',
        '+',
      ]);
      expect(tape.editing, isNull);
      expect(tape.active!.operator, Operator.add);
    });

    test('digits and a unit typed into a chip edited before a closed bracket '
        'go into the chip; the bracket at the end refuses them only with no '
        'edit open', () {
      final closed = press(const Tape(), '2 + ( 3 × 4 (');
      expect(
        closed.typeDigit('5'),
        const TapeRefused(TapeRefusal.addAnOperatorFirst),
      );
      expect(
        unit(closed, Unit.foot),
        const TapeRefused(TapeRefusal.groupCannotTakeUnit),
      );

      final edited = press(closed, 'tap:0 5 ft');

      expect(texts(edited), ['25ft', '+(3×4)']);
      expect(edited.editing!.index, 0);
    });

    test('a recalled angle reopened by a tap takes no digit, since it has no '
        'end to start a new chip at; ✕ retypes it', () {
      const angle = RememberedAngle(
        entry: EntryBuffer([Token(digits: '38')]),
        value: Angle(38),
      );
      final recalled = changed(press(const Tape(), '[Pitch]').recall(angle));
      final tape = press(recalled, '[Length] 2 ft tap:0');

      expect(
        tape.typeDigit('5'),
        const TapeEntryRefused(EntryRefusal.alreadyAnAngle),
      );
      expect(texts(press(tape, '✕ 3 0')), ['Pitch30', 'Length2ft']);
    });

    test('a chip that carries an operator keeps it through ✕, a retype and '
        'the seal', () {
      final tape = press(const Tape(), '1 8 ft × 4 ft = tap:1 ✕ 5 ft tap:1');

      expect(texts(tape).sublist(0, 2), ['18ft', '×5ft']);
      expect((tape.chips[1] as ValueChip).operator, Operator.multiply);
      expect(tape.editing, isNull);
    });

    test('the strip\'s answer is kept out of an emptied edit, as every exit '
        'is, instead of dropping the chip', () {
      final area = lengthWidthArea();
      final areaValue = (area.chips[2] as ResultChip).value;
      final emptied = press(area, 'tap:1 ✕');

      expect(
        emptied.landAnswer('Area', areaValue),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
      expect(texts(emptied)[1], 'Width');
    });

    test('a tap on an empty tape is refused like a place off the tape', () {
      expect(
        const Tape().tapChip(0),
        const TapeRefused(TapeRefusal.chipCannotBeEdited),
      );
    });

    test('a tap on the chip being typed at the end seals it', () {
      final tape = press(const Tape(), '[Length] 2 2 ft tap:0');

      expect(tape.active, isNull);
      expect(texts(tape), ['Length22ft']);
    });

    test('a result, an error chip, a closed bracket and a place off the tape '
        'are not edited by a tap', () {
      final tape = press(const Tape(), '2 + ( 3 ( × 4 =');
      expect(texts(tape), ['2', '+(3)', '×4', 'Calc20']);

      for (final index in [1, 3, 4, -1]) {
        expect(
          tape.tapChip(index),
          const TapeRefused(TapeRefusal.chipCannotBeEdited),
          reason: 'index $index',
        );
      }
      final error = press(const Tape(), '7 8 lbs ÷ 1 2 ft =');
      expect(
        error.tapChip(2),
        const TapeRefused(TapeRefusal.chipCannotBeEdited),
      );
    });

    test('a tap while an operator still waits for its number is refused, '
        'since the operator chip is an empty value (Section 5)', () {
      final tape = press(const Tape(), '1 8 ft +');

      expect(
        tape.tapChip(0),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
      expect(texts(tape), ['18ft', '+']);
    });

    test('the Read-as pill is not offered while an edit is open', () {
      final alone = press(const Tape(), '[Pitch] 6');
      expect(alone.readAsOffer, isNotNull);

      final editing = press(alone, '[Length] 2 ft tap:0');
      expect(editing.editing!.index, 0);
      expect(editing.readAsOffer, isNull);
    });

    test('while a bracket is open every other chip waits, so a tap is '
        'refused until it closes', () {
      final tape = press(const Tape(), '2 + ( 3');

      expect(
        tape.tapChip(0),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
    });
  });
}
