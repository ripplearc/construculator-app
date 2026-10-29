import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_setting_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final settings = CalculatorSettingFormatter(l10n);

  group('CalculatorSettingFormatter', () {
    test('each setting is titled from i18n', () {
      expect(
        {
          for (final setting in CalculatorSetting.values)
            setting: settings.title(setting),
        },
        {
          CalculatorSetting.fractionResolution:
              l10n.calculatorSettingFractionResolution,
          CalculatorSetting.tonDefinition: l10n.calculatorSettingPoundsPerTon,
          CalculatorSetting.metreDisplay:
              l10n.calculatorSettingMeterLengthDisplay,
          CalculatorSetting.densityUnit:
              l10n.calculatorSettingDensityDisplayUnit,
        },
      );
    });

    test('each fraction option is named by its denominator', () {
      expect(
        [
          for (final id in CalculatorSetting.fractionResolution.optionIds)
            settings.optionLabel(CalculatorSetting.fractionResolution, id),
        ],
        [
          for (final resolution in FractionResolution.values)
            l10n.calculatorOptionFraction(resolution.denominator),
        ],
      );
    });

    test('each ton, metre and density option is named from i18n', () {
      String label(CalculatorSetting setting, Enum option) =>
          settings.optionLabel(setting, option.name);

      expect(
        [
          for (final option in TonDefinition.values)
            label(CalculatorSetting.tonDefinition, option),
        ],
        [l10n.calculatorOptionShortTon, l10n.calculatorOptionLongTon],
      );
      expect(
        [
          for (final option in MetreDisplay.values)
            label(CalculatorSetting.metreDisplay, option),
        ],
        [
          l10n.calculatorOptionMetreOneDecimal,
          l10n.calculatorOptionMetreTwoDecimals,
          l10n.calculatorOptionMetreThreeDecimals,
        ],
      );
      expect(
        [
          for (final option in DensityUnit.values)
            label(CalculatorSetting.densityUnit, option),
        ],
        [
          l10n.calculatorOptionDensityPoundsPerCubicYard,
          l10n.calculatorOptionDensityPoundsPerCubicFoot,
          l10n.calculatorOptionDensityTonsPerCubicYard,
          l10n.calculatorOptionDensityKilogramsPerCubicMetre,
        ],
      );
    });

    test('an option id the setting does not know is refused', () {
      expect(
        () => settings.optionLabel(CalculatorSetting.tonDefinition, 'tonne'),
        throwsArgumentError,
      );
    });

    test('the units pill is named by the system and says what a tap does', () {
      expect(
        settings.unitsLabel(MeasurementSystem.imperial),
        l10n.calculatorUnitsImperial,
      );
      expect(
        settings.unitsLabel(MeasurementSystem.metric),
        l10n.calculatorUnitsMetric,
      );
      expect(
        settings.unitsHint(MeasurementSystem.imperial),
        l10n.calculatorUnitsSwitchToMetric,
      );
      expect(
        settings.unitsHint(MeasurementSystem.metric),
        l10n.calculatorUnitsSwitchToImperial,
      );
    });
  });
}
