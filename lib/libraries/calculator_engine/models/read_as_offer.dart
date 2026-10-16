import 'package:construculator/libraries/calculator_engine/entry_buffer.dart';
import 'package:equatable/equatable.dart';

/// The ways a bare number can be read (UX Design Doc term 2.14, rule 4.10):
/// neither reference calculator has a degree key, so 38.30 may be 38.3° or
/// 38°30'.
enum NumberReading {
  /// Decimal degrees: 38.30 is 38.3°.
  degrees,

  /// Degrees, minutes and seconds: 38.30 is 38°30'.
  degreesMinutesSeconds,
}

/// The Read-as pill (term 2.14): a dependent key pointed at an input, which
/// names the reading the calculator chose and offers the other one, so that
/// one tap re-inputs the number. "Input 12.1° as 12°01'" while the number
/// is being typed; "Re-input 38.30° as 38°30'" once a trig answer stands on
/// the tape and the tap will rewrite it (walkthrough 16.4).
final class ReadAsOffer extends Equatable {
  /// The place on the tape of the chip the offer re-reads, which can sit
  /// behind the active chip: [SIN] 12.1 ÷ 3.5 still offers the 12.1.
  final int chipIndex;

  /// How the number reads now.
  final NumberReading from;

  /// How the tap will read it.
  final NumberReading to;

  /// The entry the tap writes into the chip, rebuilt from the digits as
  /// they were typed, so that the way back is exact, not a re-derivation.
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
