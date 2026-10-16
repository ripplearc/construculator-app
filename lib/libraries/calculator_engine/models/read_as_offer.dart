import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:equatable/equatable.dart';

/// The ways a bare number can be read (UX Design Doc term 2.14, rule 4.10):
/// neither reference calculator has a degree key, so 38.30 may be 38.3° or
/// 38°30', a bare 6 under Pitch may be 6° or the 6in/12in roof a roofer
/// means, and 0.65 under Slope may be a 0.65% grade or the ratio 0.65, which
/// is 65%.
enum NumberReading {
  /// Decimal degrees: 8.45 is 8.45°.
  degrees,

  /// Degrees, minutes and seconds: 8.45 is 8°45'.
  degreesMinutesSeconds,

  /// Inches of rise per 12in of run: 8.45 under Pitch is 8.45in/12in, what
  /// the [Inch] key makes of it.
  risePerFoot,

  /// A percent grade, the reading a bare number under Slope has: 0.65 is
  /// 0.65%.
  grade,

  /// The ratio of rise to run, which both reference calculators read a bare
  /// Slope number as: 0.65 is 65%, the same digits with the point moved.
  ratio,
}

/// The Read-as pill (term 2.14): a dependent key pointed at an input, which
/// names the reading the calculator chose and offers the other one, so that
/// one tap re-inputs the number. "Input 8.45° as 8.45in/12in" while the
/// number is being typed; "Re-input 38.30° as 38°30'" once a trig answer
/// stands on the tape and the tap will rewrite it (walkthrough 16.4).
final class ReadAsOffer extends Equatable {
  /// The steepest ratio of rise to run the pill offers under Slope (rule
  /// 4.10: "Between 0 and 2 both readings are realistic"): a ratio of 2 is
  /// a 24in/12in pitch at 63°, about the steepest roof in common use.
  static const int largestSlopeRatio = 2;

  /// The steepest rise per 12in of run the pill offers under Pitch, derived
  /// from [largestSlopeRatio] so that both keys draw the line at the same
  /// roof (rule 4.10: "never offers a roof nobody could frame (over
  /// 24in/12in)"; S115).
  static const int largestRisePerFoot = 12 * largestSlopeRatio;

  /// The place on the tape of the chip the offer re-reads, which can sit
  /// behind the active chip: [SIN] 12.1 ÷ 3.5 still offers the 12.1.
  final int chipIndex;

  /// How the number reads now.
  final NumberReading from;

  /// How the tap will read it.
  final NumberReading to;

  /// The entry the tap writes into the chip, rebuilt from the digits as
  /// they were typed, so that a full lap comes home to exactly what was
  /// typed (walkthrough 17.4).
  final EntryBuffer next;

  /// Whether a trig answer stands after the chip and will be rebuilt from
  /// the re-read number: the pill then reads "Re-input" rather than
  /// "Input" (S116), because the tap changes an answer already on screen.
  final bool rebuildsAnAnswer;

  const ReadAsOffer({
    required this.chipIndex,
    required this.from,
    required this.to,
    required this.next,
    this.rebuildsAnAnswer = false,
  });

  @override
  List<Object?> get props => [chipIndex, from, to, next, rebuildsAnAnswer];
}
