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

SizeEntry refused(SizeEntryRefusal reason, {Unit? unit}) =>
    SizeEntryRefused(reason, unit: unit);

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

    test('a compound steps down within one system, as on the tape: 4ft 6in, '
        '1m 20cm (rule 4.5)', () {
      expect(inchesOf('4Feet6Inch'), const Rational(54));
      expect(inchesOf('4Feet 6Inch'), const Rational(54));
      expect(inchesOf('1M20CM', metric), const Rational(6000, 127));
    });

    test('Add is the equals key: a number typed after feet closes as inches, '
        'so 4 [Feet] 6 is 4ft 6in (B1; rule 4.5)', () {
      expect(inchesOf('4Feet6'), const Rational(54));
      expect(inchesOf('8Feet0'), const Rational(96));
    });

    test('a fraction is kept exactly: 48in 1/2 is 48-1/2in, 1ft 1/16in, and '
        '1/2in alone (B1; Section 6, "Compound values and fractions")', () {
      expect(inchesOf('48Inch1/2'), const Rational(97, 2));
      expect(inchesOf('1Feet1/16Inch'), const Rational(193, 16));
      expect(inchesOf('1/2Inch'), const Rational(1, 2));
      expect(inchesOf('7/16Inch'), const Rational(7, 16));
    });

    test('a unit that cannot continue the value is refused and named, never '
        'added up: a second Feet, centimetres after feet, feet after inches '
        '(B1; Section 5.2, "Can\'t append here")', () {
      expect(
        parser.read('4Feet4Feet', imperial),
        refused(SizeEntryRefusal.cannotAppendUnit, unit: Unit.foot),
      );
      expect(
        parser.read('4Feet20CM', imperial),
        refused(SizeEntryRefusal.cannotAppendUnit, unit: Unit.centimetre),
      );
      expect(
        parser.read('6Inch4Feet', imperial),
        refused(SizeEntryRefusal.cannotAppendUnit, unit: Unit.foot),
      );
      for (final text in ['4Feet4Feet', '4Feet20CM', '6Inch4Feet']) {
        expect(parser.lengthOf(text, imperial), isNull, reason: text);
      }
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

    test('a size of zero, an empty field, and a size that shows as zero are '
        'no size ("Size must be more than zero."; B2; term 2.16)', () {
      for (final (text, system) in [
        ('0Feet', imperial),
        ('0', imperial),
        ('0Feet0Inch', imperial),
        ('', imperial),
        ('   ', imperial),
        ('0.0001Inch', imperial),
        ('0.004Inch', imperial),
        ('0.0MM', metric),
        ('0.4MM', metric),
      ]) {
        expect(
          parser.read(text, system),
          refused(SizeEntryRefusal.zero),
          reason: '"$text"',
        );
      }
      expect(inchesOf('0.01Inch'), const Rational(1, 100));
      expect(inchesOf('1MM', metric), const Rational(5, 127));
    });

    test('a number above 19,999,999.99 is Too large, typed in any unit, and '
        '19,999,999.99 itself is a size (B2; Section 5.3)', () {
      for (final text in [
        '99999999999999Inch',
        '20000000Inch',
        '19999999.999Inch',
        '2000000Feet',
      ]) {
        expect(
          parser.read(text, imperial),
          refused(SizeEntryRefusal.tooLarge),
          reason: text,
        );
      }
      expect(inchesOf('19999999.99Inch'), const Rational(1999999999, 100));
      expect(
        parser.read('20000000MM', metric),
        refused(SizeEntryRefusal.tooLarge),
      );
      expect(
        parser.read('20000000MM', imperial),
        refused(SizeEntryRefusal.tooLarge),
        reason: 'the number typed is above the limit, whatever it shows as',
      );
      expect(
        parser.read('20000M', metric),
        refused(SizeEntryRefusal.tooLarge),
        reason: 'the row would show 20,000,000mm',
      );
      expect(inchesOf('19999M', metric), isNotNull);
    });

    test('a field the calculator would not take as a finished value is '
        'unfinished: a fraction with nothing under its line, a number after '
        'metres with no unit, an unknown face', () {
      for (final text in [
        'Feet',
        '.',
        '1/',
        '4Feet1/',
        '1M20',
        '4+2Feet',
        '4×12',
        '4Feet!',
        'x4Feet',
      ]) {
        expect(
          parser.read(text, imperial),
          isA<SizeEntryRefused>(),
          reason: text,
        );
        expect(parser.lengthOf(text, imperial), isNull, reason: text);
      }
      expect(parser.read('1M20', metric), refused(SizeEntryRefusal.unfinished));
      expect(
        parser.read('4+2Feet', imperial),
        refused(SizeEntryRefusal.unfinished),
      );
    });
  });
}
