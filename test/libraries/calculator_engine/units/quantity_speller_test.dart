import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const speller = QuantitySpeller();

  group('QuantitySpeller', () {
    group('spell a length', () {
      test('writes 22ft in inches as 264in', () {
        expect(speller.spell(const Length(16896, unit: Unit.inch)), const [
          Token(digits: '264', unit: Unit.inch),
        ]);
      });

      test('writes 18ft 8in in yards to three decimals, 6.222yd', () {
        expect(speller.spell(const Length(14336, unit: Unit.yard)), const [
          Token(digits: '6.222', unit: Unit.yard),
        ]);
      });

      test('writes 4in in feet as 0.333ft', () {
        expect(speller.spell(const Length(256, unit: Unit.foot)), const [
          Token(digits: '0.333', unit: Unit.foot),
        ]);
      });

      test('writes 22ft in millimetres, which the prototype could not', () {
        expect(
          speller.spell(const Length(16896, unit: Unit.millimetre)),
          const [Token(digits: '6705.6', unit: Unit.millimetre)],
        );
      });

      test('writes the ft-in compound as whole feet and inches', () {
        expect(speller.spell(const Length(14336, unit: Unit.footInch)), const [
          Token(digits: '18', unit: Unit.foot),
          Token(digits: '8', unit: Unit.inch),
        ]);
      });

      test('keeps two decimals of leftover inches in a compound', () {
        expect(speller.spell(const Length(772, unit: Unit.footInch)), const [
          Token(digits: '1', unit: Unit.foot),
          Token(digits: '0.06', unit: Unit.inch),
        ]);
      });

      test('writes a whole number of feet with 0in', () {
        expect(speller.spell(const Length(16896, unit: Unit.footInch)), const [
          Token(digits: '22', unit: Unit.foot),
          Token(digits: '0', unit: Unit.inch),
        ]);
      });
    });

    group('spell an area', () {
      const squareTicksPerSquareFoot =
          Area.squareTicksPerSquareInch * Area.squareInchesPerSquareFoot;

      test('writes a squared unit with power two', () {
        expect(speller.spell(const Area(2.0 * 4096, unit: Unit.inch)), const [
          Token(digits: '2', unit: Unit.inch, power: 2),
        ]);
      });

      test('converts square ticks into the unit written', () {
        const area = Area(180.0 * squareTicksPerSquareFoot, unit: Unit.yard);
        expect(speller.spell(area), const [
          Token(digits: '20', unit: Unit.yard, power: 2),
        ]);
      });

      test('writes 16,000ft² in acres to four decimals', () {
        const area = Area(16000.0 * squareTicksPerSquareFoot, unit: Unit.acre);
        expect(speller.spell(area), const [
          Token(digits: '0.3673', unit: Unit.acre),
        ]);
      });
    });

    group('spell a volume', () {
      test('writes 78yd³ converted to feet as 2106ft³', () {
        expect(speller.spell(const Volume(2106, unit: Unit.foot)), const [
          Token(digits: '2106', unit: Unit.foot, power: 3),
        ]);
      });

      test('writes 2,106ft³ in yards as 78yd³', () {
        expect(speller.spell(const Volume(2106, unit: Unit.yard)), const [
          Token(digits: '78', unit: Unit.yard, power: 3),
        ]);
      });

      test('writes board feet to four decimals, 50.1751bf', () {
        final volume = const QuantityParser().parse(const [
          Token(digits: '0.1184', unit: Unit.metre, power: 3),
        ]);
        final spelled = speller.spell(
          (volume as Volume).spelledIn(Unit.boardFoot),
        );
        expect(spelled, const [Token(digits: '50.1751', unit: Unit.boardFoot)]);
      });
    });

    group('spell a weight', () {
      test('writes 78lbs in kilograms to three decimals', () {
        expect(speller.spell(const Weight(7800, unit: Unit.kilogram)), const [
          Token(digits: '35.38', unit: Unit.kilogram),
        ]);
      });

      test('writes a ton by the Pounds-per-ton setting', () {
        const weight = Weight(78 * 2240 * 100, unit: Unit.ton);
        expect(speller.spell(weight), const [
          Token(digits: '87.36', unit: Unit.ton),
        ]);
        expect(const QuantitySpeller(poundsPerTon: 2240).spell(weight), const [
          Token(digits: '78', unit: Unit.ton),
        ]);
      });
    });

    test('writes an angle and a scalar as a bare number', () {
      expect(speller.spell(const Angle(26.57)), const [Token(digits: '26.57')]);
      expect(speller.spell(const Scalar(78)), const [Token(digits: '78')]);
    });

    test('is equal to another speller with the same ton definition', () {
      final poundsPerTon = int.parse('2000');
      expect(QuantitySpeller(poundsPerTon: poundsPerTon), speller);
      expect(const QuantitySpeller(poundsPerTon: 2240), isNot(equals(speller)));
    });
  });
}
