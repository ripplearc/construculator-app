import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ladder = UnitLadder();
  const parser = QuantityParser();

  UnitKeyOutcome press(
    List<Token> tokens,
    Unit key, {
    bool lengthOnly = false,
  }) {
    final value = parser.parse(tokens);
    if (value == null) throw StateError('test tokens must be finished');
    return ladder.press(
      tokens: tokens,
      value: value,
      key: key,
      holdsLengthOnly: lengthOnly,
    );
  }

  group('UnitLadder', () {
    group('a unit key converts a finished value in place', () {
      test('Length 22ft then [Inch] reads 264in', () {
        expect(
          press(const [Token(digits: '22', unit: Unit.foot)], Unit.inch),
          const UnitKeyConverted(Length(16896, unit: Unit.inch), [
            Token(digits: '264', unit: Unit.inch),
          ]),
        );
      });

      test('Width 18ft 8in then [Inch] collapses to 224in', () {
        expect(
          press(const [
            Token(digits: '18', unit: Unit.foot),
            Token(digits: '8', unit: Unit.inch),
          ], Unit.inch),
          const UnitKeyConverted(Length(14336, unit: Unit.inch), [
            Token(digits: '224', unit: Unit.inch),
          ]),
        );
      });

      test('[Feet] on 224in brings back the trade compound 18ft 8in', () {
        expect(
          press(const [Token(digits: '224', unit: Unit.inch)], Unit.foot),
          const UnitKeyConverted(Length(14336, unit: Unit.footInch), [
            Token(digits: '18', unit: Unit.foot),
            Token(digits: '8', unit: Unit.inch),
          ]),
        );
      });

      test('[Feet] on a compound toggles back to decimal feet', () {
        final outcome = press(const [
          Token(digits: '18', unit: Unit.foot),
          Token(digits: '8', unit: Unit.inch),
        ], Unit.foot);
        expect(
          outcome,
          const UnitKeyConverted(Length(14336, unit: Unit.foot), [
            Token(digits: '18.667', unit: Unit.foot),
          ]),
        );
      });

      test('[Yards], which has no compound, shows 6.222yd', () {
        expect(
          press(const [
            Token(digits: '18', unit: Unit.foot),
            Token(digits: '8', unit: Unit.inch),
          ], Unit.yard),
          const UnitKeyConverted(Length(14336, unit: Unit.yard), [
            Token(digits: '6.222', unit: Unit.yard),
          ]),
        );
      });

      test('a value under a foot converts to decimal feet, never 0ft 4in', () {
        expect(
          press(const [Token(digits: '4', unit: Unit.inch)], Unit.foot),
          const UnitKeyConverted(Length(256, unit: Unit.foot), [
            Token(digits: '0.333', unit: Unit.foot),
          ]),
        );
      });

      test('[Feet] on a whole number of inches stays decimal feet', () {
        expect(
          press(const [Token(digits: '24', unit: Unit.inch)], Unit.foot),
          const UnitKeyConverted(Length(1536, unit: Unit.foot), [
            Token(digits: '2', unit: Unit.foot),
          ]),
        );
      });

      test('[Feet] on decimal feet shows the compound instead of raising', () {
        expect(
          press(const [Token(digits: '18.67', unit: Unit.foot)], Unit.foot),
          const UnitKeyConverted(Length(14339, unit: Unit.footInch), [
            Token(digits: '18', unit: Unit.foot),
            Token(digits: '8.05', unit: Unit.inch),
          ]),
        );
      });

      test('the same key on a fraction re-spells it: 7/16in reads 0.438in', () {
        expect(
          press(const [
            Token(digits: '7', denominator: '16', unit: Unit.inch),
          ], Unit.inch),
          const UnitKeyConverted(Length(28, unit: Unit.inch), [
            Token(digits: '0.438', unit: Unit.inch),
          ]),
        );
      });

      test('inches convert to millimetres like every other pair', () {
        expect(
          press(const [Token(digits: '264', unit: Unit.inch)], Unit.millimetre),
          const UnitKeyConverted(Length(16896, unit: Unit.millimetre), [
            Token(digits: '6705.6', unit: Unit.millimetre),
          ]),
        );
      });

      test(
        'a different length key converts a raised value: 78yd³ → 2106ft³',
        () {
          final outcome = press(const [
            Token(digits: '78', unit: Unit.yard, power: 3),
          ], Unit.foot);
          expect(outcome, isA<UnitKeyConverted>());
          final converted = outcome as UnitKeyConverted;
          expect(converted.tokens, const [
            Token(digits: '2106', unit: Unit.foot, power: 3),
          ]);
          expect((converted.value as Volume).unit, Unit.foot);
        },
      );

      test('a different length key converts a raised area', () {
        final outcome = press(const [
          Token(digits: '180', unit: Unit.foot, power: 2),
        ], Unit.yard);
        expect((outcome as UnitKeyConverted).tokens, const [
          Token(digits: '20', unit: Unit.yard, power: 2),
        ]);
      });

      test('[Bd Ft] on a volume converts it: 2106ft³ reads 25272bf', () {
        expect(
          press(const [
            Token(digits: '2106', unit: Unit.foot, power: 3),
          ], Unit.boardFoot),
          const UnitKeyConverted(Volume(2106, unit: Unit.boardFoot), [
            Token(digits: '25272', unit: Unit.boardFoot),
          ]),
        );
      });

      test('[Feet] on board feet converts back to cubic feet', () {
        expect(
          press(const [
            Token(digits: '25272', unit: Unit.boardFoot),
          ], Unit.foot),
          const UnitKeyConverted(Volume(2106, unit: Unit.foot), [
            Token(digits: '2106', unit: Unit.foot, power: 3),
          ]),
        );
      });

      test('a weight key converts a weight: [Kg] on 78lbs', () {
        expect(
          press(const [Token(digits: '78', unit: Unit.pound)], Unit.kilogram),
          const UnitKeyConverted(Weight(7800, unit: Unit.kilogram), [
            Token(digits: '35.38', unit: Unit.kilogram),
          ]),
        );
      });
    });

    group('the same key pressed again raises the dimension', () {
      test('2in then [Inch] reads 2in², then 2in³', () {
        const inch = Token(digits: '2', unit: Unit.inch);
        expect(
          press(const [inch], Unit.inch),
          const UnitKeyRaised(Area(2 * 4096, unit: Unit.inch), [
            Token(digits: '2', unit: Unit.inch, power: 2),
          ]),
        );
        final cubed = press(const [
          Token(digits: '2', unit: Unit.inch, power: 2),
        ], Unit.inch);
        expect(cubed, isA<UnitKeyRaised>());
        expect((cubed as UnitKeyRaised).tokens, const [
          Token(digits: '2', unit: Unit.inch, power: 3),
        ]);
        expect((cubed.value as Volume).cubicFeet, closeTo(2 / 1728, 1e-12));
      });

      test('a fourth press stops at cubic and points at the other key', () {
        final outcome = press(const [
          Token(digits: '78', unit: Unit.yard, power: 3),
        ], Unit.yard);
        expect(outcome, isA<UnitKeyRefused>());
        final refused = outcome as UnitKeyRefused;
        expect(refused.reason, UnitKeyRefusal.stopsAtCubic);
        expect(refused.alternative, isA<Volume>());
        final alternative = refused.alternative as Volume;
        expect(alternative.unit, Unit.foot);
        expect(alternative.cubicFeet, closeTo(2106, 1e-9));
      });

      test('a fourth [Feet] points at yards', () {
        expect(
          press(const [
            Token(digits: '2106', unit: Unit.foot, power: 3),
          ], Unit.foot),
          const UnitKeyRefused(
            UnitKeyRefusal.stopsAtCubic,
            alternative: Volume(2106, unit: Unit.yard),
          ),
        );
      });

      test('a key that can only hold a length refuses the raise', () {
        expect(
          press(
            const [Token(digits: '22', unit: Unit.foot)],
            Unit.foot,
            lengthOnly: true,
          ),
          const UnitKeyRefused(UnitKeyRefusal.keepsLength),
        );
      });

      test('the raise is refused, not silently converted, on cubic under a '
          'length-only key', () {
        final outcome = press(
          const [Token(digits: '2', unit: Unit.inch, power: 3)],
          Unit.inch,
          lengthOnly: true,
        );
        expect((outcome as UnitKeyRefused).reason, UnitKeyRefusal.stopsAtCubic);
      });
    });

    group('a key that cannot apply says why', () {
      test('a weight key on a length cannot convert', () {
        expect(
          press(const [Token(digits: '22', unit: Unit.foot)], Unit.kilogram),
          const UnitKeyRefused(UnitKeyRefusal.cannotConvert),
        );
      });

      test('a weight key on an area cannot convert', () {
        expect(
          press(const [
            Token(digits: '4', unit: Unit.inch, power: 2),
          ], Unit.kilogram),
          const UnitKeyRefused(UnitKeyRefusal.cannotConvert),
        );
      });

      test('the same weight key again is already in that unit', () {
        expect(
          press(const [Token(digits: '78', unit: Unit.pound)], Unit.pound),
          const UnitKeyRefused(UnitKeyRefusal.alreadyInUnit),
        );
      });

      test('[Bd Ft] on board feet is already in that unit', () {
        expect(
          press(const [
            Token(digits: '25272', unit: Unit.boardFoot),
          ], Unit.boardFoot),
          const UnitKeyRefused(UnitKeyRefusal.alreadyInUnit),
        );
      });

      test('[Inch] on a raised volume converts with its power', () {
        expect(
          press(const [
            Token(digits: '78', unit: Unit.yard, power: 3),
          ], Unit.inch),
          const UnitKeyConverted(Volume(2106, unit: Unit.inch), [
            Token(digits: '3639168', unit: Unit.inch, power: 3),
          ]),
        );
      });

      test('[Inch] on board feet cannot convert: in³ is not offered', () {
        expect(
          press(const [Token(digits: '500', unit: Unit.boardFoot)], Unit.inch),
          const UnitKeyRefused(UnitKeyRefusal.cannotConvert),
        );
      });

      test('[Bd Ft] on a length cannot convert', () {
        expect(
          press(const [Token(digits: '22', unit: Unit.foot)], Unit.boardFoot),
          const UnitKeyRefused(UnitKeyRefusal.cannotConvert),
        );
      });

      test('nothing finished cannot convert', () {
        expect(
          ladder.press(
            tokens: const [],
            value: const Scalar(1),
            key: Unit.foot,
          ),
          const UnitKeyRefused(UnitKeyRefusal.cannotConvert),
        );
      });
    });

    test('is equal to another ladder with the same ton definition', () {
      final poundsPerTon = int.parse('2000');
      expect(UnitLadder(poundsPerTon: poundsPerTon), ladder);
      expect(const UnitLadder(poundsPerTon: 2240), isNot(equals(ladder)));
    });

    test('reads and writes a ton by the same definition', () {
      const longTon = UnitLadder(poundsPerTon: 2240);
      const tokens = [Token(digits: '2240', unit: Unit.pound)];
      final value = longTon.parser.parse(tokens);
      expect(
        longTon.press(tokens: tokens, value: value!, key: Unit.ton),
        UnitKeyConverted(const Weight(224000, unit: Unit.ton), const [
          Token(digits: '1', unit: Unit.ton),
        ]),
      );
    });
  });
}
