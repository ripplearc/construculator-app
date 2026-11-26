import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();
  const arbiter = Arbiter();

  PieceSize inches(int width, int height) => PieceSize(
    width: Length(width * Length.ticksPerInch, unit: Unit.inch),
    height: Length(height * Length.ticksPerInch, unit: Unit.inch),
  );

  /// Appendix B's sheet sizes and masonry sizes.
  final stores = TradeStores(
    sheetSizes: [inches(48, 96), inches(48, 108), inches(48, 120)],
    masonrySizes: [inches(8, 16), inches(4, 8)],
  );

  Tape changed(TapeOutcome? outcome) {
    if (outcome case TapeChanged(:final tape)) return tape;
    throw StateError('expected the tape to change, got $outcome');
  }

  /// The tape after [keys], each pressed on the engine as the keyboard
  /// presses it.
  Tape pressed(String keys, {Tape tape = const Tape()}) {
    var current = tape;
    for (final key in keys.split(' ')) {
      current = changed(switch (key) {
        'ft' => current.pressUnit(
          Unit.foot,
          holdsLengthOnly: LengthOnlyKeys.all.contains(current.beingTyped?.key),
        ),
        'in' => current.pressUnit(
          Unit.inch,
          holdsLengthOnly: LengthOnlyKeys.all.contains(current.beingTyped?.key),
        ),
        '×' => current.pressOperator(Operator.multiply),
        '+' => current.pressOperator(Operator.add),
        '−' => current.pressOperator(Operator.subtract),
        '=' => current.pressEquals(),
        '(' => current.pressBracket(),
        '✕' => current.clearActive(),
        '[Drywal]' => current.pressTradeKey(Trade.drywall),
        '[Msnry]' => current.pressTradeKey(Trade.masonry),
        _ when key.startsWith('tap:') => current.tapChip(
          int.parse(key.substring(4)),
        ),
        _ when key.startsWith('accept:') => current.landAnswer(
          key.substring(7),
          const DeterministicRules()
              .answersFor(current.namedValues)
              .firstWhere((answer) => answer.key == key.substring(7))
              .value,
        ),
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
        ValueChip(:final key, :final operator, :final entry) =>
          '${operator?.symbol ?? ''}${key ?? ''}${entry.text}',
        ResultChip(:final key, :final value) =>
          '$key${formatter.format(value)}',
        ErrorChip(:final error) => error.name,
        BracketChip(:final expression) => expression,
      },
  ];

  List<String> row(Tape tape) => [
    for (final offer in arbiter.arbitrate(tape, stores).offers)
      switch (offer.count) {
        final count? =>
          '${offer.key}: ${formatter.format(offer.value)} '
              '(${formatter.formatPieceSize(count.size)})',
        null => '${offer.key}: ${formatter.format(offer.value)}',
      },
  ];

  /// [tape] with the rules' answer named [key] accepted, as a tap on its
  /// strip chip lands it.
  Tape accepted(Tape tape, String key) {
    final answer = const DeterministicRules()
        .answersFor(tape.namedValues)
        .firstWhere((answer) => answer.key == key);
    return changed(tape.landAnswer(key, answer.value));
  }

  /// [tape] with the first count on row 1 accepted, as a tap lands it.
  Tape counted(Tape tape) {
    final count = arbiter
        .arbitrate(tape, stores)
        .offers
        .firstWhere((offer) => offer.count != null)
        .count!;
    return changed(
      tape.landAnswer(count.trade.resultKey, count.value, size: count.size),
    );
  }

  const wall = '[Length] 2 0 ft [Height] 9 ft';

  group('Tape.pressTradeKey: the Drywal and Msnry keys name the area on the '
      'tape (Section 3.3; walkthroughs 19.1 and 19.2; Section 9)', () {
    test('Drywal on an accepted Area names it Drywall covered area in '
        'place, and the sheet counts stay with the rule answers behind them '
        '(walkthrough 19.1, step 9: "strip unchanged")', () {
      final area = pressed('$wall accept:Area');

      final named = pressed('[Drywal]', tape: area);

      expect(texts(named), [
        'Length20ft',
        'Height9ft',
        'Drywall covered area180ft²',
      ]);
      expect(named.countedAreaTrade, Trade.drywall);
      expect(row(named), row(area));
      expect(row(named).first, 'Drywall: 5.63 (48in x 96in)');
      expect(row(named), isNot(contains(startsWith('Area'))));
    });

    test('Msnry names it Masonry covered area, which is counted in pieces; '
        'the other key names it again', () {
      final masonry = pressed('$wall accept:Area [Msnry]');

      final drywall = pressed('[Drywal]', tape: masonry);

      expect(texts(masonry).last, 'Masonry covered area180ft²');
      expect(masonry.countedAreaTrade, Trade.masonry);
      expect(row(masonry).take(2), [
        'Masonry: 202.50 (8in x 16in)',
        'Masonry: 810.00 (4in x 8in)',
      ]);
      expect(texts(drywall).last, 'Drywall covered area180ft²');
      expect(drywall.countedAreaTrade, Trade.drywall);
    });

    test(
      'with no area landed yet Msnry lands the one Area the two sides '
      'make, no = needed: Length 22ft and Height 6ft 6in give Masonry '
      'covered area 143ft² and 160.88 pieces (walkthrough 19.2, step 10)',
      () {
        final named = pressed('[Length] 2 2 ft [Height] 6 ft 6 in [Msnry]');

        expect(texts(named), [
          'Length22ft',
          'Height6ft 6in',
          'Masonry covered area143ft²',
        ]);
        expect(row(named).take(2), [
          'Masonry: 160.88 (8in x 16in)',
          'Masonry: 643.50 (4in x 8in)',
        ]);
      },
    );

    test('a typed area lands as the covered area after it (Section 9: "A '
        'typed area is as good as a computed one")', () {
      final named = pressed('1 8 0 ft ft [Drywal]');

      expect(texts(named), ['180ft²', 'Drywall covered area180ft²']);
      expect(row(named).first, 'Drywall: 5.63 (48in x 96in)');
    });

    test('a Calc that is an area takes the name too, and is counted from '
        'then on', () {
      final calc = pressed('1 2 ft × 1 5 ft =');

      final named = pressed('[Drywal]', tape: calc);

      expect(calc.countedArea, isNull);
      expect(texts(named), ['12ft', '×15ft', 'Drywall covered area180ft²']);
      expect(named.countedArea, isNotNull);
    });

    test('any accepted area takes the name and remembers which answer it '
        'was: a Wall area and a Circle area are named like an Area, the '
        'strip does not offer that answer again, and the other key names '
        'it again with the same answer behind it (Section 3.3: "Takes: An '
        'area on the tape")', () {
      final wallArea = accepted(
        pressed('[Length] 1 2 ft [Width] 1 0 ft [Height] 8 ft'),
        DeterministicRules.wallAreaKey,
      );
      final circleArea = accepted(
        pressed('[Radius] 6 ft'),
        DeterministicRules.circleAreaKey,
      );

      final namedWall = pressed('[Drywal]', tape: wallArea);
      final namedCircle = pressed('[Msnry]', tape: circleArea);
      final renamed = pressed('[Msnry]', tape: namedWall);

      expect(texts(namedWall).last, 'Drywall covered area352ft²');
      expect(
        (namedWall.chips.last as ResultChip).namedFrom,
        DeterministicRules.wallAreaKey,
      );
      expect(row(namedWall), isNot(contains(startsWith('Wall area'))));
      expect(row(namedWall).first, 'Drywall: 11.00 (48in x 96in)');
      expect(texts(namedCircle).last, 'Masonry covered area113.1ft²');
      expect(
        (namedCircle.chips.last as ResultChip).namedFrom,
        DeterministicRules.circleAreaKey,
      );
      expect(texts(renamed).last, 'Masonry covered area352ft²');
      expect(
        (renamed.chips.last as ResultChip).namedFrom,
        DeterministicRules.wallAreaKey,
      );
    });

    test('the key has nothing to name on an empty tape, a length, a count, '
        'a room whose sides make a floor and walls, an area an operator '
        'leads, an open bracket or a reopened chip', () {
      final room = pressed('[Length] 1 2 ft [Width] 1 0 ft [Height] 8 ft');
      for (final (why, tape) in [
        ('an empty tape', const Tape()),
        ('a length', pressed('[Length] 2 0 ft')),
        ('a count', counted(pressed('1 8 0 ft ft'))),
        ('a room', room),
        ('an area an operator leads', pressed('5 ft ft + 1 8 0 ft ft')),
        ('an open bracket', pressed('( 1 8 0 ft ft')),
        ('a reopened chip', pressed('$wall accept:Area tap:0')),
      ]) {
        expect(tape.pressTradeKey(Trade.drywall), isNull, reason: why);
        expect(tape.pressTradeKey(Trade.masonry), isNull, reason: why);
      }
    });
  });

  group('Tape.pressTradeKey says why it cannot count (CA-1478; Section '
      '21.3, "Keys that must also answer"; Section 1.4, "A store may be '
      'empty")', () {
    test('an area of zero or less is refused with "Area must be more than '
        'zero" by either key: a negative Calc, a zero Calc and a typed 0ft² '
        '(rows 457, 458, 460)', () {
      for (final keys in [
        '( 0 ft − 1 2 ft ( × 1 0 ft =',
        '0 ft × 1 0 ft =',
        '0 ft ft',
      ]) {
        final tape = pressed(keys);

        for (final trade in Trade.values) {
          expect(
            tape.pressTradeKey(trade),
            const TapeRefused(TapeRefusal.areaMustBeMoreThanZero),
            reason: '$keys, $trade',
          );
        }
      }
    });

    test('with its store empty the key is refused on an area it would '
        'name: "No sheet sizes" for Drywal and "No piece sizes" for Msnry, '
        'on an accepted Area, a typed area and two sides alike (row 411)', () {
      for (final keys in ['$wall accept:Area', '1 0 0 ft ft', wall]) {
        final tape = pressed(keys);

        expect(
          tape.pressTradeKey(Trade.drywall, storeIsEmpty: true),
          const TapeRefused(TapeRefusal.noSheetSizes),
          reason: keys,
        );
        expect(
          tape.pressTradeKey(Trade.masonry, storeIsEmpty: true),
          const TapeRefused(TapeRefusal.noPieceSizes),
          reason: keys,
        );
      }
    });

    test('an area of zero or less is told first, and a tape with nothing '
        'to name is still not the key\'s to answer, store empty or not', () {
      expect(
        pressed('0 ft ft').pressTradeKey(Trade.drywall, storeIsEmpty: true),
        const TapeRefused(TapeRefusal.areaMustBeMoreThanZero),
      );
      expect(
        pressed(
          '[Length] 2 0 ft',
        ).pressTradeKey(Trade.drywall, storeIsEmpty: true),
        isNull,
      );
    });
  });

  group('Tape: a covered area is made again after an edit before it (rule '
      '4.8; rule 4.7, "recomputes in place")', () {
    test('landed by the key straight from two sides, with no = pressed, it '
        'remembers the Area and follows the sides (walkthrough 19.2)', () {
      final named = pressed('[Length] 2 2 ft [Height] 6 ft 6 in [Msnry]');

      final edited = pressed('tap:0 ✕ 2 0 ft tap:0', tape: named);

      expect(
        (named.chips.last as ResultChip).namedFrom,
        DeterministicRules.areaKey,
      );
      expect(texts(edited).last, 'Masonry covered area130ft²');
    });

    test('named from a Wall area, it is made again as the Wall area of the '
        'new sides, never as the floor', () {
      final named = pressed(
        '[Drywal]',
        tape: accepted(
          pressed('[Length] 1 2 ft [Width] 1 0 ft [Height] 8 ft'),
          DeterministicRules.wallAreaKey,
        ),
      );

      final edited = pressed('tap:2 ✕ 9 ft tap:2', tape: named);

      expect(texts(edited).last, 'Drywall covered area396ft²');
      expect(
        (edited.chips.last as ResultChip).namedFrom,
        DeterministicRules.wallAreaKey,
      );
    });

    test('named from the Area two sides make, it follows the sides and '
        'keeps its name, and its count follows it', () {
      final named = counted(pressed('$wall accept:Area [Drywal]'));

      final edited = pressed('tap:0 ✕ 3 0 ft tap:0', tape: named);

      expect(texts(edited), [
        'Length30ft',
        'Height9ft',
        'Drywall covered area270ft²',
        'Number of sheets8.44',
      ]);
    });

    test('it is made again from the Area, not from whatever answer leads '
        'the rules: with a third side present Volume leads, and the covered '
        'area still follows the floor', () {
      final named = pressed(
        '[Length] 1 2 ft [Width] 1 0 ft [Height] 8 ft accept:Area [Msnry]',
      );
      expect(
        const DeterministicRules().answersFor(named.namedValues).first.key,
        DeterministicRules.volumeKey,
      );

      final edited = pressed('tap:0 ✕ 2 0 ft tap:0', tape: named);

      expect(texts(edited)[3], 'Masonry covered area200ft²');
    });

    test('named from a typed area, it follows what is typed there', () {
      final named = counted(pressed('1 8 0 ft ft [Drywal]'));

      final edited = pressed('tap:0 ✕ 2 0 0 ft ft tap:0', tape: named);

      expect(texts(edited), [
        '200ft²',
        'Drywall covered area200ft²',
        'Number of sheets6.25',
      ]);
    });

    test('named from a Calc, it follows the calculation', () {
      final named = pressed('1 2 ft × 1 5 ft = [Drywal]');

      final edited = pressed('tap:1 ✕ 2 0 ft tap:1', tape: named);

      expect(texts(edited).last, 'Drywall covered area240ft²');
    });

    test('with no area left to name, it goes with the seal and is named '
        'for its message', () {
      final named = pressed('1 8 0 ft ft [Drywal]');

      final sealed = pressed('tap:0 ✕ 3 ft', tape: named).tapChip(0);

      expect(
        sealed,
        isA<TapeChanged>()
            .having((c) => c.removed, 'removed', ['Drywall covered area'])
            .having((c) => c.tape.chips, 'chips', hasLength(1)),
      );
    });
  });
}
