import 'package:construculator/features/calculator/data/models/calculator_preferences_dto.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorPreferencesDto', () {
    group('fromJson', () {
      test(
        'reads the defaults from nothing, or from anything that is not a map',
        () {
          expect(
            CalculatorPreferencesDto.fromJson(null).preferences,
            CalculatorPreferences.defaults,
          );
          expect(
            CalculatorPreferencesDto.fromJson('imperial').preferences,
            CalculatorPreferences.defaults,
          );
        },
      );

      test('reads every setting in the shape it writes', () {
        const preferences = CalculatorPreferences(
          system: MeasurementSystem.metric,
          fractionResolution: FractionResolution.thirtySecond,
          metreDisplay: MetreDisplay.threeDecimals,
          tonDefinition: TonDefinition.longTon,
          densityUnit: DensityUnit.poundsPerCubicFoot,
        );
        final json = const CalculatorPreferencesDto(preferences).toJson();
        expect(
          CalculatorPreferencesDto.fromJson(json).preferences,
          preferences,
        );
      });

      test('reads only the keys it writes, so a stray key changes nothing', () {
        final dto = CalculatorPreferencesDto.fromJson({
          'fracRes': 8,
          'lenFormat': 'std',
          'fractional_resolution': 64,
        });
        expect(
          dto.preferences,
          const CalculatorPreferences(
            system: MeasurementSystem.imperial,
            fractionResolution: FractionResolution.sixtyFourth,
            metreDisplay: MetreDisplay.twoDecimals,
            tonDefinition: TonDefinition.shortTon,
            densityUnit: DensityUnit.poundsPerCubicYard,
          ),
        );
      });

      test('falls back to the default for a value it cannot read', () {
        final dto = CalculatorPreferencesDto.fromJson({
          'system': 'cubits',
          'fractional_resolution': 7,
          'metre_display': 'many',
          'pounds_per_ton': 1000,
          'density_unit': 'stones',
        });
        expect(dto.preferences, CalculatorPreferences.defaults);
      });

      test(
        'renders densities in kg/m³ for a metric profile with no density key',
        () {
          final dto = CalculatorPreferencesDto.fromJson({'system': 'metric'});
          expect(
            dto.preferences.densityUnit,
            DensityUnit.kilogramsPerCubicMetre,
          );
          expect(dto.preferences.system, MeasurementSystem.metric);
        },
      );

      test('a density unit that cannot be read follows the system', () {
        final imperial = CalculatorPreferencesDto.fromJson({
          'density_unit': 'slugs',
        });
        expect(
          imperial.preferences.densityUnit,
          DensityUnit.poundsPerCubicYard,
        );
        final metric = CalculatorPreferencesDto.fromJson({
          'system': 'metric',
          'density_unit': 'slugs',
        });
        expect(
          metric.preferences.densityUnit,
          DensityUnit.kilogramsPerCubicMetre,
        );
      });
    });

    group('toJson', () {
      test(
        'writes the five settings under snake_case keys and nothing else',
        () {
          expect(
            const CalculatorPreferencesDto(
              CalculatorPreferences.defaults,
            ).toJson(),
            {
              'system': 'imperial',
              'fractional_resolution': 16,
              'metre_display': 2,
              'pounds_per_ton': 2000,
              'density_unit': 'poundsPerCubicYard',
            },
          );
        },
      );
    });

    test('pins the stored name of every density unit', () {
      const stored = {
        DensityUnit.poundsPerCubicYard: 'poundsPerCubicYard',
        DensityUnit.poundsPerCubicFoot: 'poundsPerCubicFoot',
        DensityUnit.tonsPerCubicYard: 'tonsPerCubicYard',
        DensityUnit.kilogramsPerCubicMetre: 'kilogramsPerCubicMetre',
      };
      expect(stored.keys, containsAll(DensityUnit.values));
      for (final entry in stored.entries) {
        final json = CalculatorPreferencesDto(
          CalculatorPreferences(
            system: MeasurementSystem.imperial,
            fractionResolution: FractionResolution.sixteenth,
            metreDisplay: MetreDisplay.twoDecimals,
            tonDefinition: TonDefinition.shortTon,
            densityUnit: entry.key,
          ),
        ).toJson();
        expect(json['density_unit'], entry.value);
        expect(
          CalculatorPreferencesDto.fromJson(json).preferences.densityUnit,
          entry.key,
        );
      }
    });

    test('names the key it lives under', () {
      expect(CalculatorPreferencesDto.preferencesKey, 'calculator');
    });

    test('is equal to another dto of the same settings', () {
      final dto = CalculatorPreferencesDto.fromJson(<String, Object>{});
      expect(
        dto,
        const CalculatorPreferencesDto(CalculatorPreferences.defaults),
      );
    });
  });
}
