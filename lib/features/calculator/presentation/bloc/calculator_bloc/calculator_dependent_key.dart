part of 'calculator_bloc.dart';

/// A pill under the value (Section 1.1, "Dependent-key row"): what the
/// engine offers to re-read or re-spell on the display today. The pills a
/// trade result carries (Sheet size, Rate, Waste…) arrive with the stores
/// (G1 to G3).
sealed class CalculatorDependentKey extends Equatable {
  const CalculatorDependentKey();
}

/// The Read-as pill (term 2.14): the other reading of an ambiguous number,
/// "Input 8.45° as 8.45in/12in", or "Re-input 38.30° as 38°30'00"" once a
/// trig answer stands after the number and the tap rewrites it.
final class CalculatorReadAsPill extends CalculatorDependentKey {
  /// The offer the tape makes, which [CalculatorReadAsAccepted] takes.
  final ReadAsOffer offer;

  /// The number as it reads now, with its reading written out: 8.45°,
  /// 8.45in/12in, 0.65%.
  final String sourceText;

  /// The number as the tap will read it: 8.45in/12in, 8°45'00", 65%.
  final String targetText;

  const CalculatorReadAsPill({
    required this.offer,
    required this.sourceText,
    required this.targetText,
  });

  /// Whether a trig answer standing after the number is rebuilt by the tap,
  /// so the pill reads "Re-input" rather than "Input" (S116).
  bool get rebuildsAnAnswer => offer.rebuildsAnAnswer;

  @override
  List<Object?> get props => [offer, sourceText, targetText];
}

/// The "Shown as" pill under a pitch answer (Section 8): the spelling the
/// answer wears, in/12in, degrees or grade; a tap cycles to the next, as
/// pressing Pitch does.
final class CalculatorPitchSpellingPill extends CalculatorDependentKey {
  /// The spelling the pitch answer is written in.
  final AngleSpelling spelling;

  const CalculatorPitchSpellingPill(this.spelling);

  @override
  List<Object?> get props => [spelling];
}
