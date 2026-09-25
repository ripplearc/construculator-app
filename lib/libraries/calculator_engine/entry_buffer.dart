import 'package:construculator/libraries/calculator_engine/models/dimension.dart';
import 'package:construculator/libraries/calculator_engine/models/token.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// Why a key could not go into the number being typed. The app turns each
/// into the toast of UX Design Doc Section 5.1 or 5.2. Two of them answer
/// where the prototype swallowed the key: [decimalInDenominator] and the
/// unit key's [finishTheFraction].
enum EntryRefusal {
  /// [/] with no open number in front of it, or on a number whose fraction
  /// is already finished ("Fractions go inside a number").
  fractionNeedsNumerator,

  /// [/] while the fraction still waits for its denominator ("Finish the
  /// fraction").
  fractionAlreadyOpen,

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

  /// A weight unit under a key that takes lengths ("Width needs a length").
  needsLength,

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
            : EntryRefusal.fractionNeedsNumerator,
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
  /// takes lengths, which refuses a weight unit: while editing, Width 18ft 8
  /// [Lbs] needs a length (Section 5.2); on fresh entry the same keys leave
  /// Width 18ft and start 8lbs as its own chip (rule 4.5).
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
    final needsLength = holdsLengthOnly && unit.dimension != Dimension.length;
    if (editing && needsLength) {
      return const EntryRefused(EntryRefusal.needsLength);
    }
    if (tokens.length > 1 &&
        !_stepsDownWithinOneSystem(tokens[tokens.length - 2], unit)) {
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
    if (needsLength) return const EntryRefused(EntryRefusal.needsLength);
    return _replaceLast(last.copyWith(unit: () => unit));
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
