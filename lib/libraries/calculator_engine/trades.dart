import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
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

  /// The piece's face in square ticks.
  double get squareTicks => width.ticks * height.ticks.toDouble();

  @override
  List<Object?> get props => [width, height];
}

/// How many pieces of one size an area needs: the answer the strip offers
/// and, once accepted, the result that carries its size as the Sheet size
/// or Piece size pill (requirement R8). The count is `area ÷ (w × h)` with
/// no rounding up (Section 9), kept exact here and rounded to two decimals
/// at display; a recount after the pill is edited goes through [recount],
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

  /// The count as the bare number the result chip holds.
  Scalar get value => Scalar(count);

  /// The same area counted in another size, as the pill recomputes it.
  TradeCount recount(PieceSize size) =>
      TradeCount(trade: trade, area: area, size: size);

  @override
  List<Object?> get props => [trade, area, size];
}

/// The material rules of UX Design Doc Section 9: an area on the tape
/// becomes a sheet count for every stored drywall size, or a piece count
/// for every stored masonry size, one offer per size in the store's order.
/// The port of the prototype's `materials`, over the sizes the trade-stores
/// repository holds; which area earns the offers, and when, is the
/// arbiter's.
class Trades extends Equatable {
  const Trades();

  /// A count of [area] for each of [sizes], in their order. A size with no
  /// face — a width or a height of nothing — counts nothing and is left
  /// out, because nothing divides by it.
  List<TradeCount> countsFor(Trade trade, Area area, List<PieceSize> sizes) => [
    for (final size in sizes)
      if (size.squareTicks > 0)
        TradeCount(trade: trade, area: area, size: size),
  ];

  @override
  List<Object?> get props => const [];
}
