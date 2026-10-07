import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// The function keys whose values the geometry rules read, by the stable
/// id a [ValueChip.key] carries.
enum DimensionKey {
  /// The length of a rectangle or a box.
  length('Length'),

  /// The width of a rectangle or a box.
  width('Width'),

  /// The height of a wall or a box.
  height('Height'),

  /// The rise of a right triangle.
  rise('Rise'),

  /// The run of a right triangle.
  run('Run');

  /// The chip key the function key writes.
  final String id;

  const DimensionKey(this.id);
}

/// An answer the named values on the tape earn (UX Design Doc Section 8):
/// what it is called, what it is worth, and which named values it was
/// computed from, so that it can be recomputed after one of them is edited
/// (requirement R8) and a rule never consumes a chip it did not name
/// (rule 4.5).
final class Answer extends Equatable {
  /// The label of the answer: Area, Diagonal, Perimeter…
  final String key;

  /// The answer, at full precision except where the prototype rounds.
  final Quantity value;

  /// The keys of the named values the answer was computed from, in the
  /// order the rule read them.
  final List<String> sources;

  const Answer({required this.key, required this.value, required this.sources});

  @override
  List<Object?> get props => [key, value, sources];
}

/// The deterministic rules of UX Design Doc Section 8: as soon as the named
/// values on the tape match a rule, the answers are computed and offered on
/// the strip. The port of the prototype's `deterministic`, over the named
/// values the tape holds.
///
/// Any two of Length, Width and Height give Area, Diagonal and Perimeter,
/// in that order (Figma 62421:72531: two sides default to Area, never
/// straight to drywall); Length and Width are read first, then Length and
/// Height, then Width and Height. All three give a box: Volume and Wall
/// area lead, and the rectangle facts of Length and Width follow (BuildCalc
/// [Height]: "Calculate Volume, Wall Area and Room Area"). Rise and Run
/// give the Diagonal of the right triangle (rule 4.4, BuildCalc p50: 12ft
/// and 15ft give 19.21ft).
///
/// Derived lengths follow the entry system (Section 8): metres when every
/// length read was metric, feet otherwise; an area or a volume follows the
/// same vote. Rounding points are the prototype's: a diagonal is rounded
/// to whole ticks (JavaScript's `Math.round`, a half tick toward +∞), an
/// area is the exact product of the ticks and a perimeter their exact sum.
/// A volume is kept exact and rounded to two decimals only at display, as
/// the Full Design Doc decides where the prototype pre-rounds it, so the
/// text is the same 960ft³ and a cost later prices what is shown.
class DeterministicRules extends Equatable {
  /// The label of the area of two named sides.
  static const String areaKey = 'Area';

  /// The label of the diagonal of two named sides, or of Rise and Run.
  static const String diagonalKey = 'Diagonal';

  /// The label of the perimeter of two named sides.
  static const String perimeterKey = 'Perimeter';

  /// The label of the volume of a box.
  static const String volumeKey = 'Volume';

  /// The label of the area of a box's four walls.
  static const String wallAreaKey = 'Wall area';

  const DeterministicRules();

  /// The answers [namedValues] earn, in the order the strip offers them;
  /// empty when no rule matches. [namedValues] maps a chip key to the
  /// value under it, as [Tape.namedValues] collects them.
  List<Answer> answersFor(Map<String, Quantity> namedValues) {
    final lengths = <DimensionKey, Length>{};
    for (final key in DimensionKey.values) {
      final value = namedValues[key.id];
      if (value is Length) lengths[key] = value;
    }
    final unit = _entrySystemUnit(lengths.values);
    return [
      ..._box(lengths, unit),
      ..._rectangle(lengths, unit),
      ..._rightTriangle(lengths, unit),
    ];
  }

  static const List<(DimensionKey, DimensionKey)> _sidePairs = [
    (DimensionKey.length, DimensionKey.width),
    (DimensionKey.length, DimensionKey.height),
    (DimensionKey.width, DimensionKey.height),
  ];

  List<Answer> _box(Map<DimensionKey, Length> lengths, Unit unit) {
    final length = lengths[DimensionKey.length];
    final width = lengths[DimensionKey.width];
    final height = lengths[DimensionKey.height];
    if (length == null || width == null || height == null) return const [];
    final sources = [
      DimensionKey.length.id,
      DimensionKey.width.id,
      DimensionKey.height.id,
    ];
    return [
      Answer(
        key: volumeKey,
        value: Volume(
          _feetOf(length) * _feetOf(width) * _feetOf(height),
          unit: unit,
        ),
        sources: sources,
      ),
      Answer(
        key: wallAreaKey,
        value: Area(
          2 * (length.ticks + width.ticks) * height.ticks.toDouble(),
          unit: unit,
        ),
        sources: sources,
      ),
    ];
  }

  List<Answer> _rectangle(Map<DimensionKey, Length> lengths, Unit unit) {
    for (final (first, second) in _sidePairs) {
      final a = lengths[first];
      final b = lengths[second];
      if (a != null && b != null) {
        return _rectangleOf(a.ticks, b.ticks, [first.id, second.id], unit);
      }
    }
    return const [];
  }

  List<Answer> _rectangleOf(int a, int b, List<String> sources, Unit unit) => [
    Answer(
      key: areaKey,
      value: Area(a * b.toDouble(), unit: unit),
      sources: sources,
    ),
    Answer(
      key: diagonalKey,
      value: Length(_wholeTicks(_hypotenuse(a, b)), unit: unit),
      sources: sources,
    ),
    Answer(
      key: perimeterKey,
      // Whole-number math wraps only past 6 × 10^15ft, which CA-1236's limit
      // rules out.
      value: Length(2 * (a + b), unit: unit),
      sources: sources,
    ),
  ];

  List<Answer> _rightTriangle(Map<DimensionKey, Length> lengths, Unit unit) {
    final rise = lengths[DimensionKey.rise];
    final run = lengths[DimensionKey.run];
    if (rise == null || run == null || run.ticks <= 0) return const [];
    return [
      Answer(
        key: diagonalKey,
        value: Length(
          _wholeTicks(_hypotenuse(rise.ticks, run.ticks)),
          unit: unit,
        ),
        sources: [DimensionKey.rise.id, DimensionKey.run.id],
      ),
    ];
  }

  Unit _entrySystemUnit(Iterable<Length> lengths) =>
      lengths.isNotEmpty && lengths.every((length) => length.unit.isMetric)
      ? Unit.metre
      : Unit.foot;

  // Both squares in double math: an int square wraps past 3,954,427ft, which
  // is inside the 19,999,999.99 limit CA-1236 will enforce.
  double _hypotenuse(int a, int b) =>
      math.sqrt(a.toDouble() * a + b.toDouble() * b);

  double _feetOf(Length length) => length.ticks / Length.ticksPerFoot;

  int _wholeTicks(double ticks) => (ticks + 0.5).floor();

  @override
  List<Object?> get props => const [];
}
