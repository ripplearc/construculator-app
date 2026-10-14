import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
import 'package:construculator/libraries/calculator_engine/trig.dart';
import 'package:equatable/equatable.dart';

/// The four operators of a chain (UX Design Doc rule 4.6), spelled as the
/// tape writes them.
enum Operator {
  /// ×
  multiply('×'),

  /// ÷
  divide('÷'),

  /// +
  add('+'),

  /// −
  subtract('−');

  /// The glyph the tape shows.
  final String symbol;

  const Operator(this.symbol);
}

/// Why a step of the calculation could not be computed (Section 5.3).
enum CalculationError {
  /// The dimension table refuses the combination: pounds ÷ feet, a number
  /// + feet, a length + an area.
  dimensionError,

  /// ÷ 0.
  divisionByZero,

  /// The answer is too large to keep: a length beyond
  /// [ChainArithmetic.maxTicks], or a number that overflowed to infinity.
  outOfRange,
}

/// The exact quantity a conversion re-spelled an entry from, with the entry
/// it produced. It is read only while the chip's entry still equals
/// [spelled]: 18ft 8in shown as 6.222yd is still 14,336 ticks (rule 4.15),
/// and 6.222yd with a digit typed after it is the digits again.
typedef ExactSpelling = ({Quantity value, EntryBuffer spelled});

/// One chip on the tape (term 2.1): a value the user typed, an answer the
/// app produced, or the place a step failed. Named so that a widget can
/// import it beside Flutter's own `Chip` and `InputChip`.
sealed class TapeChip extends Equatable {
  const TapeChip();
}

/// A value the user typed, with its function-key id or none for a bare
/// number (term 2.2). Active while the keyboard writes into it, editable
/// once it is finished.
final class ValueChip extends TapeChip {
  /// The stable id of the function key the value is named by, or `null`
  /// for a bare number.
  final String? key;

  /// The operator that leads into this chip in a chain, or `null` when the
  /// chip starts one.
  final Operator? operator;

  /// The number as typed or re-spelled.
  final EntryBuffer entry;

  /// The exact quantity a conversion re-spelled [entry] from, and the
  /// spelling it produced; `null` while the entry is what was typed. Read
  /// through [exactValue], which ignores it once the entry is edited.
  final ExactSpelling? exact;

  /// How many pounds the ton in [entry] stood for when it was typed or
  /// re-spelled, `null` while the entry holds no ton. A setting never
  /// changes what was typed (rule 4.14), so a later ton definition reads
  /// only the tons typed after it: [value] reads this chip by the
  /// definition it was typed under, whatever the tape's is now.
  final int? poundsPerTon;

  /// Whether the function key the chip is named by wants a unit on its
  /// number. A dimension key does (Section 5.1: Length 18 cannot be left),
  /// where Pitch, Slope and Sides take a plain number (Section 5.1: "A bare
  /// number under a key that takes a plain number … is complete"), so a
  /// bare 6 under them seals the way a bare 78 with no key does. Set by the
  /// caller of [Tape.pressFunctionKey]; ignored while the chip has no key.
  final bool keyWantsUnit;

  /// Whether a plain number under the chip's key is an angle in degrees,
  /// true under Pitch (rule 4.10: "Under Pitch, a bare number is degrees"):
  /// Pitch 30 + 15 is 45° and Pitch 30 × 2ft a Dimension Error (Section 7),
  /// where the count under Sides and the grade under Slope stay scalars.
  /// Set by the caller of [Tape.pressFunctionKey]; read only while
  /// [keyWantsUnit] is false.
  final bool readsDegrees;

  /// Whether the keyboard writes into this chip.
  final bool isActive;

  const ValueChip({
    this.key,
    this.operator,
    this.entry = const EntryBuffer(),
    this.exact,
    this.poundsPerTon,
    this.keyWantsUnit = true,
    this.readsDegrees = false,
    this.isActive = true,
  });

  /// The value the chip stands for: the exact quantity a conversion kept,
  /// else what the entry parses to; `null` while the entry is open. A bare
  /// number — one open token of digits and no unit, 78 or 0.65; a fraction
  /// without a unit is not a number yet — is a scalar, unless it sits under
  /// a function key that wants its unit (Section 5.1: Length 18 cannot be
  /// left); under Pitch, Slope or Sides it is the plain number those keys
  /// take ([keyWantsUnit]), in degrees under Pitch ([readsDegrees]).
  ///
  /// A trig chip ([trigFunction]) is worth its answer, not its digits, so
  /// Sine 89° × 56 is 55.99 (Section 6, "Trig chips in a chain"); one whose
  /// function has no value at its angle (Tangent 90°) is worth nothing.
  Quantity? value(QuantityParser parser) {
    if (exactValue case final value?) return value;
    if (trigOperand case final angle?) return trigFunction?.of(angle.degrees);
    if (entry.isComplete) return _typedUnder(parser).parse(entry.tokens);
    if (!_isPlainNumber) return null;
    final number = entry.tokens.first.value;
    return readsDegrees ? Angle(number) : Scalar(number);
  }

  QuantityParser _typedUnder(QuantityParser parser) {
    if (poundsPerTon case final typedUnder?
        when typedUnder != parser.poundsPerTon) {
      return QuantityParser(poundsPerTon: typedUnder);
    }
    return parser;
  }

  /// The exact quantity behind the entry while the entry is still the
  /// spelling the conversion produced; `null` once it is edited, or when
  /// the entry was typed.
  Quantity? get exactValue {
    if (exact case (:final value, :final spelled) when spelled == entry) {
      return value;
    }
    return null;
  }

  /// Whether the chip holds a value that can be sealed: a finished entry, a
  /// converted one, or a bare number with no function key or under a key
  /// that takes a plain number.
  bool get isReadable =>
      exactValue != null || entry.isComplete || _isPlainNumber;

  bool get _isPlainNumber => (key == null || !keyWantsUnit) && _isBareNumber;

  /// The forward trig function the chip asks, when its key is a trig key
  /// (Sine…), else `null`.
  TrigFunction? get trigFunction => TrigFunction.named(key);

  /// The angle a trig chip asks its function of: its bare number, in
  /// degrees; `null` for any other chip or before a number is typed.
  Angle? get trigOperand => trigFunction != null && _isBareNumber
      ? Angle(entry.tokens.first.value)
      : null;

  /// Whether the chip asks its trig function at an angle the function has
  /// no value for (Tangent 90°): the strip says why, and no key may treat
  /// its digits as a number in its place (Section 5.4: "Tangent can't
  /// answer that").
  bool get asksAnUndefinedTrig => switch ((trigFunction, trigOperand)) {
    (final function?, final angle?) => function.of(angle.degrees) == null,
    _ => false,
  };

  bool get _isBareNumber =>
      entry.tokens.length == 1 &&
      entry.tokens.first.unit == null &&
      entry.tokens.first.denominator == null &&
      double.tryParse(entry.tokens.first.digits) != null;

  /// Returns a copy with the given fields replaced. [key], [operator],
  /// [exact] and [poundsPerTon] take a `Function()?` wrapper so that
  /// clearing them to `null` can be told apart from leaving them as they
  /// are.
  ValueChip copyWith({
    String? Function()? key,
    Operator? Function()? operator,
    EntryBuffer? entry,
    ExactSpelling? Function()? exact,
    int? Function()? poundsPerTon,
    bool? keyWantsUnit,
    bool? readsDegrees,
    bool? isActive,
  }) {
    return ValueChip(
      key: key != null ? key() : this.key,
      operator: operator != null ? operator() : this.operator,
      entry: entry ?? this.entry,
      exact: exact != null ? exact() : this.exact,
      poundsPerTon: poundsPerTon != null ? poundsPerTon() : this.poundsPerTon,
      keyWantsUnit: keyWantsUnit ?? this.keyWantsUnit,
      readsDegrees: readsDegrees ?? this.readsDegrees,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    key,
    operator,
    entry,
    exact,
    poundsPerTon,
    keyWantsUnit,
    readsDegrees,
    isActive,
  ];
}

/// An answer the app computed (term 2.3): an accepted suggestion, an equals
/// result labelled Calc, or a trade result.
final class ResultChip extends TapeChip {
  /// The label of the answer: Calc, Area, Diagonal…
  final String key;

  /// The answer.
  final Quantity value;

  /// The operator that leads into this chip when it continues a chain.
  final Operator? operator;

  const ResultChip({required this.key, required this.value, this.operator});

  @override
  List<Object?> get props => [key, value, operator];
}

/// One chip that holds a whole bracket (term 2.22): the operator before it
/// and everything typed inside it, "+(3×4)". Open while the keypad types
/// inside it; closed once [( )] folds the inside to one value.
///
/// The inside is a tape of its own, so every key works inside a bracket
/// exactly as it works outside one. One level only: while a bracket is
/// open the [( )] key closes it and a second opening is refused before any
/// key is routed inside, so the inner tape never sees a bracket.
final class BracketChip extends TapeChip {
  /// The operator that leads into the bracket in a chain, or `null` when
  /// the bracket starts one.
  final Operator? operator;

  /// The chips typed inside the bracket.
  final List<TapeChip> inner;

  /// Whether the keypad still types inside the bracket.
  final bool isOpen;

  /// The inside the bracket had before ⌫ reopened it, kept while the edit
  /// lasts so that emptying the bracket cancels the edit and brings the
  /// group back as it was (Section 7, "Editing a bracket"); `null` for a
  /// bracket opened by the key, or once the edit closes.
  final List<TapeChip>? original;

  const BracketChip({
    this.operator,
    this.inner = const [],
    this.isOpen = true,
    this.original,
  });

  /// The bracket as the tape spells it, "+(3×4" while open and "+(3×4)"
  /// once closed.
  String get expression {
    final inside = [
      for (final chip in inner)
        if (chip case ValueChip(:final operator, :final entry))
          '${operator?.symbol ?? ''}${entry.text}',
    ].join();
    return '${operator?.symbol ?? ''}($inside${isOpen ? '' : ')'}';
  }

  /// Returns a copy with the given fields replaced. [operator] and
  /// [original] take a `Function()?` wrapper so that clearing them to
  /// `null` can be told apart from leaving them as they are.
  BracketChip copyWith({
    Operator? Function()? operator,
    List<TapeChip>? inner,
    bool? isOpen,
    List<TapeChip>? Function()? original,
  }) {
    return BracketChip(
      operator: operator != null ? operator() : this.operator,
      inner: inner ?? this.inner,
      isOpen: isOpen ?? this.isOpen,
      original: original != null ? original() : this.original,
    );
  }

  @override
  List<Object?> get props => [operator, inner, isOpen, original];
}

/// The place a step could not be computed (term 2.4). The strip goes
/// silent; ⌫ removes the chip and reopens the value before it.
final class ErrorChip extends TapeChip {
  /// What went wrong.
  final CalculationError error;

  const ErrorChip(this.error);

  @override
  List<Object?> get props => [error];
}
