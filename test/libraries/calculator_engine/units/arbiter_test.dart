import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const arbiter = Arbiter();

  /// The tape after [keys], each pressed on the engine as the keyboard
  /// presses it; a refused key leaves the tape as it was.
  Tape pressed(String keys, {Tape tape = const Tape()}) {
    var current = tape;
    for (final key in keys.split(' ')) {
      final outcome = switch (key) {
        'ft' => current.pressUnit(Unit.foot),
        'in' => current.pressUnit(Unit.inch),
        'lbs' => current.pressUnit(Unit.pound),
        '×' => current.pressOperator(Operator.multiply),
        '÷' => current.pressOperator(Operator.divide),
        '+' => current.pressOperator(Operator.add),
        '=' => current.pressEquals(),
        '(' => current.pressBracket(),
        '[SIN]' => current.pressTrigKey(TrigFunction.sine),
        '[ATAN]' => current.pressTrigKey(TrigFunction.arctangent),
        _ when key.startsWith('[') => current.pressFunctionKey(
          key.substring(1, key.length - 1),
        ),
        _ => current.typeDigit(key),
      };
      if (outcome case TapeChanged(:final tape)) current = tape;
    }
    return current;
  }

  group('Arbiter', () {
    group('rung 1, the error state (rule 4.4, "is the last chip an error? '
        'then show nothing")', () {
      test('after 78lbs ÷ 12ft = the strip is silent, and before the = too, '
          'since the step cannot be computed (S18)', () {
        for (final keys in ['7 8 lbs ÷ 1 2 ft', '7 8 lbs ÷ 1 2 ft =']) {
          final arbitration = arbiter.arbitrate(pressed(keys));

          expect(arbitration.rung, LadderRung.error, reason: keys);
          expect(arbitration.silence, StripSilence.chainFailed, reason: keys);
          expect(arbitration.trace, const [
            LadderStep(LadderRung.error, applies: true),
          ], reason: keys);
        }
      });

      test('while a bracket is open the strip is silent with its own '
          'reason, and it is not once the bracket closes (Section 7)', () {
        final open = arbiter.arbitrate(pressed('2 + ( 3 × 4'));
        expect(open.rung, LadderRung.error);
        expect(open.silence, StripSilence.openBracket);

        final closed = arbiter.arbitrate(pressed('2 + ( 3 × 4 ('));
        expect(closed.silence, isNull);
        expect(closed.rung, isNot(LadderRung.error));
      });

      test('the divisor ÷ 0 reopened still leads on from its error chip, so '
          'the strip stays silent until a new divisor lands a result', () {
        expect(
          arbiter.arbitrate(pressed('5 ÷ 0 =')).silence,
          StripSilence.chainFailed,
        );

        final retyped = pressed('5 ÷ 0 = 2 =');
        expect(retyped.endsWithResult, isTrue);
        expect(arbiter.arbitrate(retyped).silence, isNull);
      });

      test('a value that starts a chain of its own after an error chip is '
          'not silenced by it: the error ended only its own chain', () {
        final typedAfter = pressed('7 8 lbs ÷ 1 2 ft = 5');
        expect(typedAfter.chips, hasLength(4));

        final arbitration = arbiter.arbitrate(typedAfter);
        expect(arbitration.silence, isNull);
        expect(arbitration.rung, isNot(LadderRung.error));
      });

      test('an empty tape and a finished value are no error, and the trace '
          'says the error rung was asked and did not answer', () {
        for (final tape in [const Tape(), pressed('[Length] 2 2 ft')]) {
          final arbitration = arbiter.arbitrate(tape);

          expect(arbitration.silence, isNull);
          expect(arbitration.rung, isNot(LadderRung.error));
          expect(
            arbitration.trace.first,
            const LadderStep(LadderRung.error, applies: false),
          );
        }
      });

      test(
        'two silences are told apart, in the answer and in its equality',
        () {
          final open = arbiter.arbitrate(pressed('2 + ( 3'));
          final failed = arbiter.arbitrate(pressed('7 8 lbs ÷ 1 2 ft ='));

          expect(open.rung, failed.rung);
          expect(open, isNot(failed));
          expect(
            const LadderStep(LadderRung.error, applies: true),
            isNot(const LadderStep(LadderRung.error, applies: false)),
          );
        },
      );
    });

    test('the arbiter is a pure function: the same tape is the same '
        'arbitration, every time (requirement R5)', () {
      final tape = pressed('7 8 lbs ÷ 1 2 ft =');

      expect(arbiter.arbitrate(tape), arbiter.arbitrate(tape));
      expect(const Arbiter(), const Arbiter());
    });
  });
}
