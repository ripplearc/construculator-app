import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = QuantityParser();

  group('QuantityParser', () {
    group('parse', () {
      test('reads Length 22ft as 16,896 ticks in feet', () {
        final quantity = parser.parse(const [
          Token(digits: '22', unit: Unit.foot),
        ]);
        expect(quantity, const Length(16896, unit: Unit.foot));
      });

      test('reads Width 18ft 8in as 14,336 ticks spelled as ft-in', () {
        final quantity = parser.parse(const [
          Token(digits: '18', unit: Unit.foot),
          Token(digits: '8', unit: Unit.inch),
        ]);
        expect(quantity, const Length(14336, unit: Unit.footInch));
      });

      test('reads 1ft 1/16in as exactly 772 ticks', () {
        final quantity = parser.parse(const [
          Token(digits: '1', unit: Unit.foot),
          Token(digits: '1', denominator: '16', unit: Unit.inch),
        ]);
        expect(quantity, const Length(772, unit: Unit.footInch));
      });

      test('reads a bare fraction 7/16in as 28 ticks', () {
        final quantity = parser.parse(const [
          Token(digits: '7', denominator: '16', unit: Unit.inch),
        ]);
        expect(quantity, const Length(28, unit: Unit.inch));
      });

      test('converts a metre on entry to the nearest tick', () {
        final quantity = parser.parse(const [
          Token(digits: '1', unit: Unit.metre),
        ]);
        expect(quantity, const Length(2520, unit: Unit.metre));
      });

      test('rounds each token of a compound on its own before adding', () {
        // 0.3m is 755.9 ticks and 3cm 75.6: rounded apart they add to 832,
        // where the exact sum 831.5 would round to 831.
        final quantity = parser.parse(const [
          Token(digits: '0.3', unit: Unit.metre),
          Token(digits: '3', unit: Unit.centimetre),
        ]);
        expect(quantity, const Length(756 + 76, unit: Unit.metre));
      });

      test('adds a metric token to an imperial one in ticks', () {
        // The entry buffer keeps a compound in one system, so this only pins
        // that the sum is over ticks: 768 for the foot, 504 for the 20cm.
        final quantity = parser.parse(const [
          Token(digits: '1', unit: Unit.foot),
          Token(digits: '20', unit: Unit.centimetre),
        ]);
        expect(quantity, const Length(1272, unit: Unit.footInch));
      });

      test('reads a fraction over zero as no value at all', () {
        expect(
          parser.parse(const [
            Token(digits: '7', denominator: '0', unit: Unit.inch),
          ]),
          isNull,
        );
        expect(
          parser.parse(const [
            Token(digits: '1', unit: Unit.foot),
            Token(digits: '7', denominator: '0', unit: Unit.inch),
          ]),
          isNull,
        );
        expect(
          parser.parse(const [
            Token(digits: '7', denominator: '0', unit: Unit.pound),
          ]),
          isNull,
        );
      });

      test('raises a unit pressed twice to an area in that unit', () {
        final quantity = parser.parse(const [
          Token(digits: '2', unit: Unit.inch, power: 2),
        ]);
        expect(quantity, const Area(2 * 4096, unit: Unit.inch));
      });

      test('raises a unit pressed three times to a volume in cubic feet', () {
        final quantity = parser.parse(const [
          Token(digits: '78', unit: Unit.yard, power: 3),
        ]);
        expect(quantity, isA<Volume>());
        final volume = quantity as Volume;
        expect(volume.cubicFeet, closeTo(2106, 1e-9));
        expect(volume.unit, Unit.yard);
      });

      test('reads 0.1184m³ as the 50.1751 board feet of walkthrough 20.5', () {
        final quantity = parser.parse(const [
          Token(digits: '0.1184', unit: Unit.metre, power: 3),
        ]);
        final volume = quantity as Volume;
        expect(volume.boardFeet, closeTo(50.1751, 0.00005));
      });

      test('reads a board-foot token as a twelfth of a cubic foot', () {
        final quantity = parser.parse(const [
          Token(digits: '500', unit: Unit.boardFoot),
        ]);
        expect(quantity, const Volume(500 / 12, unit: Unit.boardFoot));
      });

      test('reads 78lbs as 7,800 hundredths of a pound', () {
        final quantity = parser.parse(const [
          Token(digits: '78', unit: Unit.pound),
        ]);
        expect(quantity, const Weight(7800, unit: Unit.pound));
      });

      test('weighs a typed ton by the Pounds-per-ton setting', () {
        const tokens = [Token(digits: '78', unit: Unit.ton)];
        expect(
          parser.parse(tokens),
          const Weight(78 * 2000 * 100, unit: Unit.ton),
        );
        expect(
          const QuantityParser(poundsPerTon: 2240).parse(tokens),
          const Weight(78 * 2240 * 100, unit: Unit.ton),
        );
      });

      test('adds the tokens of a compound weight', () {
        final quantity = parser.parse(const [
          Token(digits: '5', unit: Unit.pound),
          Token(digits: '3', unit: Unit.kilogram),
        ]);
        expect(quantity, const Weight(500 + 3 * 220.462262, unit: Unit.pound));
      });

      test('is null while nothing has been typed', () {
        expect(parser.parse(const []), isNull);
      });

      test('is null while a token is still open', () {
        expect(parser.parse(const [Token(digits: '22')]), isNull);
        expect(
          parser.parse(const [
            Token(digits: '1', unit: Unit.foot),
            Token(digits: '7', denominator: '', unit: Unit.inch),
          ]),
          isNull,
        );
      });

      test('is null when a raised unit sits inside a compound', () {
        expect(
          parser.parse(const [
            Token(digits: '2511', unit: Unit.foot, power: 3),
            Token(digits: '45', unit: Unit.inch),
          ]),
          isNull,
        );
      });

      test('is null when the tokens measure different things', () {
        expect(
          parser.parse(const [
            Token(digits: '5', unit: Unit.pound),
            Token(digits: '3', unit: Unit.foot),
          ]),
          isNull,
        );
      });

      test('is null for two board-foot tokens, which never compound', () {
        expect(
          parser.parse(const [
            Token(digits: '500', unit: Unit.boardFoot),
            Token(digits: '3', unit: Unit.boardFoot),
          ]),
          isNull,
        );
      });

      test('is null for a raised weight, which the ladder never makes', () {
        expect(
          parser.parse(const [Token(digits: '5', unit: Unit.pound, power: 2)]),
          isNull,
        );
      });
    });

    group('ticksOf', () {
      test('rounds a length token to whole ticks', () {
        expect(
          parser.ticksOf(const Token(digits: '22', unit: Unit.foot)),
          16896,
        );
        expect(
          parser.ticksOf(const Token(digits: '1', unit: Unit.metre)),
          2520,
        );
      });

      test('is a programming error on a token that is not a length', () {
        expect(
          () => parser.ticksOf(const Token(digits: '5', unit: Unit.pound)),
          throwsArgumentError,
        );
        expect(
          () => parser.ticksOf(const Token(digits: '5')),
          throwsArgumentError,
        );
      });

      test('is a programming error on a fraction over zero', () {
        expect(
          () => parser.ticksOf(
            const Token(digits: '7', denominator: '0', unit: Unit.inch),
          ),
          throwsArgumentError,
        );
      });
    });

    test('is equal to another parser with the same ton definition', () {
      final poundsPerTon = int.parse('2000');
      expect(QuantityParser(poundsPerTon: poundsPerTon), parser);
      expect(const QuantityParser(poundsPerTon: 2240), isNot(equals(parser)));
    });
  });
}
