import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const arbiter = Arbiter();
  const formatter = QuantityFormatter();

  PieceSize sheet(int width, int height, {String? id}) => PieceSize(
    width: Length(width * Length.ticksPerInch, unit: Unit.inch),
    height: Length(height * Length.ticksPerInch, unit: Unit.inch),
    id: id,
  );

  /// Appendix B's sheet sizes: 48in x 96in, 108in and 120in.
  final stores = TradeStores(
    sheetSizes: [sheet(48, 96), sheet(48, 108), sheet(48, 120)],
    masonrySizes: [sheet(8, 16), sheet(4, 8)],
  );

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

  /// [tape] with [offer] accepted, as a tap on its chip lands it: a count
  /// under its trade's result key.
  Tape accepted(Tape tape, StripOffer offer) {
    final key = switch (offer.count) {
      final count? => count.trade.resultKey,
      null => offer.key,
    };
    return switch (tape.landAnswer(key, offer.value)) {
      TapeChanged(:final tape) => tape,
      _ => tape,
    };
  }

  List<String> row(Arbitration arbitration) => [
    for (final offer in arbitration.offers)
      switch (offer.count) {
        final count? =>
          '${offer.key}: ${formatter.format(offer.value)} '
              '(${formatter.formatPieceSize(count.size)})',
        null => '${offer.key}: ${formatter.format(offer.value)}',
      },
  ];

  Tape areaAccepted() {
    final sides = pressed('[Length] 2 0 ft [Height] 9 ft');
    return accepted(sides, arbiter.arbitrate(sides, stores).offers.first);
  }

  group('Arbiter', () {
    group('rung 1, the error state (rule 4.4, "is the last chip an error? '
        'then show nothing")', () {
      test('after 78lbs ÷ 12ft = the strip is silent, and before the = too, '
          'since the step cannot be computed (S18)', () {
        for (final keys in ['7 8 lbs ÷ 1 2 ft', '7 8 lbs ÷ 1 2 ft =']) {
          final arbitration = arbiter.arbitrate(pressed(keys), stores);

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
        final open = arbiter.arbitrate(pressed('2 + ( 3 × 4'), stores);
        expect(open.rung, LadderRung.error);
        expect(open.silence, StripSilence.openBracket);

        expect(open.offers, isEmpty);

        final closed = arbiter.arbitrate(pressed('2 + ( 3 × 4 ('), stores);
        expect(closed.silence, isNull);
        expect(row(closed), ['Calc: 14']);
      });

      test('the divisor ÷ 0 reopened still leads on from its error chip, so '
          'the strip stays silent until a new divisor lands a result', () {
        expect(
          arbiter.arbitrate(pressed('5 ÷ 0 ='), stores).silence,
          StripSilence.chainFailed,
        );

        final retyped = pressed('5 ÷ 0 = 2 =');
        expect(retyped.endsWithResult, isTrue);
        expect(arbiter.arbitrate(retyped, stores).silence, isNull);
      });

      test('a value that starts a chain of its own after an error chip is '
          'not silenced by it: the error ended only its own chain', () {
        final typedAfter = pressed('7 8 lbs ÷ 1 2 ft = 5');
        expect(typedAfter.chips, hasLength(4));

        final arbitration = arbiter.arbitrate(typedAfter, stores);
        expect(arbitration.silence, isNull);
        expect(arbitration.rung, LadderRung.none);
      });

      test('an empty tape and a single named value are no error and match '
          'no rule: no rung answers, and the trace says each was asked', () {
        for (final tape in [const Tape(), pressed('[Length] 2 2 ft')]) {
          final arbitration = arbiter.arbitrate(tape, stores);

          expect(arbitration.silence, isNull);
          expect(arbitration.rung, LadderRung.none);
          expect(arbitration.offers, isEmpty);
          expect(arbitration.trace, const [
            LadderStep(LadderRung.error, applies: false),
            LadderStep(LadderRung.tradeFollowOn, applies: false),
            LadderStep(LadderRung.rules, applies: false),
          ]);
        }
      });

      test(
        'two silences are told apart, in the answer and in its equality',
        () {
          final open = arbiter.arbitrate(pressed('2 + ( 3'), stores);
          final failed = arbiter.arbitrate(
            pressed('7 8 lbs ÷ 1 2 ft ='),
            stores,
          );

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
          stores,
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
        expect(arbitration.countedArea, isNull);
        expect(arbitration.trace, const [
          LadderStep(LadderRung.error, applies: false),
          LadderStep(LadderRung.tradeFollowOn, applies: false),
          LadderStep(LadderRung.rules, applies: true),
        ]);
      });

      test('while an operator has values on both sides the running total '
          'takes the row in place of the rule answers (term 2.15; '
          'walkthrough 12.3)', () {
        final arbitration = arbiter.arbitrate(
          pressed('[Rise] 3 ft [Run] 4 ft × 2'),
          stores,
        );

        expect(arbitration.rung, LadderRung.rules);
        expect(row(arbitration), ['Calc: 8ft 0in']);
        expect(arbitration.offers.single.kind, StripOfferKind.runningTotal);
      });

      test('a value with no operator applied is no calculation, so a lone '
          '12ft offers no Calc', () {
        final arbitration = arbiter.arbitrate(pressed('1 2 ft'), stores);

        expect(arbitration.offers, isEmpty);
        expect(arbitration.rung, LadderRung.none);
      });

      test('a trig chip standing alone leads with its answer, and one that '
          'builds its ratio across ÷ leads before the Calc of the same '
          'digits (S111)', () {
        final sine = arbiter.arbitrate(pressed('[SIN] 3 0'), stores);
        expect(row(sine), ['Sine: 0.5']);
        expect(sine.rung, LadderRung.rules);

        expect(row(arbiter.arbitrate(pressed('[ATAN] 1 6 ÷ 1 2'), stores)), [
          'Arctangent(16 ÷ 12): 53.13°',
          'Calc: 1.33',
        ]);
      });

      test('a trig chip that continues a chain follows the Calc, since = '
          'lands the running total (rule 4.6)', () {
        final arbitration = arbiter.arbitrate(pressed('5 + [SIN] 3 0'), stores);

        expect(row(arbitration), ['Calc: 5.5', 'Sine: 0.5']);
        expect(
          [for (final offer in arbitration.offers) offer.kind],
          [StripOfferKind.runningTotal, StripOfferKind.answer],
        );
      });

      test('an answer already landed leaves the row and the others stay: '
          'after Diagonal is accepted, Area and Perimeter (Section 8)', () {
        final sides = pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in');
        final landed = accepted(
          sides,
          arbiter.arbitrate(sides, stores).offers[1],
        );

        expect(row(arbiter.arbitrate(landed, stores)), [
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

        expect(row(arbiter.arbitrate(chained, stores)), ['Calc: 8ft 0in']);
        expect(arbiter.ruleAnswersFor(chained), isNotEmpty);
      });
    });

    group('rung 2, the trade follow-ons (rule 4.4, "After Area is accepted '
        'the strip shows sheet counts")', () {
      test('an accepted Area leads with a drywall count per stored sheet '
          'size, in the store\'s order, the rule answers behind them '
          '(walkthrough 11.1; S02)', () {
        final arbitration = arbiter.arbitrate(areaAccepted(), stores);

        expect(arbitration.rung, LadderRung.tradeFollowOn);
        expect(row(arbitration), [
          'Drywall: 5.63 (48in x 96in)',
          'Drywall: 5.00 (48in x 108in)',
          'Drywall: 4.50 (48in x 120in)',
          'Diagonal: 21.93ft',
          'Perimeter: 58ft',
        ]);
        expect([
          for (final offer in arbitration.offers.take(3)) offer.kind,
        ], everyElement(StripOfferKind.materialCount));
        expect(formatter.format(arbitration.countedArea!), '180ft²');
        expect(arbitration.counts, hasLength(3));
        expect(arbitration.trace, const [
          LadderStep(LadderRung.error, applies: false),
          LadderStep(LadderRung.tradeFollowOn, applies: true),
        ]);
      });

      test('a typed area is as good as a computed one: 180 ft ft earns the '
          'three counts (Section 9; rule 4.4, rung 5)', () {
        final arbitration = arbiter.arbitrate(pressed('1 8 0 ft ft'), stores);

        expect(arbitration.rung, LadderRung.tradeFollowOn);
        expect(row(arbitration), [
          'Drywall: 5.63 (48in x 96in)',
          'Drywall: 5.00 (48in x 108in)',
          'Drywall: 4.50 (48in x 120in)',
        ]);
      });

      test('once a count is accepted the row holds the other sizes and no '
          'rule answer, and nothing once every size is accepted (rule 4.4; '
          'walkthrough 15.2, step 4)', () {
        var tape = areaAccepted();
        tape = accepted(tape, arbiter.arbitrate(tape, stores).offers.first);
        final afterOne = arbiter.arbitrate(tape, stores);

        expect(afterOne.rung, LadderRung.tradeFollowOn);
        expect(row(afterOne), [
          'Drywall: 5.00 (48in x 108in)',
          'Drywall: 4.50 (48in x 120in)',
        ]);
        expect(afterOne.counts, hasLength(3), reason: 'the table lists all');
        expect(formatter.format(afterOne.countedArea!), '180ft²');

        tape = accepted(tape, afterOne.offers.first);
        tape = accepted(tape, arbiter.arbitrate(tape, stores).offers.first);
        final afterAll = arbiter.arbitrate(tape, stores);

        expect(afterAll.rung, LadderRung.tradeFollowOn);
        expect(afterAll.offers, isEmpty);
      });

      test('an accepted count hides one offer of its value and no more: '
          'with 48in x 96in and 96in x 48in stored, the other stays', () {
        final twins = TradeStores(
          sheetSizes: [
            sheet(48, 96, id: 'a'),
            sheet(96, 48, id: 'b'),
          ],
        );
        var tape = pressed('1 8 0 ft ft');
        tape = accepted(tape, arbiter.arbitrate(tape, twins).offers.first);

        expect(row(arbiter.arbitrate(tape, twins)), [
          'Drywall: 5.63 (96in x 48in)',
        ]);
      });

      test('a silent strip still names the area on the display and its '
          'counts, which the table under the strip lists: an area typed in '
          'an open bracket, and one in a chain that cannot be computed', () {
        for (final (keys, silence) in [
          ('( 1 8 0 ft ft', StripSilence.openBracket),
          ('5 lbs + 1 8 0 ft ft', StripSilence.chainFailed),
        ]) {
          final arbitration = arbiter.arbitrate(pressed(keys), stores);

          expect(arbitration.silence, silence, reason: keys);
          expect(arbitration.offers, isEmpty, reason: keys);
          expect(arbitration.countedArea, isNotNull, reason: keys);
          expect(
            [
              for (final count in arbitration.counts)
                formatter.format(count.value),
            ],
            ['5.63', '5.00', '4.50'],
            reason: keys,
          );
        }
      });

      test('a Calc that is an area earns no count, and neither does a '
          'length, a key with nothing typed under it or a value after the '
          'counts', () {
        for (final keys in [
          '1 2 ft × 5 ft =',
          '[Length] 2 2 ft',
          '1 8 0 ft ft [Length]',
        ]) {
          final arbitration = arbiter.arbitrate(pressed(keys), stores);

          expect(arbitration.countedArea, isNull, reason: keys);
          expect(arbitration.counts, isEmpty, reason: keys);
          expect(
            arbitration.rung,
            isNot(LadderRung.tradeFollowOn),
            reason: keys,
          );
        }

        var tape = pressed('1 8 0 ft ft');
        tape = accepted(tape, arbiter.arbitrate(tape, stores).offers.first);
        final moved = arbiter.arbitrate(pressed('3 ft', tape: tape), stores);
        expect(moved.countedArea, isNull);
        expect(moved.offers, isEmpty);
      });

      test('the running total takes the row from the counts while an '
          'operator has values on both sides: 2 × 180ft² offers Calc alone, '
          'though the area being typed is the one the table counts', () {
        final arbitration = arbiter.arbitrate(
          pressed('2 × 1 8 0 ft ft'),
          stores,
        );

        expect(arbitration.rung, LadderRung.rules);
        expect(row(arbitration), ['Calc: 360ft²']);
        expect(formatter.format(arbitration.countedArea!), '180ft²');
        expect(arbitration.counts, hasLength(3));
      });

      test('a tape that holds a count and nothing before it has no area to '
          'count: the rung is the trade\'s and the row is empty', () {
        final lone = Tape(
          chips: [
            ResultChip(
              key: Trade.drywall.resultKey,
              value: const Scalar(5.63, decimals: 2),
            ),
          ],
        );

        final arbitration = arbiter.arbitrate(lone, stores);

        expect(arbitration.rung, LadderRung.tradeFollowOn);
        expect(arbitration.countedArea, isNull);
        expect(arbitration.offers, isEmpty);
      });

      test('an empty store has no count to offer, so the rule answers lead '
          'and the area is still the one the table would count', () {
        final arbitration = arbiter.arbitrate(
          areaAccepted(),
          const TradeStores(),
        );

        expect(arbitration.rung, LadderRung.rules);
        expect(row(arbitration), ['Diagonal: 21.93ft', 'Perimeter: 58ft']);
        expect(formatter.format(arbitration.countedArea!), '180ft²');
        expect(arbitration.counts, isEmpty);
      });
    });

    test('the arbiter is a pure function: the same tape is the same '
        'arbitration, every time, and another tape is another (requirement '
        'R5)', () {
      final tape = pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in');

      expect(arbiter.arbitrate(tape, stores), arbiter.arbitrate(tape, stores));
      expect(
        arbiter.arbitrate(tape, stores),
        isNot(
          arbiter.arbitrate(pressed('[Length] 2 2 ft [Width] 1 8 ft'), stores),
        ),
      );
      expect(
        arbiter.arbitrate(areaAccepted(), stores),
        isNot(arbiter.arbitrate(areaAccepted(), const TradeStores())),
        reason: 'other stores are another arbitration',
      );
      expect(const Arbiter(), const Arbiter());
    });

    test('the stores name the sizes a trade counts by', () {
      expect(stores.sizesFor(Trade.drywall), stores.sheetSizes);
      expect(stores.sizesFor(Trade.masonry), stores.masonrySizes);
      expect(stores, isNot(const TradeStores()));
    });
  });
}
