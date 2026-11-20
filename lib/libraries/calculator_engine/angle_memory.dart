import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/quantity_formatter.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:construculator/libraries/calculator_engine/trig.dart';
import 'package:equatable/equatable.dart';

/// Which end of the drawer's six decimals an angle fell past (rule 4.16):
/// it reads 0 or 90 at six decimals and is not 0 or 90, so the drawer shows
/// it as "Under 0.000001°" or "Over 89.999999°" rather than a number that
/// lies. The words are the screen's; the engine says only which.
enum AngleDrawerLimit {
  /// Its size is above 0 and under 0.000001°, so it reads 0 at six
  /// decimals.
  belowSmallest,

  /// Its size is within 0.000001° of 90°, on either side, so it reads 90
  /// (or -90) at six decimals.
  aboveLargest,
}

/// An angle the drawer remembers: the entry it is offered back as, with the
/// spelling it was typed or rendered in (38°03'00" stays 38°03'00"), and
/// the angle it is worth at full precision, so that a recalled answer
/// computes from the value and not from the two decimals on screen. An
/// answer that would read 0 or 90 at the display rounding carries more
/// decimals (rule 4.16; [AngleMemory.spelledForDrawer]), and one that still
/// reads so at six names its [limit] instead.
final class RememberedAngle extends Equatable {
  /// The entry the recalled chip shows.
  final EntryBuffer entry;

  /// The angle the entry stands for.
  final Angle value;

  /// The end of the drawer's decimals the angle fell past, or `null` for an
  /// angle the [entry] reads as it is.
  final AngleDrawerLimit? limit;

  const RememberedAngle({required this.entry, required this.value, this.limit});

  /// Whether [other] is the same drawer entry: it reads as the same angle in
  /// any spelling, or it is worth the same angle (rule 4.16, "filed by what
  /// it reads as": 30, 30°00'00" and an answer shown as 30 are one entry,
  /// whichever was filed first, and so are 31.45 and 31°26'56" when both
  /// are one answer). The same means within [AngleMemory.sameAngleTolerance]
  /// of each other, so 38.02 and 38°01'12" are one entry although a double
  /// reads the second as 38.019999999999996. A limit angle is never the
  /// same entry as an angle that is exactly 0 or 90, although both read 0
  /// or 90: "Under 0.000001°" and 0 are two angles that read differently.
  bool isSameEntryAs(RememberedAngle other) =>
      !_isALimitBesideAnExactAngle(other) &&
      (_isSameAngle(_degreesItReadsAs, other._degreesItReadsAs) ||
          _isSameAngle(value.degrees, other.value.degrees));

  bool _isALimitBesideAnExactAngle(RememberedAngle other) =>
      (limit != null || other.limit != null) &&
      (_isExactlyZeroOrRightAngle || other._isExactlyZeroOrRightAngle);

  bool get _isExactlyZeroOrRightAngle =>
      AngleMemory._isZeroOrRightAngle(value.degrees);

  double get _degreesItReadsAs =>
      entry.tokens.firstOrNull?.value ?? value.degrees;

  static bool _isSameAngle(double degrees, double otherDegrees) =>
      (degrees - otherDegrees).abs() <= AngleMemory.sameAngleTolerance;

  @override
  List<Object?> get props => [entry, value, limit];
}

/// The shared angle drawer of UX Design Doc rule 4.16: a value enters it
/// once, newest first, three deep, no duplicates, and re-filing a value
/// moves it to the front rather than skipping it. Lengths are filed under
/// their key, which is right for them ([Width] must never offer a length);
/// angles are the exception, because a rafter angle typed under Sine is the
/// same physical thing when Pitch wants it, so every angle goes into one
/// drawer and any key that takes an angle can have it back (S118). Inverse
/// trig keys never offer one, because they take a ratio.
///
/// The drawer is a value: the caller files a typed value when it seals, a
/// value still active when C is pressed, and an angle answer once, when it
/// renders, and keeps the drawer that comes back. On an empty row the strip
/// shows the three newest; once computed answers are on the row it shows
/// one (Section 1.2; [offeredFor]), and [Tape.recall] types the one tapped
/// into the empty chip the key opened. When the chip is removed from the
/// strip (the first keystroke) is the strip's rule.
///
/// Two spellings of one angle are one entry, kept in the newest spelling
/// (rule 4.16): 30 typed under Sine and 30°00'00" typed afterwards are the
/// one entry 30°00'00", and 38.05 and 38°03'00" are one, since three
/// minutes are 0.05°. Two entries that read the same are one as well, so
/// the answer 38.05° and a typed 38.05 never sit side by side. The drawer
/// keeps the minus of a negative answer (-30°00'00" files as it reads, with
/// its hyphen); [Tape.recall] refuses it into Pitch, which needs an angle
/// above 0°, and takes it under a forward trig key.
class AngleMemory extends Equatable {
  /// How many angles the drawer keeps: three, so that a value reused across
  /// a job stays reachable without the drawer becoming a menu.
  static const int depth = 3;

  /// How far apart two angles may be and still be one angle: a billionth
  /// of a degree, which is well under a second of arc (1/3600°, the finest
  /// any spelling shows) and well over the rounding noise of a double, so
  /// that Arcsine 0.5, which a double computes as 29.999999999999996°, is
  /// the same entry as a typed 30.
  static const double sameAngleTolerance = 1e-9;

  /// The remembered angles, newest first, at most [depth], no two the same
  /// entry ([RememberedAngle.isSameEntryAs]).
  final List<RememberedAngle> remembered;

  /// An empty drawer.
  const AngleMemory() : remembered = const [];

  /// A drawer holding [angles], newest first, under the drawer's own rules:
  /// a later entry that reads like an earlier one, or is worth the same
  /// angle, is dropped, and only the first [depth] are kept. The list is
  /// copied, so the caller's list can change afterwards without changing
  /// the drawer.
  AngleMemory.of(Iterable<RememberedAngle> angles) : remembered = _kept(angles);

  static List<RememberedAngle> _kept(Iterable<RememberedAngle> angles) {
    final kept = <RememberedAngle>[];
    for (final angle in angles) {
      if (kept.length == depth) break;
      if (kept.any((earlier) => earlier.isSameEntryAs(angle))) continue;
      kept.add(angle);
    }
    return List.unmodifiable(kept);
  }

  /// Whether [key] can have an angle back: Pitch and the forward trig keys.
  static bool keyTakesAnAngle(String key) =>
      key == PlainNumberKeys.pitch ||
      TrigFunction.named(key)?.isInverse == false;

  /// The remembered angles the strip offers when [key] is pressed, newest
  /// first: the three newest on an empty row, the newest one beside the
  /// computed answers of a live row ([rowHasAnswers]; Section 1.2, the
  /// strip ladder); none for a key that takes no angle.
  List<RememberedAngle> offeredFor(String key, {required bool rowHasAnswers}) {
    if (!keyTakesAnAngle(key)) return const [];
    return List.unmodifiable(remembered.take(rowHasAnswers ? 1 : depth));
  }

  /// The drawer with [chip]'s typed value filed, when it reads as an angle
  /// ([ValueChip.filedAngle]); any other chip leaves the drawer as it is.
  /// A number typed as degrees or D:M:S is filed as it reads once sealed
  /// ([EntryBuffer.sealed]), so a chip filed while still active (C pressed
  /// on 38 [D:M:S] 75) comes back as 39°15'00", the spelling the tape
  /// shows for it, never as a field left open. A pitch typed in inches of
  /// rise is filed as the degrees it is worth, spelled as an answer is
  /// ([filedAnswer]): [Pitch] 6 [Inch] comes back as 26.57° over the exact
  /// angle, and the same chip filed again when its answer renders is still
  /// one entry (rule 4.16; product decision of 23 October 2026). A typed
  /// angle is never negative: the keypad has no minus.
  AngleMemory filed(
    ValueChip chip, {
    required QuantityParser parser,
    required QuantityFormatter formatter,
  }) {
    final angle = chip.filedAngle(parser);
    if (angle == null) return this;
    if (angle.spelling == AngleSpelling.risePerFoot) {
      return filedAnswer(angle, formatter: formatter);
    }
    return _withFront(RememberedAngle(entry: chip.entry.sealed, value: angle));
  }

  /// The drawer with an angle answer filed, as the entry [formatter] renders
  /// it (53.13°, or 31°26'56" for an answer spelled that way) over the exact
  /// value, so that the recalled chip reads as the answer did and computes
  /// from what the answer was worth. The entry is read off the formatter's
  /// own text, so the two can never split an angle differently. A pitch
  /// answer is filed in degrees, the spelling every angle key reads
  /// (16in/12in comes back as 53.13°); a negative answer keeps its hyphen.
  /// An answer that would read 0 or 90 and is not gets more decimals
  /// ([spelledForDrawer]; rule 4.16, product manager 17 November 2026).
  AngleMemory filedAnswer(
    Angle answer, {
    required QuantityFormatter formatter,
  }) {
    final angle = switch (answer.spelling) {
      AngleSpelling.risePerFoot ||
      AngleSpelling.grade => answer.spelledAs(AngleSpelling.degrees),
      AngleSpelling.degrees || AngleSpelling.degreesMinutesSeconds => answer,
    };
    final spelled = spelledForDrawer(angle, formatter: formatter);
    if (spelled == null) return this;
    return _withFront(
      RememberedAngle(entry: spelled.entry, value: angle, limit: spelled.limit),
    );
  }

  /// The decimals a remembered angle shows, the display's two.
  static const int drawerDecimals = 2;

  /// The most decimals the drawer adds before it names a limit instead.
  static const int drawerMostDecimals = 6;

  /// The entry the drawer files an angle answer as (rule 4.16): the
  /// [formatter]'s own spelling at two decimals, and, when that would read
  /// 0.00° or 90.00° for an angle that is not exactly 0 or 90, one decimal
  /// more at a time up to six (ASIN 0.00001 files as 0.001°, ACOS 0.00001
  /// as 89.999°, Pitch 9999999 Inch as 89.9999°). Exactly means as the
  /// double holds it: ASIN 1 is 90.0, while ASIN 0.00000000001 is 5.7e-10°
  /// and not 0. A D:M:S answer keeps its three fields and only its seconds
  /// take the decimals, by the same rule (0.00001° files as 0°00'00.04",
  /// 89.99999° as 89°59'59.96"). An angle that still reads 0 or 90 at six
  /// decimals keeps that spelling and names the [AngleDrawerLimit] it fell
  /// past, "Under 0.000001°" or "Over 89.999999°". `null` for a spelling
  /// the formatter does not write as a plain number or a D:M:S angle.
  static ({EntryBuffer entry, AngleDrawerLimit? limit})? spelledForDrawer(
    Angle angle, {
    required QuantityFormatter formatter,
  }) {
    final isDegreesMinutesSeconds =
        angle.spelling == AngleSpelling.degreesMinutesSeconds;
    final exact = _isZeroOrRightAngle(angle.degrees);
    EntryBuffer? spelledTo(int decimals) => _spelled(
      isDegreesMinutesSeconds
          ? formatter.formatDegreesMinutesSeconds(
              angle,
              secondsDecimals: decimals,
            )
          : formatter.formatDegrees(angle, decimals: decimals),
    );
    for (
      var decimals = isDegreesMinutesSeconds ? 0 : drawerDecimals;
      decimals <= drawerMostDecimals;
      decimals++
    ) {
      final entry = spelledTo(decimals);
      if (entry == null) return null;
      if (exact || !_isZeroOrRightAngle(entry.tokens.single.value)) {
        return (entry: entry, limit: null);
      }
    }
    final pastTheLimit = spelledTo(drawerMostDecimals);
    if (pastTheLimit == null) return null;
    return (
      entry: pastTheLimit,
      limit: angle.degrees.abs() < _halfOfARightAngle
          ? AngleDrawerLimit.belowSmallest
          : AngleDrawerLimit.aboveLargest,
    );
  }

  static const double _halfOfARightAngle = 45;

  static bool _isZeroOrRightAngle(double degrees) =>
      degrees == 0 || degrees.abs() == 90;

  /// The entry an angle answer reads as, taken off [formatter]'s own text
  /// (53.13, or 31°26'56" for an answer spelled that way), the one the
  /// drawer files and the one the D:M:S key converts a recalled angle to
  /// in place, so that the two can never split an angle differently.
  /// `null` for a spelling the formatter does not write as a plain number
  /// or a D:M:S angle.
  static EntryBuffer? spelledAnswer(
    Angle angle, {
    required QuantityFormatter formatter,
  }) => _spelled(formatter.format(angle, groupThousands: false));

  AngleMemory _withFront(RememberedAngle angle) =>
      AngleMemory.of([angle, ...remembered]);

  static final RegExp _degreesMinutesSeconds = RegExp(
    '^(-?\\d+)°(\\d+)\'(\\d+(?:\\.\\d+)?)"\$',
  );

  static EntryBuffer? _spelled(String rendered) {
    if (_degreesMinutesSeconds.firstMatch(rendered) case final match?) {
      final degrees = match[1];
      final minutes = match[2];
      final seconds = match[3];
      if (degrees == null || minutes == null || seconds == null) return null;
      return EntryBuffer(
        List.unmodifiable([
          Token(digits: degrees, minutes: minutes, seconds: seconds),
        ]),
      );
    }
    final digits = rendered.replaceFirst('°', '');
    if (double.tryParse(digits) == null) return null;
    return EntryBuffer(List.unmodifiable([Token(digits: digits)]));
  }

  @override
  List<Object?> get props => [remembered];
}
