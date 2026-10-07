import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';

/// The sheet or piece counts an area earns, read through the trade-stores
/// repository (UX Design Doc Section 9; requirement R9): one [TradeCount]
/// per stored size of the trade's store under the unit system in force,
/// in the user's order, re-emitted whenever the store changes — a size
/// added from the detail panel, or a Sheet size pill edited and written
/// back (R8), shows up in the next emission without a recount being asked
/// for.
///
/// The engine counts over a [PieceSize]; this is the one place a stored
/// size becomes one, which keeps the engine free of the feature's
/// entities. The stream is the repository's own watch, so it ends when the
/// repository is disposed.
class WatchMaterialCountsUseCase {
  final TradeStoresRepository _repository;
  final Trades _trades;

  /// Creates the use case over the repository that holds the sizes.
  WatchMaterialCountsUseCase({
    required this._repository,
    this._trades = const Trades(),
  });

  /// The counts of [area] for [trade], one per size of its store under
  /// [system], as the store is now and after every change.
  Stream<List<TradeCount>> call({
    required Trade trade,
    required Area area,
    required MeasurementSystem system,
  }) => _repository
      .watchSizes(_storeOf(trade), system)
      .map(
        (sizes) => _trades.countsFor(trade, area, sizes.map(_pieceOf).toList()),
      );

  SizeStore _storeOf(Trade trade) => switch (trade) {
    Trade.drywall => SizeStore.sheet,
    Trade.masonry => SizeStore.masonry,
  };

  PieceSize _pieceOf(StoredSize size) =>
      PieceSize(width: size.width, height: size.height);
}
