import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = QuantityFormatter();
  const squareTicksPerSquareFoot =
      Area.squareTicksPerSquareInch * Area.squareInchesPerSquareFoot;
  const twentyTwoFeet = 22 * Length.ticksPerFoot;
  const widthTicks = 18 * Length.ticksPerFoot + 8 * Length.ticksPerInch;

  group('QuantityFormatter', () {
    group('lengths, as Section 6 spells them', () {
      test('22ft in feet, inches, yards and metres', () {
        expect(
          formatter.format(const Length(twentyTwoFeet, unit: Unit.foot)),
          '22ft',
        );
        expect(
          formatter.format(const Length(twentyTwoFeet, unit: Unit.inch)),
          '264in',
        );
        expect(
          formatter.format(const Length(twentyTwoFeet, unit: Unit.yard)),
          '7.33yd',
        );
        expect(
          formatter.format(const Length(twentyTwoFeet, unit: Unit.metre)),
          '6.71m',
        );
      });

      test('the ft-in compound and millimetres of 264in', () {
        expect(
          formatter.format(const Length(twentyTwoFeet, unit: Unit.footInch)),
          '22ft 0in',
        );
        expect(
          formatter.format(const Length(twentyTwoFeet, unit: Unit.millimetre)),
          '6,706mm',
        );
      });

      test('a computed length is rounded once, at display (C3)', () {
        final diagonal = Length.computed(
          13 * Length.ticksPerFoot * math.sqrt2,
          unit: Unit.foot,
        );
        expect(formatter.format(diagonal), '18.38ft');
        expect(
          formatter.format(const Length(14120, unit: Unit.foot)),
          '18.39ft',
        );
        expect(
          formatter.format(diagonal.spelledIn(Unit.footInch)),
          '18ft 4-5/8in',
        );
        expect(formatter.format(diagonal.spelledIn(Unit.metre)), '5.6m');
        expect(
          formatter.format(Length.computed(1.9, unit: Unit.inch)),
          'Under 1/16in',
        );
        expect(formatter.format(const Length(2, unit: Unit.inch)), '0-1/16in');
        expect(
          formatter.format(Length.computed(1.9, unit: Unit.footInch)),
          'Under 1/16in',
        );
        expect(
          formatter.format(const Length(2, unit: Unit.footInch)),
          '0ft 0-1/16in',
        );
        expect(
          formatter.format(Length.computed(255.9, unit: Unit.footInch)),
          '0ft 4in',
        );
        expect(formatter.formatStoredLength(diagonal), '220.62in');
      });

      test('18ft 8in as a compound, in inches and in metres', () {
        expect(
          formatter.format(const Length(widthTicks, unit: Unit.footInch)),
          '18ft 8in',
        );
        expect(
          formatter.format(const Length(widthTicks, unit: Unit.inch)),
          '224in',
        );
        expect(
          formatter.format(const Length(widthTicks, unit: Unit.metre)),
          '5.69m',
        );
      });

      test('fractions in inches: 12-1/16in and 0ft 0-7/16in', () {
        expect(
          formatter.format(const Length(772, unit: Unit.inch)),
          '12-1/16in',
        );
        expect(
          formatter.format(const Length(28, unit: Unit.footInch)),
          '0ft 0-7/16in',
        );
      });

      test('reduces the fraction: 12/16 reads 3/4 and 8/16 reads 1/2', () {
        expect(formatter.format(const Length(560, unit: Unit.inch)), '8-3/4in');
        expect(
          formatter.format(const Length(96, unit: Unit.footInch)),
          '0ft 1-1/2in',
        );
      });

      test('a remainder that rounds up to a whole inch carries', () {
        expect(formatter.format(const Length(63, unit: Unit.inch)), '1in');
        expect(
          formatter.format(const Length(767, unit: Unit.footInch)),
          '1ft 0in',
        );
      });

      test('the feet of a compound are never grouped: 4368ft 0in', () {
        expect(
          formatter.format(
            const Length(4368 * Length.ticksPerFoot, unit: Unit.footInch),
          ),
          '4368ft 0in',
        );
      });

      test('inches group their thousands as a result and not as an entry', () {
        const length = Length(200 * Length.ticksPerFoot, unit: Unit.inch);
        expect(formatter.format(length), '2,400in');
        expect(formatter.format(length, groupThousands: false), '2400in');
      });

      test('centimetres keep two decimals', () {
        expect(
          formatter.format(const Length(twentyTwoFeet, unit: Unit.centimetre)),
          '670.56cm',
        );
      });

      test('a negative length carries one sign in front', () {
        expect(
          formatter.format(const Length(-772, unit: Unit.inch)),
          '-12-1/16in',
        );
        expect(
          formatter.format(const Length(-widthTicks, unit: Unit.footInch)),
          '-18ft 8in',
        );
        expect(formatter.format(const Length(-768, unit: Unit.foot)), '-1ft');
      });
    });

    group('CA-1190: a typed length is rendered from its exact value', () {
      test('a typed length near the limit renders in metres and the '
          'conversions instead of throwing', () {
        const huge = Length.exact(Rational(100000000000001), unit: Unit.inch);
        expect(
          formatter.format(huge.spelledIn(Unit.metre)),
          '2,540,000,000,000.03m',
        );
        expect(const UnitConverter().offersFor(huge).map(formatter.format), [
          '8333333333333ft 5in',
          '2,540,000,000,000,026mm',
        ]);
        expect(
          formatter.format(huge.spelledIn(Unit.inch)),
          '100,000,000,000,001in',
        );
      });

      const decimalFeet = Length.exact(Rational(5196, 25), unit: Unit.foot);

      test('17.32 ft reads 17.32ft, and 17ft 3-13/16in as a compound', () {
        expect(formatter.format(decimalFeet), '17.32ft');
        expect(
          formatter.format(decimalFeet.spelledIn(Unit.footInch)),
          '17ft 3-13/16in',
        );
        expect(
          formatter.format(decimalFeet.spelledIn(Unit.inch)),
          '207-13/16in',
        );
      });

      test('a metre typed exactly reads 1m, 100cm and 1,000mm', () {
        const metre = Length.exact(Rational(5000, 127), unit: Unit.metre);
        expect(formatter.format(metre), '1m');
        expect(formatter.format(metre.spelledIn(Unit.centimetre)), '100cm');
        expect(formatter.format(metre.spelledIn(Unit.millimetre)), '1,000mm');
      });

      test('a stored size keeps its typed decimal inch', () {
        const sheet = Length.exact(Rational(1181, 25), unit: Unit.inch);
        expect(formatter.formatStoredLength(sheet), '47.24in');
      });

      test('a negative exact length carries one sign in front', () {
        expect(
          formatter.format(
            const Length.exact(Rational(-5196, 25), unit: Unit.footInch),
          ),
          '-17ft 3-13/16in',
        );
        expect(
          formatter.format(
            const Length.exact(Rational(-433, 25), unit: Unit.inch),
          ),
          '-17-5/16in',
        );
      });

      test('a negative length smaller than the first step is written in '
          'words, never as -0', () {
        const tiny = Rational(-1, 128);
        expect(
          formatter.format(const Length.exact(tiny, unit: Unit.inch)),
          'Below zero',
        );
        expect(
          formatter.format(const Length.exact(tiny, unit: Unit.footInch)),
          'Below zero',
        );
        expect(
          formatter.format(Length.computed(-0.9, unit: Unit.footInch)),
          'Below zero',
        );
        const firstStep = Rational(-1, 16);
        expect(
          formatter.format(const Length.exact(firstStep, unit: Unit.inch)),
          '-0-1/16in',
        );
        expect(
          formatter.format(const Length.exact(firstStep, unit: Unit.footInch)),
          '-0ft 0-1/16in',
        );
      });
    });

    group('CA-1236: a real value under the rounding reads in words', () {
      const tick = Length(1, unit: Unit.footInch);
      const minusTick = Length(-1, unit: Unit.footInch);

      test('Example 2: a compound is Under 1/16in, or Below zero', () {
        expect(formatter.format(tick), 'Under 1/16in');
        expect(formatter.format(minusTick), 'Below zero');
        expect(
          formatter.format(const Length(0, unit: Unit.footInch)),
          '0ft 0in',
        );
        expect(
          formatter.format(const Length(-2, unit: Unit.footInch)),
          '-0ft 0-1/16in',
        );
      });

      test('inches alike, and the step follows the fraction setting', () {
        expect(
          formatter.format(const Length(1, unit: Unit.inch)),
          'Under 1/16in',
        );
        expect(
          formatter.format(const Length(-1, unit: Unit.inch)),
          'Below zero',
        );
        expect(formatter.format(const Length(0, unit: Unit.inch)), '0in');
        const sixtyFourths = QuantityFormatter(
          preferences: CalculatorPreferences(
            fractionResolution: FractionResolution.sixtyFourth,
          ),
        );
        const quarterTick = Length.exact(Rational(1, 256), unit: Unit.footInch);
        expect(sixtyFourths.format(quarterTick), 'Under 1/64in');
        expect(sixtyFourths.format(tick), '0ft 0-1/64in');
      });

      test('a decimal length names the smallest step its unit shows', () {
        expect(
          formatter.format(const Length(1, unit: Unit.foot)),
          'Under 0.01ft',
        );
        expect(
          formatter.format(const Length(-1, unit: Unit.yard)),
          'Below zero',
        );
        expect(
          formatter.format(const Length(1, unit: Unit.millimetre)),
          'Under 1mm',
        );
        const threeDecimals = QuantityFormatter(
          preferences: CalculatorPreferences(
            metreDisplay: MetreDisplay.threeDecimals,
          ),
        );
        const fiftyTicks = Length.exact(Rational(1, 128), unit: Unit.metre);
        expect(threeDecimals.format(fiftyTicks), 'Under 0.001m');
        expect(formatter.format(const Length(0, unit: Unit.foot)), '0ft');
      });

      test('Example 3: an area and a volume, in every unit', () {
        const eighthSquared = Area(64, unit: Unit.foot);
        expect(formatter.format(eighthSquared), 'Under 0.01ft²');
        expect(
          formatter.format(const Area(-64, unit: Unit.metre)),
          'Below zero',
        );
        expect(
          formatter.format(eighthSquared.spelledIn(Unit.acre)),
          'Under 0.0001acre',
        );
        expect(formatter.format(const Area(0, unit: Unit.foot)), '0ft²');
        expect(formatter.format(const Volume(1e-4)), 'Under 0.01ft³');
        expect(
          formatter.format(const Volume(-1e-4, unit: Unit.yard)),
          'Below zero',
        );
        expect(
          formatter.format(const Volume(1e-4, unit: Unit.boardFoot)),
          'Under 0.01bf',
        );
        expect(formatter.format(const Volume(0)), '0ft³');
      });

      test('B5: a weight reads the same way, in every unit', () {
        const thousandthOfAPound = Weight(0.1, unit: Unit.pound);
        expect(formatter.format(thousandthOfAPound), 'Under 0.01lbs');
        expect(
          formatter.format(const Weight(-0.1, unit: Unit.pound)),
          'Below zero',
        );
        expect(formatter.format(const Weight(0, unit: Unit.pound)), '0lbs');
        expect(
          formatter.format(const Weight(200, unit: Unit.ton)),
          'Under 0.01 ton',
          reason: 'two pounds is a thousandth of a ton; the space stays',
        );
        expect(formatter.format(const Weight(0, unit: Unit.ton)), '0 ton');
        expect(
          formatter.format(thousandthOfAPound.spelledIn(Unit.kilogram)),
          'Under 0.01kg',
        );
        expect(
          formatter.format(const Weight(-200, unit: Unit.metricTon)),
          'Below zero',
        );
      });
    });

    group('CA-1236: the largest number a value shows', () {
      test('19,999,999.99 is shown, 20,000,000 is Too large', () {
        expect(formatter.isTooLarge(const Scalar(19999999.99)), isFalse);
        expect(formatter.isTooLarge(const Scalar(20000000)), isTrue);
        expect(formatter.isTooLarge(const Scalar(-20000000)), isTrue);
        expect(formatter.isTooLarge(const Scalar(19999999.98 + 0.01)), isFalse);
        expect(formatter.isTooLarge(const Scalar(double.infinity)), isTrue);
      });

      test('a very large negative value is too large before it is written, '
          'whatever its kind', () {
        expect(formatter.isTooLarge(const Scalar(-1e40)), isTrue);
        expect(
          formatter.isTooLarge(const Length(-(1 << 53), unit: Unit.foot)),
          isTrue,
        );
        expect(formatter.isTooLarge(const Area(-1e40)), isTrue);
        expect(formatter.isTooLarge(const Volume(-1e40)), isTrue);
        expect(formatter.isTooLarge(const Weight(-1e40)), isTrue);
        expect(formatter.isTooLarge(const Angle(-1e40)), isTrue);
        expect(
          formatter.isTooLarge(const Volume(-1e40, unit: Unit.yard)),
          isTrue,
        );
        expect(
          formatter.isTooLarge(const Weight(-1e40, unit: Unit.ton)),
          isTrue,
        );
        for (final infinite in [
          const Area(double.infinity),
          const Volume(double.infinity),
          const Weight(double.infinity),
          const Angle(double.negativeInfinity),
        ]) {
          expect(formatter.isTooLarge(infinite), isTrue, reason: '$infinite');
        }
      });

      test('in the unit the value is written in', () {
        const feet = 20000000 * Length.ticksPerFoot;
        expect(
          formatter.isTooLarge(const Length(feet, unit: Unit.foot)),
          isTrue,
        );
        expect(
          formatter.isTooLarge(const Length(feet, unit: Unit.footInch)),
          isTrue,
        );
        expect(
          formatter.isTooLarge(
            const Length(feet - Length.ticksPerFoot, unit: Unit.footInch),
          ),
          isFalse,
        );
        expect(
          formatter.isTooLarge(const Length(feet, unit: Unit.yard)),
          isFalse,
        );
        expect(
          formatter.isTooLarge(
            const Area(2e7 * squareTicksPerSquareFoot, unit: Unit.foot),
          ),
          isTrue,
        );
        expect(
          formatter.isTooLarge(
            const Area(2e7 * squareTicksPerSquareFoot, unit: Unit.yard),
          ),
          isFalse,
        );
        expect(
          formatter.isTooLarge(
            const Area(2e7 * squareTicksPerSquareFoot, unit: Unit.acre),
          ),
          isFalse,
        );
        expect(formatter.isTooLarge(const Volume(2e7)), isTrue);
        expect(
          formatter.isTooLarge(const Volume(2e7, unit: Unit.yard)),
          isFalse,
        );
        expect(
          formatter.isTooLarge(const Volume(2e6, unit: Unit.boardFoot)),
          isTrue,
        );
        expect(formatter.isTooLarge(const Weight(2e9)), isTrue);
        expect(
          formatter.isTooLarge(const Weight(2e9, unit: Unit.ton)),
          isFalse,
        );
        expect(formatter.isTooLarge(const Angle(2e7)), isTrue);
        expect(formatter.isTooLarge(const Angle(19999999)), isFalse);
      });

      test('on the number the formatter writes, at its own rounding', () {
        Length typed(String number, Unit unit) {
          final value = Rational.tryParse(number);
          if (value == null) throw StateError('$number is not a number');
          return Length.exact(value * unit.inchesPer, unit: unit);
        }

        final millimetres = typed('19999999.6', Unit.millimetre);
        expect(formatter.format(millimetres), '20,000,000mm');
        expect(formatter.isTooLarge(millimetres), isTrue);
        const inches = Length(19999999 * 64 + 63, unit: Unit.inch);
        expect(formatter.format(inches), '20,000,000in');
        expect(formatter.isTooLarge(inches), isTrue);
        const halfInch = QuantityFormatter(
          preferences: CalculatorPreferences(
            fractionResolution: FractionResolution.half,
          ),
        );
        const feetInches = Length(
          19999999 * Length.ticksPerFoot + 11 * 64 + 48,
          unit: Unit.footInch,
        );
        expect(halfInch.format(feetInches), '20000000ft 0in');
        expect(halfInch.isTooLarge(feetInches), isTrue);
        expect(formatter.isTooLarge(feetInches), isFalse);
        const oneDecimal = QuantityFormatter(
          preferences: CalculatorPreferences(
            metreDisplay: MetreDisplay.oneDecimal,
          ),
        );
        final metres = typed('19999999.96', Unit.metre);
        expect(oneDecimal.isTooLarge(metres), isTrue);
        expect(formatter.isTooLarge(metres), isFalse);
        final justUnder = typed(
          '239999999.95',
          Unit.inch,
        ).spelledIn(Unit.footInch);
        expect(formatter.format(justUnder), '19999999ft 11-15/16in');
        expect(formatter.isTooLarge(justUnder), isFalse);
        expect(formatter.format(const Scalar(-19999999.995)), '-19,999,999.99');
        expect(formatter.isTooLarge(const Scalar(-19999999.995)), isFalse);
        expect(formatter.isTooLarge(const Scalar(-19999999.996)), isTrue);
      });

      test('a value past 2⁶³ is too large though its text is not', () {
        expect(formatter.isTooLarge(const Area(1e40)), isTrue);
        expect(formatter.isTooLarge(const Scalar(1e22)), isTrue);
        expect(formatter.isTooLarge(const Scalar(double.nan)), isTrue);
      });
    });

    group('fractional resolution, one row per setting', () {
      const tenInchesOverThree = Length(213, unit: Unit.footInch);

      test('10in ÷ 3 at every step from 1/2 to 1/64', () {
        const expected = {
          FractionResolution.half: '0ft 3-1/2in',
          FractionResolution.quarter: '0ft 3-1/4in',
          FractionResolution.eighth: '0ft 3-3/8in',
          FractionResolution.sixteenth: '0ft 3-5/16in',
          FractionResolution.thirtySecond: '0ft 3-11/32in',
          FractionResolution.sixtyFourth: '0ft 3-21/64in',
        };
        for (final entry in expected.entries) {
          final rendered = QuantityFormatter(
            preferences: CalculatorPreferences(fractionResolution: entry.key),
          ).format(tenInchesOverThree);
          expect(rendered, entry.value, reason: entry.key.name);
        }
      });
    });

    group('metre display, one row per setting', () {
      test('22ft in metres at 0.0, 0.00 and 0.000', () {
        const expected = {
          MetreDisplay.oneDecimal: '6.7m',
          MetreDisplay.twoDecimals: '6.71m',
          MetreDisplay.threeDecimals: '6.706m',
        };
        for (final entry in expected.entries) {
          final rendered = QuantityFormatter(
            preferences: CalculatorPreferences(metreDisplay: entry.key),
          ).format(const Length(twentyTwoFeet, unit: Unit.metre));
          expect(rendered, entry.value, reason: entry.key.name);
        }
      });
    });

    group('areas', () {
      const lot = Area(16000.0 * squareTicksPerSquareFoot);

      test('410.67ft² from 22ft × 18ft 8in', () {
        expect(
          formatter.format(const Area(twentyTwoFeet * widthTicks * 1.0)),
          '410.67ft²',
        );
      });

      test('16,000ft² and its offered spellings', () {
        expect(formatter.format(lot), '16,000ft²');
        expect(formatter.format(lot.spelledIn(Unit.yard)), '1,777.78yd²');
        expect(formatter.format(lot.spelledIn(Unit.inch)), '2,304,000in²');
        expect(formatter.format(lot.spelledIn(Unit.metre)), '1,486.45m²');
        expect(formatter.format(lot.spelledIn(Unit.acre)), '0.3673acre');
      });

      test('a tiny area reads in words in a big unit', () {
        const twoSquareInches = Area(
          2.0 * Area.squareTicksPerSquareInch,
          unit: Unit.inch,
        );
        expect(formatter.format(twoSquareInches), '2in²');
        expect(
          formatter.format(twoSquareInches.spelledIn(Unit.yard)),
          'Under 0.01yd²',
        );
      });
    });

    group('volumes', () {
      test(
        '136.88ft³, and the same volume in yards, metres and board feet',
        () {
          const volume = Volume(136.8833333);
          expect(formatter.format(volume), '136.88ft³');
          expect(formatter.format(volume.spelledIn(Unit.yard)), '5.07yd³');
          expect(formatter.format(volume.spelledIn(Unit.metre)), '3.88m³');
          expect(
            formatter.format(volume.spelledIn(Unit.boardFoot)),
            '1,642.6bf',
          );
        },
      );

      test('2,106ft³ groups its thousands', () {
        expect(formatter.format(const Volume(2106)), '2,106ft³');
      });
    });

    group('weights', () {
      const seventyEightPounds = Weight(7800, unit: Unit.pound);

      test('78lbs and its offered spellings', () {
        expect(formatter.format(seventyEightPounds), '78lbs');
        expect(
          formatter.format(seventyEightPounds.spelledIn(Unit.kilogram)),
          '35.38kg',
        );
        expect(
          formatter.format(seventyEightPounds.spelledIn(Unit.ton)),
          '0.04 ton',
        );
      });

      test('a metric ton takes its space and its plural', () {
        expect(
          formatter.format(const Weight(12 * 220462.262, unit: Unit.metricTon)),
          '12 m tons',
        );
      });

      test('6.5lbs after 78lbs ÷ 12', () {
        expect(formatter.format(const Weight(650, unit: Unit.pound)), '6.5lbs');
      });
    });

    group('pounds per ton, one row per setting', () {
      test('re-renders 22.28 ton as 19.89 ton without changing the weight', () {
        const weight = Weight(22.28 * 2000 * 100, unit: Unit.ton);
        const expected = {
          TonDefinition.shortTon: '22.28 ton',
          TonDefinition.longTon: '19.89 ton',
        };
        for (final entry in expected.entries) {
          final rendered = QuantityFormatter(
            preferences: CalculatorPreferences(tonDefinition: entry.key),
          ).format(weight);
          expect(rendered, entry.value, reason: entry.key.name);
        }
      });
    });

    group('angles and scalars', () {
      test('degrees keep two decimals', () {
        expect(formatter.format(const Angle(26.5651)), '26.57°');
        expect(formatter.format(const Angle(90)), '90°');
      });

      test('a pitch reads as inches per 12in of run or as a grade (C3)', () {
        const sixteenInTwelve = Angle(53.13010235415598);
        expect(
          formatter.format(
            sixteenInTwelve.spelledAs(AngleSpelling.risePerFoot),
          ),
          '16in/12in',
        );
        expect(
          formatter.format(sixteenInTwelve.spelledAs(AngleSpelling.grade)),
          '133.3%',
        );
        const sevenPercent = Angle(4.004362249);
        expect(formatter.format(sevenPercent), '4°');
        expect(
          formatter.format(sevenPercent.spelledAs(AngleSpelling.risePerFoot)),
          '13/16in/12in',
        );
        expect(
          formatter.format(sevenPercent.spelledAs(AngleSpelling.grade)),
          '7%',
        );
        expect(
          formatter.format(
            const Angle(26.56505117707799, spelling: AngleSpelling.grade),
          ),
          '50%',
        );
      });

      group('degrees, minutes and seconds, as a survey sheet writes them', () {
        String dms(double degrees) => formatter.format(
          Angle(degrees, spelling: AngleSpelling.degreesMinutesSeconds),
        );
        double degreesOf(double radians) => radians * 180 / math.pi;

        test(
          'S107: a whole-degree answer keeps its minutes, zero included',
          () {
            expect(dms(0), '0°00\'00"');
            expect(dms(degreesOf(math.asin(0.5))), '30°00\'00"');
          },
        );

        test('S107: seconds show when there are some, both spellings', () {
          final arctangent = degreesOf(math.atan(12 / 23));
          expect(formatter.format(Angle(arctangent)), '27.55°');
          expect(dms(arctangent), '27°33\'10"');
        });

        test('S108 and walkthrough 16.3: the answer, written both ways', () {
          expect(dms(degreesOf(math.atan(0.12))), '6°50\'34"');
          expect(dms(degreesOf(math.asin(12 / 23))), '31°26\'56"');
          expect(dms(38 + 30 / 60 + 45 / 3600), '38°30\'45"');
        });

        test('pads minutes and seconds to two digits, never degrees', () {
          expect(dms(45.0333), '45°02\'00"');
          expect(dms(5 + 5 / 60 + 5 / 3600), '5°05\'05"');
          expect(dms(120), '120°00\'00"');
        });

        test('rounds to the nearest second and carries into the degree', () {
          expect(dms(29.99999), '30°00\'00"');
          expect(dms(29.5 / 3600 + 10), '10°00\'30"');
        });

        test('a negative angle carries the prototype\'s minus sign', () {
          expect(dms(-30.5), '-30°30\'00"');
        });

        test('a negative angle that rounds to zero reads 0°00\'00"', () {
          expect(dms(-0.00001), '0°00\'00"');
        });

        test('a negative angle takes a hyphen in both spellings', () {
          expect(dms(-31.448981389379565), '-31°26\'56"');
          expect(
            const QuantityFormatter().format(const Angle(-38.5)),
            '-38.5°',
          );
        });

        test('groups the thousands of the degrees as a result, not as an '
            'entry', () {
          expect(dms(1234.5), '1,234°30\'00"');
          expect(
            formatter.format(
              const Angle(
                1234.5,
                spelling: AngleSpelling.degreesMinutesSeconds,
              ),
              groupThousands: false,
            ),
            '1234°30\'00"',
          );
        });

        test('a very large angle reads the same whole degrees in both '
            'spellings', () {
          expect(
            formatter.format(const Angle(1e16)),
            '10,000,000,000,000,000°',
          );
          expect(dms(1e16), '10,000,000,000,000,000°00\'00"');
          expect(dms(1e12 + 0.5), '1,000,000,000,000°30\'00"');
        });
      });

      test('a scalar keeps two decimals and groups: 78 × 56 = 4,368', () {
        expect(formatter.format(const Scalar(4368)), '4,368');
        expect(formatter.format(const Scalar(3)), '3');
        expect(formatter.format(const Scalar(62.5)), '62.5');
      });

      test('a ratio below 0.1 keeps two significant digits', () {
        expect(formatter.format(const Scalar(1 / 78)), '0.013');
        expect(formatter.format(const Scalar(0.0029)), '0.0029');
        expect(formatter.format(const Scalar(-0.0129)), '-0.013');
      });

      test('zero reads 0', () {
        expect(formatter.format(const Scalar(0)), '0');
      });
    });

    group('stored sizes, one row per system', () {
      const sheetWidth = Length(48 * Length.ticksPerInch, unit: Unit.inch);
      const metricSheet = Length(3023, unit: Unit.inch);

      test(
        'render in inches under Imperial and whole millimetres under Metric',
        () {
          const expected = {
            MeasurementSystem.imperial: ('48in', '47.23in'),
            MeasurementSystem.metric: ('1219mm', '1200mm'),
          };
          for (final entry in expected.entries) {
            final sized = QuantityFormatter(
              preferences: CalculatorPreferences(system: entry.key),
            );
            expect(
              sized.formatStoredLength(sheetWidth),
              entry.value.$1,
              reason: entry.key.name,
            );
            expect(
              sized.formatStoredLength(metricSheet),
              entry.value.$2,
              reason: entry.key.name,
            );
          }
        },
      );

      test('never group their thousands', () {
        expect(
          formatter.formatStoredLength(
            const Length(2400 * Length.ticksPerInch, unit: Unit.inch),
          ),
          '2400in',
        );
      });
    });

    group('densities, one row per unit', () {
      test('4,050 lbs/yd³ of concrete in every display unit', () {
        const expected = {
          DensityUnit.poundsPerCubicYard: '4,050lbs/yd³',
          DensityUnit.poundsPerCubicFoot: '150lbs/ft³',
          DensityUnit.tonsPerCubicYard: '2.03tons/yd³',
          DensityUnit.kilogramsPerCubicMetre: '2,403kg/m³',
        };
        for (final entry in expected.entries) {
          final rendered = QuantityFormatter(
            preferences: CalculatorPreferences(densityUnit: entry.key),
          ).formatDensity(4050);
          expect(rendered, entry.value, reason: entry.key.name);
        }
      });

      test('tons per cubic yard follow the ton definition', () {
        const longTon = QuantityFormatter(
          preferences: CalculatorPreferences(
            densityUnit: DensityUnit.tonsPerCubicYard,
            tonDefinition: TonDefinition.longTon,
          ),
        );
        expect(longTon.formatDensity(4480), '2tons/yd³');
      });
    });

    group('number spelling', () {
      test(
        'rounds half away from zero on the decimal spelling, as ICU does',
        () {
          expect(
            formatter.format(const Weight(100.5, unit: Unit.pound)),
            '1.01lbs',
          );
          expect(
            formatter.format(const Weight(267.5, unit: Unit.pound)),
            '2.68lbs',
          );
        },
      );

      test('carries a round-up through every nine', () {
        expect(
          formatter.format(const Weight(99999.5, unit: Unit.pound)),
          '1,000lbs',
        );
        expect(
          formatter.format(const Length(230398, unit: Unit.yard)),
          '100yd',
        );
      });

      test('drops trailing zeros and a trailing point', () {
        expect(formatter.format(const Scalar(1.5)), '1.5');
        expect(formatter.format(const Scalar(100)), '100');
      });

      test('writes a number too small for a plain spelling in words', () {
        expect(
          formatter.format(const Weight(1e-5, unit: Unit.pound)),
          'Under 0.01lbs',
        );
        expect(
          formatter.format(const Length(1, unit: Unit.metre)),
          'Under 0.01m',
        );
      });
    });

    test('is equal to another formatter with equal preferences', () {
      final resolution = FractionResolution.values[int.parse('3')];
      expect(
        QuantityFormatter(
          preferences: CalculatorPreferences(fractionResolution: resolution),
        ),
        formatter,
      );
    });
  });
}
