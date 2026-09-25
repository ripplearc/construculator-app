import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
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
/// prototype lands: a number is pre-rounded with JavaScript's
/// `Math.round(v * 100) / 100`, whose half rounds toward +∞ (-2.5 is -2),
/// then written as en-US `toLocaleString` writes it: at most the allowed
/// decimals, no trailing zeros, rounded half away from zero on the shortest
/// decimal spelling of the double (which is what ICU rounds, and why 1.005
/// reads 1.01 there while `toStringAsFixed` would say 1.00). A scalar below
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
/// The formatter is a value over its preferences: a bloc keeps one per
/// preference state and two formatters with equal preferences render every
/// quantity alike.
class QuantityFormatter extends Equatable {
  /// Decimals a computed result keeps: 410.67ft², 7.33yd, 0.04 ton.
  static const int resultDecimals = 2;

  /// Decimals an area in acres keeps: 0.3673acre.
  static const int acreDecimals = 4;

  /// Decimals a stored size keeps under Imperial: 47.24in.
  static const int storedInchDecimals = 2;

  /// Millimetres in one inch, for stored sizes under Metric.
  static const double millimetresPerInch = 25.4;

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
        Angle() =>
          '${_jsRoundedNumber(value.degrees, resultDecimals, groupThousands)}°',
        Scalar() => _scalar(value.value, groupThousands),
      };

  /// A stored size (a sheet, a masonry piece, a footing cross-section) the
  /// way the trade quotes it: inches under Imperial (48 × 96), whole
  /// millimetres under Metric (1200 × 2400), never grouped, and pre-rounded
  /// with `Math.round` as the prototype's `fmtSizeLen` does.
  String formatStoredLength(Length value) {
    final inches = value.ticks / Length.ticksPerInch;
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
    Unit.inch => _wholeInchesAndFraction(value.ticks, group),
    Unit.footInch => _feetAndInches(value.ticks),
    Unit.metre => _decimalLength(
      value,
      preferences.metreDisplay.decimals,
      group,
    ),
    Unit.millimetre => _decimalLength(value, 0, group),
    _ => _decimalLength(value, resultDecimals, group),
  };

  String _decimalLength(Length value, int decimals, bool group) =>
      '${_localeNumber(value.ticks / value.unit.ticksPerUnit, decimals, group)}'
      '${value.unit.suffix}';

  String _wholeInchesAndFraction(int ticks, bool group) {
    final magnitude = ticks.abs();
    var whole = magnitude ~/ Length.ticksPerInch;
    final fraction = _fractionOfInch(magnitude % Length.ticksPerInch);
    whole += fraction.carry;
    return '${ticks < 0 ? '-' : ''}${_localeNumber(whole.toDouble(), 0, group)}'
        '${fraction.text}${Unit.inch.suffix}';
  }

  String _feetAndInches(int ticks) {
    final magnitude = ticks.abs();
    var feet = magnitude ~/ Length.ticksPerFoot;
    final remainder = magnitude % Length.ticksPerFoot;
    var inches = remainder ~/ Length.ticksPerInch;
    final fraction = _fractionOfInch(remainder % Length.ticksPerInch);
    inches += fraction.carry;
    if (inches == 12) {
      feet += 1;
      inches = 0;
    }
    return '${ticks < 0 ? '-' : ''}${feet}ft $inches${fraction.text}in';
  }

  ({String text, int carry}) _fractionOfInch(int remainderTicks) {
    final steps = preferences.fractionResolution.denominator;
    var numerator = _jsMathRound(
      remainderTicks / (Length.ticksPerInch / steps),
    );
    if (numerator == 0) return (text: '', carry: 0);
    if (numerator == steps) return (text: '', carry: 1);
    var denominator = steps;
    while (numerator.isEven) {
      numerator ~/= 2;
      denominator ~/= 2;
    }
    return (text: '-$numerator/$denominator', carry: 0);
  }

  String _area(Area value, bool group) {
    if (value.unit == Unit.acre) {
      final acres = value.squareFeet / Area.squareFeetPerAcre;
      return '${_jsRoundedNumber(acres, acreDecimals, group)}${Unit.acre.suffix}';
    }
    final ticksPerUnit = value.unit.ticksPerUnit;
    final inUnit = value.squareTicks / ticksPerUnit / ticksPerUnit;
    return '${_localeNumber(inUnit, resultDecimals, group)}${value.unit.suffix}²';
  }

  String _volume(Volume value, bool group) {
    if (value.unit == Unit.boardFoot) {
      return '${_jsRoundedNumber(value.boardFeet, resultDecimals, group)}'
          '${Unit.boardFoot.suffix}';
    }
    final feetPerUnit = Length.ticksPerFoot / value.unit.ticksPerUnit;
    final inUnit = value.cubicFeet * feetPerUnit * feetPerUnit * feetPerUnit;
    return '${_jsRoundedNumber(inUnit, resultDecimals, group)}${value.unit.suffix}³';
  }

  String _weight(Weight value, bool group) {
    final perUnit = value.unit.hundredthsOfPoundPer(
      poundsPerTon: preferences.poundsPerTon,
    );
    final number = _localeNumber(
      value.hundredthsOfPound / perUnit,
      resultDecimals,
      group,
    );
    return switch (value.unit) {
      Unit.ton => '$number ${Unit.ton.suffix}',
      _ => '$number${value.unit.suffix}',
    };
  }

  String _scalar(double value, bool group) {
    if (value == 0) return '0';
    if (value.abs() >= 0.1) {
      return _jsRoundedNumber(value, resultDecimals, group);
    }
    return double.parse(value.toStringAsPrecision(2)).toString();
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

  int _jsMathRound(double value) => (value + 0.5).floor();

  @override
  List<Object?> get props => [preferences];
}
