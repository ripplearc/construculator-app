import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';

/// The words the calculator page shows for its settings (UX Design Doc
/// term 2.20, Appendix C): a setting sheet's title, each of its options,
/// and the face of the System of units pill. The bloc names a setting and
/// its options by their stable ids; this is where they become text.
class CalculatorSettingFormatter {
  /// The translations the words come from.
  final AppLocalizations l10n;

  const CalculatorSettingFormatter(this.l10n);

  /// The name of a setting: the sheet's title and the toast's.
  String title(CalculatorSetting setting) => switch (setting) {
    CalculatorSetting.fractionResolution =>
      l10n.calculatorSettingFractionResolution,
    CalculatorSetting.tonDefinition => l10n.calculatorSettingPoundsPerTon,
    CalculatorSetting.metreDisplay => l10n.calculatorSettingMeterLengthDisplay,
    CalculatorSetting.densityUnit => l10n.calculatorSettingDensityDisplayUnit,
  };

  /// The label of one option of [setting], by the id the bloc names it
  /// with ([CalculatorSetting.optionIds]).
  String optionLabel(CalculatorSetting setting, String optionId) =>
      switch (setting) {
        CalculatorSetting.fractionResolution => l10n.calculatorOptionFraction(
          FractionResolution.values.byName(optionId).denominator,
        ),
        CalculatorSetting.tonDefinition => switch (TonDefinition.values.byName(
          optionId,
        )) {
          TonDefinition.shortTon => l10n.calculatorOptionShortTon,
          TonDefinition.longTon => l10n.calculatorOptionLongTon,
        },
        CalculatorSetting.metreDisplay => switch (MetreDisplay.values.byName(
          optionId,
        )) {
          MetreDisplay.oneDecimal => l10n.calculatorOptionMetreOneDecimal,
          MetreDisplay.twoDecimals => l10n.calculatorOptionMetreTwoDecimals,
          MetreDisplay.threeDecimals => l10n.calculatorOptionMetreThreeDecimals,
        },
        CalculatorSetting.densityUnit => switch (DensityUnit.values.byName(
          optionId,
        )) {
          DensityUnit.poundsPerCubicYard =>
            l10n.calculatorOptionDensityPoundsPerCubicYard,
          DensityUnit.poundsPerCubicFoot =>
            l10n.calculatorOptionDensityPoundsPerCubicFoot,
          DensityUnit.tonsPerCubicYard =>
            l10n.calculatorOptionDensityTonsPerCubicYard,
          DensityUnit.kilogramsPerCubicMetre =>
            l10n.calculatorOptionDensityKilogramsPerCubicMetre,
        },
      };

  /// The face of the System of units pill: the system in force.
  String unitsLabel(MeasurementSystem system) => switch (system) {
    MeasurementSystem.imperial => l10n.calculatorUnitsImperial,
    MeasurementSystem.metric => l10n.calculatorUnitsMetric,
  };

  /// What a tap on the System of units pill does, for a screen reader.
  String unitsHint(MeasurementSystem system) => switch (system) {
    MeasurementSystem.imperial => l10n.calculatorUnitsSwitchToMetric,
    MeasurementSystem.metric => l10n.calculatorUnitsSwitchToImperial,
  };
}
