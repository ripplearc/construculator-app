// coverage:ignore-file
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';

/// Reads and writes the trade stores held on the device.
///
/// Methods throw on failure rather than returning a result type: the
/// repository is the single place that decides what a failure means. Every
/// `watch` emits the rows as they are now and again after each change, in
/// the user's order; an update or delete answers `false` when no row has
/// that id, so the repository can say "not found" without a second read.
abstract class LocalTradeStoresDataSource {
  /// The sizes of one store under one unit system, in position order.
  Future<List<StoredSize>> fetchSizes(
    SizeStore store,
    MeasurementSystem system,
  );

  /// [fetchSizes], re-run after every change to the sizes table.
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  );

  /// Inserts a size with a fresh id and answers it.
  Future<StoredSize> insertSize(StoredSize size);

  /// Rewrites the row with the size's id; `false` when there is none.
  Future<bool> updateSize(StoredSize size);

  /// Deletes the row with that id; `false` when there is none.
  Future<bool> deleteSize(String id);

  /// The spacings, in position order.
  Future<List<StoredSpacing>> fetchSpacings();

  /// [fetchSpacings], re-run after every change to the spacings table.
  Stream<List<StoredSpacing>> watchSpacings();

  /// Inserts a spacing with a fresh id and answers it.
  Future<StoredSpacing> insertSpacing(StoredSpacing spacing);

  /// Rewrites the row with the spacing's id; `false` when there is none.
  Future<bool> updateSpacing(StoredSpacing spacing);

  /// Deletes the row with that id; `false` when there is none.
  Future<bool> deleteSpacing(String id);

  /// The fence configuration, or `null` before it has been seeded.
  Future<FenceConfiguration?> fetchFence();

  /// [fetchFence], re-run after every change to the fence table.
  Stream<FenceConfiguration?> watchFence();

  /// Writes the one fence row, inserting it if there is none.
  Future<void> upsertFence(FenceConfiguration fence);

  /// Every stored rate.
  Future<List<StoredRate>> fetchRates();

  /// [fetchRates], re-run after every change to the rates table.
  Stream<List<StoredRate>> watchRates();

  /// Writes the row of the rate's unit, inserting it if there is none.
  Future<void> upsertRate(StoredRate rate);

  /// The densities, in position order.
  Future<List<StoredDensity>> fetchDensities();

  /// [fetchDensities], re-run after every change to the densities table.
  Stream<List<StoredDensity>> watchDensities();

  /// Inserts a density with a fresh id and answers it.
  Future<StoredDensity> insertDensity(StoredDensity density);

  /// Rewrites the row with the density's id; `false` when there is none.
  Future<bool> updateDensity(StoredDensity density);

  /// Deletes the row with that id; `false` when there is none.
  Future<bool> deleteDensity(String id);

  /// Ends every stream handed out; the database stays open.
  Future<void> dispose();
}
