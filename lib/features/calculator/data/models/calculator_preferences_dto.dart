import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:equatable/equatable.dart';

/// The JSON shape of the five calculator settings under the `calculator`
/// key of `users.user_preferences`.
///
/// The keys are the snake_case names of the settings, and a save writes
/// those five keys and nothing else. There is no older spelling to read: no
/// profile carries a `calculator` key yet, and the prototype kept its
/// settings in the browser's local storage, never in a profile, so the
/// migration CA-1085 allows for has nothing to migrate.
///
/// A value that is missing or unreadable falls back to the default, and an
/// unreadable one is logged: a setting only changes how values render
/// (rule 4.14), so a bad one can never corrupt a calculation. The fallback
/// is what the next save writes, so a value this build cannot read — a
/// density unit or a key a later build adds — is replaced by this build's
/// default the next time this build saves; the warning is how such a write
/// is found.
class CalculatorPreferencesDto extends Equatable {
  static final _logger = AppLogger().tag('CalculatorPreferencesDto');

  /// The key under `user_preferences` that holds the calculator settings.
  static const String preferencesKey = 'calculator';

  /// The system of units: `imperial` or `metric`.
  static const String systemKey = 'system';

  /// The fraction step as its denominator: 2, 4, 8, 16, 32 or 64.
  static const String fractionResolutionKey = 'fractional_resolution';

  /// The decimals of a length shown in metres: 1, 2 or 3.
  static const String metreDisplayKey = 'metre_display';

  /// Pounds in a ton: 2000 or 2240.
  static const String poundsPerTonKey = 'pounds_per_ton';

  /// The density display unit by name.
  static const String densityUnitKey = 'density_unit';

  /// The settings this JSON stands for.
  final CalculatorPreferences preferences;

  const CalculatorPreferencesDto(this.preferences);

  /// Reads the `calculator` value of a profile's `user_preferences`; `null`
  /// or anything that is not a map is the defaults of a fresh install, with
  /// the density unit of the system read.
  factory CalculatorPreferencesDto.fromJson(Object? json) {
    if (json is! Map) {
      return const CalculatorPreferencesDto(CalculatorPreferences.defaults);
    }
    final system = _enumByName(
      MeasurementSystem.values,
      systemKey,
      json[systemKey],
      MeasurementSystem.imperial,
    );
    return CalculatorPreferencesDto(
      CalculatorPreferences(
        system: system,
        fractionResolution: _enumByNumber(
          FractionResolution.values,
          (r) => r.denominator,
          fractionResolutionKey,
          json[fractionResolutionKey],
          FractionResolution.sixteenth,
        ),
        metreDisplay: _enumByNumber(
          MetreDisplay.values,
          (m) => m.decimals,
          metreDisplayKey,
          json[metreDisplayKey],
          MetreDisplay.twoDecimals,
        ),
        tonDefinition: _enumByNumber(
          TonDefinition.values,
          (t) => t.poundsPerTon,
          poundsPerTonKey,
          json[poundsPerTonKey],
          TonDefinition.shortTon,
        ),
        densityUnit: _enumByName(
          DensityUnit.values,
          densityUnitKey,
          json[densityUnitKey],
          DensityUnit.defaultFor(system),
        ),
      ),
    );
  }

  /// The settings in the shape every save writes.
  Map<String, Object> toJson() => {
    systemKey: preferences.system.name,
    fractionResolutionKey: preferences.fractionResolution.denominator,
    metreDisplayKey: preferences.metreDisplay.decimals,
    poundsPerTonKey: preferences.tonDefinition.poundsPerTon,
    densityUnitKey: preferences.densityUnit.name,
  };

  static T _enumByName<T extends Enum>(
    List<T> values,
    String key,
    Object? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return _fallback(key, name, fallback);
  }

  static T _enumByNumber<T extends Enum>(
    List<T> values,
    int Function(T) numberOf,
    String key,
    Object? number,
    T fallback,
  ) {
    for (final value in values) {
      if (numberOf(value) == number) return value;
    }
    return _fallback(key, number, fallback);
  }

  static T _fallback<T extends Enum>(String key, Object? stored, T fallback) {
    if (stored != null) {
      _logger.warning(
        'Calculator preference "$key" holds $stored, which this build cannot '
        'read; using ${fallback.name}',
      );
    }
    return fallback;
  }

  @override
  List<Object?> get props => [preferences];
}
