import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/trade_stores.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';
import 'package:rxdart/rxdart.dart';

/// The trade stores as the ladder reads them, through the trade-stores
/// repository (UX Design Doc term 2.16, rule 4.4; requirement R9): one
/// [TradeStores] holding the sheet sizes and the masonry sizes under the
/// unit system in force, in the user's order, re-emitted whenever either
/// store changes — a size added or deleted in the detail panel shows up in
/// the next emission, and the strip counts by it without being asked.
///
/// The engine counts over a [PieceSize]; this is where a stored size
/// becomes one ([StoredSize.piece]), which keeps the engine free of the
/// feature's entities. The stream is built on the repository's own
/// watches, so it ends when the repository is disposed.
class WatchTradeStoresUseCase {
  final TradeStoresRepository _repository;

  /// Creates the use case over the repository that holds the stores.
  WatchTradeStoresUseCase({required this._repository});

  /// The stores under [system], as they are now and after every change.
  Stream<TradeStores> call({required MeasurementSystem system}) =>
      Rx.combineLatest2(
        _repository.watchSizes(SizeStore.sheet, system),
        _repository.watchSizes(SizeStore.masonry, system),
        (sheets, pieces) => TradeStores(
          sheetSizes: [for (final size in sheets) size.piece],
          masonrySizes: [for (final size in pieces) size.piece],
        ),
      ).distinct();
}
