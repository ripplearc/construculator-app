import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
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
  ///
  /// A trig chip carries it too, set by [Tape.pressTrigKey] in both orders,
  /// so its operand chip names its unit the way a Pitch chip does ("Sine ·
  /// degrees 38°", rule 4.11) while the chip is worth its answer.
  final bool readsDegrees;

  /// Whether the keyboard writes into this chip.
  final bool isActive;

  /// Whether a tap reopened the chip in place to change it (rule 4.8), so
  /// that the keys edit a finished value rather than type a fresh one,
  /// wherever the chip sits. A chip ⌫ reopened at the end of the tape is
  /// entry again. Cleared when the chip seals.
  final bool isEditing;

  /// Whether the result this step's operator led on from was removed by an
  /// edit (Section 5.5), so the step has no left value: it stays on the
  /// tape, computes nothing, and = is refused with
  /// [TapeRefusal.stepLostItsValue] until ⌫ removes the step or a value is
  /// edited back (product decision of 13 November 2026).
  final bool followsARemovedResult;

  /// Whether the % key marked the number as a percent (UX Design Doc
  /// Section 7, "Percent"): after + or − it is that percent of the running
  /// total, after × or ÷ the number ÷ 100. The tape chip reads it with its
  /// sign, "+10%" ([text]).
  final bool isPercent;

  /// The chip's number as the tape writes it: the entry, and a % sign when
  /// [isPercent].
  String get text => isPercent ? '${entry.text}%' : entry.text;

  /// Whether a second decimal point, or the D:M:S key, may read the chip's
  /// number as degrees, minutes and seconds (Section 5.4, "A second decimal
  /// point makes an angle"): a bare number, which the trig keys read as
  /// degrees, and a key whose plain number is degrees, Pitch and the forward
  /// trig keys ([readsDegrees]). Under Width, Slope, Sides or an inverse
  /// trig key the point is refused and the number stays as typed.
  bool get takesAnAngle => key == null || readsDegrees;

  const ValueChip({
    this.key,
    this.operator,
    this.entry = const EntryBuffer(),
    this.exact,
    this.poundsPerTon,
    this.keyWantsUnit = true,
    this.readsDegrees = false,
    this.isActive = true,
    this.isEditing = false,
    this.followsARemovedResult = false,
    this.isPercent = false,
  });

  /// The value the chip stands for: the exact quantity a conversion kept,
  /// else what the entry parses to; `null` while the entry is open. A bare
  /// number — one open token of digits and no unit, 78 or 0.65; a fraction
  /// without a unit is not a number yet — is a scalar, unless it sits under
  /// a function key that wants its unit (Section 5.1: Length 18 cannot be
  /// left); under Pitch, Slope or Sides it is the plain number those keys
  /// take ([keyWantsUnit]), in degrees under Pitch ([readsDegrees]). A
  /// number typed as degrees, minutes and seconds is an angle whatever key
  /// it sits under, in that spelling: the segments are its unit (rule 4.10),
  /// so 38°30' [SIN] is the sine of 38.5° and 60° + 12°01' is 72.02°. Under
  /// Pitch a bare fraction over 12 is the rise in 12 a roofer quotes, with
  /// no unit key needed: [Pitch] 6/12 is 6in/12in, 26.57° (rule 4.10); any
  /// other fraction keeps its usual reading and still needs its unit.
  ///
  /// A trig chip ([trigFunction]) is worth its answer, not its digits, so
  /// Sine 89° × 56 is 55.99 and Arccosine 0.8 × 6 is 221.22° (Section 6,
  /// "Trig chips in a chain"); one whose function has no value at its
  /// operand (Tangent 90°, Arcsine 2) is worth nothing. An angle recalled
  /// from the drawer under a forward trig key ([exact]) is the operand, so
  /// Sine 45° recalled and × 10 is 7.07, as it is typed by hand.
  Quantity? value(QuantityParser parser) {
    if (trigOperand case final operand?) {
      return trigFunction?.answerTo(operand);
    }
    if (exactValue case final value?) return value;
    if (entry.isComplete) return _typedUnder(parser).parse(entry.tokens);
    if (_isRiseOverTwelve) {
      return Angle.ofRisePerFoot(double.parse(entry.tokens.single.digits));
    }
    if (!_isPlainNumber) return null;
    if (entry.isDegreesMinutesSeconds || readsDegrees) return _typedAngle;
    return Scalar(entry.tokens.first.value);
  }

  Angle get _typedAngle => Angle(
    entry.tokens.first.value,
    spelling: entry.isDegreesMinutesSeconds
        ? AngleSpelling.degreesMinutesSeconds
        : AngleSpelling.degrees,
  );

  /// The angle the chip's typed number reads as, in its spelling, or `null`
  /// when the number is not one: a plain number under Pitch or a forward
  /// trig key, or any number typed as degrees, minutes and seconds. What
  /// the angle drawer files when the chip seals (rule 4.16: "anything that
  /// reads as degrees or D:M:S"); a bare count, a grade and the ratio under
  /// an inverse trig key are not angles and are not filed. A recalled or
  /// converted angle is worth its exact value ([exact]), not its digits.
  Angle? get typedAngle {
    if (exactValue case final Angle angle) return angle;
    return _isPlainNumber && (readsDegrees || entry.isDegreesMinutesSeconds)
        ? _typedAngle
        : null;
  }

  /// The angle the drawer files for the chip (rule 4.16: "a pitch typed in
  /// inches of rise included, stored as the degrees it is worth"):
  /// [typedAngle], or the pitch a length typed under Pitch stands for —
  /// [Pitch] 6 [Inch] is 6in of rise per 12in of run, 26.57°, and the bare
  /// [Pitch] 6/12 is the same pitch — in the rise spelling, read the way
  /// the rules read it ([Angle.ofRise], so the drawer and the strip agree).
  /// A chip filed while still active reads as every leaving key closes it
  /// ([EntryBuffer.withFractionClosedAsInches]): [Pitch] 6 [Inch] 1/2, C
  /// pressed, files 6-1/2in of rise, 28.44°. `null` for a chip that files
  /// nothing: a count, a grade, a ratio, or a length under any other key.
  Angle? filedAngle(QuantityParser parser) {
    if (typedAngle case final angle?) return angle;
    if (!readsDegrees || trigFunction != null) return null;
    final closed = copyWith(entry: entry.withFractionClosedAsInches);
    return switch (closed.value(parser)) {
      final Length rise => Angle.ofRise(rise),
      Angle(spelling: AngleSpelling.risePerFoot) && final pitch => pitch,
      _ => null,
    };
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
      exactValue != null ||
      entry.isComplete ||
      _isPlainNumber ||
      _isRiseOverTwelve;

  bool get _isPlainNumber => (key == null || !keyWantsUnit) && _isBareNumber;

  bool get _isRiseOverTwelve =>
      readsDegrees &&
      trigFunction == null &&
      entry.tokens.length == 1 &&
      entry.tokens.single.unit == null &&
      entry.tokens.single.denominator == '${Angle.inchesPerFootOfRun}' &&
      double.tryParse(entry.tokens.single.digits) != null;

  /// The trig function the chip asks, when its key is a trig key (Sine…,
  /// Arcsine…), else `null`.
  TrigFunction? get trigFunction => TrigFunction.named(key);

  /// What a trig chip asks its function of: its bare number, in degrees
  /// for SIN, COS and TAN, spelled as it was typed (38°30'45" stays a
  /// survey angle), and as a ratio for the inverse keys; `null` for any
  /// other chip or before a number is typed. A recalled angle is read at
  /// its exact value, so the sine of a recalled 53.13° is 0.8, not 0.799999.
  Quantity? get trigOperand => switch ((trigFunction, bareNumber)) {
    (final function?, final number?) =>
      function.isInverse
          ? Scalar(number)
          : switch (exactValue) {
              final Angle recalled => recalled,
              _ => _typedAngle,
            },
    _ => null,
  };

  /// Whether the chip asks its trig function of an operand the function
  /// has no value for (Tangent 90°, Arcsine 2): the strip says why, and no
  /// key may treat its digits as a number in its place (Section 5.4:
  /// "Tangent can't answer that").
  bool get asksAnUndefinedTrig => switch ((trigFunction, trigOperand)) {
    (final function?, final operand?) => function.answerTo(operand) == null,
    _ => false,
  };

  /// The number of a chip that holds one bare number and nothing else,
  /// else `null`.
  double? get bareNumber => _isBareNumber ? entry.tokens.first.value : null;

  /// Whether the chip divides the ratio an Arctangent chip before it
  /// builds (Section 6, "÷ builds the ratio for ATAN"): ÷ and a bare number
  /// with no key. ÷ Pitch 12 is an angle and ÷ Sine 30 a trig chip of its
  /// own, so neither joins the ratio.
  bool get dividesAnArctangentRatio =>
      key == null && operator == Operator.divide && bareNumber != null;

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
    bool? isEditing,
    bool? followsARemovedResult,
    bool? isPercent,
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
      isEditing: isEditing ?? this.isEditing,
      followsARemovedResult:
          followsARemovedResult ?? this.followsARemovedResult,
      isPercent: isPercent ?? this.isPercent,
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
    isEditing,
    followsARemovedResult,
    isPercent,
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

  /// The unit a unit key converted this answer to, kept when an edit
  /// rebuilds it (rule 4.8); `null` for the unit the chain answered in.
  final Unit? readIn;

  const ResultChip({
    required this.key,
    required this.value,
    this.operator,
    this.readIn,
  });

  @override
  List<Object?> get props => [key, value, operator, readIn];
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

  /// Whether the result this bracket's operator led on from was removed by
  /// an edit, as [ValueChip.followsARemovedResult] says of a step.
  final bool followsARemovedResult;

  /// Whether the % key marked the closed bracket as a percent, worth the
  /// percent of what it folds to, as [ValueChip.isPercent] says of a
  /// number.
  final bool isPercent;

  const BracketChip({
    this.operator,
    this.inner = const [],
    this.isOpen = true,
    this.original,
    this.followsARemovedResult = false,
    this.isPercent = false,
  });

  /// The bracket as the tape spells it, "+(3×4" while open and "+(3×4)"
  /// once closed.
  String get expression {
    final inside = [
      for (final chip in inner)
        if (chip case ValueChip(:final operator, :final text))
          '${operator?.symbol ?? ''}$text',
    ].join();
    return '${operator?.symbol ?? ''}($inside${isOpen ? '' : ')'}'
        '${isPercent ? '%' : ''}';
  }

  /// Returns a copy with the given fields replaced. [operator] and
  /// [original] take a `Function()?` wrapper so that clearing them to
  /// `null` can be told apart from leaving them as they are.
  BracketChip copyWith({
    Operator? Function()? operator,
    List<TapeChip>? inner,
    bool? isOpen,
    List<TapeChip>? Function()? original,
    bool? followsARemovedResult,
    bool? isPercent,
  }) {
    return BracketChip(
      operator: operator != null ? operator() : this.operator,
      inner: inner ?? this.inner,
      isOpen: isOpen ?? this.isOpen,
      original: original != null ? original() : this.original,
      followsARemovedResult:
          followsARemovedResult ?? this.followsARemovedResult,
      isPercent: isPercent ?? this.isPercent,
    );
  }

  @override
  List<Object?> get props => [
    operator,
    inner,
    isOpen,
    original,
    followsARemovedResult,
    isPercent,
  ];
}

/// The place a step could not be computed (term 2.4). The strip goes
/// silent; ⌫ removes the chip and reopens the value before it.
final class ErrorChip extends TapeChip {
  /// What went wrong.
  final CalculationError error;

  /// Whether the chip stands where an edit's recompute found a result
  /// failing (rule 4.8), so that a ÷ after it is a step of its own and never
  /// read as a divisor ÷ 0 reopened (Section 5, "Division by zero").
  final bool replacesAResult;

  /// The unit the result this chip replaced was read in, kept so that the
  /// result reads in it again once the chain is repaired: 10ft ÷ 2 = read
  /// in inches, edited to ÷ 0 and back to ÷ 4, reads Calc 30in (product
  /// decision of 13 November 2026).
  final Unit? readIn;

  const ErrorChip(this.error, {this.replacesAResult = false, this.readIn});

  @override
  List<Object?> get props => [error, replacesAResult, readIn];
}
