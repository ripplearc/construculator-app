import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/quantity_formatter.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:construculator/libraries/calculator_engine/trig.dart';
import 'package:equatable/equatable.dart';

/// An angle the drawer remembers: the entry it is offered back as, with the
/// spelling it was typed or rendered in (38°03' stays 38°03'), and the angle
/// it is worth at full precision, so that a recalled answer computes from
/// the value and not from the two decimals on screen.
final class RememberedAngle extends Equatable {
  /// The entry the recalled chip shows.
  final EntryBuffer entry;

  /// The angle the entry stands for.
  final Angle value;

  const RememberedAngle({required this.entry, required this.value});

  @override
  List<Object?> get props => [entry, value];
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
/// Two entries are the same value when they read the same: 38°03' typed as
/// 38 [D:M:S] 03 and the answer 38.05° rendered as D:M:S are one entry. The
/// drawer keeps the minus sign of a negative answer (-30°00' files as it
/// reads, with a hyphen); [Tape.recall] refuses it into Pitch, which needs
/// an angle above 0°, and takes it under a forward trig key.
class AngleMemory extends Equatable {
  /// How many angles the drawer keeps: three, so that a value reused across
  /// a job stays reachable without the drawer becoming a menu.
  static const int depth = 3;

  /// The remembered angles, newest first, at most [depth], no two reading
  /// the same.
  final List<RememberedAngle> remembered;

  /// An empty drawer.
  const AngleMemory() : remembered = const [];

  /// A drawer holding [angles], newest first, under the drawer's own rules:
  /// a later entry that reads like an earlier one is dropped, and only the
  /// first [depth] are kept. The list is copied, so the caller's list can
  /// change afterwards without changing the drawer.
  AngleMemory.of(Iterable<RememberedAngle> angles) : remembered = _kept(angles);

  static List<RememberedAngle> _kept(Iterable<RememberedAngle> angles) {
    final kept = <RememberedAngle>[];
    for (final angle in angles) {
      if (kept.length == depth) break;
      if (kept.any((earlier) => earlier.entry.text == angle.entry.text)) {
        continue;
      }
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

  /// The drawer with [chip]'s typed number filed, when it reads as an angle
  /// ([ValueChip.typedAngle]); any other chip leaves the drawer as it is.
  /// A typed angle is never negative: the keypad has no minus.
  AngleMemory filed(ValueChip chip) {
    final angle = chip.typedAngle;
    if (angle == null) return this;
    return _withFront(RememberedAngle(entry: chip.entry, value: angle));
  }

  /// The drawer with an angle answer filed, as the entry [formatter] renders
  /// it (53.13°, or 31°26'56" for an answer spelled that way) over the exact
  /// value, so that the recalled chip reads as the answer did and computes
  /// from what the answer was worth. The entry is read off the formatter's
  /// own text, so the two can never split an angle differently. A pitch
  /// answer is filed in degrees, the spelling every angle key reads
  /// (16in/12in comes back as 53.13°); a negative answer keeps its minus
  /// sign, written as a hyphen whichever sign the formatter wrote.
  AngleMemory filedAnswer(
    Angle answer, {
    required QuantityFormatter formatter,
  }) {
    final angle = switch (answer.spelling) {
      AngleSpelling.risePerFoot ||
      AngleSpelling.grade => answer.spelledAs(AngleSpelling.degrees),
      AngleSpelling.degrees || AngleSpelling.degreesMinutesSeconds => answer,
    };
    final entry = spelledAnswer(angle, formatter: formatter);
    if (entry == null) return this;
    return _withFront(RememberedAngle(entry: entry, value: angle));
  }

  /// The entry an angle answer reads as, taken off [formatter]'s own text
  /// (53.13, or 31°26'56" for an answer spelled that way), the one the
  /// drawer files and the one the D:M:S key converts a recalled angle to
  /// in place, so that the two can never split an angle differently.
  /// `null` for a spelling the formatter does not write as a plain number
  /// or a D:M:S angle.
  static EntryBuffer? spelledAnswer(
    Angle angle, {
    required QuantityFormatter formatter,
  }) => _spelled(
    formatter
        .format(angle, groupThousands: false)
        .replaceFirst(QuantityFormatter.minusSign, '-'),
  );

  AngleMemory _withFront(RememberedAngle angle) =>
      AngleMemory.of([angle, ...remembered]);

  static final RegExp _degreesMinutesSeconds = RegExp(
    '^(-?\\d+)°(\\d+)\'(?:(\\d+)")?\$',
  );

  static EntryBuffer? _spelled(String rendered) {
    if (_degreesMinutesSeconds.firstMatch(rendered) case final match?) {
      final degrees = match[1];
      final minutes = match[2];
      if (degrees == null || minutes == null) return null;
      return EntryBuffer(
        List.unmodifiable([
          Token(digits: degrees, minutes: minutes, seconds: match[3] ?? ''),
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
