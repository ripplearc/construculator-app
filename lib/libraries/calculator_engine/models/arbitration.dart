import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:equatable/equatable.dart';

/// The questions the ladder asks, in order, to choose the strip (UX Design
/// Doc rule 4.4): the first one answered yes is the rung the strip stops
/// at. The rungs after [rules] — a plain result's implications, a single
/// value's conversions and the remembered values — are G2's and G3's.
enum LadderRung {
  /// 1: the chain holds an error or a step it cannot compute, or a bracket
  /// is open. The strip shows nothing.
  error,

  /// 2: an area on the display, or a count just accepted from it: the
  /// stored sizes that are still on offer.
  tradeFollowOn,

  /// 3: the named values match a rule, a trig chip waits for its answer, or
  /// an operator has values on both sides.
  rules,

  /// No rung of this ladder answered.
  none,
}

/// Why the strip shows nothing at [LadderRung.error].
enum StripSilence {
  /// A bracket is open (Section 7: no preview until the group closes).
  openBracket,

  /// The chain holds an error chip or a step it cannot compute (Section
  /// 5: "after an error the area stays empty on purpose").
  chainFailed,
}

/// One question of the ladder as the trace records it: the rung asked and
/// whether it answered.
final class LadderStep extends Equatable {
  /// The rung that was asked.
  final LadderRung rung;

  /// Whether it had something to say.
  final bool applies;

  /// The answer [applies] the ladder got when it asked [rung].
  const LadderStep(this.rung, {required this.applies});

  @override
  List<Object?> get props => [rung, applies];
}

/// What kind of chip an offer is drawn as, and what accepting it lands.
enum StripOfferKind {
  /// An answer of the rules or of a trig chip, landed under its key.
  answer,

  /// The running total of the chain, which = lands as Calc.
  runningTotal,
}

/// One chip of the strip's row 1: what it is called and what it is worth.
final class StripOffer extends Equatable {
  /// The key the offer is labelled by.
  final String key;

  /// The offered value.
  final Quantity value;

  /// What kind of offer it is.
  final StripOfferKind kind;

  /// An offer of [value] under [key], drawn as [kind].
  const StripOffer({
    required this.key,
    required this.value,
    required this.kind,
  });

  @override
  List<Object?> get props => [key, value, kind];
}

/// What the ladder chose for a tape: the rung it stopped at, row 1 of the
/// strip, and the trace of every question asked on the way.
final class Arbitration extends Equatable {
  /// The first rung that answered.
  final LadderRung rung;

  /// Row 1 of the strip, in the order it is drawn.
  final List<StripOffer> offers;

  /// Why the strip is empty at [LadderRung.error]; `null` at any other
  /// rung.
  final StripSilence? silence;

  /// The questions asked, in order, up to the rung that answered.
  final List<LadderStep> trace;

  /// What the ladder chose: the [rung] it stopped at and the [trace] of
  /// the questions that led there.
  const Arbitration({
    required this.rung,
    required this.trace,
    this.offers = const [],
    this.silence,
  });

  @override
  List<Object?> get props => [rung, offers, silence, trace];
}
