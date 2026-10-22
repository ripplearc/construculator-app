import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// One number of a value exactly as it was typed: its digits, the fraction
/// under them if [/] was pressed, the unit key that closed it, and how many
/// times that key was pressed.
///
/// A value is a list of tokens because the trade writes compounds: 18ft 8in
/// is two tokens, 1ft 1/16in is two tokens with a fraction on the second.
/// A token keeps its digits as text rather than a number so that the tape
/// can echo exactly what was typed ("0.", "7/", "1ft 1") while the number
/// is still open (UX Design Doc rule 4.1).
///
/// An angle typed as degrees, minutes and seconds (rule 4.10; Section 3.5,
/// the D:M:S key) is one token in three segments: the degrees stay in
/// [digits], the [minutes] and [seconds] are segments of their own, so that
/// the tape can echo 38°30'00" while the seconds are still to come.
class Token extends Equatable {
  /// Minutes of arc in one degree.
  static const int minutesPerDegree = 60;

  /// Seconds of arc in one degree.
  static const int secondsPerDegree = 3600;

  /// The digits typed so far, possibly with one decimal point; empty while
  /// nothing has been typed into this token yet. The whole degrees of an
  /// angle typed as degrees, minutes and seconds.
  final String digits;

  /// The denominator typed after [/]: `null` when the number has no fraction,
  /// empty while [/] has been pressed but no denominator typed yet.
  final String? denominator;

  /// The unit key that closed the number, or `null` while it is still open.
  final Unit? unit;

  /// How many times the closing unit was pressed: 1 for a length, 2 for its
  /// square (ft²) and 3 for its cube (ft³). The ladder stops at cubic
  /// (rule 4.3).
  final int power;

  /// The minutes of an angle typed as degrees, minutes and seconds: `null`
  /// while the number is a plain one, empty while the segment is open with
  /// nothing typed in it yet. A segment is never left above 59: closing it
  /// carries the excess into the degrees (30°89' closes as 31°29'00").
  final String? minutes;

  /// The seconds of such an angle: `null` until the minutes have closed,
  /// empty while open. Opening the seconds is what closes the minutes; a
  /// key that leaves the chip closes the seconds ([EntryBuffer.sealed]).
  final String? seconds;

  /// The digits as they were typed before the number was re-read another
  /// way (the 23.16 behind 23°16'), so that the Read-as pill can bring them
  /// back untouched (term 2.14; walkthrough 17.4: "each lap rebuilds from
  /// the typed digits").
  /// `null` for a number that was never re-read; the next digit typed clears
  /// it, since the way back belongs to the digits it was made from.
  final String? typedAs;

  const Token({
    required this.digits,
    this.denominator,
    this.unit,
    this.power = 1,
    this.minutes,
    this.seconds,
    this.typedAs,
  }) : assert(power >= 1 && power <= 3, 'the unit ladder stops at cubic'),
       assert(
         seconds == null || minutes != null,
         'the seconds of an angle follow its minutes',
       );

  /// Whether this token can be read as a number: it has digits, a unit, and
  /// no fraction left half-typed. Only complete tokens have a value.
  bool get isComplete => digits.isNotEmpty && unit != null && denominator != '';

  /// Whether the token is an angle typed as degrees, minutes and seconds,
  /// which carries its unit in its own notation and never takes a unit key.
  bool get isDegreesMinutesSeconds => minutes != null;

  /// The typed number: the digits divided by the denominator when there is
  /// one, or the decimal degrees of an angle typed as degrees, minutes and
  /// seconds, where a minus on the degrees is the whole angle's (-30°30'00"
  /// is -30.5°, the way the angle drawer files a negative answer, rule 4.16).
  /// Exact only in the sense the user typed it; a length becomes exact once
  /// it is turned into ticks.
  ///
  /// A zero denominator has no finite value: 7/0 reads as infinity and 0/0
  /// as NaN. The token does not guard this, because the digits must stay
  /// exactly as typed while the number is open. `QuantityParser.parse`
  /// answers `null` for a token whose value is not finite, so nothing
  /// downstream ever turns such a token into a quantity.
  double get value {
    final numerator = double.tryParse(digits) ?? 0;
    if (minutes case final minutes?) {
      final magnitude =
          numerator.abs() +
          _segment(minutes) / minutesPerDegree +
          _segment(seconds) / secondsPerDegree;
      return digits.startsWith('-') ? -magnitude : magnitude;
    }
    final denominatorValue = double.tryParse(denominator ?? '');
    if (denominatorValue == null) return numerator;
    return numerator / denominatorValue;
  }

  static double _segment(String? digits) => double.tryParse(digits ?? '') ?? 0;

  /// Returns a copy with the given fields replaced. [denominator], [unit],
  /// [minutes], [seconds] and [typedAs] take a `Function()?` wrapper so that
  /// clearing them to `null` can be told apart from leaving them as they are.
  Token copyWith({
    String? digits,
    String? Function()? denominator,
    Unit? Function()? unit,
    int? power,
    String? Function()? minutes,
    String? Function()? seconds,
    String? Function()? typedAs,
  }) {
    return Token(
      digits: digits ?? this.digits,
      denominator: denominator != null ? denominator() : this.denominator,
      unit: unit != null ? unit() : this.unit,
      power: power ?? this.power,
      minutes: minutes != null ? minutes() : this.minutes,
      seconds: seconds != null ? seconds() : this.seconds,
      typedAs: typedAs != null ? typedAs() : this.typedAs,
    );
  }

  @override
  List<Object?> get props => [
    digits,
    denominator,
    unit,
    power,
    minutes,
    seconds,
    typedAs,
  ];
}
