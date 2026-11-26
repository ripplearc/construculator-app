part of 'calculator_bloc.dart';

/// A pill under the value (Section 1.1, "Dependent-key row"): what the
/// engine offers to re-read or re-spell on the display, and the stored
/// fact a trade result was made from. The other pills a trade result
/// carries (Rate, Waste…) arrive with their stores (G2, G3).
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

/// The pill of a stored size (rule 4.7: "A result that used a stored fact
/// carries it as a dependent key"): the sheet size behind a drywall count,
/// "Sheet size: 48in x 96in", or the piece size behind a masonry count.
final class CalculatorStoredSizePill extends CalculatorDependentKey {
  /// Which stored fact the pill names.
  final DependentKeyId id;

  /// The size as the formatter writes it: 48in x 96in.
  final String sizeText;

  /// What the value editor opens on from the pill (term 2.18): the size's
  /// width, then its height, each as the editor's keys type it, "48Inch"
  /// and "96Inch".
  final List<String> editorFields;

  /// The pill [id] over the size written as [sizeText], edited from
  /// [editorFields].
  const CalculatorStoredSizePill({
    required this.id,
    required this.sizeText,
    this.editorFields = const [],
  });

  @override
  List<Object?> get props => [id, sizeText, editorFields];
}
