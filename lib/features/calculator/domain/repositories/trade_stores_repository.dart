// coverage:ignore-file
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// The trade stores (UX Design Doc term 2.16, Section 9, Appendix B): the
/// editable lists the material keys read and the pills write. They follow
/// the signed-in user's account through the synced `user_calculator_stores`
/// table (Design Appendices B and E): only what the user added or changed is
/// stored, and Appendix B's defaults are laid over those rows on every read,
/// so there is nothing to seed and a fresh account shows the defaults at
/// once. The rates are not here: since CA-1304 they are the company's saved
/// rates, read through estimation; the waste factor stays.
///
/// Every `watch` emits the store as it is now and again after each change,
/// in the user's order: the defaults in Appendix B's order, then what the
/// user added, each new entry after the last. A default the user changed
/// shows in its place and one the user deleted is hidden. Every write
/// answers with what was stored or a [Failure], never a throw; a write with
/// nobody signed in is refused. Update and delete take the entity rather
/// than an id, because a default has no id until it is changed.
abstract class TradeStoresRepository {
  /// The sizes of one store, in the user's order. [system] picks which
  /// sheet-size defaults show, since Appendix B seeds them per unit system;
  /// masonry and footing have one set, and a size the user added shows
  /// under both systems (term 2.16).
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  );

  /// Adds a size after the last one of its store and answers it with its
  /// id and position.
  Future<Either<Failure, StoredSize>> addSize(StoredSize size);

  /// Rewrites the size the pill or detail panel came from: a stored row by
  /// its id, or a default by its seed, which stores it for the first time.
  Future<Either<Failure, StoredSize>> updateSize(StoredSize size);

  /// Removes a size: a stored row by its id, or a default by its seed, which
  /// hides it on every phone.
  Future<Either<Failure, void>> deleteSize(StoredSize size);

  /// The on-centre spacings, in the user's order.
  Stream<List<StoredSpacing>> watchSpacings();

  /// Adds a spacing after the last one and answers it with its id and
  /// position.
  Future<Either<Failure, StoredSpacing>> addSpacing(StoredSpacing spacing);

  /// Rewrites a spacing, a stored row by its id or a default by its seed.
  Future<Either<Failure, StoredSpacing>> updateSpacing(StoredSpacing spacing);

  /// Removes a spacing, a stored row by its id or a default by its seed.
  Future<Either<Failure, void>> deleteSpacing(StoredSpacing spacing);

  /// The fence configuration.
  Stream<FenceConfiguration> watchFence();

  /// Rewrites the fence configuration.
  Future<Either<Failure, FenceConfiguration>> updateFence(
    FenceConfiguration fence,
  );

  /// The waste factor of every [RateUnit], in the enum's order.
  Stream<List<StoredWaste>> watchWaste();

  /// Rewrites the waste factor of one unit.
  Future<Either<Failure, StoredWaste>> updateWaste(StoredWaste waste);

  /// The named densities, in the user's order.
  Stream<List<StoredDensity>> watchDensities();

  /// Adds a material after the last one and answers it with its id and
  /// position ("+ Add material").
  Future<Either<Failure, StoredDensity>> addDensity(StoredDensity density);

  /// Rewrites a density, a stored row by its id or a default by its seed.
  Future<Either<Failure, StoredDensity>> updateDensity(StoredDensity density);

  /// Removes a material, a stored row by its id or a default by its seed.
  Future<Either<Failure, void>> deleteDensity(StoredDensity density);

  /// Ends every stream handed out.
  void dispose();
}
