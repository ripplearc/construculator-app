import 'dart:async';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// [TradeStoresRepository] over the local store: turns what the data source
/// throws into a [CalculatorFailure], says "not found" where the source
/// answered `false`, and seeds Appendix B into any store that is empty.
///
/// The watches are the data source's own streams: the source tracks and
/// ends them, so [dispose] delegates to it and only logs a source that
/// fails to close. A row the source could not find is thrown as a private
/// not-found into the guard, so every write answers through one path.
class TradeStoresRepositoryImpl implements TradeStoresRepository {
  static final _logger = AppLogger().tag('TradeStoresRepositoryImpl');

  final LocalTradeStoresDataSource _dataSource;

  /// Creates a repository over a local data source.
  TradeStoresRepositoryImpl({required this._dataSource});

  @override
  Future<Either<Failure, void>> seedDefaults() => _guard(() async {
    for (final store in SizeStore.values) {
      for (final system in MeasurementSystem.values) {
        if ((await _dataSource.fetchSizes(store, system)).isEmpty) {
          for (final size in TradeStoreSeeds.sizes.where(
            (seed) => seed.store == store && seed.system == system,
          )) {
            await _dataSource.insertSize(size);
          }
        }
      }
    }
    if ((await _dataSource.fetchSpacings()).isEmpty) {
      for (final spacing in TradeStoreSeeds.spacings) {
        await _dataSource.insertSpacing(spacing);
      }
    }
    if (await _dataSource.fetchFence() == null) {
      await _dataSource.upsertFence(TradeStoreSeeds.fence);
    }
    if ((await _dataSource.fetchRates()).isEmpty) {
      for (final rate in TradeStoreSeeds.rates) {
        await _dataSource.upsertRate(rate);
      }
    }
    if ((await _dataSource.fetchDensities()).isEmpty) {
      for (final density in TradeStoreSeeds.densities) {
        await _dataSource.insertDensity(density);
      }
    }
  }, 'seeding the trade stores');

  @override
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  ) => _dataSource.watchSizes(store, system);

  @override
  Future<Either<Failure, StoredSize>> addSize(StoredSize size) =>
      _guard(() => _dataSource.insertSize(size), 'adding a size');

  @override
  Future<Either<Failure, StoredSize>> updateSize(StoredSize size) => _guard(
    () async => _found(await _dataSource.updateSize(size), size),
    'updating a size',
  );

  @override
  Future<Either<Failure, void>> deleteSize(String id) => _guard(
    () async => _found(await _dataSource.deleteSize(id), null),
    'deleting a size',
  );

  @override
  Stream<List<StoredSpacing>> watchSpacings() => _dataSource.watchSpacings();

  @override
  Future<Either<Failure, StoredSpacing>> addSpacing(StoredSpacing spacing) =>
      _guard(() => _dataSource.insertSpacing(spacing), 'adding a spacing');

  @override
  Future<Either<Failure, StoredSpacing>> updateSpacing(StoredSpacing spacing) =>
      _guard(
        () async => _found(await _dataSource.updateSpacing(spacing), spacing),
        'updating a spacing',
      );

  @override
  Future<Either<Failure, void>> deleteSpacing(String id) => _guard(
    () async => _found(await _dataSource.deleteSpacing(id), null),
    'deleting a spacing',
  );

  @override
  Stream<FenceConfiguration> watchFence() =>
      _dataSource.watchFence().map((fence) => fence ?? TradeStoreSeeds.fence);

  @override
  Future<Either<Failure, FenceConfiguration>> updateFence(
    FenceConfiguration fence,
  ) => _guard(() async {
    await _dataSource.upsertFence(fence);
    return fence;
  }, 'updating the fence');

  @override
  Stream<List<StoredRate>> watchRates() => _dataSource.watchRates();

  @override
  Future<Either<Failure, StoredRate>> updateRate(StoredRate rate) =>
      _guard(() async {
        await _dataSource.upsertRate(rate);
        return rate;
      }, 'updating a rate');

  @override
  Stream<List<StoredDensity>> watchDensities() => _dataSource.watchDensities();

  @override
  Future<Either<Failure, StoredDensity>> addDensity(StoredDensity density) =>
      _guard(() => _dataSource.insertDensity(density), 'adding a material');

  @override
  Future<Either<Failure, StoredDensity>> updateDensity(StoredDensity density) =>
      _guard(
        () async => _found(await _dataSource.updateDensity(density), density),
        'updating a material',
      );

  @override
  Future<Either<Failure, void>> deleteDensity(String id) => _guard(
    () async => _found(await _dataSource.deleteDensity(id), null),
    'deleting a material',
  );

  @override
  void dispose() => unawaited(
    _dataSource.dispose().catchError((Object error, StackTrace stackTrace) {
      _logger.warning('Failed to dispose the trade stores data source: $error');
    }),
  );

  T _found<T>(bool found, T value) {
    if (!found) throw const _NotFound();
    return value;
  }

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() operation,
    String what,
  ) async {
    try {
      return Right(await operation());
    } on _NotFound {
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.notFound),
      );
    } catch (error) {
      _logger.error('Error $what: $error');
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
    }
  }
}

class _NotFound implements Exception {
  const _NotFound();
}
