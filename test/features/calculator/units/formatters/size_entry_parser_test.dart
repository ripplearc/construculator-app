import 'package:construculator/features/calculator/presentation/formatters/size_entry_parser.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const parser = SizeEntryParser();
const imperial = MeasurementSystem.imperial;
const metric = MeasurementSystem.metric;

Rational? inchesOf(String text, [MeasurementSystem system = imperial]) =>
    parser.lengthOf(text, system)?.inches;

Unit? unitOf(String text, [MeasurementSystem system = imperial]) =>
    parser.lengthOf(text, system)?.unit;

void main() {
  group('SizeEntryParser', () {
    test('4 [Feet] reads 48in and 12 [Feet] reads 144in (walkthrough '
        '11.4)', () {
      expect(inchesOf('4Feet'), const Rational(48));
      expect(inchesOf('12Feet'), const Rational(144));
      expect(unitOf('4Feet'), Unit.foot);
    });

    test('every unit face of the editor\'s keyboard reads as its unit', () {
      expect(inchesOf('2Yards'), const Rational(72));
      expect(inchesOf('48Inch'), const Rational(48));
      expect(inchesOf('1M'), const Rational(5000, 127));
      expect(inchesOf('254CM'), const Rational(100));
      expect(inchesOf('254MM'), const Rational(10));
    });

    test('a compound adds its parts and keeps the unit of the first', () {
      expect(inchesOf('4Feet6Inch'), const Rational(54));
      expect(inchesOf('4Feet 6Inch'), const Rational(54));
      expect(unitOf('4Feet6Inch'), Unit.foot);
    });

    test('a decimal reads exactly', () {
      expect(inchesOf('47.25Inch'), const Rational(189, 4));
      expect(inchesOf('.5Feet'), const Rational(6));
      expect(inchesOf('4.Feet'), const Rational(48));
    });

    test('a number with no unit is in inches under Imperial and in '
        'millimetres under Metric (term 2.16)', () {
      expect(inchesOf('48'), const Rational(48));
      expect(unitOf('48'), Unit.inch);
      expect(inchesOf('254', metric), const Rational(10));
      expect(unitOf('254', metric), Unit.millimetre);
    });

    test('a size of zero is no size ("Size must be more than zero.")', () {
      expect(parser.lengthOf('0Feet', imperial), isNull);
      expect(parser.lengthOf('0', imperial), isNull);
      expect(parser.lengthOf('0Feet0Inch', imperial), isNull);
      expect(parser.lengthOf('0.0MM', metric), isNull);
    });

    test('a field that spells no length is no size', () {
      for (final text in [
        '',
        '   ',
        'Feet',
        '.',
        '4Feet6',
        '4+2Feet',
        '4×12',
        '1/2Inch',
        '4Feet!',
        'x4Feet',
      ]) {
        expect(parser.lengthOf(text, imperial), isNull, reason: text);
      }
    });

    test('a number too long to keep exactly is no size: too many digits, '
        'or a number whose inches outgrow an exact value', () {
      expect(parser.lengthOf('9' * 30, imperial), isNull);
      expect(parser.lengthOf('${'9' * 15}Yards', imperial), isNull);
      expect(inchesOf('${'9' * 14}Inch'), Rational(int.parse('9' * 14)));
    });
  });
}
