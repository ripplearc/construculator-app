import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const arbiter = Arbiter();
  const formatter = QuantityFormatter();

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

  /// [tape] with [offer] accepted, as a tap on its chip lands it.
  Tape accepted(Tape tape, StripOffer offer) =>
      switch (tape.landAnswer(offer.key, offer.value)) {
        TapeChanged(:final tape) => tape,
        _ => tape,
      };

  List<String> row(Arbitration arbitration) => [
    for (final offer in arbitration.offers)
      '${offer.key}: ${formatter.format(offer.value)}',
  ];

  group('Arbiter', () {
    group('rung 1, the error state (rule 4.4, "is the last chip an error? '
        'then show nothing")', () {
      test('after 78lbs ÷ 12ft = the strip is silent, and before the = too, '
          'since the step cannot be computed (S18)', () {
        for (final keys in ['7 8 lbs ÷ 1 2 ft', '7 8 lbs ÷ 1 2 ft =']) {
          final arbitration = arbiter.arbitrate(pressed(keys));

          expect(arbitration.rung, LadderRung.error, reason: keys);
          expect(arbitration.silence, StripSilence.chainFailed, reason: keys);
          expect(arbitration.offers, isEmpty, reason: keys);
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

        expect(open.offers, isEmpty);

        final closed = arbiter.arbitrate(pressed('2 + ( 3 × 4 ('));
        expect(closed.silence, isNull);
        expect(row(closed), ['Calc: 14']);
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
        expect(arbitration.rung, LadderRung.none);
      });

      test('an empty tape and a single named value are no error and match '
          'no rule: no rung answers, and the trace says each was asked', () {
        for (final tape in [const Tape(), pressed('[Length] 2 2 ft')]) {
          final arbitration = arbiter.arbitrate(tape);

          expect(arbitration.silence, isNull);
          expect(arbitration.rung, LadderRung.none);
          expect(arbitration.offers, isEmpty);
          expect(arbitration.trace, const [
            LadderStep(LadderRung.error, applies: false),
            LadderStep(LadderRung.rules, applies: false),
          ]);
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

    group('rung 3, the rules (rule 4.4, "do the named values match a '
        'deterministic rule?")', () {
      test('Length 22ft and Width 18ft 8in earn Area, Diagonal and '
          'Perimeter, in the rule\'s order (S01)', () {
        final arbitration = arbiter.arbitrate(
          pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in'),
        );

        expect(arbitration.rung, LadderRung.rules);
        expect(row(arbitration), [
          'Area: 410.67ft²',
          'Diagonal: 28.85ft',
          'Perimeter: 81.33ft',
        ]);
        expect([
          for (final offer in arbitration.offers) offer.kind,
        ], everyElement(StripOfferKind.answer));
        expect(arbitration.trace, const [
          LadderStep(LadderRung.error, applies: false),
          LadderStep(LadderRung.rules, applies: true),
        ]);
      });

      test('while an operator has values on both sides the running total '
          'takes the row in place of the rule answers (term 2.15; '
          'walkthrough 12.3)', () {
        final arbitration = arbiter.arbitrate(
          pressed('[Rise] 3 ft [Run] 4 ft × 2'),
        );

        expect(arbitration.rung, LadderRung.rules);
        expect(row(arbitration), ['Calc: 8ft 0in']);
        expect(arbitration.offers.single.kind, StripOfferKind.runningTotal);
      });

      test('a value with no operator applied is no calculation, so a lone '
          '12ft offers no Calc', () {
        final arbitration = arbiter.arbitrate(pressed('1 2 ft'));

        expect(arbitration.offers, isEmpty);
        expect(arbitration.rung, LadderRung.none);
      });

      test('a trig chip standing alone leads with its answer, and one that '
          'builds its ratio across ÷ leads before the Calc of the same '
          'digits (S111)', () {
        final sine = arbiter.arbitrate(pressed('[SIN] 3 0'));
        expect(row(sine), ['Sine: 0.5']);
        expect(sine.rung, LadderRung.rules);

        expect(row(arbiter.arbitrate(pressed('[ATAN] 1 6 ÷ 1 2'))), [
          'Arctangent(16 ÷ 12): 53.13°',
          'Calc: 1.33',
        ]);
      });

      test('a trig chip that continues a chain follows the Calc, since = '
          'lands the running total (rule 4.6)', () {
        final arbitration = arbiter.arbitrate(pressed('5 + [SIN] 3 0'));

        expect(row(arbitration), ['Calc: 5.5', 'Sine: 0.5']);
        expect(
          [for (final offer in arbitration.offers) offer.kind],
          [StripOfferKind.runningTotal, StripOfferKind.answer],
        );
      });

      test('an answer already landed leaves the row and the others stay: '
          'after Diagonal is accepted, Area and Perimeter (Section 8)', () {
        final sides = pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in');
        final landed = accepted(sides, arbiter.arbitrate(sides).offers[1]);

        expect(row(arbiter.arbitrate(landed)), [
          'Area: 410.67ft²',
          'Perimeter: 81.33ft',
        ]);
        expect(
          [for (final offer in arbiter.ruleAnswersFor(landed)) offer.key],
          [DeterministicRules.areaKey, DeterministicRules.perimeterKey],
        );
      });

      test('the rule answers are read off the tape while Calc takes the '
          'row, which is what the detail panel\'s tiles show', () {
        final chained = pressed('[Rise] 3 ft [Run] 4 ft × 2');

        expect(row(arbiter.arbitrate(chained)), ['Calc: 8ft 0in']);
        expect(arbiter.ruleAnswersFor(chained), isNotEmpty);
      });
    });

    test('the arbiter is a pure function: the same tape is the same '
        'arbitration, every time, and another tape is another (requirement '
        'R5)', () {
      final tape = pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in');

      expect(arbiter.arbitrate(tape), arbiter.arbitrate(tape));
      expect(
        arbiter.arbitrate(tape),
        isNot(arbiter.arbitrate(pressed('[Length] 2 2 ft [Width] 1 8 ft'))),
      );
      expect(const Arbiter(), const Arbiter());
    });
  });
}
