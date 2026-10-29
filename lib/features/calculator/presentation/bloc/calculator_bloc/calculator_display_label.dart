part of 'calculator_bloc.dart';

/// What the label row names (Section 1.1): the key of the value being
/// typed or of the last answer, the operator that opened a chip with no key
/// ("Multiplication 5"), a bare value, with the reading of a bare number
/// after it and the inside of a closed bracket ("Addition · (3×4)",
/// Section 7). The page spells the parts from i18n; the ellipsis of a
/// value still being typed is the display's own.
final class CalculatorDisplayLabel extends Equatable {
  /// The stable id the head of the label names: a function key, an answer's
  /// key or an error's name; `null` for a bare value or a bracket.
  final String? keyId;

  /// The operator that leads the chip into its chain, which names a chip
  /// with no key; `null` when the chip starts a chain.
  final Operator? operator;

  /// How the bare number is read (the engine's reading of it, rule 4.10),
  /// when the label should say so: "Pitch · degrees", "Slope · grade",
  /// "Arcsine · a ratio".
  final NumberReading? reading;

  /// The inside of a closed bracket, as the tape spells it ("3×4"), or
  /// `null`.
  final String? bracketExpression;

  /// Whether the value is still being typed, so the label ends in an
  /// ellipsis: an entry not complete yet, or an empty chip a key opened. A
  /// bare number after an operator is complete enough (Section 7:
  /// "Addition 3").
  final bool isTyping;

  const CalculatorDisplayLabel({
    this.keyId,
    this.operator,
    this.reading,
    this.bracketExpression,
    this.isTyping = false,
  });

  /// Whether the label names nothing: an empty tape.
  bool get isEmpty =>
      keyId == null &&
      operator == null &&
      reading == null &&
      bracketExpression == null &&
      !isTyping;

  @override
  List<Object?> get props => [
    keyId,
    operator,
    reading,
    bracketExpression,
    isTyping,
  ];
}
