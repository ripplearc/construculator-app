import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';

/// Reads a field of the value editor back as a length (UX Design Doc term
/// 2.18). The editor's keys type their faces into the field, so
/// 4 [Feet] reads "4Feet" and 4 [Feet] 6 [Inch] reads "4Feet6Inch"; a
/// number with no unit is in the unit a stored size is quoted in, inches
/// under Imperial and millimetres under Metric (term 2.16).
class SizeEntryParser {
  /// Creates a parser.
  const SizeEntryParser();

  static const Map<String, Unit> _unitFaces = {
    'Yards': Unit.yard,
    'Feet': Unit.foot,
    'Inch': Unit.inch,
    'M': Unit.metre,
    'CM': Unit.centimetre,
    'MM': Unit.millimetre,
  };

  static final RegExp _part = RegExp(
    r'(\d+\.?\d*|\.\d+)\s*(Yards|Feet|Inch|CM|MM|M)?\s*',
  );

  /// The length [text] spells under [system], or `null` when it spells
  /// none or a length of zero, which a size refuses ("Size must be more
  /// than zero."; term 2.16). The length keeps the unit of its first part.
  Length? lengthOf(String text, MeasurementSystem system) {
    final trimmed = text.trim();
    final parts = _part.allMatches(trimmed).toList();
    if (parts.isEmpty || parts.map((part) => part[0]).join() != trimmed) {
      return null;
    }
    var inches = Rational.zero;
    Unit? spelledIn;
    try {
      for (final part in parts) {
        final unit = switch (part[2]) {
          null when parts.length == 1 => _bareNumberUnit(system),
          null => null,
          final face => _unitFaces[face],
        };
        final number = Rational.tryParse(part[1] ?? '');
        if (unit == null || number == null) return null;
        spelledIn ??= unit;
        inches += number * unit.inchesPer;
      }
    } on RationalOverflow {
      return null;
    }
    if (spelledIn == null || inches.isZero) return null;
    return Length.exact(inches, unit: spelledIn);
  }

  Unit _bareNumberUnit(MeasurementSystem system) => switch (system) {
    MeasurementSystem.imperial => Unit.inch,
    MeasurementSystem.metric => Unit.millimetre,
  };
}
