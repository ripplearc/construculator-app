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

      test(
        'reads the prototype\'s keys, so an old profile migrates on read',
        () {
          final dto = CalculatorPreferencesDto.fromJson({
            'system': 'metric',
            'fracRes': 8,
            'meterDp': 1,
            'lbsTon': 2240,
            'denUnit': 'ton_yd3',
            'lenFormat': 'std',
            'mmDp': 0,
            'strip': 'tworow',
            'editStyle': 'recompute',
            'v': 2,
          });
          expect(
            dto.preferences,
            const CalculatorPreferences(
              system: MeasurementSystem.metric,
              fractionResolution: FractionResolution.eighth,
              metreDisplay: MetreDisplay.oneDecimal,
              tonDefinition: TonDefinition.longTon,
              densityUnit: DensityUnit.tonsPerCubicYard,
            ),
          );
        },
      );

      test('prefers the new key when both spellings are present', () {
        final dto = CalculatorPreferencesDto.fromJson({
          'fractional_resolution': 64,
          'fracRes': 8,
        });
        expect(
          dto.preferences.fractionResolution,
          FractionResolution.sixtyFourth,
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

      test('a legacy density key that cannot be read follows the system', () {
        final dto = CalculatorPreferencesDto.fromJson({'denUnit': 'slugs'});
        expect(dto.preferences.densityUnit, DensityUnit.poundsPerCubicYard);
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
