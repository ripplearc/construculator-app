import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:equatable/equatable.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Why a field of the size editor spells no size.
enum SizeEntryRefusal {
  /// Nothing typed, or a size that is zero or shows as zero ("Size must be
  /// more than zero."; UX Design Doc term 2.16).
  zero,

  /// A value the calculator would not take as finished either: a fraction
  /// with no number under its line, a number after metres with no unit.
  unfinished,

  /// A unit that cannot continue the value typed so far: a second Feet,
  /// centimetres after feet, feet after inches (Section 5.2, "Can't append
  /// here").
  cannotAppendUnit,

  /// A number above 19,999,999.99 (Section 5.3, "Too large").
  tooLarge,
}

/// What a field of the size editor spells.
sealed class SizeEntry extends Equatable {
  const SizeEntry();
}

/// The field spells a size.
final class SizeEntryLength extends SizeEntry {
  /// The length, exact as typed.
  final Length length;

  const SizeEntryLength(this.length);

  @override
  List<Object?> get props => [length];
}

/// The field spells no size.
final class SizeEntryRefused extends SizeEntry {
  /// Why.
  final SizeEntryRefusal reason;

  /// The unit that could not be appended, for
  /// [SizeEntryRefusal.cannotAppendUnit].
  final Unit? unit;

  const SizeEntryRefused(this.reason, {this.unit});

  @override
  List<Object?> get props => [reason, unit];
}

/// Reads a field of the value editor back as a length (UX Design Doc term
/// 2.18) by the calculator's own entry rules. The editor's keys type their
/// faces into the field, so 4 [Feet] 6 [Inch] reads "4Feet6Inch"; the
/// faces are pressed again, in order, on the engine's [EntryBuffer], and
/// Add is the equals key. So a field takes what the tape takes — 4ft 6,
/// which Add closes as 4ft 6in (rule 4.5), a fraction after whole inches
/// (48in 1/2 is 48-1/2in), 1ft 1/16in exact (Section 6) — and refuses
/// what the tape refuses, a second Feet or centimetres after feet (Section
/// 5.2). A number with no unit is in the unit a stored size is quoted in,
/// inches under Imperial and millimetres under Metric (term 2.16).
class SizeEntryParser {
  /// Creates a parser.
  const SizeEntryParser();

  /// The largest number the calculator writes (Section 5.3).
  static const double largestNumber = 19999999.99;

  static final Map<String, Unit> _unitsByKeyFace = {
    UnitType.yards.label: Unit.yard,
    UnitType.feet.label: Unit.foot,
    UnitType.inch.label: Unit.inch,
    UnitType.meter.label: Unit.metre,
    UnitType.centimeter.label: Unit.centimetre,
    UnitType.millimeter.label: Unit.millimetre,
  };

  static const String _fractionKeyFace = '/';

  static final RegExp _keyFace = RegExp(
    [
      ...(_unitsByKeyFace.keys.toList()
            ..sort((a, b) => b.length.compareTo(a.length)))
          .map(RegExp.escape),
      r'\d',
      r'\.',
      RegExp.escape(_fractionKeyFace),
    ].join('|'),
  );

  /// The length [text] spells under [system], or `null` when [read]
  /// refuses it.
  Length? lengthOf(String text, MeasurementSystem system) =>
      switch (read(text, system)) {
        SizeEntryLength(:final length) => length,
        SizeEntryRefused() => null,
      };

  /// What [text] spells under [system]: the length, or why it is none.
  SizeEntry read(String text, MeasurementSystem system) {
    final typed = text.replaceAll(' ', '');
    final faces = [for (final match in _keyFace.allMatches(typed)) match[0]];
    if (faces.join() != typed) {
      return const SizeEntryRefused(SizeEntryRefusal.unfinished);
    }
    var buffer = const EntryBuffer();
    for (final face in faces.nonNulls) {
      final unit = _unitsByKeyFace[face];
      final outcome = switch (face) {
        _fractionKeyFace => buffer.typeFraction(),
        _ when unit != null => buffer.closeWith(unit, holdsLengthOnly: true),
        _ => buffer.typeDigit(face),
      };
      switch (outcome) {
        case EntryChanged(buffer: final next) ||
            EntryCarried(buffer: final next):
          buffer = next;
        case EntrySplit() || EntryRefused():
          return SizeEntryRefused(
            unit == null
                ? SizeEntryRefusal.unfinished
                : SizeEntryRefusal.cannotAppendUnit,
            unit: unit,
          );
      }
    }
    if (buffer.isEmpty) return const SizeEntryRefused(SizeEntryRefusal.zero);
    final closed = _closedAsEqualsWould(buffer, system);
    if (closed == null || !closed.isComplete) {
      return const SizeEntryRefused(SizeEntryRefusal.unfinished);
    }
    final length = const QuantityParser().parse(closed.tokens);
    if (length is! Length) {
      return const SizeEntryRefused(SizeEntryRefusal.unfinished);
    }
    final writer = QuantityFormatter(
      preferences: CalculatorPreferences(system: system),
    );
    if (closed.tokens.any((token) => token.value > largestNumber) ||
        _storedNumberOf(length, system) > largestNumber) {
      return const SizeEntryRefused(SizeEntryRefusal.tooLarge);
    }
    if (writer.formatStoredLength(length) ==
        writer.formatStoredLength(Length(0, unit: length.unit))) {
      return const SizeEntryRefused(SizeEntryRefusal.zero);
    }
    return SizeEntryLength(length);
  }

  EntryBuffer? _closedAsEqualsWould(
    EntryBuffer buffer,
    MeasurementSystem system,
  ) {
    final finished = buffer.withFractionClosedAsInches;
    if (!finished.isOpen) return finished;
    final unit = switch (finished.tokens) {
      [_] => _bareNumberUnit(system),
      [..., Token(unit: Unit.foot), _] => Unit.inch,
      _ => null,
    };
    if (unit == null) return null;
    return switch (finished.closeWith(unit, holdsLengthOnly: true)) {
      EntryChanged(buffer: final closed) ||
      EntryCarried(buffer: final closed) => closed,
      EntrySplit() || EntryRefused() => null,
    };
  }

  double _storedNumberOf(Length length, MeasurementSystem system) =>
      switch (system) {
        MeasurementSystem.imperial => length.inches.toDouble().abs(),
        MeasurementSystem.metric =>
          (length.inches.toDouble() * QuantityFormatter.millimetresPerInch)
              .abs(),
      };

  Unit _bareNumberUnit(MeasurementSystem system) => switch (system) {
    MeasurementSystem.imperial => Unit.inch,
    MeasurementSystem.metric => Unit.millimetre,
  };
}
