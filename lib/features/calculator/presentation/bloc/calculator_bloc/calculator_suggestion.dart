part of 'calculator_bloc.dart';

/// Where a chip on the strip comes from (UX Design Doc Section 1.2), which
/// decides what accepting it does.
enum CalculatorSuggestionKind {
  /// An answer the engine computed from the tape: a rule's answer (Area,
  /// Diagonal, Pitch-degrees…) or a pending trig chip's (Sine 0.615661).
  /// Accepting lands it as a result chip.
  answer,

  /// The running total of a chain, Calc. Accepting lands it as = would.
  runningTotal,

  /// The value on screen re-spelled in another unit (term 2.12). Accepting
  /// converts the value in place and never starts a new calculation.
  conversion,

  /// A count of the area on screen at one stored size (term 2.10, "A sheet
  /// count proposed for the area, with its sheet size"), read through the
  /// trade stores. Accepting lands it as a result chip under the trade's
  /// result key (Number of sheets).
  materialCount,
}

/// One chip of the suggestion strip: an answer already computed when the
/// chip is drawn, so that accepting it recalculates nothing (Section 1.2).
final class CalculatorSuggestion extends Equatable {
  /// The engine's id of the answer, which the page names from i18n: a
  /// rule's key (Area, Pitch-rise per 12in run), a trig function's
  /// (Sine, Arctangent(16 ÷ 12)) or [Tape.calcKey]; `null` for a
  /// conversion, which is named by its value alone.
  final String? key;

  /// The answer, or the value re-spelled.
  final Quantity value;

  /// Where the chip comes from.
  final CalculatorSuggestionKind kind;

  /// [value] as the tape's formatter writes it: 410.67ft², 26.57°, 224in,
  /// 5.63.
  final String text;

  /// The count a [CalculatorSuggestionKind.materialCount] chip offers, with
  /// the trade, the area and the size it was made from; `null` for every
  /// other kind.
  final TradeCount? count;

  /// The stored fact the chip shows inside its parentheses ("the assumption
  /// it used … inside the chip", term 2.10): the size as the tape's
  /// formatter writes it, 48in x 96in; `null` when the chip states none.
  final String? basis;

  const CalculatorSuggestion({
    required this.key,
    required this.value,
    required this.kind,
    required this.text,
    this.count,
    this.basis,
  });

  @override
  List<Object?> get props => [key, value, kind, text, count, basis];
}
