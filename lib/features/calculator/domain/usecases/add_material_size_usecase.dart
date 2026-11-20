import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Adds a size to the store a trade counts by, from "+ Add size" in the
/// detail panel's sheet table (UX Design Doc Section 1.4 and term 2.18:
/// Add "adds a row"). The size goes after the last one, so its count joins
/// the table and the strip at the end, and it shows under Imperial and
/// Metric alike (term 2.16).
class AddMaterialSizeUseCase {
  final TradeStoresRepository _repository;

  /// Creates the use case over the repository that holds the sizes.
  AddMaterialSizeUseCase({required this._repository});

  /// Adds [width] × [height] to [trade]'s store, answering the size as
  /// stored or the repository's [Failure].
  Future<Either<Failure, StoredSize>> call({
    required Trade trade,
    required Length width,
    required Length height,
  }) => _repository.addSize(
    StoredSize(
      store: trade.sizeStore,
      width: width,
      height: height,
      position: 0,
    ),
  );
}
