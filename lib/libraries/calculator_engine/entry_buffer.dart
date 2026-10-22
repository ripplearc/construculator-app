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

  /// A second decimal point in one number; only an angle key may read it as
  /// degrees:minutes:seconds ("A second decimal point makes an angle").
  secondDecimalPoint,

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
class EntryBuffer extends Equatable {
  /// The tokens typed so far; the last one may still be open.
  final List<Token> tokens;

  const EntryBuffer([this.tokens = const []]);

  /// Whether nothing has been typed.
  bool get isEmpty => tokens.isEmpty;

  /// Whether every token has its digits, its unit and a finite value, so
  /// the buffer can be read as a value; a fraction over zero (7/0in) is
  /// closed but never complete.
  bool get isComplete =>
      tokens.isNotEmpty &&
      tokens.every((token) => token.isComplete && token.value.isFinite);

  /// Whether the last token still waits for a unit.
  bool get isOpen => tokens.isNotEmpty && tokens.last.unit == null;

  /// The buffer exactly as the tape echoes it: "18ft 8", "7/16in", "2in³".
  String get text => tokens
      .map(
        (token) =>
            '${token.digits}'
            '${token.denominator == null ? '' : '/${token.denominator}'}'
            '${token.unit?.suffix ?? ''}'
            '${_exponent(token.power)}',
      )
      .join(' ');

  /// A digit or a decimal point.
  ///
  /// Digits go into the open number, or into its denominator once [/] was
  /// pressed; after a finished token they start a new one (18ft then 8). A
  /// leading point reads 0.; a second point is an angle's business and is
  /// refused here.
  EntryOutcome typeDigit(String digit) {
    final last = tokens.isEmpty ? null : tokens.last;
    if (last == null || last.unit != null) {
      return _changed([...tokens, Token(digits: digit == '.' ? '0.' : digit)]);
    }
    if (last.denominator case final denominator?) {
      if (digit == '.') {
        return const EntryRefused(EntryRefusal.decimalInDenominator);
      }
      return _replaceLast(
        last.copyWith(denominator: () => '$denominator$digit'),
      );
    }
    if (digit == '.' && last.digits.contains('.')) {
      return const EntryRefused(EntryRefusal.secondDecimalPoint);
    }
    return _replaceLast(last.copyWith(digits: '${last.digits}$digit'));
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
    if (last.digits.contains('.')) {
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
    if (previous != null && !_stepsDownWithinOneSystem(previous, unit)) {
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
  /// clears it.
  EntryOutcome backspace() {
    final last = tokens.isEmpty ? null : tokens.last;
    if (last == null) return const EntryRefused(EntryRefusal.nothingToDelete);
    if (last.power > 1) {
      return _replaceLast(last.copyWith(power: last.power - 1));
    }
    if (last.unit != null) {
      return _replaceLast(last.copyWith(unit: () => null));
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
      last.copyWith(digits: last.digits.substring(0, last.digits.length - 1)),
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
