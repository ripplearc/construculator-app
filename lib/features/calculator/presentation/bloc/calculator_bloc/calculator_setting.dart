part of 'calculator_bloc.dart';

/// The four settings a setting sheet changes (UX Design Doc term 2.20,
/// Appendix C): one single-choice list each, and an Update button. The
/// fifth setting, the System of units, is a pill on the empty tape row
/// with no sheet.
enum CalculatorSetting {
  /// The step a fraction of an inch rounds to: 1/2 … 1/64.
  fractionResolution,

  /// How many pounds make a ton: 2,000 lb or 2,240 lb.
  tonDefinition,

  /// The decimals of a length shown in metres: 0.0, 0.00 or 0.000.
  metreDisplay,

  /// The unit densities render in: lbs/yd³, lbs/ft³, tons/yd³ or kg/m³.
  densityUnit;

  /// The ids of the sheet's options, in the order the sheet lists them:
  /// the names of the setting's values.
  List<String> get optionIds => switch (this) {
    fractionResolution => [for (final v in FractionResolution.values) v.name],
    tonDefinition => [for (final v in TonDefinition.values) v.name],
    metreDisplay => [for (final v in MetreDisplay.values) v.name],
    densityUnit => [for (final v in DensityUnit.values) v.name],
  };

  /// The id of the option [preferences] holds for this setting.
  String selectedOptionId(CalculatorPreferences preferences) => switch (this) {
    fractionResolution => preferences.fractionResolution.name,
    tonDefinition => preferences.tonDefinition.name,
    metreDisplay => preferences.metreDisplay.name,
    densityUnit => preferences.densityUnit.name,
  };

  /// [preferences] with this setting set to the option [optionId] names.
  /// Throws an [ArgumentError] for an id that is not one of [optionIds].
  CalculatorPreferences applied(
    CalculatorPreferences preferences,
    String optionId,
  ) => switch (this) {
    fractionResolution => preferences.copyWith(
      fractionResolution: FractionResolution.values.byName(optionId),
    ),
    tonDefinition => preferences.copyWith(
      tonDefinition: TonDefinition.values.byName(optionId),
    ),
    metreDisplay => preferences.copyWith(
      metreDisplay: MetreDisplay.values.byName(optionId),
    ),
    densityUnit => preferences.copyWith(
      densityUnit: DensityUnit.values.byName(optionId),
    ),
  };
}
