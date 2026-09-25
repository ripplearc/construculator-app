import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorPreferences', () {
    test('defaults to Imperial, 1/16, 0.00, 2,000 lb and lbs/yd³', () {
      const preferences = CalculatorPreferences.defaults;
      expect(preferences.system, MeasurementSystem.imperial);
      expect(preferences.fractionResolution, FractionResolution.sixteenth);
      expect(preferences.metreDisplay, MetreDisplay.twoDecimals);
      expect(preferences.tonDefinition, TonDefinition.shortTon);
      expect(preferences.densityUnit, DensityUnit.poundsPerCubicYard);
      expect(preferences.poundsPerTon, 2000);
    });

    test('reads the long ton as 2,240 pounds', () {
      const preferences = CalculatorPreferences(
        tonDefinition: TonDefinition.longTon,
      );
      expect(preferences.poundsPerTon, 2240);
    });

    test('copyWith replaces the given settings and keeps the rest', () {
      final changed = CalculatorPreferences.defaults.copyWith(
        system: MeasurementSystem.metric,
        fractionResolution: FractionResolution.half,
        metreDisplay: MetreDisplay.threeDecimals,
        tonDefinition: TonDefinition.longTon,
        densityUnit: DensityUnit.kilogramsPerCubicMetre,
      );
      expect(
        changed,
        const CalculatorPreferences(
          system: MeasurementSystem.metric,
          fractionResolution: FractionResolution.half,
          metreDisplay: MetreDisplay.threeDecimals,
          tonDefinition: TonDefinition.longTon,
          densityUnit: DensityUnit.kilogramsPerCubicMetre,
        ),
      );
      expect(changed.copyWith(), changed);
    });

    test('is equal to another with the same five settings', () {
      // Built through copyWith so the instance is not a compile-time
      // constant: two equal const values are one object and Equatable would
      // answer on identical() without ever comparing the fields.
      final halves = CalculatorPreferences.defaults.copyWith(
        fractionResolution: FractionResolution.half,
      );
      expect(
        halves,
        const CalculatorPreferences(
          fractionResolution: FractionResolution.half,
        ),
      );
      expect(
        const CalculatorPreferences(
          fractionResolution: FractionResolution.half,
        ),
        isNot(equals(CalculatorPreferences.defaults)),
      );
    });

    test('lists the six fraction steps from 1/2 to 1/64', () {
      expect(FractionResolution.values.map((r) => r.denominator), [
        2,
        4,
        8,
        16,
        32,
        64,
      ]);
    });

    test('lists the three metre displays', () {
      expect(MetreDisplay.values.map((m) => m.decimals), [1, 2, 3]);
    });

    test(
      'renders densities in lbs/yd³ under Imperial and kg/m³ under Metric',
      () {
        expect(
          DensityUnit.defaultFor(MeasurementSystem.imperial),
          DensityUnit.poundsPerCubicYard,
        );
        expect(
          DensityUnit.defaultFor(MeasurementSystem.metric),
          DensityUnit.kilogramsPerCubicMetre,
        );
      },
    );
  });
}
