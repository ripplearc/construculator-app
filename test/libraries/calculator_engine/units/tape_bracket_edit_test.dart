import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();

  Tape changed(TapeOutcome outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  TapeOutcome pressOnce(Tape tape, String key) => switch (key) {
    'ft' => tape.pressUnit(Unit.foot),
    'lbs' => tape.pressUnit(Unit.pound),
    '+' => tape.pressOperator(Operator.add),
    '×' => tape.pressOperator(Operator.multiply),
    '=' => tape.pressEquals(),
    '⌫' => tape.backspace(),
    '✕' => tape.clearActive(),
    '(' => tape.pressBracket(),
    _ when key.startsWith('tap:') => tape.tapChip(int.parse(key.substring(4))),
    _ when key.startsWith('[') => tape.pressFunctionKey(
      key.substring(1, key.length - 1),
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

  group('Tape — a closed bracket reopened by a tap (Section 7, "Editing a '
      'bracket"; walkthrough 12.8)', () {
    test('a tap on a closed bracket reopens it in place: one chip, the '
        'keypad typing inside it, and the chips before it waiting (S125)', () {
      final closed = press(const Tape(), '2 + ( 3 × 4 (');
      expect(texts(closed), ['2', '+(3×4)']);

      final outcome = closed.tapChip(1);
      expect(
        outcome,
        isA<TapeChanged>().having(
          (change) => change.notice,
          'notice',
          TapeNotice.editingThisGroup,
        ),
      );
      final open = changed(outcome);
      expect(texts(open), ['2', '+(3×4']);
      expect(open.openBracketIndex, 1);
      expect(open.beingTyped!.entry.text, '4');

      final retyped = press(open, '⌫ 5');
      expect(texts(retyped), ['2', '+(3×5']);

      final reclosed = press(retyped, '(');
      expect(texts(reclosed), ['2', '+(3×5)']);
      expect(reclosed.openBracket, isNull);
      expect(texts(press(reclosed, '=')), ['2', '+(3×5)', 'Calc17']);
    });

    test('a bracket reopened in the middle of a calculation keeps the chips '
        'after it, and closing it recomputes every answer after it (S126)', () {
      final tape = press(const Tape(), '2 + ( 3 × 4 ( × 5 =');
      expect(texts(tape), ['2', '+(3×4)', '×5', 'Calc70']);

      final open = press(tape, 'tap:1');
      expect(texts(open), ['2', '+(3×4', '×5', 'Calc70']);
      expect(open.openBracketIndex, 1);

      final typed = press(open, '⌫ 1');
      expect(texts(typed), [
        '2',
        '+(3×1',
        '×5',
        'Calc70',
      ], reason: 'the answer waits as it was until the group closes');

      final closed = press(typed, '(');
      expect(texts(closed), ['2', '+(3×1)', '×5', 'Calc25']);
      expect(closed.openBracket, isNull);
    });

    test('= on a bracket reopened in the middle closes it and recomputes, '
        'and lands no second answer', () {
      final tape = press(const Tape(), '2 + ( 3 × 4 ( × 5 = tap:1 ⌫ 1');

      final closed = tape.pressEquals();
      expect(closed, isA<TapeChanged>());
      expect(texts((closed as TapeChanged).tape), [
        '2',
        '+(3×1)',
        '×5',
        'Calc25',
      ]);
      expect(closed.notice, isNull);
    });

    test('closing a reopened bracket with nothing changed puts the tape back '
        'as it was', () {
      final tape = press(const Tape(), '2 + ( 3 × 4 ( × 5 =');
      final back = press(tape, 'tap:1 (');

      expect(back, tape);
    });

    test('emptying a reopened bracket and closing it cancels the edit: the '
        'original group and its answer are back (S135)', () {
      final tape = press(const Tape(), '2 + ( 3 × 4 ( =');
      final emptied = press(tape, 'tap:1 ⌫ ⌫ ⌫');
      expect(texts(emptied), ['2', '+(', 'Calc14']);
      expect(emptied.openBracketIndex, 1);

      final outcome = emptied.pressBracket();
      expect(
        outcome,
        isA<TapeChanged>().having(
          (change) => change.notice,
          'notice',
          TapeNotice.bracketEditCancelled,
        ),
      );
      expect(changed(outcome), tape);
    });

    test('⌫ on an emptied reopened bracket removes it, the operator before '
        'it waits again, and the answer that has nothing left to compute goes '
        '(Section 7; S127 as the design decides it)', () {
      final emptied = press(const Tape(), '2 + ( 3 × 4 ( = tap:1 ⌫ ⌫ ⌫');

      final tape = press(emptied, '⌫');
      expect(texts(tape), ['2', '+']);
      expect(tape.active!.operator, Operator.add);
      expect(tape.openBracket, isNull);
      expect(texts(press(tape, '5 =')), ['2', '+5', 'Calc7']);
    });

    test('a bracket that led the chain, emptied and removed, leaves the chips '
        'after it and takes the answer that was a calculation no more', () {
      final tape = press(const Tape(), '( 3 × 4 ( × 5 =');
      expect(texts(tape), ['(3×4)', '×5', 'Calc60']);

      final outcome = press(tape, 'tap:0 ⌫ ⌫ ⌫').backspace();
      expect(outcome, isA<TapeChanged>());
      final TapeChanged(tape: removed, :notice, removed: key) =
          outcome as TapeChanged;
      expect(texts(removed), ['×5']);
      expect(notice, TapeNotice.resultRemoved);
      expect(key, 'Calc');
    });

    test('⌫ straight after ) reopens the bracket with the same notice as a '
        'tap (Section 5.6)', () {
      final closed = press(const Tape(), '2 + ( 3 × 4 (');

      expect(
        closed.backspace(),
        isA<TapeChanged>().having(
          (change) => change.notice,
          'notice',
          TapeNotice.editingThisGroup,
        ),
      );
    });

    test('a tap on a bracket while a chip reads seals the chip first; while '
        'the chip is broken the tap is refused', () {
      final tape = press(const Tape(), '5 + ( 3 ( × 2 =');
      expect(texts(tape), ['5', '+(3)', '×2', 'Calc16']);

      final reopened = press(tape, 'tap:0 ⌫ 6 tap:1');
      expect(texts(reopened), ['6', '+(3', '×2', 'Calc18']);
      expect(reopened.editing, isNull);
      expect(reopened.openBracketIndex, 1);

      final broken = press(tape, 'tap:0 ✕');
      expect(
        broken.tapChip(1),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
    });

    test('while a bracket is reopened the keys type inside it and a function '
        'key is refused, as in any open bracket', () {
      final open = press(const Tape(), '2 + ( 3 × 4 ( × 5 = tap:1');

      expect(texts(press(open, '⌫ 9')), ['2', '+(3×9', '×5', 'Calc70']);
      expect(
        open.pressFunctionKey('Length'),
        const TapeRefused(TapeRefusal.bracketsHoldPlainArithmetic),
      );
      expect(
        open.tapChip(2),
        const TapeRefused(TapeRefusal.chipCannotBeEdited),
        reason: 'every other chip waits while a bracket is open',
      );
    });

    test('a tap on the reopened bracket itself closes it, as the key does', () {
      final tape = press(const Tape(), '2 + ( 3 × 4 ( × 5 =');

      final back = press(tape, 'tap:1 tap:1');

      expect(back, tape);
      expect(texts(press(tape, 'tap:1 ⌫ 1 tap:1')), [
        '2',
        '+(3×1)',
        '×5',
        'Calc25',
      ]);
    });

    test('= on a bracket reopened in the middle of a chain with no answer '
        'yet closes it and lands the chain, as = does at the end', () {
      final tape = press(const Tape(), '2 + ( 3 × 4 ( × 5 tap:1 ⌫ 1');
      expect(texts(tape), ['2', '+(3×1', '×5']);

      final landed = tape.pressEquals();
      expect(landed, isA<TapeChanged>());
      expect(texts((landed as TapeChanged).tape), [
        '2',
        '+(3×1)',
        '×5',
        'Calc25',
      ]);
      expect(landed.notice, isNull);
    });

    test('⌫ that takes a result off and reaches the closed bracket before it '
        'reopens the bracket with the same notice as a tap', () {
      final tape = press(const Tape(), '2 + ( 3 ( =');
      expect(texts(tape), ['2', '+(3)', 'Calc5']);

      final outcome = tape.backspace();
      expect(outcome, isA<TapeChanged>());
      final TapeChanged(tape: reopened, :notice) = outcome as TapeChanged;
      expect(texts(reopened), ['2', '+(3']);
      expect(reopened.openBracketIndex, 1);
      expect(notice, TapeNotice.editingThisGroup);
    });

    test('a tap while an operator still waits for its number after the '
        'bracket is refused for the empty chip, as any tap is', () {
      final tape = press(const Tape(), '2 + ( 3 ( ×');

      expect(
        tape.tapChip(1),
        const TapeRefused(TapeRefusal.finishThisValueFirst),
      );
    });

    test('with two brackets side by side a tap reopens the one tapped, and '
        'the other waits closed', () {
      final tape = press(const Tape(), '( 2 ( + ( 3 ( =');
      expect(texts(tape), ['(2)', '+(3)', 'Calc5']);

      final first = press(tape, 'tap:0');
      expect(texts(first), ['(2', '+(3)', 'Calc5']);
      expect(first.openBracketIndex, 0);
      expect(
        first.tapChip(1),
        const TapeRefused(TapeRefusal.chipCannotBeEdited),
      );
      expect(texts(press(first, '⌫ 7 (')), ['(7)', '+(3)', 'Calc10']);
    });

    test('an error chip after a reopened bracket is rebuilt when the bracket '
        'closes: the chain repaired lands its Calc in its place', () {
      final tape = press(const Tape(), '( 5 ft ( + 3 lbs =');
      expect(texts(tape), ['(5ft)', '+3lbs', 'dimensionError']);

      final repaired = press(tape, 'tap:0 ⌫ lbs (');
      expect(texts(repaired), ['(5lbs)', '+3lbs', 'Calc8lbs']);
    });
  });
}
