import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';

/// The words the calculator page shows for its settings (UX Design Doc
/// term 2.20, Appendix C): the face of the System of units pill and what a
/// tap on it does; the setting sheets' titles and options follow (4/4).
class CalculatorSettingFormatter {
  /// The translations the words come from.
  final AppLocalizations l10n;

  const CalculatorSettingFormatter(this.l10n);

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
