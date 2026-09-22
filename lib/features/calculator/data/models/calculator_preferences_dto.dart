import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:equatable/equatable.dart';

/// The JSON shape of the five calculator settings under the `calculator`
/// key of `users.user_preferences`.
///
/// Reads two spellings and writes one. The keys written are snake_case
/// names of the settings; the keys also read are the prototype's
/// (`fracRes`, `meterDp`, `lbsTon`, `denUnit`), so a profile that carries
/// the old JSON is read correctly once and rewritten in the new shape on
/// the next save — the migration CA-1085 asks for, without a version field.
/// A value that is missing or unreadable falls back to the default: a
/// setting only changes how values render (rule 4.14), so a bad one can
/// never corrupt a calculation, and the prototype's dropped preferences
/// (length format, millimetre decimals, strip layout, edit style) are
/// simply not read.
class CalculatorPreferencesDto extends Equatable {
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

  static const String _legacyFractionResolutionKey = 'fracRes';
  static const String _legacyMetreDisplayKey = 'meterDp';
  static const String _legacyPoundsPerTonKey = 'lbsTon';
  static const String _legacyDensityUnitKey = 'denUnit';

  static const Map<String, DensityUnit> _legacyDensityUnits = {
    'lbs_yd3': DensityUnit.poundsPerCubicYard,
    'lbs_ft3': DensityUnit.poundsPerCubicFoot,
    'ton_yd3': DensityUnit.tonsPerCubicYard,
    'kg_m3': DensityUnit.kilogramsPerCubicMetre,
  };

  /// The settings this JSON stands for.
  final CalculatorPreferences preferences;

  const CalculatorPreferencesDto(this.preferences);

  /// Reads the `calculator` value of a profile's `user_preferences`, in
  /// either spelling; `null` or anything that is not a map is the defaults
  /// of a fresh install, with the density unit of the system read.
  factory CalculatorPreferencesDto.fromJson(Object? json) {
    if (json is! Map) {
      return const CalculatorPreferencesDto(CalculatorPreferences.defaults);
    }
    final system = _enumByName(
      MeasurementSystem.values,
      json[systemKey],
      MeasurementSystem.imperial,
    );
    final fraction = _read(
      json,
      fractionResolutionKey,
      _legacyFractionResolutionKey,
    );
    final metre = _read(json, metreDisplayKey, _legacyMetreDisplayKey);
    final ton = _read(json, poundsPerTonKey, _legacyPoundsPerTonKey);
    final density = json[densityUnitKey];
    final legacyDensity = json[_legacyDensityUnitKey];
    return CalculatorPreferencesDto(
      CalculatorPreferences(
        system: system,
        fractionResolution: _enumByNumber(
          FractionResolution.values,
          (r) => r.denominator,
          fraction,
          FractionResolution.sixteenth,
        ),
        metreDisplay: _enumByNumber(
          MetreDisplay.values,
          (m) => m.decimals,
          metre,
          MetreDisplay.twoDecimals,
        ),
        tonDefinition: _enumByNumber(
          TonDefinition.values,
          (t) => t.poundsPerTon,
          ton,
          TonDefinition.shortTon,
        ),
        densityUnit: _enumByName(
          DensityUnit.values,
          density,
          _legacyDensityUnits[legacyDensity] ?? DensityUnit.defaultFor(system),
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

  static Object? _read(Map json, String key, String legacyKey) =>
      json.containsKey(key) ? json[key] : json[legacyKey];

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static T _enumByNumber<T extends Enum>(
    List<T> values,
    int Function(T) numberOf,
    Object? number,
    T fallback,
  ) {
    for (final value in values) {
      if (numberOf(value) == number) return value;
    }
    return fallback;
  }

  @override
  List<Object?> get props => [preferences];
}
