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

      test('a tiny area reads 0 in a big unit', () {
        const twoSquareInches = Area(
          2.0 * Area.squareTicksPerSquareInch,
          unit: Unit.inch,
        );
        expect(formatter.format(twoSquareInches), '2in²');
        expect(formatter.format(twoSquareInches.spelledIn(Unit.yard)), '0yd²');
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

      test('writes a number too small for a plain spelling as 0', () {
        expect(formatter.format(const Weight(1e-5, unit: Unit.pound)), '0lbs');
        expect(formatter.format(const Length(1, unit: Unit.metre)), '0m');
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
