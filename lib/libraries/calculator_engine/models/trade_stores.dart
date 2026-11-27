import 'package:construculator/libraries/calculator_engine/trades.dart';
import 'package:equatable/equatable.dart';

/// The trade stores as the ladder reads them (UX Design Doc term 2.16): the
/// stored sizes a trade counts by, in the user's order, under the unit
/// system in force. A snapshot, so that the same tape over the same stores
/// always earns the same strip (requirement R5).
final class TradeStores extends Equatable {
  /// The drywall sheet sizes.
  final List<PieceSize> sheetSizes;

  /// The masonry piece sizes.
  final List<PieceSize> masonrySizes;

  /// The stores holding [sheetSizes] and [masonrySizes]; both empty until
  /// the store has answered.
  const TradeStores({this.sheetSizes = const [], this.masonrySizes = const []});

  /// The sizes [trade] counts by.
  List<PieceSize> sizesFor(Trade trade) => switch (trade) {
    Trade.drywall => sheetSizes,
    Trade.masonry => masonrySizes,
  };

  @override
  List<Object?> get props => [sheetSizes, masonrySizes];
}
