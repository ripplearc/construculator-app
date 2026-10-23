import 'dart:math' as math;

import 'package:construculator/libraries/calculator_engine/chain_arithmetic.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:construculator/libraries/calculator_engine/quantity_formatter.dart';
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
  run('Run'),

  /// The diameter of a circle or a regular polygon.
  diameter('Diameter'),

  /// The radius of a circle.
  radius('Radius'),

  /// The number of sides of a regular polygon, a bare number.
  sides('Sides'),

  /// The chord of an arc; Run is read as the chord when no Chord is named.
  chord('Chord'),

  /// The hypotenuse of a right triangle, typed under the Diag key (the
  /// key's label in the app, the UX Design Doc and the prototype); a
  /// diagonal a rule computes is offered as [DeterministicRules.diagonalKey].
  diagonal('Diag'),

  /// The pitch of a roof: a length is inches of rise per 12in of run, a
  /// bare number is degrees (Section 8, "Pitch alone"; the F3 grammar).
  pitch('Pitch'),

  /// The grade of a slope, a bare number in percent (Section 8, "Slope").
  slope('Slope');

  /// The chip key the function key writes.
  final String id;

  const DimensionKey(this.id);
}

/// Which span of a regular polygon its diameter measures (UX Design Doc
/// Section 8, "Regular polygon"; the Across pill of walkthrough 18.2).
/// BuildCalc silently assumes corner to corner; here the assumption is an
/// editable dependent key on the result.
enum PolygonSpan {
  /// Corner to corner: the diameter of the circumscribed circle.
  corners,

  /// Flat to flat: the corner radius grows by 1 ÷ cos(π ÷ n).
  flats,
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
/// give the pitch three ways — inches of rise per 12in of run, degrees and
/// a percent grade, one angle in three spellings — and then the Diagonal of
/// the right triangle (rule 4.4, BuildCalc p50: 12ft and 15ft give
/// 19.21ft). Section 8 lists three pairs — Pitch with Diag (Rise = Diag ×
/// sin θ, Run = Diag × cos θ), Pitch with Run (Rise = Run × tan θ, Diagonal
/// = Run ÷ cos θ) and Rise with Run — and this port adds two that neither
/// the doc nor the prototype has: Pitch with Rise, and a Diagonal with one
/// leg, which answers the other leg first and then the pitch. A pitch on
/// its own offers all three spellings, degrees first (Section 8, "Pitch
/// alone"), and a bare number under Slope is a percent grade that reads as
/// a pitch, offers its other two spellings and solves Rise with Run (Section
/// 8, "Slope"). A pitch of 0° or less, or of 90° or more, solves nothing and
/// offers nothing (Section 5.1, "A pitch has to be under 90°": the strip
/// says why), and a solved leg past [ChainArithmetic.maxTicks] is left out
/// where the prototype would show it. Height with a Radius or a Diameter
/// gives the column and the cone (Section 8, "Column and cone": π r² h, and
/// a third of it), leading the circle facts, and reads the Diameter when
/// both are named, as the circle facts do. A rise, a run or a diagonal the
/// solver computes keeps its fraction of a tick ([Length.computed]) and is
/// rounded once, at display, as the rectangle's diagonal is. A rise below
/// zero, or a column whose height or span is zero or less, answers nothing:
/// a drop below grade is not a roof and a flat or hollow column is no
/// column. A flat triangle offers its 0° pitch (Rise 0 with a Run, or a
/// Diagonal equal to the Run), as the owner decided on 2026-10-15; an
/// upright one (Run 0, or a Diagonal equal to the Rise) is no triangle, as
/// Section 5.4 refuses 90°. A Diameter or a Radius gives the missing half
/// of the pair first (what BuildCalc's first [Circle] press shows), then
/// the circle's area and circumference; with Sides it gives a regular
/// polygon instead, measured across the corners: area, side length,
/// perimeter and corner angle (BuildCalc p129: 12ft and 6 sides is the
/// gazebo floor), and [polygonArea] recomputes the area for the Across
/// pill. A chord and a segment height — Chord and Rise, or Run and Rise,
/// with Rise read as the height — give the arc (BuildCalc [Arc] p13):
/// radius R = (c² ÷ 8h) + h ÷ 2, central angle 2 asin(c ÷ 2R), taken as
/// the major arc when the height exceeds half the chord, and arc length
/// R × angle. An arc whose radius would pass [Length.maxTicks] is left
/// out, as a Diagonal is: a chord at the size limit over a one-tick height
/// has no radius a length can hold. Entered as Run and Rise the triangle's
/// Diagonal comes first and the arc follows; which one leads the strip is
/// the arbiter's.
///
/// Derived lengths follow the entry system (Section 8): metres when every
/// side the rule read was metric, feet otherwise, so a chip no rule used
/// never changes an answer's unit (rule 4.5); an area or a volume follows
/// the same vote. A diagonal keeps its fraction of a tick ([Length.computed])
/// and is rounded once, at display (Section 6, "Nothing is rounded until it
/// is displayed"; Section 8, the formulas are computed exactly): 13ft by
/// 13ft reads 18.38ft, as the prototype's open PR has it, where a whole
/// tick read 18.39ft. An area is the exact product of the ticks and a
/// perimeter their exact sum. The diagonal's squares are taken in double
/// math, because an `int` square wraps past 3,954,427ft, inside the limit
/// CA-1236 will enforce; the perimeter's `int` sum wraps only past 6 ×
/// 10^15ft, a side that limit refuses once it lands. A diagonal past
/// [Length.maxTicks], the 2⁵³ ticks a computed length holds, is left out
/// and the other answers stay, until that limit refuses such a side. A
/// volume is kept exact and rounded to two decimals only at display, as the
/// Full Design Doc decides where the prototype pre-rounds it, so the text is
/// the same 960ft³. A cost prices the displayed value (rule 4.15), so the
/// cost step must round the volume to two decimals before it prices it:
/// 986.6667ft³ reads 986.67ft³ and is priced as 986.67ft³, not as the exact
/// volume.
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

  /// The label of a circle's or polygon's diameter.
  static const String diameterKey = 'Diameter';

  /// The label of a circle's radius.
  static const String radiusKey = 'Radius';

  /// The label of a circle's area.
  static const String circleAreaKey = 'Circle area';

  /// The label of a circle's circumference.
  static const String circumferenceKey = 'Circumference';

  /// The label of a regular polygon's area.
  static const String polygonAreaKey = 'Polygon area';

  /// The label of a regular polygon's side.
  static const String sideLengthKey = 'Side length';

  /// The label of a regular polygon's corner angle.
  static const String cornerAngleKey = 'Corner angle';

  /// The fewest sides a regular polygon can have.
  static const int fewestSides = 3;

  /// The label of an arc's central angle.
  static const String arcAngleKey = 'Arc angle';

  /// The label of an arc's radius.
  static const String arcRadiusKey = 'Arc radius';

  /// The label of an arc's length.
  static const String arcLengthKey = 'Arc length';

  /// The label of the pitch written as inches of rise per 12in of run.
  static const String pitchRiseKey = 'Pitch-rise per 12in run';

  /// The label of the pitch written in degrees.
  static const String pitchDegreesKey = 'Pitch-degrees';

  /// The label of the pitch written as a percent grade.
  static const String pitchGradeKey = 'Pitch-grade';

  /// The label of a rise the solver found.
  static const String riseKey = 'Rise';

  /// The label of a run the solver found.
  static const String runKey = 'Run';

  /// The label of a column's volume.
  static const String columnKey = 'Column';

  /// The label of a cone's volume, a third of the column's.
  static const String coneKey = 'Cone';

  /// A cone holds a third of the column on the same base (Section 8).
  static const int coneDivisor = 3;

  /// Degrees in a right angle: a pitch this steep has no run to solve from.
  static const int rightAngle = 90;

  /// Degrees in a full turn.
  static const int fullTurn = 360;

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
    return [
      ..._columnAndCone(lengths),
      ..._box(lengths),
      ..._rectangle(lengths),
      ..._triangle(lengths, _pitchOf(namedValues)),
      ..._arc(lengths),
      ..._shape(lengths, _sidesOf(namedValues)),
    ];
  }

  List<Answer> _columnAndCone(Map<DimensionKey, Length> lengths) {
    final height = lengths[DimensionKey.height];
    final (span, radiusTicks, spanKey) = switch ((
      lengths[DimensionKey.diameter],
      lengths[DimensionKey.radius],
    )) {
      (final Length diameter, _) => (
        diameter,
        diameter.preciseTicks / 2,
        DimensionKey.diameter,
      ),
      (null, final Length radius) => (
        radius,
        radius.preciseTicks,
        DimensionKey.radius,
      ),
      (null, null) => (null, 0.0, DimensionKey.radius),
    };
    if (height == null || span == null) return const [];
    if (height.preciseTicks <= 0 || radiusTicks <= 0) return const [];
    final radiusFeet = radiusTicks / Length.ticksPerFoot;
    final column =
        math.pi *
        radiusFeet *
        radiusFeet *
        height.preciseTicks /
        Length.ticksPerFoot;
    final unit = _entrySystemUnit([height, span]);
    final sources = [DimensionKey.height.id, spanKey.id];
    return [
      Answer(
        key: columnKey,
        value: Volume(column, unit: unit),
        sources: sources,
      ),
      Answer(
        key: coneKey,
        value: Volume(column / coneDivisor, unit: unit),
        sources: sources,
      ),
    ];
  }

  /// The area of a regular polygon of [sides] sides whose [diameter] was
  /// measured across the corners or across the flats (Section 8:
  /// R = D ÷ 2, or (D ÷ 2) ÷ cos(π ÷ n) across the flats; area =
  /// ½ n R² sin(2π ÷ n)), in square ticks. The port of the prototype's
  /// `polygonArea`, shared with the Across pill so that flipping the pill
  /// recomputes through the same formula. [sides] must be at least
  /// [fewestSides], as [answersFor] guarantees before it calls this: fewer
  /// is no polygon, and the formula would answer with a number anyway.
  Area polygonArea(
    Length diameter,
    int sides, {
    PolygonSpan across = PolygonSpan.corners,
    Unit unit = Unit.foot,
  }) {
    assert(sides >= fewestSides, 'a polygon has at least $fewestSides sides');
    final cornerRadius = switch (across) {
      PolygonSpan.corners => diameter.ticks / 2,
      PolygonSpan.flats => diameter.ticks / 2 / math.cos(math.pi / sides),
    };
    return Area(
      0.5 * sides * cornerRadius * cornerRadius * math.sin(2 * math.pi / sides),
      unit: unit,
    );
  }

  List<Answer> _arc(Map<DimensionKey, Length> lengths) {
    final chordKey = lengths.containsKey(DimensionKey.chord)
        ? DimensionKey.chord
        : DimensionKey.run;
    final chord = lengths[chordKey];
    final height = lengths[DimensionKey.rise];
    if (chord == null || height == null) return const [];
    final unit = _entrySystemUnit([chord, height]);
    if (chord.ticks <= 0 || height.ticks <= 0) return const [];
    final c = chord.ticks.toDouble();
    final h = height.ticks.toDouble();
    final radius = (h * h + c * c / 4) / (2 * h);
    if (radius > Length.maxTicks) return const [];
    final minorAngle =
        2 * math.asin(math.min(1, c / (2 * radius))) * 180 / math.pi;
    final angle = h > c / 2 ? fullTurn - minorAngle : minorAngle;
    final sources = [chordKey.id, DimensionKey.rise.id];
    return [
      Answer(key: arcAngleKey, value: Angle(angle), sources: sources),
      Answer(
        key: arcRadiusKey,
        value: Length(_wholeTicks(radius), unit: unit),
        sources: sources,
      ),
      Answer(
        key: arcLengthKey,
        value: Length(_wholeTicks(radius * angle * math.pi / 180), unit: unit),
        sources: sources,
      ),
    ];
  }

  int? _sidesOf(Map<String, Quantity> namedValues) {
    if (namedValues[DimensionKey.sides.id] case Scalar(
      :final value,
    ) when value >= fewestSides && value == value.roundToDouble()) {
      return value.toInt();
    }
    return null;
  }

  List<Answer> _shape(Map<DimensionKey, Length> lengths, int? sides) {
    final diameter = lengths[DimensionKey.diameter];
    final radius = lengths[DimensionKey.radius];
    // TODO: [CA-1236] The int doubling wraps past 2^62 ticks, about 6 × 10^15ft
    // a radius; the 19,999,999.99 limit refuses such a radius after CA-1236
    // merges. https://ripplearc.youtrack.cloud/issue/CA-1236
    final span =
        diameter ??
        (radius == null ? null : Length(2 * radius.ticks, unit: radius.unit));
    if (span == null) return const [];
    final unit = _entrySystemUnit([span]);
    final sources = [
      diameter == null ? DimensionKey.radius.id : DimensionKey.diameter.id,
    ];
    if (sides != null) return _polygon(span, sides, sources, unit);
    final missingHalf = diameter == null
        ? Answer(
            key: diameterKey,
            value: Length(span.ticks, unit: unit),
            sources: sources,
          )
        : Answer(
            key: radiusKey,
            value: Length(_wholeTicks(span.ticks / 2), unit: unit),
            sources: sources,
          );
    final halfTicks = span.ticks / 2;
    return [
      missingHalf,
      Answer(
        key: circleAreaKey,
        value: Area(math.pi * halfTicks * halfTicks, unit: unit),
        sources: sources,
      ),
      Answer(
        key: circumferenceKey,
        value: Length(_wholeTicks(math.pi * span.ticks), unit: unit),
        sources: sources,
      ),
    ];
  }

  List<Answer> _polygon(
    Length span,
    int sides,
    List<String> spanSources,
    Unit unit,
  ) {
    final sources = [...spanSources, DimensionKey.sides.id];
    final side = span.ticks * math.sin(math.pi / sides);
    return [
      Answer(
        key: polygonAreaKey,
        value: polygonArea(span, sides, unit: unit),
        sources: sources,
      ),
      Answer(
        key: sideLengthKey,
        value: Length(_wholeTicks(side), unit: unit),
        sources: sources,
      ),
      Answer(
        key: perimeterKey,
        value: Length(_wholeTicks(sides * side), unit: unit),
        sources: sources,
      ),
      Answer(
        key: cornerAngleKey,
        value: Angle(180 - 360 / sides),
        sources: sources,
      ),
    ];
  }

  static const List<(DimensionKey, DimensionKey)> _sidePairs = [
    (DimensionKey.length, DimensionKey.width),
    (DimensionKey.length, DimensionKey.height),
    (DimensionKey.width, DimensionKey.height),
  ];

  List<Answer> _box(Map<DimensionKey, Length> lengths) {
    final length = lengths[DimensionKey.length];
    final width = lengths[DimensionKey.width];
    final height = lengths[DimensionKey.height];
    if (length == null || width == null || height == null) return const [];
    final unit = _entrySystemUnit([length, width, height]);
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

  List<Answer> _rectangle(Map<DimensionKey, Length> lengths) {
    for (final (first, second) in _sidePairs) {
      final a = lengths[first];
      final b = lengths[second];
      if (a != null && b != null) {
        return _rectangleOf(a.ticks, b.ticks, [
          first.id,
          second.id,
        ], _entrySystemUnit([a, b]));
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
    ?_leg(diagonalKey, _hypotenuse(a.toDouble(), b.toDouble()), unit, sources),
    // TODO: [CA-1236] The int sum wraps past 6 × 10^15ft a side; the
    // 19,999,999.99 limit refuses such a side after CA-1236 merges.
    // https://ripplearc.youtrack.cloud/issue/CA-1236
    Answer(
      key: perimeterKey,
      value: Length(2 * (a + b), unit: unit),
      sources: sources,
    ),
  ];

  (Angle, DimensionKey)? _pitchOf(Map<String, Quantity> namedValues) {
    final pitch = switch (namedValues[DimensionKey.pitch.id]) {
      final Length rise => _angleOfRatio(
        rise.preciseTicks /
            Length.ticksPerInch /
            QuantityFormatter.inchesPerFootOfRun,
      ).spelledAs(AngleSpelling.risePerFoot),
      final Angle angle => angle,
      Scalar(:final value) => Angle(value),
      _ => null,
    };
    if (pitch != null) return _inRange(pitch, DimensionKey.pitch);
    if (namedValues[DimensionKey.slope.id] case Scalar(:final value)) {
      return _inRange(
        _angleOfRatio(
          value / QuantityFormatter.percent,
        ).spelledAs(AngleSpelling.grade),
        DimensionKey.slope,
      );
    }
    return null;
  }

  (Angle, DimensionKey)? _inRange(Angle pitch, DimensionKey key) =>
      pitch.degrees > 0 && pitch.degrees < rightAngle ? (pitch, key) : null;

  List<Answer> _triangle(
    Map<DimensionKey, Length> lengths,
    (Angle, DimensionKey)? pitch,
  ) {
    final rise = lengths[DimensionKey.rise];
    final run = lengths[DimensionKey.run];
    final diagonal = lengths[DimensionKey.diagonal];
    if (rise != null && run != null) return _fromRiseAndRun(rise, run);
    if (pitch case (final angle, final key)) {
      return _fromPitch(angle, key, rise: rise, run: run, diagonal: diagonal);
    }
    if (diagonal != null && rise != null) {
      return _fromDiagonalAndLeg(diagonal, rise, DimensionKey.rise);
    }
    if (diagonal != null && run != null) {
      return _fromDiagonalAndLeg(diagonal, run, DimensionKey.run);
    }
    return const [];
  }

  List<Answer> _fromRiseAndRun(Length rise, Length run) {
    if (run.preciseTicks <= 0 || rise.preciseTicks < 0) return const [];
    final sources = [DimensionKey.rise.id, DimensionKey.run.id];
    return [
      ..._pitchFamily(
        _angleOfRatio(rise.preciseTicks / run.preciseTicks),
        sources,
      ),
      ?_leg(
        diagonalKey,
        _hypotenuse(rise.preciseTicks, run.preciseTicks),
        _entrySystemUnit([rise, run]),
        sources,
      ),
    ];
  }

  List<Answer> _fromPitch(
    Angle pitch,
    DimensionKey key, {
    required Length? rise,
    required Length? run,
    required Length? diagonal,
  }) {
    final radians = pitch.degrees * math.pi / 180;
    final sine = math.sin(radians);
    final cosine = math.cos(radians);
    if (diagonal != null) {
      final sources = [key.id, DimensionKey.diagonal.id];
      final unit = _entrySystemUnit([diagonal]);
      return [
        ?_leg(riseKey, diagonal.preciseTicks * sine, unit, sources),
        ?_leg(runKey, diagonal.preciseTicks * cosine, unit, sources),
      ];
    }
    if (run != null) {
      final sources = [key.id, DimensionKey.run.id];
      final unit = _entrySystemUnit([run]);
      return [
        ?_leg(riseKey, run.preciseTicks * sine / cosine, unit, sources),
        ?_leg(diagonalKey, run.preciseTicks / cosine, unit, sources),
      ];
    }
    if (rise != null) {
      final sources = [key.id, DimensionKey.rise.id];
      final unit = _entrySystemUnit([rise]);
      return [
        ?_leg(runKey, rise.preciseTicks * cosine / sine, unit, sources),
        ?_leg(diagonalKey, rise.preciseTicks / sine, unit, sources),
      ];
    }
    return key == DimensionKey.pitch
        ? _pitchFamily(pitch, [key.id], spellings: _degreesFirst)
        : _otherSpellings(pitch, [key.id]);
  }

  List<Answer> _fromDiagonalAndLeg(
    Length diagonal,
    Length leg,
    DimensionKey legKey,
  ) {
    final other = math.sqrt(
      diagonal.preciseTicks * diagonal.preciseTicks -
          leg.preciseTicks * leg.preciseTicks,
    );
    if (!other.isFinite || leg.preciseTicks <= 0) return const [];
    final sources = [legKey.id, DimensionKey.diagonal.id];
    final unit = _entrySystemUnit([leg, diagonal]);
    final (riseTicks, runTicks) = legKey == DimensionKey.rise
        ? (leg.preciseTicks, other)
        : (other, leg.preciseTicks);
    if (runTicks <= 0) return const [];
    return [
      ?_leg(
        legKey == DimensionKey.rise ? runKey : riseKey,
        other,
        unit,
        sources,
      ),
      ..._pitchFamily(_angleOfRatio(riseTicks / runTicks), sources),
    ];
  }

  static const List<AngleSpelling> _riseFirst = [
    AngleSpelling.risePerFoot,
    AngleSpelling.degrees,
    AngleSpelling.grade,
  ];

  static const List<AngleSpelling> _degreesFirst = [
    AngleSpelling.degrees,
    AngleSpelling.risePerFoot,
    AngleSpelling.grade,
  ];

  List<Answer> _pitchFamily(
    Angle pitch,
    List<String> sources, {
    List<AngleSpelling> spellings = _riseFirst,
  }) => [
    for (final spelling in spellings)
      Answer(
        key: _pitchKeyOf(spelling),
        value: pitch.spelledAs(spelling),
        sources: sources,
      ),
  ];

  List<Answer> _otherSpellings(Angle pitch, List<String> sources) {
    final first = pitch.spelling.nextPitchSpelling;
    return [
      for (final spelling in [first, first.nextPitchSpelling])
        Answer(
          key: _pitchKeyOf(spelling),
          value: pitch.spelledAs(spelling),
          sources: sources,
        ),
    ];
  }

  String _pitchKeyOf(AngleSpelling spelling) => switch (spelling) {
    AngleSpelling.risePerFoot => pitchRiseKey,
    AngleSpelling.grade => pitchGradeKey,
    AngleSpelling.degrees ||
    AngleSpelling.degreesMinutesSeconds => pitchDegreesKey,
  };

  Answer? _leg(String key, double ticks, Unit unit, List<String> sources) {
    if (!ticks.isFinite || ticks.abs() > ChainArithmetic.maxTicks) return null;
    return Answer(
      key: key,
      value: Length.computed(ticks, unit: unit),
      sources: sources,
    );
  }

  Angle _angleOfRatio(double ratio) => Angle(math.atan(ratio) * 180 / math.pi);

  Unit _entrySystemUnit(Iterable<Length> lengths) =>
      lengths.isNotEmpty && lengths.every((length) => length.unit.isMetric)
      ? Unit.metre
      : Unit.foot;

  double _hypotenuse(double a, double b) => math.sqrt(a * a + b * b);

  double _feetOf(Length length) => length.ticks / Length.ticksPerFoot;

  int _wholeTicks(double ticks) => (ticks + 0.5).floor();

  @override
  List<Object?> get props => const [];
}
