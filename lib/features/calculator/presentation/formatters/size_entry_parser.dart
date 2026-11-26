import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:equatable/equatable.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Why a field of the size editor spells no size.
enum SizeEntryRefusal {
  /// Nothing typed, or a size of exactly zero ("Size must be more than
  /// zero."; UX Design Doc term 2.16).
  zero,

  /// A size above zero that shows as zero ("0.0001in rounds to 0in. Type a
  /// bigger size.").
  roundsToZero,

  /// A number with no unit ("48 has no unit yet. Press a unit key."). A
  /// number after feet is not one: Add closes it as inches (rule 4.5).
  noUnit,

  /// A value the calculator would not take as finished either: a fraction
  /// with no number under its line, a number after metres with no unit.
  unfinished,

  /// The unit the value already holds, pressed again ("Feet is already
  /// used. Type inches next.").
  unitUsedTwice,

  /// A unit of the other system after the first ("Use feet and inches, or
  /// m and cm.").
  otherSystem,

  /// A larger unit after a smaller one of its system ("Type feet first,
  /// then inches.").
  largerUnitAfterSmaller,

  /// A number above 19,999,999.99 ("Over 19,999,999.99. Type a smaller
  /// size.").
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

  /// The unit whose key was refused, for [SizeEntryRefusal.unitUsedTwice]
  /// and [SizeEntryRefusal.largerUnitAfterSmaller].
  final Unit? unit;

  /// The face of [unit]'s key, as the field holds it ("Feet").
  final String unitFace;

  /// The smaller unit typed before [unit], for
  /// [SizeEntryRefusal.largerUnitAfterSmaller].
  final Unit? after;

  /// What the field spells, as the calculator writes it: the number of
  /// [SizeEntryRefusal.noUnit] ("48") and the size of
  /// [SizeEntryRefusal.roundsToZero] ("0.0001in").
  final String typed;

  /// How a size of [SizeEntryRefusal.roundsToZero] shows ("0in").
  final String shownAs;

  const SizeEntryRefused(
    this.reason, {
    this.unit,
    this.unitFace = '',
    this.after,
    this.typed = '',
    this.shownAs = '',
  });

  @override
  List<Object?> get props => [reason, unit, unitFace, after, typed, shownAs];
}

/// Reads a field of the value editor back as a length (UX Design Doc term
/// 2.18) by the calculator's own entry rules. The editor's keys type their
/// faces into the field, so 4 [Feet] 6 [Inch] reads "4Feet6Inch"; the
/// faces are pressed again, in order, on the engine's [EntryBuffer], and
/// Add is the equals key. So a field takes what the tape takes — 4ft 6,
/// which Add closes as 4ft 6in (rule 4.5), a fraction after whole inches
/// (48in 1/2 is 48-1/2in), 1ft 1/16in exact (Section 6) — and refuses
/// what the tape refuses, a second Feet or centimetres after feet (Section
/// 5.2). A number with no unit is refused too, since nothing says whether
/// 8 is inches or feet (term 2.16), and each refusal says which mistake it
/// is, so that the field can say what to type next.
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

  static const List<List<Unit>> _largestFirst = [
    [Unit.yard, Unit.foot, Unit.inch],
    [Unit.metre, Unit.centimetre, Unit.millimetre],
  ];

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
          return unit == null
              ? const SizeEntryRefused(SizeEntryRefusal.unfinished)
              : _refusedUnit(buffer, unit, face);
      }
    }
    if (buffer.isEmpty) return const SizeEntryRefused(SizeEntryRefusal.zero);
    final finished = buffer.withFractionClosedAsInches;
    if (finished.tokens case [final number] when finished.isOpen) {
      if (number.denominator == '') {
        return const SizeEntryRefused(SizeEntryRefusal.unfinished);
      }
      return number.value == 0
          ? const SizeEntryRefused(SizeEntryRefusal.zero)
          : SizeEntryRefused(SizeEntryRefusal.noUnit, typed: finished.text);
    }
    final closed = _closedAsEqualsWould(finished);
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
    final shownAsZero = writer.formatStoredLength(Length(0, unit: length.unit));
    if (writer.formatStoredLength(length) == shownAsZero) {
      return length.inches.toDouble() == 0
          ? const SizeEntryRefused(SizeEntryRefusal.zero)
          : SizeEntryRefused(
              SizeEntryRefusal.roundsToZero,
              typed: closed.text,
              shownAs: shownAsZero,
            );
    }
    return SizeEntryLength(length);
  }

  SizeEntryRefused _refusedUnit(EntryBuffer buffer, Unit unit, String face) {
    final before = buffer.tokens.map((token) => token.unit).nonNulls.lastOrNull;
    if (before == null) {
      return const SizeEntryRefused(SizeEntryRefusal.unfinished);
    }
    if (before == unit) {
      return SizeEntryRefused(
        SizeEntryRefusal.unitUsedTwice,
        unit: unit,
        unitFace: face,
      );
    }
    final system = _largestFirst.firstWhere(
      (units) => units.contains(before),
      orElse: () => const [],
    );
    if (!system.contains(unit)) {
      return const SizeEntryRefused(SizeEntryRefusal.otherSystem);
    }
    if (system.indexOf(unit) < system.indexOf(before)) {
      return SizeEntryRefused(
        SizeEntryRefusal.largerUnitAfterSmaller,
        unit: unit,
        unitFace: face,
        after: before,
      );
    }
    return const SizeEntryRefused(SizeEntryRefusal.unfinished);
  }

  EntryBuffer? _closedAsEqualsWould(EntryBuffer finished) {
    if (!finished.isOpen) return finished;
    if (finished.tokens case [..., Token(unit: Unit.foot), _]) {
      return switch (finished.closeWith(Unit.inch, holdsLengthOnly: true)) {
        EntryChanged(buffer: final closed) ||
        EntryCarried(buffer: final closed) => closed,
        EntrySplit() || EntryRefused() => null,
      };
    }
    return null;
  }

  double _storedNumberOf(Length length, MeasurementSystem system) =>
      switch (system) {
        MeasurementSystem.imperial => length.inches.toDouble().abs(),
        MeasurementSystem.metric =>
          (length.inches.toDouble() * QuantityFormatter.millimetresPerInch)
              .abs(),
      };
}
