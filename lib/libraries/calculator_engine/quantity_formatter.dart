import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/rational.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// Turns a quantity into the text on screen, following UX Design Doc
/// Section 6 ("Display settings", "Rounding at display") and the settings
/// that exist (Appendix C). The port of the prototype's `fmt*` functions.
///
/// Nothing is rounded until it is displayed, and a setting changes the text,
/// never the value (rule 4.14): the same [Length] renders as 3-5/16in at
/// 1/16 and 3-1/2in at 1/2. Results show a thousands separator; entries and
/// stored sizes do not, so [format] takes a `groupThousands` switch and
/// [formatStoredLength] never groups.
///
/// Rounding follows the prototype, so a value on a boundary lands where the
/// prototype lands: volumes, angles, scalars at or above 0.1, acres and
/// stored sizes are first pre-rounded with JavaScript's
/// `Math.round(v * 10^d) / 10^d` for their d decimals, whose half rounds
/// toward +∞ (-2.5 is -2); every number is then written as en-US
/// `toLocaleString` writes it: at most the allowed decimals, no trailing
/// zeros, rounded half away from zero on the shortest decimal spelling of
/// the double (which is what ICU rounds, and why 1.005 reads 1.01 there
/// while `toStringAsFixed` would say 1.00). A scalar below
/// 0.1 keeps two significant digits instead of two decimals, because two
/// decimals there hide up to a third of the value (0.0129 → 0.01) or erase a
/// nonzero answer (rule 4.15: 1 ÷ 78 reads 0.013).
///
/// An inch remainder is rounded to the nearest step of the fractional
/// resolution and reduced (8/16 reads 1/2); a remainder that rounds up to a
/// whole inch carries instead of reading 16/16, and the sign is written once,
/// in front (-8-3/4in). The feet of a compound are never grouped, as the
/// prototype writes them raw ("4368ft 0in"). A volume speaks the unit the
/// question was asked in (500bf ÷ 4 reads 125bf, not 10.42ft³), and tons take
/// a space before the word ("0.04 ton") where lbs and kg do not.
///
/// An angle reads in decimal degrees (27.55°) or, re-spelled, the way a
/// survey sheet writes it (Section 6, "Rounding at display"; scenario
/// S107): the whole seconds nearest the exact angle, degrees unpadded,
/// minutes and seconds always present and padded to two digits, 30°30'00"
/// (owner decision of 18 October 2026, which departs from the prototype's
/// `degToDMS` and its 30°30'). A negative angle takes a hyphen in both
/// spellings, -38.5° and -38°30'00", the sign every other quantity takes,
/// and a value that rounds to zero reads 0°00'00", never -0°00'00".
///
/// The formatter is a value over its preferences: a bloc keeps one per
/// preference state and two formatters with equal preferences render every
/// quantity alike.
class QuantityFormatter extends Equatable {
  /// Decimals a computed result keeps: 410.67ft², 7.33yd, 0.04 ton.
  static const int resultDecimals = 2;

  /// Decimals of a pitch written as a grade (Section 8: 133.3%); the rise
  /// per 12in of run is a fraction of an inch instead.
  static const int pitchDecimals = 1;

  /// A grade is a ratio in hundredths: a rise of 0.07 per unit of run is 7%.
  static const int percent = 100;

  /// Decimals an area in acres keeps: 0.3673acre.
  static const int acreDecimals = 4;

  /// Decimals a stored size keeps under Imperial: 47.24in.
  static const int storedInchDecimals = 2;

  /// Millimetres in one inch, for stored sizes under Metric.
  static const double millimetresPerInch = 25.4;

  /// Seconds of arc in one degree.
  static const int secondsPerDegree = 3600;

  /// Seconds of arc in one minute.
  static const int secondsPerMinute = 60;

  /// The settings this formatter renders by.
  final CalculatorPreferences preferences;

  const QuantityFormatter({this.preferences = CalculatorPreferences.defaults});

  /// The text of a computed or converted value.
  ///
  /// [groupThousands] is on for results (16,000ft²) and off where the tape
  /// echoes an entry.
  String format(Quantity value, {bool groupThousands = true}) =>
      switch (value) {
        Length() => _length(value, groupThousands),
        Area() => _area(value, groupThousands),
        Volume() => _volume(value, groupThousands),
        Weight() => _weight(value, groupThousands),
        Angle() => _angle(value, groupThousands),
        Scalar(:final decimals?, padsDecimals: true) => _paddedNumber(
          value.value,
          decimals,
          groupThousands,
        ),
        Scalar(:final decimals?) => _jsRoundedNumber(
          value.value,
          decimals,
          groupThousands,
        ),
        Scalar() => _scalar(value.value, groupThousands),
      };

  /// A stored size (a sheet, a masonry piece, a footing cross-section) the
  /// way the trade quotes it: inches under Imperial (48 × 96), whole
  /// millimetres under Metric (1200 × 2400), never grouped, and pre-rounded
  /// with `Math.round` as the prototype's `fmtSizeLen` does.
  String formatStoredLength(Length value) {
    final inches = value.inches.toDouble();
    return switch (preferences.system) {
      MeasurementSystem.imperial =>
        '${_jsRoundedNumber(inches, storedInchDecimals, false)}${Unit.inch.suffix}',
      MeasurementSystem.metric =>
        '${_jsRoundedNumber(inches * millimetresPerInch, 0, false)}'
            '${Unit.millimetre.suffix}',
    };
  }

  /// A density stored in lbs/yd³ in the unit the setting chooses.
  String formatDensity(double poundsPerCubicYard) {
    final (factor, decimals, suffix) = switch (preferences.densityUnit) {
      DensityUnit.poundsPerCubicYard => (1.0, 0, 'lbs/yd³'),
      DensityUnit.poundsPerCubicFoot => (1 / 27, 1, 'lbs/ft³'),
      DensityUnit.tonsPerCubicYard => (
        1 / preferences.poundsPerTon,
        2,
        'tons/yd³',
      ),
      DensityUnit.kilogramsPerCubicMetre => (0.593276421, 0, 'kg/m³'),
    };
    return '${_localeNumber(poundsPerCubicYard * factor, decimals, true)}$suffix';
  }

  String _length(Length value, bool group) => switch (value.unit) {
    Unit.inch => _wholeInchesAndFraction(value.inches, group),
    Unit.footInch => _feetAndInches(value.inches),
    _ => '${_decimalLengthNumber(value, group)}${value.unit.suffix}',
  };

  String _decimalLengthNumber(Length value, bool group) =>
      _localeNumber(value.amountIn(value.unit), switch (value.unit) {
        Unit.metre => preferences.metreDisplay.decimals,
        Unit.millimetre => 0,
        _ => resultDecimals,
      }, group);

  String _wholeInchesAndFraction(Rational inches, bool group) {
    final negative = inches.numerator < 0;
    final (:whole, :fraction) = _inchParts(negative ? -inches : inches);
    final text =
        '${_localeNumber(whole.toDouble(), 0, group)}'
        '${fraction.text}${Unit.inch.suffix}';
    return negative && (whole != 0 || fraction.text.isNotEmpty)
        ? '-$text'
        : text;
  }

  ({int whole, _InchFraction fraction}) _inchParts(Rational magnitude) {
    final whole = magnitude.floor();
    final fraction = _fractionOfInch(magnitude - Rational(whole));
    return (whole: whole + fraction.carry, fraction: fraction);
  }

  String _feetAndInches(Rational inches) {
    final negative = inches.numerator < 0;
    final magnitude = negative ? -inches : inches;
    var feet = (magnitude / Unit.foot.inchesPer).floor();
    final remainder = magnitude - Rational(feet) * Unit.foot.inchesPer;
    var wholeInches = remainder.floor();
    final fraction = _fractionOfInch(remainder - Rational(wholeInches));
    wholeInches += fraction.carry;
    if (wholeInches == 12) {
      feet += 1;
      wholeInches = 0;
    }
    final text = '${feet}ft $wholeInches${fraction.text}in';
    return negative &&
            (feet != 0 || wholeInches != 0 || fraction.text.isNotEmpty)
        ? '-$text'
        : text;
  }

  _InchFraction _fractionOfInch(Rational remainderInches) {
    final steps = preferences.fractionResolution.denominator;
    var numerator = _jsMathRound(
      (remainderInches * Rational(steps)).toDouble(),
    );
    if (numerator == 0) {
      return (text: '', carry: 0, numerator: 0, denominator: 0);
    }
    if (numerator == steps) {
      return (text: '', carry: 1, numerator: 0, denominator: 0);
    }
    var denominator = steps;
    while (numerator.isEven) {
      numerator ~/= 2;
      denominator ~/= 2;
    }
    return (
      text: '-$numerator/$denominator',
      carry: 0,
      numerator: numerator,
      denominator: denominator,
    );
  }

  /// The tokens a conversion chip's value is read by on the tape, written
  /// the way [format] writes the chip, ungrouped: a ft-in reading as
  /// [footInchTokens], inches as whole inches and the fraction of an inch
  /// at the Fractional resolution setting (39-3/8in), every other unit as
  /// the number [format] writes under it, with the unit's power (0.83ft³,
  /// 1777.78yd², 0.91m, 0.03ton). So a chip accepted from the strip reads
  /// on the tape as it read on the strip, never a respelling of the same
  /// value (Section 1.2; decision tree row 201), where the unit key alone
  /// would read 39.37in or 0.8333ft³ ([QuantitySpeller]). The tokens are
  /// only how the value is read; the caller keeps the exact quantity beside
  /// them (rule 4.15). An angle or a scalar is never offered as a
  /// conversion and has no tokens here.
  List<Token> tokens(Quantity value) => switch (value) {
    Length(unit: Unit.footInch) => footInchTokens(value),
    Length(unit: Unit.inch) => _inchTokens(value.inches),
    Length(:final unit) => [
      Token(digits: _decimalLengthNumber(value, false), unit: unit),
    ],
    Area(:final unit) => [
      Token(
        digits: _areaNumber(value, false),
        unit: unit,
        power: unit == Unit.acre ? 1 : 2,
      ),
    ],
    Volume(:final unit) => [
      Token(
        digits: _volumeNumber(value, false),
        unit: unit,
        power: unit == Unit.boardFoot ? 1 : 3,
      ),
    ],
    Weight(:final unit) => [
      Token(digits: _weightNumber(value, false), unit: unit),
    ],
    Angle() || Scalar() => const [],
  };

  List<Token> _inchTokens(Rational inches) {
    final (:whole, :fraction) = _inchParts(
      inches.numerator < 0 ? -inches : inches,
    );
    return [
      Token(digits: '$whole', unit: Unit.inch),
      if (fraction.denominator != 0)
        Token(
          digits: '${fraction.numerator}',
          denominator: '${fraction.denominator}',
          unit: Unit.inch,
        ),
    ];
  }

  /// The tokens a ft-in reading is typed as, written the way [format] writes
  /// it: whole feet, whole inches and the fraction of an inch at the
  /// Fractional resolution setting, so 1m accepted from the strip reads
  /// 3ft 3-3/8in on its chip as on the strip chip (Section 2.1, "the chip
  /// keeps what was typed"). The tokens are only how the value is read;
  /// the caller keeps the exact quantity beside them (rule 4.15).
  List<Token> footInchTokens(Length value) {
    final magnitude = value.inches.numerator < 0 ? -value.inches : value.inches;
    var feet = (magnitude / Unit.foot.inchesPer).floor();
    final remainder = magnitude - Rational(feet) * Unit.foot.inchesPer;
    var wholeInches = remainder.floor();
    final fraction = _fractionOfInch(remainder - Rational(wholeInches));
    wholeInches += fraction.carry;
    if (wholeInches == 12) {
      feet += 1;
      wholeInches = 0;
    }
    return [
      Token(digits: '$feet', unit: Unit.foot),
      Token(digits: '$wholeInches', unit: Unit.inch),
      if (fraction.denominator != 0)
        Token(
          digits: '${fraction.numerator}',
          denominator: '${fraction.denominator}',
          unit: Unit.inch,
        ),
    ];
  }

  String _area(Area value, bool group) => switch (value.unit) {
    Unit.acre => '${_areaNumber(value, group)}${Unit.acre.suffix}',
    final unit => '${_areaNumber(value, group)}${unit.suffix}²',
  };

  String _areaNumber(Area value, bool group) {
    if (value.unit == Unit.acre) {
      final acres = value.squareFeet / Area.squareFeetPerAcre;
      return _jsRoundedNumber(acres, acreDecimals, group);
    }
    final ticksPerUnit = value.unit.ticksPerUnit;
    final inUnit = value.squareTicks / ticksPerUnit / ticksPerUnit;
    return _localeNumber(inUnit, resultDecimals, group);
  }

  String _volume(Volume value, bool group) => switch (value.unit) {
    Unit.boardFoot => '${_volumeNumber(value, group)}${Unit.boardFoot.suffix}',
    final unit => '${_volumeNumber(value, group)}${unit.suffix}³',
  };

  String _volumeNumber(Volume value, bool group) {
    if (value.unit == Unit.boardFoot) {
      return _jsRoundedNumber(value.boardFeet, resultDecimals, group);
    }
    final feetPerUnit = Length.ticksPerFoot / value.unit.ticksPerUnit;
    final inUnit = value.cubicFeet * feetPerUnit * feetPerUnit * feetPerUnit;
    return _jsRoundedNumber(inUnit, resultDecimals, group);
  }

  String _weight(Weight value, bool group) => switch (value.unit) {
    Unit.ton => '${_weightNumber(value, group)} ${Unit.ton.suffix}',
    final unit => '${_weightNumber(value, group)}${unit.suffix}',
  };

  String _weightNumber(Weight value, bool group) {
    final perUnit = value.unit.hundredthsOfPoundPer(
      poundsPerTon: preferences.poundsPerTon,
    );
    return _localeNumber(
      value.hundredthsOfPound / perUnit,
      resultDecimals,
      group,
    );
  }

  String _angle(Angle value, bool group) => switch (value.spelling) {
    AngleSpelling.degrees =>
      '${_jsRoundedNumber(value.degrees, resultDecimals, group)}°',
    AngleSpelling.degreesMinutesSeconds => _degreesMinutesSeconds(
      value.degrees,
      group,
    ),
    AngleSpelling.risePerFoot =>
      '${_riseInInches(_rise(value) * Angle.inchesPerFootOfRun, group)}in/12in',
    AngleSpelling.grade =>
      '${_jsRoundedNumber(_rise(value) * percent, pitchDecimals, group)}%',
  };

  double _rise(Angle value) => math.tan(value.degrees * math.pi / 180);

  String _riseInInches(double inches, bool group) {
    final ticks = inches.abs() * Length.ticksPerInch;
    var whole = ticks ~/ Length.ticksPerInch;
    final fraction = _fractionOfInch(
      Length.computed(ticks % Length.ticksPerInch, unit: Unit.inch).inches,
    );
    whole += fraction.carry;
    final sign = inches < 0 ? '-' : '';
    if (whole == 0 && fraction.text.isNotEmpty) {
      return '$sign${fraction.text.substring(1)}';
    }
    return '$sign${_localeNumber(whole.toDouble(), 0, group)}${fraction.text}';
  }

  /// An angle in decimal degrees to [decimals] places, ungrouped, for the
  /// angle drawer (rule 4.16): 0.000573° to 3 decimals is 0.001°, and
  /// 89.99993° to 4 is 89.9999°. The display keeps [resultDecimals].
  String formatDegrees(Angle angle, {required int decimals}) =>
      '${_jsRoundedNumber(angle.degrees, decimals, false)}°';

  /// An angle as degrees, minutes and seconds with the seconds to
  /// [secondsDecimals] places, ungrouped, for the angle drawer (rule 4.16):
  /// 0.00001° to 2 is 0°00'00.04", and 89.99999° to 2 is 89°59'59.96". A
  /// rounding that reaches 60 seconds carries, so 89.99999° to 1 reads
  /// 90°00'00.0".
  String formatDegreesMinutesSeconds(
    Angle angle, {
    required int secondsDecimals,
  }) => _degreesMinutesSeconds(
    angle.degrees,
    false,
    secondsDecimals: secondsDecimals,
  );

  String _degreesMinutesSeconds(
    double degrees,
    bool group, {
    int secondsDecimals = 0,
  }) {
    // The seconds stay a double: an int would clamp at 2^63 and show a
    // different angle from the degrees spelling (CA-1201 owns 2^53). They
    // are counted in units of the last decimal, so that a rounding that
    // reaches 60 carries into the minutes.
    final scale = math.pow(10, secondsDecimals).toDouble();
    final totalUnits = (degrees.abs() * secondsPerDegree * scale + 0.5)
        .floorToDouble();
    final unitsPerDegree = secondsPerDegree * scale;
    final rest = totalUnits % unitsPerDegree;
    final wholeDegrees = (totalUnits - rest) / unitsPerDegree;
    final unitsPerMinute = secondsPerMinute * scale;
    final secondUnits = rest % unitsPerMinute;
    final minutes = ((rest - secondUnits) / unitsPerMinute).round();
    final seconds = _secondsText(secondUnits, scale, secondsDecimals);
    final sign = degrees < 0 && totalUnits > 0 ? '-' : '';
    return '$sign${_localeNumber(wholeDegrees, 0, group)}°'
        "${_twoDigits(minutes)}'$seconds\"";
  }

  String _secondsText(double units, double scale, int decimals) {
    final whole = (units / scale).floor();
    if (decimals == 0) return _twoDigits(whole);
    final fraction = (units - whole * scale).round().toString();
    return '${_twoDigits(whole)}.${fraction.padLeft(decimals, '0')}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _scalar(double value, bool group) {
    if (value == 0) return '0';
    if (value.abs() >= 0.1) {
      return _jsRoundedNumber(value, resultDecimals, group);
    }
    return double.parse(value.toStringAsPrecision(2)).toString();
  }

  String _paddedNumber(double value, int decimals, bool group) {
    final text = _jsRoundedNumber(value, decimals, group);
    final point = text.indexOf('.');
    final shown = point == -1 ? 0 : text.length - point - 1;
    return '${point == -1 ? '$text.' : text}${'0' * (decimals - shown)}';
  }

  String _jsRoundedNumber(double value, int decimals, bool group) {
    final scale = math.pow(10, decimals).toDouble();
    return _localeNumber(_jsMathRound(value * scale) / scale, decimals, group);
  }

  String _localeNumber(double value, int decimals, bool group) {
    final negative = value < 0;
    var text = _roundDecimalText(value.abs(), decimals);
    if (group) text = _grouped(text);
    return negative && text != '0' ? '-$text' : text;
  }

  String _roundDecimalText(double value, int decimals) {
    var text = value.toString();
    if (text.contains('e')) text = value.toStringAsFixed(decimals);
    final point = text.indexOf('.');
    if (point == -1) return text;
    final whole = text.substring(0, point);
    final fraction = text.substring(point + 1);
    if (fraction.length <= decimals) {
      return _trimFraction('$whole.$fraction');
    }
    final kept = '$whole${fraction.substring(0, decimals)}';
    final roundUp = fraction.codeUnitAt(decimals) >= '5'.codeUnitAt(0);
    final digits = roundUp ? _incrementDigits(kept) : kept;
    if (decimals == 0) return digits;
    final split = digits.length - decimals;
    return _trimFraction(
      '${digits.substring(0, split)}.${digits.substring(split)}',
    );
  }

  String _incrementDigits(String digits) {
    final units = digits.codeUnits.toList();
    var index = units.length - 1;
    while (index >= 0) {
      if (units[index] == '9'.codeUnitAt(0)) {
        units[index] = '0'.codeUnitAt(0);
        index -= 1;
      } else {
        units[index] += 1;
        return String.fromCharCodes(units);
      }
    }
    return '1${String.fromCharCodes(units)}';
  }

  String _trimFraction(String text) =>
      text.contains('.') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text;

  String _grouped(String text) {
    final point = text.indexOf('.');
    final whole = point == -1 ? text : text.substring(0, point);
    final rest = point == -1 ? '' : text.substring(point);
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '$buffer$rest';
  }

  // TODO: [CA-1201] Refuse a value at or above 2^53, NaN or an infinity
  // instead of clamping it at 2^63 or throwing; reachable since × landed
  // in #642. https://ripplearc.youtrack.cloud/issue/CA-1201
  int _jsMathRound(double value) => (value + 0.5).floor();

  @override
  List<Object?> get props => [preferences];
}

typedef _InchFraction = ({
  String text,
  int carry,
  int numerator,
  int denominator,
});
