import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/rational.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';

/// Writes the values a tape chip holds — a [Quantity] and the typed
/// [EntryBuffer] — as JSON objects for the `computation` of a
/// `calculator_tapes` row, and reads them back (Design Appendices D).
///
/// A quantity is written in its canonical unit beside the unit it was
/// spelled in, so nothing is rounded on the way to the row: a length as
/// the fraction of inches it is kept as ("6000/127" for 1200 mm, which a
/// computed length's ticks reduce to), an area in square ticks, a volume
/// in cubic feet, a weight in hundredths of a pound, an angle in degrees
/// with its spelling, a bare number with the decimals it shows. An entry
/// is its tokens, field for field. A JSON a value cannot be read from is a
/// [FormatException] that names where, so a tape written by a later build
/// or a damaged row is refused whole.
///
/// The readers at the end are shared with `TapeChipCodec`, which reads the
/// chip objects around these values.
abstract final class TapeValueCodec {
  /// The key a quantity's dimension is written under.
  static const String dimensionKey = 'dim';

  /// The key a quantity's canonical magnitude is written under; a length
  /// uses [inchesKey] instead.
  static const String valueKey = 'value';

  /// The key a length's exact inches are written under, as a fraction.
  static const String inchesKey = 'inches';

  /// The key a quantity's, or a token's, unit name is written under.
  static const String unitKey = 'unit';

  static const String _spellingKey = 'spelling';
  static const String _decimalsKey = 'decimals';
  static const String _padsDecimalsKey = 'pads';
  static const String _digitsKey = 'n';
  static const String _denominatorKey = 'd';
  static const String _powerKey = 'p';
  static const String _minutesKey = 'm';
  static const String _secondsKey = 's';
  static const String _typedAsKey = 't';

  /// The JSON object of [value].
  static Map<String, Object?> quantity(Quantity value) => switch (value) {
    Length() => {
      dimensionKey: value.dimension.name,
      inchesKey: _fraction(value.inches),
      unitKey: value.unit.name,
    },
    Area() => {
      dimensionKey: value.dimension.name,
      valueKey: value.squareTicks,
      unitKey: value.unit.name,
    },
    Volume() => {
      dimensionKey: value.dimension.name,
      valueKey: value.cubicFeet,
      unitKey: value.unit.name,
    },
    Weight() => {
      dimensionKey: value.dimension.name,
      valueKey: value.hundredthsOfPound,
      unitKey: value.unit.name,
    },
    Angle() => {
      dimensionKey: value.dimension.name,
      valueKey: value.degrees,
      _spellingKey: value.spelling.name,
    },
    Scalar() => {
      dimensionKey: value.dimension.name,
      valueKey: value.value,
      _decimalsKey: value.decimals,
      _padsDecimalsKey: value.padsDecimals,
    },
  };

  /// The quantity [json] holds; [where] names it in a [FormatException].
  static Quantity quantityFrom(Object? json, String where) {
    final map = object(json, where);
    return switch (map[dimensionKey]) {
      'length' => Length.exact(_inches(map, where), unit: unit(map, where)),
      'area' => Area(_real(map, where), unit: unit(map, where)),
      'volume' => Volume(_real(map, where), unit: unit(map, where)),
      'weight' => Weight(_real(map, where), unit: unit(map, where)),
      'angle' => Angle(
        _real(map, where),
        spelling:
            AngleSpelling.values.asNameMap()[map[_spellingKey]] ??
            (throw FormatException('Unreadable tape: $where.$_spellingKey')),
      ),
      'scalar' => Scalar(
        _real(map, where),
        decimals: optionalInteger(map, _decimalsKey, where),
        padsDecimals: flag(map, _padsDecimalsKey, where),
      ),
      _ => throw FormatException('Unreadable tape: $where.$dimensionKey'),
    };
  }

  /// The JSON list of [entry]'s tokens.
  static List<Map<String, Object?>> entry(EntryBuffer entry) => [
    for (final token in entry.tokens)
      {
        _digitsKey: token.digits,
        _denominatorKey: token.denominator,
        unitKey: token.unit?.name,
        _powerKey: token.power,
        _minutesKey: token.minutes,
        _secondsKey: token.seconds,
        _typedAsKey: token.typedAs,
      },
  ];

  /// The entry [json] holds; [where] names it in a [FormatException].
  static EntryBuffer entryFrom(Object? json, String where) => EntryBuffer([
    for (final (index, token) in list(json, where).indexed)
      _token(object(token, '$where[$index]'), '$where[$index]'),
  ]);

  static Token _token(Map<String, Object?> json, String where) => Token(
    digits: text(json, _digitsKey, where),
    denominator: optionalText(json, _denominatorKey, where),
    unit: optionalUnit(json, where),
    power: optionalInteger(json, _powerKey, where) ?? 1,
    minutes: optionalText(json, _minutesKey, where),
    seconds: optionalText(json, _secondsKey, where),
    typedAs: optionalText(json, _typedAsKey, where),
  );

  static String _fraction(Rational inches) =>
      '${inches.numerator}/${inches.denominator}';

  static Rational _inches(Map<String, Object?> json, String where) {
    if (text(json, inchesKey, where).split('/') case [
      final numerator,
      final denominator,
    ]) {
      final top = int.tryParse(numerator);
      final bottom = int.tryParse(denominator);
      if (top != null && bottom != null && bottom > 0) {
        return Rational(top, bottom);
      }
    }
    throw FormatException('Unreadable tape: $where.$inchesKey');
  }

  static double _real(Map<String, Object?> json, String where) =>
      switch (json[valueKey]) {
        final num value => value.toDouble(),
        _ => throw FormatException('Unreadable tape: $where.$valueKey'),
      };

  /// The unit named under [unitKey], which must be there.
  static Unit unit(Map<String, Object?> json, String where) =>
      optionalUnit(json, where) ??
      (throw FormatException('Unreadable tape: $where.$unitKey'));

  /// The unit named under [unitKey], or `null` when there is none.
  static Unit? optionalUnit(Map<String, Object?> json, String where) =>
      switch (json[unitKey]) {
        null => null,
        final name =>
          Unit.values.asNameMap()[name] ??
              (throw FormatException('Unreadable tape: $where.$unitKey')),
      };

  /// The boolean under [key], which must be there.
  static bool flag(Map<String, Object?> json, String key, String where) =>
      switch (json[key]) {
        final bool flag => flag,
        _ => throw FormatException('Unreadable tape: $where.$key'),
      };

  /// The string under [key], which must be there.
  static String text(Map<String, Object?> json, String key, String where) =>
      optionalText(json, key, where) ??
      (throw FormatException('Unreadable tape: $where.$key'));

  /// The string under [key], or `null` when there is none.
  static String? optionalText(
    Map<String, Object?> json,
    String key,
    String where,
  ) => switch (json[key]) {
    null => null,
    final String text => text,
    _ => throw FormatException('Unreadable tape: $where.$key'),
  };

  /// The whole number under [key], or `null` when there is none.
  static int? optionalInteger(
    Map<String, Object?> json,
    String key,
    String where,
  ) => switch (json[key]) {
    null => null,
    final int value => value,
    _ => throw FormatException('Unreadable tape: $where.$key'),
  };

  /// [json] as the object it must be.
  static Map<String, Object?> object(Object? json, String where) =>
      switch (json) {
        final Map<String, Object?> object => object,
        _ => throw FormatException('Unreadable tape: $where'),
      };

  /// [json] as the list it must be.
  static List<Object?> list(Object? json, String where) => switch (json) {
    final List<Object?> list => list,
    _ => throw FormatException('Unreadable tape: $where'),
  };
}
