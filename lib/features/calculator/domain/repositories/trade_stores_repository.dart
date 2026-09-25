// coverage:ignore-file
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// The trade stores (UX Design Doc term 2.16, Section 9, Appendix B): the
/// editable lists the material keys read and the pills write. Version one
/// keeps them on the device only.
///
/// Every `watch` emits the store as it is now and again after each change,
/// in the user's order; every write answers with what was stored or a
/// [Failure], never a throw. A store that is empty on first use is seeded
/// with Appendix B's defaults by [seedDefaults].
abstract class TradeStoresRepository {
  /// Fills every empty store with the seed values of Appendix B; a store
  /// that already holds rows is left as it is. Safe to call on every start.
  Future<Either<Failure, void>> seedDefaults();

  /// The sizes of one store under one unit system, in the user's order.
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  );

  /// Adds a size at the end of its store and answers it with its id.
  Future<Either<Failure, StoredSize>> addSize(StoredSize size);

  /// Rewrites the stored row the pill or detail panel came from.
  Future<Either<Failure, StoredSize>> updateSize(StoredSize size);

  /// Removes a size by its id.
  Future<Either<Failure, void>> deleteSize(String id);

  /// The on-centre spacings, in the user's order.
  Stream<List<StoredSpacing>> watchSpacings();

  /// Adds a spacing at the end and answers it with its id.
  Future<Either<Failure, StoredSpacing>> addSpacing(StoredSpacing spacing);

  /// Rewrites a stored spacing.
  Future<Either<Failure, StoredSpacing>> updateSpacing(StoredSpacing spacing);

  /// Removes a spacing by its id.
  Future<Either<Failure, void>> deleteSpacing(String id);

  /// The fence configuration.
  Stream<FenceConfiguration> watchFence();

  /// Rewrites the fence configuration.
  Future<Either<Failure, FenceConfiguration>> updateFence(
    FenceConfiguration fence,
  );

  /// Every rate with its waste factor, one per [RateUnit].
  Stream<List<StoredRate>> watchRates();

  /// Rewrites the rate and waste factor of one unit.
  Future<Either<Failure, StoredRate>> updateRate(StoredRate rate);

  /// The named densities, in the user's order.
  Stream<List<StoredDensity>> watchDensities();

  /// Adds a material at the end and answers it with its id ("+ Add
  /// material").
  Future<Either<Failure, StoredDensity>> addDensity(StoredDensity density);

  /// Rewrites a stored density.
  Future<Either<Failure, StoredDensity>> updateDensity(StoredDensity density);

  /// Removes a material by its id.
  Future<Either<Failure, void>> deleteDensity(String id);

  /// Ends every stream handed out.
  void dispose();
}
