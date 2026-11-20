import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Removes a size from the store a trade counts by, as a row of the detail
/// panel's sheet table is deleted (UX Design Doc Section 1.4: "swiped to
/// delete"). A result already on the tape keeps its count; the next count
/// uses the sizes that remain.
///
/// The table shows a size, not a stored row, so the size removed is the
/// first one of the store, under the unit system in force, with the same
/// width and height. A size no longer in the store, removed on another
/// phone while the table was on screen, leaves nothing to remove.
class DeleteMaterialSizeUseCase {
  final TradeStoresRepository _repository;

  /// Creates the use case over the repository that holds the sizes.
  DeleteMaterialSizeUseCase({required this._repository});

  /// Removes [size] from [trade]'s store as shown under [system], answering
  /// what the repository answers, or success when the store no longer
  /// holds it.
  Future<Either<Failure, void>> call({
    required Trade trade,
    required PieceSize size,
    required MeasurementSystem system,
  }) async {
    final sizes = await _repository.watchSizes(trade.sizeStore, system).first;
    for (final stored in sizes) {
      if (PieceSize(width: stored.width, height: stored.height) == size) {
        return _repository.deleteSize(stored);
      }
    }
    return const Right(null);
  }
}
