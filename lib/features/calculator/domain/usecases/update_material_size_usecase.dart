import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Rewrites the stored size a count was made from, as Update does in the
/// value editor opened from the count's pill (UX Design Doc rule 4.7:
/// "Update rewrites the stored row the pill came from"; term 2.18). The row
/// keeps its place in the store, so the strip and the table keep their
/// order, and the next count uses the new size.
///
/// The row rewritten is the one the size is named by ([PieceSize.id]). A
/// size no longer in the store, deleted from the table while its count
/// stayed on the tape, is added back as a new row after the last one
/// (decision tree row 409).
class UpdateMaterialSizeUseCase {
  final TradeStoresRepository _repository;

  /// Creates the use case over the repository that holds the sizes.
  UpdateMaterialSizeUseCase({required this._repository});

  /// Rewrites [size] of [trade]'s store, as shown under [system], to
  /// [width] × [height], answering the size as stored or the repository's
  /// [Failure].
  Future<Either<Failure, StoredSize>> call({
    required Trade trade,
    required PieceSize size,
    required Length width,
    required Length height,
    required MeasurementSystem system,
  }) async {
    final sizes = await _repository.watchSizes(trade.sizeStore, system).first;
    for (final stored in sizes) {
      if (stored.isTheRowOf(size)) {
        return _repository.updateSize(
          stored.copyWith(width: width, height: height),
        );
      }
    }
    return _repository.addSize(
      StoredSize(
        store: trade.sizeStore,
        width: width,
        height: height,
        // The repository gives the size its place, after the last one; this
        // value is not read.
        position: 0,
      ),
    );
  }
}
