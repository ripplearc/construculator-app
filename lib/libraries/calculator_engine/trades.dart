import 'dart:math';

import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/rational.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// The two trades that count pieces over an area (UX Design Doc Section 9,
/// "Drywall sheets and masonry pieces"): what the strip calls the offer and
/// what the accepted result is called.
enum Trade {
  /// Sheets of drywall from the sheet-size store.
  drywall('Drywall', 'Number of sheets'),

  /// Blocks, bricks or tiles from the masonry-size store.
  masonry('Masonry', 'Number of pieces');

  /// The key the strip labels the offer by.
  final String offerKey;

  /// The key the accepted count is labelled by.
  final String resultKey;

  const Trade(this.offerKey, this.resultKey);
}

/// One stored piece: a sheet, a block, a brick or a tile, as the trade
/// store holds it.
final class PieceSize extends Equatable {
  /// The piece's width.
  final Length width;

  /// The piece's height.
  final Length height;

  const PieceSize({required this.width, required this.height});

  /// The piece's face in square ticks, from the exact sides
  /// ([Length.preciseTicks]): a metric or a decimal-inch side is no whole
  /// number of ticks, and a face rounded before the division counts 172.8
  /// m² of 1200 × 2400 mm sheets as 59.99 instead of 60 (Sections 6 and 9:
  /// nothing is rounded until it is displayed).
  double get squareTicks => width.preciseTicks * height.preciseTicks;

  /// Whether both sides are longer than zero, so the piece has a face to
  /// divide by. Each side is checked on its own: two negative sides make a
  /// positive face, and a size of −6in × −6in is no size at all ("Size must
  /// be more than zero"; product owner, 5 November 2026).
  bool get hasFace => width.preciseTicks > 0 && height.preciseTicks > 0;

  @override
  List<Object?> get props => [width, height];
}

/// How many pieces of one size an area needs: the answer the strip offers
/// and, once accepted, the result that carries its size as the Sheet size
/// or Piece size pill (requirement R8). The count is `area ÷ (w × h)` with
/// no rounding up (Section 9), kept exact here and rounded to two decimals
/// at display for every size of count (0.031 reads 0.03, never the two
/// significant digits of a ratio); a recount after the pill is edited goes
/// through [recount],
/// which keeps the area the count was made from.
final class TradeCount extends Equatable {
  /// The trade the count belongs to.
  final Trade trade;

  /// The area the count covers.
  final Area area;

  /// The size one piece has.
  final PieceSize size;

  const TradeCount({
    required this.trade,
    required this.area,
    required this.size,
  });

  /// Pieces of [size] that cover [area], fractional pieces included.
  double get count => area.squareTicks / size.squareTicks;

  /// The count as the bare number the result chip holds, written to two
  /// decimals with the zeros kept, so a count under 0.005 reads 0.00
  /// (Section 9; product owner, 5 November 2026).
  Scalar get value =>
      Scalar(count, decimals: countDecimals, padsDecimals: true);

  /// The decimals a count is written with.
  static const countDecimals = 2;

  /// The same area counted in another size, as the pill recomputes it, or
  /// `null` for a size with no face — a side of zero or less, see
  /// [PieceSize.hasFace] — which is refused so that the caller keeps the
  /// last good size ("Size must be more than zero"; product owner,
  /// 5 November 2026).
  TradeCount? recount(PieceSize size) {
    if (!size.hasFace) return null;
    return TradeCount(trade: trade, area: area, size: size);
  }

  @override
  List<Object?> get props => [trade, area, size];
}

/// The concrete a length of footing takes at one stored cross-section (UX
/// Design Doc Section 9, "Concrete footing": volume (yd³) = length (ft) ×
/// (w × h ÷ 144) ÷ 27, for each stored cross-section, 16in × 8in and
/// 24in × 18in): the offer the strip makes per cross-section and, once
/// accepted, the result that carries its Cross-section pill (requirement
/// R8). The cross-section is a stored width × height like a sheet, so it
/// is a [PieceSize]. A recount after the pill is edited goes through
/// [recount], which keeps the length the volume was made from.
final class FootingVolume extends Equatable {
  /// The key the strip labels the offer by.
  static const String offerKey = 'Footing';

  /// The key the accepted volume is labelled by.
  static const String resultKey = 'Footing volume';

  /// The run of footing.
  final Length length;

  /// The cross-section of the footing.
  final PieceSize crossSection;

  /// The system of units the volume is written in: cubic yards under
  /// Imperial, cubic metres under Metric, whatever unit the length was
  /// typed in (Section 6, "Display settings": "A trade result follows the
  /// System of units setting, as a weight does. A footing mixes the typed
  /// length with a stored cross-section, so 10m then Footng reads in yd³
  /// under Imperial and in m³ under Metric"; Section 9, "(m³ under
  /// Metric)"; product manager, 17 November 2026).
  final MeasurementSystem system;

  /// A run of footing of [length] at [crossSection], written in the cubic
  /// unit of [system].
  const FootingVolume({
    required this.length,
    required this.crossSection,
    required this.system,
  });

  /// The concrete: the length times the cross-section's face, both at
  /// their precise ticks, kept exact and rounded to two decimals at
  /// display, in the cubic unit of [system].
  Volume get volume => Volume(
    length.preciseTicks /
        Length.ticksPerFoot *
        crossSection.squareTicks /
        _squareTicksPerSquareFoot,
    unit: switch (system) {
      MeasurementSystem.imperial => Unit.yard,
      MeasurementSystem.metric => Unit.metre,
    },
  );

  /// The same length of footing at another cross-section, as the pill
  /// recomputes it, or `null` for a cross-section with no face — a side of
  /// zero or less, see [PieceSize.hasFace] — which is refused so that the
  /// caller keeps the last good one ("Size must be more than zero").
  FootingVolume? recount(PieceSize crossSection) {
    if (!crossSection.hasFace) return null;
    return FootingVolume(
      length: length,
      crossSection: crossSection,
      system: system,
    );
  }

  @override
  List<Object?> get props => [length, crossSection, system];
}

/// The posts and rails a length of fence needs (Section 9, "Fence":
/// sections = ceil(length ÷ O.C.), at least 1; posts = sections + 1;
/// rails = sections × rails per section; seeds O.C. 8ft, 3 rails per
/// section). The Posts result carries the O.C. and Rails/section pills,
/// and the rails are offered as a suggestion beside it (requirement R8). A
/// recount after a pill is edited goes through [recount], which keeps the
/// length the fence was counted for.
final class FenceCount extends Equatable {
  /// The key the accepted posts are labelled by.
  static const String postsKey = 'Fence posts';

  /// The key the strip labels the rails offer by.
  static const String railsOfferKey = 'Rails';

  /// The key the accepted rails are labelled by.
  static const String railsKey = 'Fence rails';

  /// The run of fence.
  final Length length;

  /// The post spacing, on centre.
  final Length onCentre;

  /// Rails between two posts.
  final int railsPerSection;

  /// A run of fence of [length] with posts [onCentre] and [railsPerSection]
  /// rails between them. A spacing of zero or less has no sections, so a
  /// caller counts through [Trades.fenceFor] or [recount], which refuse it.
  const FenceCount({
    required this.length,
    required this.onCentre,
    required this.railsPerSection,
  });

  /// Sections of fence: the length over the spacing, rounded up, computed
  /// exactly over the inches so that 24m at 2.4m is ten sections and not
  /// eleven. A length within one part of a tick ([Length.partsPerTick]) of a
  /// whole number of spacings is that many, because a computed length is
  /// kept only to that part: Calc 24m from 57.6m² ÷ 2.4m is ten sections
  /// too, as the screen reads it. A length above zero always has at least
  /// one, and lengths too long for exact sums are counted in ticks.
  int get sections => _spacingsIn(length, onCentre);

  /// One post more than there are sections.
  int get posts => sections + 1;

  /// The rails of every section.
  int get rails => sections * railsPerSection;

  /// The posts as the whole number the result chip holds.
  Scalar get postsValue => Scalar(posts.toDouble(), decimals: 0);

  /// The rails as the whole number the result chip holds.
  Scalar get railsValue => Scalar(rails.toDouble(), decimals: 0);

  /// The same length of fence at another spacing or with other rails per
  /// section, as the pills recompute it, or `null` for a spacing of zero
  /// or less or rails below zero, which are refused so that the caller
  /// keeps the last good pill.
  FenceCount? recount({Length? onCentre, int? railsPerSection}) {
    final spacing = onCentre ?? this.onCentre;
    final rails = railsPerSection ?? this.railsPerSection;
    if (!_isAboveZero(spacing) || rails < 0) return null;
    return FenceCount(
      length: length,
      onCentre: spacing,
      railsPerSection: rails,
    );
  }

  @override
  List<Object?> get props => [length, onCentre, railsPerSection];
}

/// The members along a span at one on-centre spacing (Section 9, "Quantity
/// at on-centre spacing": members = ceil(length ÷ spacing) + 1 for each
/// stored spacing, 16in and 24in): the offer the strip makes per spacing
/// and, once accepted, the result that carries its O.C. pill (requirement
/// R8). A recount after the pill is edited goes through [recount], which
/// keeps the span: 22ft 8-3/4in at 19.5in gives 15.
final class SpacingCount extends Equatable {
  /// The key the strip labels the offer by.
  static const String offerKey = 'Qty';

  /// The key the accepted count is labelled by.
  static const String resultKey = 'Quantity';

  /// The span the members are laid along.
  final Length span;

  /// The spacing, on centre.
  final Length spacing;

  /// Members along [span] at [spacing] on centre. A spacing of zero or
  /// less has no members, so a caller counts through
  /// [Trades.spacingCountsFor] or [recount], which leave it out.
  const SpacingCount({required this.span, required this.spacing});

  /// The members: the span over the spacing, rounded up as
  /// [FenceCount.sections] rounds it, plus the one that closes the span.
  int get members => _spacingsIn(span, spacing) + 1;

  /// The members as the whole number the result chip holds.
  Scalar get value => Scalar(members.toDouble(), decimals: 0);

  /// The same span at another spacing, as the pill recomputes it, or
  /// `null` for a spacing of zero or less, which is refused so that the
  /// caller keeps the last good one.
  SpacingCount? recount(Length spacing) {
    if (!_isAboveZero(spacing)) return null;
    return SpacingCount(span: span, spacing: spacing);
  }

  @override
  List<Object?> get props => [span, spacing];
}

const int _squareTicksPerSquareFoot =
    Area.squareTicksPerSquareInch * Area.squareInchesPerSquareFoot;

bool _isAboveZero(Length length) => length.preciseTicks > 0;

const Rational _onePartOfATick = Rational(
  1,
  Length.ticksPerInch * Length.partsPerTick,
);

int _spacingsIn(Length length, Length spacing) {
  try {
    final whole = (length.inches / spacing.inches).floor();
    final over = length.inches - spacing.inches * Rational(whole);
    if (whole > 0 && over.compareTo(_onePartOfATick) <= 0) return whole;
    return whole + 1;
  } on RationalOverflow {
    final ticksOver = length.preciseTicks - 1 / Length.partsPerTick;
    return max(1, (ticksOver / spacing.preciseTicks).ceil());
  }
}

/// The material rules of UX Design Doc Section 9: an area on the tape
/// becomes a sheet count for every stored drywall size, or a piece count
/// for every stored masonry size, one offer per size in the store's order;
/// a length becomes concrete for every stored footing cross-section, posts
/// and rails at the stored fence spacing, or members at every stored
/// on-centre spacing. The port of the prototype's `materials`,
/// `footingChips`, `fenceCalc` and `qtyOcChips`, over what the trade-stores
/// repository holds; which value earns the offers, and when, is the
/// arbiter's, and so are the follow-on offers after a trade result (Cost,
/// Weight), which are rules of their own.
class Trades extends Equatable {
  const Trades();

  /// A count of [area] for each of [sizes], in their order. An area of
  /// zero or less has no count at all, so that the screen can refuse the
  /// key ("Area must be more than zero"; product owner, 5 November 2026),
  /// and so has an area that is not a finite number, which nothing on the
  /// tape produces today and which no formatter could write.
  /// A size with no face — a width or a height of zero or less, see
  /// [PieceSize.hasFace] — counts nothing and is left out, because nothing
  /// divides by it.
  List<TradeCount> countsFor(Trade trade, Area area, List<PieceSize> sizes) {
    final ticks = area.squareTicks;
    if (!ticks.isFinite || ticks <= 0) return const [];
    return [
      for (final size in sizes)
        if (size.hasFace) TradeCount(trade: trade, area: area, size: size),
    ];
  }

  /// The concrete of [length] at each of [crossSections], in their order.
  /// A length of zero or less takes no concrete at all, so that the screen
  /// can refuse the key with the red Alert "Length must be more than zero"
  /// (design doc 21.3, "Keys that must also answer"); a cross-section with
  /// no face — see [PieceSize.hasFace] — is left out. A length is always
  /// finite ([Length.computed] refuses the rest), so that is the one guard.
  List<FootingVolume> footingVolumesFor(
    Length length,
    List<PieceSize> crossSections, {
    required MeasurementSystem system,
  }) {
    if (!_isAboveZero(length)) return const [];
    return [
      for (final crossSection in crossSections)
        if (crossSection.hasFace)
          FootingVolume(
            length: length,
            crossSection: crossSection,
            system: system,
          ),
    ];
  }

  /// The fence along [length] with posts [onCentre] and [railsPerSection]
  /// rails between them; `null` for a length of zero or less, a spacing of
  /// zero or less, or rails below zero, none of which the screen lets
  /// through.
  FenceCount? fenceFor(
    Length length, {
    required Length onCentre,
    required int railsPerSection,
  }) {
    if (!_isAboveZero(length) ||
        !_isAboveZero(onCentre) ||
        railsPerSection < 0) {
      return null;
    }
    return FenceCount(
      length: length,
      onCentre: onCentre,
      railsPerSection: railsPerSection,
    );
  }

  /// The members along [span] at each of [spacings], in their order. A span
  /// of zero or less has no members at all; a spacing of zero or less is
  /// left out.
  List<SpacingCount> spacingCountsFor(Length span, List<Length> spacings) {
    if (!_isAboveZero(span)) return const [];
    return [
      for (final spacing in spacings)
        if (_isAboveZero(spacing)) SpacingCount(span: span, spacing: spacing),
    ];
  }

  @override
  List<Object?> get props => const [];
}
