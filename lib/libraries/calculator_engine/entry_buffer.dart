import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// Why a key could not go into the number being typed. The app turns each
/// into the toast of UX Design Doc Section 5.1 or 5.2. Two of them answer
/// where the prototype swallowed the key: [decimalInDenominator] and the
/// unit key's [finishTheFraction].
enum EntryRefusal {
  /// [/] with no open number in front of it ("Type the top number first";
  /// Section 5.1). A second [/] on a finished fraction is
  /// [fractionNeedsUnit].
  fractionNeedsNumerator,

  /// [/] while the fraction still waits for its denominator ("Finish the
  /// fraction").
  fractionAlreadyOpen,

  /// A second [/] once the top and bottom numbers are typed (7 [/] 16 [/]):
  /// the fraction wants its unit key ("Finish the fraction. Press a unit
  /// key"; owner decision of 3 October 2026).
  fractionNeedsUnit,

  /// [/] on a number with a decimal point ("A decimal can't take a
  /// fraction").
  decimalCannotTakeFraction,

  /// A decimal point typed into a denominator.
  decimalInDenominator,

  /// A 0 typed as the first digit under the line (7 [/] 0): a fraction
  /// cannot have 0 underneath ("A fraction can't have 0 underneath"; owner
  /// decision of 3 October 2026). 10, 16, 20 and 100 are fine, inside and
  /// outside a bracket alike.
  zeroDenominator,

  /// A second decimal point, or the D:M:S key, on a number that cannot be an
  /// angle: under a key that takes a length, a grade or a ratio (Width,
  /// Slope, Arcsine), or on a number that continues a compound ("A second
  /// decimal point makes an angle"; Section 5.4). Only a bare number, a
  /// number under Pitch or one under a forward trig key reads as
  /// degrees:minutes:seconds.
  secondDecimalPoint,

  /// A unit key on an angle typed as degrees, minutes and seconds (38°30'
  /// then [Feet]): the value carries its unit in its own notation and has
  /// no length ("That value is already an angle"; Section 5.4).
  alreadyAnAngle,

  /// A unit key while [/] still waits for its denominator ("Finish the
  /// fraction").
  finishTheFraction,

  /// A unit that cannot continue the compound while a tapped chip is being
  /// re-edited: a metric unit after feet, inches after ft² ("Can't append
  /// centimeters here").
  cannotAppendUnit,

  /// A weight unit on the number first typed under a key that takes lengths
  /// (Width 8 [Lbs]: "Width needs a length"; Section 5.2).
  needsLength,

  /// A weight unit on a number typed after a finished length under a key
  /// that takes lengths (Width 18ft 8 [Lbs]): the 8 stays typed and wants a
  /// length unit ("Width takes lengths and not pounds. Press a length unit
  /// for the 8, or backspace to remove it."; Section 5.2; owner decision of
  /// 3 October 2026). The two toasts of that row are two refusals.
  tailNeedsLength,

  /// A unit key with no open number to close; a finished value is the
  /// ladder's, an empty buffer is "Type a number first".
  nothingOpen,

  /// Backspace with nothing typed; the tape decides what to unwind.
  nothingToDelete,
}

/// What a key did to the buffer.
sealed class EntryOutcome extends Equatable {
  const EntryOutcome();
}

/// The buffer took the key.
final class EntryChanged extends EntryOutcome {
  /// The buffer after the key.
  final EntryBuffer buffer;

  const EntryChanged(this.buffer);

  @override
  List<Object?> get props => [buffer];
}

/// A unit that could not continue the compound closed a new value instead:
/// 2511ft³ then 45 [Inch] is a finished volume and a new 45in (rule 4.5).
final class EntrySplit extends EntryOutcome {
  /// The value that was already typed, now finished.
  final EntryBuffer finished;

  /// The new value the unit closed.
  final EntryBuffer started;

  const EntrySplit({required this.finished, required this.started});

  @override
  List<Object?> get props => [finished, started];
}

/// A unit key closed a part as large as the unit above it and carried it
/// up (UX Design Doc Section 6; owner decision of 3 October 2026): 18ft
/// then 13 [Inch] is 19ft 1in, 1m then 100 [cm] is 2m 0cm. The tape tells
/// the user, naming the spelling before and after the key.
final class EntryCarried extends EntryOutcome {
  /// The buffer after the key, with the carry done.
  final EntryBuffer buffer;

  const EntryCarried(this.buffer);

  @override
  List<Object?> get props => [buffer];
}

/// The key was refused and the buffer is untouched.
final class EntryRefused extends EntryOutcome {
  /// Why.
  final EntryRefusal reason;

  const EntryRefused(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// The number being typed into the active chip, token by token (UX Design
/// Doc rule 4.1: function key, digits, unit; Section 4.3 and Section 6 for
/// compounds and fractions).
///
/// Every key returns a new buffer or a refusal; nothing is mutated, so the
/// tape can keep the buffer a tapped chip had before an edit. What the
/// buffer holds is spelling, not value: [QuantityParser] reads a finished
/// buffer as a quantity.
///
/// An angle is typed as degrees, minutes and seconds the way both reference
/// calculators type it, with no degree key (rule 4.10; Section 3.5): a
/// second decimal point, or the D:M:S key, re-reads the number as its
/// segments (23.16.45 is 23°16'45", 38 [D:M:S] 30 [D:M:S] 45 the same), one
/// segment closes when the next opens, and a segment that closes above 59
/// carries into the one above it rather than being refused (30.89 reads
/// 31°29'00"; Construction Master Pro redisplays such entries in the
/// correct convention). An angle is always written with its three fields
/// (Section 6, "Rounding at display"): 38 [D:M:S] 30 reads 38°30'00" with
/// the seconds still to come. The seal is the padding: a field that has
/// closed is written to two digits the way a bearing is, 45°02'00", and
/// one still being typed shows exactly what was typed, 38°5'00" and
/// 38°05'9", because a padded 38°05' would supply a zero the next digit
/// takes away again. The minutes close when the seconds open; the seconds
/// close when a key leaves the chip ([sealed]), as rule 4.10 has it: any
/// operator, =, a closing bracket or a function key closes the open field,
/// so 38°75' becomes 39°15'00" on the tape and on the chip at once.
class EntryBuffer extends Equatable {
  /// The tokens typed so far; the last one may still be open.
  final List<Token> tokens;

  const EntryBuffer([this.tokens = const []]);

  /// Whether nothing has been typed.
  bool get isEmpty => tokens.isEmpty;

  /// Whether the buffer holds one angle typed as degrees, minutes and
  /// seconds, which reads as an angle whatever key it sits under and takes
  /// no unit key.
  bool get isDegreesMinutesSeconds =>
      tokens.length == 1 && tokens.first.isDegreesMinutesSeconds;

  /// Whether every token has its digits, its unit and a finite value, so
  /// the buffer can be read as a value; a fraction over zero (7/0in) is
  /// closed but never complete.
  bool get isComplete =>
      tokens.isNotEmpty &&
      tokens.every((token) => token.isComplete && token.value.isFinite);

  /// Whether the last token still waits for a unit.
  bool get isOpen => tokens.isNotEmpty && tokens.last.unit == null;

  /// Whether the last token is a finished fraction with no unit (1/2), which
  /// cannot be left: [+], [=] and [( )] answer "Finish the fraction. Press a
  /// unit key" (Section 6; owner decision of 4 October 2026).
  bool get endsWithUnitlessFraction =>
      tokens.isNotEmpty && _isUnitlessFraction(tokens.last);

  /// Whether the last token is a finished fraction typed right after whole
  /// inches (5ft 7in 1/2), which closes as inches by itself, the way the
  /// Construction Master Pro types it (Section 6; owner decision of 4
  /// October 2026). The exception is narrow: the token before it is in
  /// inches, whole, with no fraction and not raised; after feet, after a
  /// decimal inch or on its own the fraction still wants its unit key.
  bool get endsWithFractionAfterWholeInches =>
      tokens.length > 1 &&
      _isUnitlessFraction(tokens.last) &&
      _isWholeInches(tokens[tokens.length - 2]);

  static bool _isUnitlessFraction(Token token) =>
      token.unit == null && (token.denominator?.isNotEmpty ?? false);

  static bool _isWholeInches(Token token) =>
      token.unit == Unit.inch &&
      token.power == 1 &&
      token.denominator == null &&
      !token.digits.contains('.');

  /// The buffer exactly as the tape echoes it: "18ft 8", "7/16in", "2in³".
  /// A fraction closed in inches right after whole inches is written the
  /// way the trade writes it, 5ft 7-1/2in (Section 6); a zero whole part is
  /// left out, since the trade writes a half inch as 1/2in, not 0-1/2in
  /// (0in 1/2 reads 1/2in, 5ft 0in 1/2 reads 5ft 1/2in).
  String get text {
    final text = StringBuffer();
    for (final (index, token) in tokens.indexed) {
      final isWholeOfMixed =
          index + 1 < tokens.length && _isMixedNumber(token, tokens[index + 1]);
      if (isWholeOfMixed && token.digits == '0') continue;
      if (text.isNotEmpty) {
        final previous = tokens[index - 1];
        text.write(
          _isMixedNumber(previous, token) && previous.digits != '0' ? '-' : ' ',
        );
      }
      text.write(isWholeOfMixed ? token.digits : _spelled(token));
    }
    return text.toString();
  }

  String _spelled(Token token) {
    if (token.isDegreesMinutesSeconds) return _degreesMinutesSeconds(token);
    return '${token.digits}'
        '${token.denominator == null ? '' : '/${token.denominator}'}'
        '${token.unit?.suffix ?? ''}'
        '${_exponent(token.power)}';
  }

  String _degreesMinutesSeconds(Token token) {
    final minutes = token.minutes ?? '';
    final seconds = token.seconds;
    if (seconds == null) {
      return minutes.isEmpty
          ? '${token.digits}°'
          : "${token.digits}°$minutes'$_emptyField\"";
    }
    return "${token.digits}°${_twoDigits(minutes)}'"
        '${seconds.isEmpty ? _emptyField : seconds}"';
  }

  static const String _emptyField = '00';

  static String _twoDigits(String segment) => segment.padLeft(2, '0');

  /// The buffer as a key that leaves the chip seals it: an angle's open
  /// field closes, with the carry and the padding a closed field has
  /// (38°75' seals as 39°15'00", 38°05'9" as 38°05'09", 38°30'75" as
  /// 38°31'15", and 38 [D:M:S] alone as 38°00'00"), so that the chip and
  /// the tape read the sealed angle at once (rule 4.10). Any other buffer,
  /// and an angle whose fields have all closed, is returned as it is, so
  /// sealing twice changes nothing and a chip keeps the exact value behind
  /// a spelling it already had.
  /// A chip ⌫ makes active again keeps the sealed spelling: the field was
  /// closed, and what it holds is what ⌫ now steps through.
  EntryBuffer get sealed {
    if (!isDegreesMinutesSeconds) return this;
    final angle = tokens.single;
    final closed = _withFieldsClosed(
      angle.digits,
      angle.minutes ?? '',
      angle.seconds ?? '',
    );
    final token = angle.copyWith(
      digits: closed.degrees,
      minutes: () => closed.minutes,
      seconds: () => closed.seconds,
    );
    return token == angle ? this : EntryBuffer(List.unmodifiable([token]));
  }

  static ({String degrees, String minutes, String seconds}) _withFieldsClosed(
    String degrees,
    String minutes,
    String seconds,
  ) {
    final totalSeconds =
        (double.tryParse(degrees) ?? 0).abs() * Token.secondsPerDegree +
        (double.tryParse(minutes) ?? 0) * Token.minutesPerDegree +
        (double.tryParse(seconds) ?? 0);
    if (totalSeconds > _largestWholeNumberADoubleHolds) {
      return (degrees: degrees, minutes: minutes, seconds: _twoDigits(seconds));
    }
    final total = totalSeconds.toInt();
    final rest = total % Token.secondsPerDegree;
    final sign = degrees.startsWith('-') ? '-' : '';
    return (
      degrees: '$sign${total ~/ Token.secondsPerDegree}',
      minutes: '${rest ~/ Token.minutesPerDegree}',
      seconds: _twoDigits('${rest % Token.minutesPerDegree}'),
    );
  }

  static bool _isMixedNumber(Token whole, Token fraction) =>
      _isWholeInches(whole) &&
      fraction.unit == Unit.inch &&
      fraction.power == 1 &&
      (fraction.denominator?.isNotEmpty ?? false);

  /// A digit or a decimal point.
  ///
  /// Digits go into the open number, or into its denominator once [/] was
  /// pressed; after a finished token they start a new one (18ft then 8). A
  /// leading point reads 0.; a second point makes an angle where
  /// [readsAngles] (23.16 then . reads 23°16'00" with the minutes closed,
  /// and the digits go on into the seconds) and is refused anywhere else. On an
  /// angle the point is the D:M:S key ([closeDegreesMinutesSeconds]): after
  /// 38 [D:M:S] 30 it opens the seconds, and a third point changes nothing,
  /// since an angle has three segments. An inch the Read-as pill read a
  /// bare number as ([Token.typedAs] behind the unit) is not a unit the
  /// user typed, so the key goes to the number as if the inch were not
  /// there, under the number's own rules: 6in then 5 is 65, and 8.45in then
  /// . is 8°45' with the seconds open, the second point of 8.45 (rule 4.10).
  /// Only the pill under Pitch writes such an inch, so no other key meets
  /// one; an [Inch] pressed on it raises it to a square the user typed,
  /// which the pill never wrote, so a digit after that starts a new token.
  EntryOutcome typeDigit(String digit, {bool readsAngles = false}) {
    final last = tokens.isEmpty ? null : tokens.last;
    if (last case Token(unit: Unit.inch, power: 1, typedAs: _?)) {
      return EntryBuffer(
        List.unmodifiable([
          ...tokens.sublist(0, tokens.length - 1),
          Token(digits: last.digits),
        ]),
      ).typeDigit(digit, readsAngles: readsAngles);
    }
    if (last == null || last.unit != null) {
      return _changed([...tokens, Token(digits: digit == '.' ? '0.' : digit)]);
    }
    if (last.denominator case final denominator?) {
      if (digit == '.') {
        return const EntryRefused(EntryRefusal.decimalInDenominator);
      }
      if (denominator.isEmpty && digit == '0') {
        return const EntryRefused(EntryRefusal.zeroDenominator);
      }
      return _replaceLast(
        last.copyWith(denominator: () => '$denominator$digit'),
      );
    }
    if (last.isDegreesMinutesSeconds) {
      if (digit == '.') return closeDegreesMinutesSeconds();
      return _replaceLast(_withSegmentDigit(last, digit));
    }
    if (digit == '.' && last.digits.contains('.')) {
      if (!readsAngles || tokens.length > 1) {
        return const EntryRefused(EntryRefusal.secondDecimalPoint);
      }
      return _replaceLast(_asDegreesMinutesSeconds(last, closingMinutes: true));
    }
    return _replaceLast(
      last.copyWith(digits: '${last.digits}$digit', typedAs: () => null),
    );
  }

  /// The D:M:S key (Section 3.5): closes the segment being typed and opens
  /// the next one. On a plain number it is the second decimal point made
  /// visible: 38 reads 38° with the minutes open, 38.3 reads 38°03'00"
  /// with the seconds open. Pressed with the seconds open it changes nothing,
  /// since an angle has three segments and a fourth press never eats the
  /// third (walkthrough 16.3, step 6). A fraction cannot be an angle.
  EntryOutcome closeDegreesMinutesSeconds() {
    final last = tokens.isEmpty ? null : tokens.last;
    if (last == null || last.unit != null) {
      return const EntryRefused(EntryRefusal.nothingOpen);
    }
    if (last.denominator != null) {
      return const EntryRefused(EntryRefusal.fractionNeedsUnit);
    }
    if (last.seconds != null) return EntryChanged(this);
    if (last.minutes case final minutes?) {
      return _replaceLast(
        _withMinutesClosed(last.digits, minutes, typedAs: last.typedAs),
      );
    }
    final closingMinutes =
        last.digits.contains('.') && !last.digits.endsWith('.');
    return _replaceLast(
      _asDegreesMinutesSeconds(last, closingMinutes: closingMinutes),
    );
  }

  Token _asDegreesMinutesSeconds(Token plain, {required bool closingMinutes}) {
    final (degrees, decimals) = _wholeAndDecimals(plain.digits);
    final minutes = decimals.isEmpty ? '' : decimals.substring(1);
    final typedAs =
        plain.typedAs ?? (plain.digits.contains('.') ? plain.digits : null);
    if (!closingMinutes) {
      return Token(digits: degrees, minutes: minutes, typedAs: typedAs);
    }
    return _withMinutesClosed(degrees, minutes, typedAs: typedAs);
  }

  Token _withMinutesClosed(
    String degrees,
    String minutes, {
    required String? typedAs,
  }) {
    final totalMinutes =
        double.parse(degrees) * Token.minutesPerDegree +
        (double.tryParse(minutes) ?? 0);
    if (totalMinutes > _largestWholeNumberADoubleHolds) {
      return Token(
        digits: degrees,
        minutes: minutes,
        seconds: '',
        typedAs: typedAs,
      );
    }
    final carried = totalMinutes.round();
    return Token(
      digits: '${carried ~/ Token.minutesPerDegree}',
      minutes: '${carried % Token.minutesPerDegree}',
      seconds: '',
      typedAs: typedAs,
    );
  }

  static const double _largestWholeNumberADoubleHolds = 9007199254740992;

  Token _withSegmentDigit(Token angle, String digit) {
    if (angle.seconds case final seconds?) {
      return angle.copyWith(
        seconds: () => '$seconds$digit',
        typedAs: () => null,
      );
    }
    return angle.copyWith(
      minutes: () => '${angle.minutes}$digit',
      typedAs: () => null,
    );
  }

  /// [/]: splits the open number into a fraction, 7 [/] 16 [Inch] → 7/16in.
  EntryOutcome typeFraction() {
    final last = tokens.isEmpty ? null : tokens.last;
    if (last == null || last.unit != null || last.digits.isEmpty) {
      return const EntryRefused(EntryRefusal.fractionNeedsNumerator);
    }
    if (last.denominator case final denominator?) {
      return EntryRefused(
        denominator.isEmpty
            ? EntryRefusal.fractionAlreadyOpen
            : EntryRefusal.fractionNeedsUnit,
      );
    }
    if (last.digits.contains('.') || last.isDegreesMinutesSeconds) {
      return const EntryRefused(EntryRefusal.decimalCannotTakeFraction);
    }
    return _replaceLast(last.copyWith(denominator: () => ''));
  }

  /// A unit key on the open number closes it.
  ///
  /// A second unit may only continue a compound by stepping down within one
  /// system (yd → ft → in, m → cm → mm: 18ft 8in, 1m 20cm) and never after a
  /// squared or cubed value, since there is no "2511ft³ 45in"; anything else
  /// starts a new value on fresh entry ([EntrySplit]) and is refused while
  /// [editing] a tapped chip. [holdsLengthOnly] is true under a key that
  /// takes lengths, which refuses a weight unit, on fresh entry as while
  /// editing: Width 18ft 8 [Lbs] needs a length and keeps the 8 typed
  /// (Section 5.2; owner decision of 3 October 2026), where Width 18ft 8
  /// [Feet] still starts 8ft as its own chip (rule 4.5). A part as large as
  /// the unit above it is carried up on its whole parts when the unit closes
  /// it ([EntryCarried]): 18ft 13in reads 19ft 1in and 18ft 13.5in reads
  /// 19ft 1.5in (Section 6: any inch part as large as a foot), and the carry
  /// runs on up the ladder while the part above is as large as its own unit
  /// (1m 95cm 100mm reads 2m 5cm 0mm). A fraction (13/2 is a numerator over
  /// a line, not whole inches), a fraction above it (3/4ft 13in) or a
  /// decimal above it (18.5ft 13in) is left as typed.
  EntryOutcome closeWith(
    Unit unit, {
    bool editing = false,
    bool holdsLengthOnly = false,
  }) {
    final last = tokens.isEmpty ? null : tokens.last;
    if (last == null || last.unit != null) {
      return const EntryRefused(EntryRefusal.nothingOpen);
    }
    if (last.isDegreesMinutesSeconds) {
      return const EntryRefused(EntryRefusal.alreadyAnAngle);
    }
    if (last.denominator == '') {
      return const EntryRefused(EntryRefusal.finishTheFraction);
    }
    final previous = tokens.length > 1 ? tokens[tokens.length - 2] : null;
    if (holdsLengthOnly && unit.dimension != Dimension.length) {
      return EntryRefused(
        previous == null
            ? EntryRefusal.needsLength
            : EntryRefusal.tailNeedsLength,
      );
    }
    if (previous != null &&
        !_stepsDownWithinOneSystem(previous, unit) &&
        !(unit == Unit.inch && endsWithFractionAfterWholeInches)) {
      if (editing) return const EntryRefused(EntryRefusal.cannotAppendUnit);
      return EntrySplit(
        finished: EntryBuffer(
          List.unmodifiable(tokens.take(tokens.length - 1)),
        ),
        started: EntryBuffer(
          List.unmodifiable([last.copyWith(unit: () => unit)]),
        ),
      );
    }
    final closed = last.copyWith(unit: () => unit);
    if (previous case Token(unit: final above?)) {
      return _carriedUp(previous, above, closed, unit);
    }
    return _replaceLast(closed);
  }

  EntryOutcome _carriedUp(Token previous, Unit above, Token closed, Unit unit) {
    final replaced = [...tokens.take(tokens.length - 1), closed];
    final carried = _carryInto(replaced, replaced.length - 1, above, unit);
    if (carried == null) return _replaceLast(closed);
    return EntryCarried(EntryBuffer(List.unmodifiable(carried)));
  }

  List<Token>? _carryInto(
    List<Token> tokens,
    int index,
    Unit above,
    Unit unit,
  ) {
    final part = tokens[index];
    final previous = tokens[index - 1];
    final partsPerUnit = (above.ticksPerUnit / unit.ticksPerUnit).round();
    final (whole, decimals) = _wholeAndDecimals(part.digits);
    final parts = part.denominator == null ? int.tryParse(whole) : null;
    final wholeAbove = previous.denominator == null
        ? int.tryParse(previous.digits)
        : null;
    if (parts == null || wholeAbove == null || parts < partsPerUnit) {
      return null;
    }
    final carried = [
      ...tokens.take(index - 1),
      previous.copyWith(digits: '${wholeAbove + parts ~/ partsPerUnit}'),
      part.copyWith(digits: '${parts % partsPerUnit}$decimals'),
      ...tokens.skip(index + 1),
    ];
    final higher = index >= 2 ? tokens[index - 2].unit : null;
    if (higher == null) return carried;
    return _carryInto(carried, index - 1, higher, above) ?? carried;
  }

  static (String, String) _wholeAndDecimals(String digits) {
    final point = digits.indexOf('.');
    if (point < 0) return (digits, '');
    return (digits.substring(0, point), digits.substring(point));
  }

  /// ⌫: removes one token step, in the order it was typed — the power
  /// (in³ → in² → in), the unit, a denominator digit, the [/], a digit —
  /// and drops the token when its last digit goes. A leading point was
  /// typed as 0., so one ⌫ leaves the 0 the prototype leaves and a second
  /// clears it. On an angle it steps back through the segments: a seconds
  /// digit, the seconds (which reopens the minutes), a minutes digit, and
  /// then the minutes, which leaves the whole degrees as a plain number.
  /// A minutes digit removed clears the way back ([Token.typedAs]), as a
  /// digit typed does; reopening a segment keeps the digits, so it keeps
  /// the way back. (A seconds digit was typed, which already cleared it.)
  EntryOutcome backspace() {
    final last = tokens.isEmpty ? null : tokens.last;
    if (last == null) return const EntryRefused(EntryRefusal.nothingToDelete);
    if (last.power > 1) {
      return _replaceLast(last.copyWith(power: last.power - 1));
    }
    if (last.unit != null) {
      return _replaceLast(last.copyWith(unit: () => null));
    }
    if (last.seconds case final seconds?) {
      if (seconds.isEmpty) {
        return _replaceLast(last.copyWith(seconds: () => null));
      }
      return _replaceLast(
        last.copyWith(seconds: () => seconds.substring(0, seconds.length - 1)),
      );
    }
    if (last.minutes case final minutes?) {
      if (minutes.isEmpty) return _replaceLast(Token(digits: last.digits));
      return _replaceLast(
        last.copyWith(
          minutes: () => minutes.substring(0, minutes.length - 1),
          typedAs: () => null,
        ),
      );
    }
    if (last.denominator case final denominator?) {
      if (denominator.isEmpty) {
        return _replaceLast(last.copyWith(denominator: () => null));
      }
      return _replaceLast(
        last.copyWith(
          denominator: () => denominator.substring(0, denominator.length - 1),
        ),
      );
    }
    if (last.digits.length <= 1) {
      return _changed(tokens.sublist(0, tokens.length - 1));
    }
    return _replaceLast(
      last.copyWith(
        digits: last.digits.substring(0, last.digits.length - 1),
        typedAs: () => null,
      ),
    );
  }

  bool _stepsDownWithinOneSystem(Token previous, Unit unit) {
    final previousUnit = previous.unit;
    if (previousUnit == null || previous.power > 1) return false;
    return previousUnit.isMetric == unit.isMetric &&
        previousUnit.compoundRank > unit.compoundRank &&
        unit.compoundRank > 0;
  }

  EntryOutcome _replaceLast(Token token) =>
      _changed([...tokens.sublist(0, tokens.length - 1), token]);

  EntryOutcome _changed(List<Token> tokens) =>
      EntryChanged(EntryBuffer(List.unmodifiable(tokens)));

  String _exponent(int power) => switch (power) {
    2 => '²',
    3 => '³',
    _ => '',
  };

  @override
  List<Object?> get props => [tokens];
}
