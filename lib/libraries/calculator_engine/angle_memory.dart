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
/// renders, and keeps the drawer that comes back. Only the newest is ever
/// offered, so the strip never becomes a menu; [Tape.recall] types it into
/// the empty chip the key opened. Which key offers it and when it is
/// removed from the strip (the first keystroke) are the strip's rules.
class AngleMemory extends Equatable {
  /// How many angles the drawer keeps: three, so that a value reused across
  /// a job stays reachable without the drawer becoming a menu.
  static const int depth = 3;

  /// The remembered angles, newest first.
  final List<RememberedAngle> remembered;

  const AngleMemory([this.remembered = const []]);

  /// Whether [key] can have an angle back: Pitch and the forward trig keys.
  static bool keyTakesAnAngle(String key) =>
      key == PlainNumberKeys.pitch ||
      TrigFunction.named(key)?.isInverse == false;

  /// The newest remembered angle for [key], or `null` when the drawer is
  /// empty or the key takes no angle.
  RememberedAngle? newestFor(String key) =>
      keyTakesAnAngle(key) ? remembered.firstOrNull : null;

  /// The drawer with [chip]'s typed number filed, when it reads as an angle
  /// ([ValueChip.typedAngle]); any other chip leaves the drawer as it is.
  AngleMemory filed(ValueChip chip) {
    final angle = chip.typedAngle;
    if (angle == null) return this;
    return _withFront(RememberedAngle(entry: chip.entry, value: angle));
  }

  /// The drawer with an angle answer filed, as the entry [formatter] renders
  /// it (53.13°, or 31°26'56" for an answer spelled that way) over the exact
  /// value, so that the recalled chip reads as the answer did and computes
  /// from what the answer was worth. A pitch answer is filed in degrees,
  /// the spelling every angle key reads (16in/12in comes back as 53.13°).
  AngleMemory filedAnswer(
    Angle answer, {
    required QuantityFormatter formatter,
  }) {
    final angle = switch (answer.spelling) {
      AngleSpelling.risePerFoot ||
      AngleSpelling.grade => answer.spelledAs(AngleSpelling.degrees),
      AngleSpelling.degrees || AngleSpelling.degreesMinutesSeconds => answer,
    };
    return _withFront(
      RememberedAngle(entry: _spelled(angle, formatter), value: angle),
    );
  }

  AngleMemory _withFront(RememberedAngle angle) => AngleMemory(
    List.unmodifiable(
      [
        angle,
        ...remembered.where((kept) => kept.entry != angle.entry),
      ].take(depth),
    ),
  );

  // A pitch spelling never reaches here: filedAnswer files it in degrees.
  static EntryBuffer _spelled(Angle answer, QuantityFormatter formatter) {
    final token = switch (answer.spelling) {
      AngleSpelling.degreesMinutesSeconds => _degreesMinutesSeconds(answer),
      AngleSpelling.degrees ||
      AngleSpelling.risePerFoot ||
      AngleSpelling.grade => Token(
        digits: formatter
            .format(
              answer.spelledAs(AngleSpelling.degrees),
              groupThousands: false,
            )
            .replaceFirst('°', ''),
      ),
    };
    return EntryBuffer(List.unmodifiable([token]));
  }

  static Token _degreesMinutesSeconds(Angle answer) {
    final total = (answer.degrees.abs() * Token.secondsPerDegree).round();
    final rest = total % Token.secondsPerDegree;
    final seconds = rest % Token.minutesPerDegree;
    return Token(
      digits: '${total ~/ Token.secondsPerDegree}',
      minutes: '${rest ~/ Token.minutesPerDegree}',
      seconds: seconds == 0 ? '' : '$seconds',
    );
  }

  @override
  List<Object?> get props => [remembered];
}
