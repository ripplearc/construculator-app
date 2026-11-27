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

    test('a unit that cannot continue the value is refused by its own '
        'mistake, never added up: the same unit again, a unit of the other '
        'system, a larger unit after a smaller one (B1, B4; term 2.16)', () {
      for (final text in ['4Feet4Feet', '4FeetFeet']) {
        expect(
          parser.read(text, imperial),
          const SizeEntryRefused(
            SizeEntryRefusal.unitUsedTwice,
            unit: Unit.foot,
            unitFace: 'Feet',
          ),
          reason: text,
        );
      }
      expect(
        parser.read('1M1M', metric),
        const SizeEntryRefused(
          SizeEntryRefusal.unitUsedTwice,
          unit: Unit.metre,
          unitFace: 'M',
        ),
      );
      for (final text in ['4Feet20CM', '1M4Inch']) {
        expect(
          parser.read(text, imperial),
          refused(SizeEntryRefusal.otherSystem),
          reason: text,
        );
      }
      expect(
        parser.read('6Inch4Feet', imperial),
        const SizeEntryRefused(
          SizeEntryRefusal.largerUnitAfterSmaller,
          unit: Unit.foot,
          unitFace: 'Feet',
          after: Unit.inch,
        ),
      );
      expect(
        parser.read('20CM1M', metric),
        const SizeEntryRefused(
          SizeEntryRefusal.largerUnitAfterSmaller,
          unit: Unit.metre,
          unitFace: 'M',
          after: Unit.centimetre,
        ),
      );
      expect(
        parser.read('4FeetInch', imperial),
        refused(SizeEntryRefusal.unfinished),
        reason: 'a smaller unit with no number before it names no mistake',
      );
      for (final text in ['4Feet4Feet', '4Feet20CM', '6Inch4Feet']) {
        expect(parser.lengthOf(text, imperial), isNull, reason: text);
      }
    });

    test('a stored size is spelled in key faces as the pill writes it, and '
        'reads back as that: 48in is 48Inch, 47.24in is 47.24Inch, and under '
        'Metric 1200mm is 1200MM (T2b, CA-1096; term 2.18)', () {
      const sheetWidth = Length(48 * Length.ticksPerInch, unit: Unit.inch);
      final metricSheet = parser.lengthOf('1200MM', metric)!;
      final prototypeSheet = parser.lengthOf('47.24Inch', imperial)!;

      expect(parser.facesOf(sheetWidth, imperial), '48Inch');
      expect(parser.facesOf(prototypeSheet, imperial), '47.24Inch');
      expect(parser.facesOf(metricSheet, metric), '1200MM');
      expect(
        parser.lengthOf(parser.facesOf(sheetWidth, imperial), imperial)!.inches,
        const Rational(48),
      );
      expect(
        parser.lengthOf(parser.facesOf(metricSheet, metric), metric)!.inches,
        metricSheet.inches,
      );
    });

    test('a decimal reads exactly', () {
      expect(inchesOf('47.25Inch'), const Rational(189, 4));
      expect(inchesOf('.5Feet'), const Rational(6));
      expect(inchesOf('4.Feet'), const Rational(48));
    });

    test('a number with no unit is refused and named under either system, '
        'a fraction too, while a number after feet still closes as inches '
        '(B3; term 2.16: "48 has no unit yet. Press a unit key."; rule '
        '4.5)', () {
      for (final system in [imperial, metric]) {
        expect(
          parser.read('48', system),
          const SizeEntryRefused(SizeEntryRefusal.noUnit, typed: '48'),
        );
        expect(parser.lengthOf('8', system), isNull);
      }
      expect(
        parser.read('1/2', imperial),
        const SizeEntryRefused(SizeEntryRefusal.noUnit, typed: '1/2'),
      );
      expect(inchesOf('4Feet6'), const Rational(54));
      expect(
        parser.read('1/', imperial),
        refused(SizeEntryRefusal.unfinished),
        reason: 'a fraction with nothing under its line is not a number yet',
      );
    });

    test('a size of exactly zero and an empty field are no size ("Size must '
        'be more than zero."; B2; term 2.16)', () {
      for (final (text, system) in [
        ('0Feet', imperial),
        ('0', imperial),
        ('0Feet0Inch', imperial),
        ('', imperial),
        ('   ', imperial),
        ('0.0MM', metric),
      ]) {
        expect(
          parser.read(text, system),
          refused(SizeEntryRefusal.zero),
          reason: '"$text"',
        );
      }
    });

    test('a size above zero that shows as zero is refused with what was '
        'typed and how it shows, under the system in force (B2, B4; term '
        '2.16: "0.0001in rounds to 0in. Type a bigger size.")', () {
      for (final (text, system, typed, shownAs) in [
        ('0.0001Inch', imperial, '0.0001in', '0in'),
        ('0.004Inch', imperial, '0.004in', '0in'),
        ('0.4MM', metric, '0.4mm', '0mm'),
      ]) {
        expect(
          parser.read(text, system),
          SizeEntryRefused(
            SizeEntryRefusal.roundsToZero,
            typed: typed,
            shownAs: shownAs,
          ),
          reason: '"$text"',
        );
      }
      expect(inchesOf('0.01Inch'), const Rational(1, 100));
      expect(inchesOf('1MM', metric), const Rational(5, 127));
      expect(
        parser.read('0.4MM', imperial),
        isA<SizeEntryLength>(),
        reason: '0.4mm shows as 0.02in under Imperial',
      );
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
        parser.read('Feet', imperial),
        refused(SizeEntryRefusal.unfinished),
        reason: 'a unit key on an empty field names no mistake of a unit',
      );
      expect(
        parser.read('4+2Feet', imperial),
        refused(SizeEntryRefusal.unfinished),
      );
    });
  });
}
