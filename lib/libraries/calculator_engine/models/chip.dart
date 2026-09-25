import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/quantity_parser.dart';
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

  /// Whether the keyboard writes into this chip.
  final bool isActive;

  const ValueChip({
    this.key,
    this.operator,
    this.entry = const EntryBuffer(),
    this.exact,
    this.isActive = true,
  });

  /// The value the chip stands for: the exact quantity a conversion kept,
  /// else what the entry parses to; `null` while the entry is open. A bare
  /// number — one open token of digits and no unit, 78 or 0.65; a fraction
  /// without a unit is not a number yet — is a scalar, unless it sits under
  /// a function key, which wants its unit (Section 5.1: Length 18 cannot be
  /// left).
  Quantity? value(QuantityParser parser) {
    if (exactValue case final value?) return value;
    if (entry.isComplete) return parser.parse(entry.tokens);
    if (_isUnnamedBareNumber) return Scalar(entry.tokens.first.value);
    return null;
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
  /// converted one, or a bare number with no function key.
  bool get isReadable =>
      exactValue != null || entry.isComplete || _isUnnamedBareNumber;

  bool get _isUnnamedBareNumber => key == null && _isBareNumber;

  bool get _isBareNumber =>
      entry.tokens.length == 1 &&
      entry.tokens.first.unit == null &&
      entry.tokens.first.denominator == null &&
      double.tryParse(entry.tokens.first.digits) != null;

  /// Returns a copy with the given fields replaced. [key], [operator] and
  /// [exact] take a `Function()?` wrapper so that clearing them to `null`
  /// can be told apart from leaving them as they are.
  ValueChip copyWith({
    String? Function()? key,
    Operator? Function()? operator,
    EntryBuffer? entry,
    ExactSpelling? Function()? exact,
    bool? isActive,
  }) {
    return ValueChip(
      key: key != null ? key() : this.key,
      operator: operator != null ? operator() : this.operator,
      entry: entry ?? this.entry,
      exact: exact != null ? exact() : this.exact,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [key, operator, entry, exact, isActive];
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
