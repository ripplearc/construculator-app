import 'dart:async';
import 'dart:math';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';
import 'package:construculator/features/calculator/data/models/trade_store_row_mapper.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// [TradeStoresRepository] over the synced `user_calculator_stores` rows:
/// lays Appendix B's defaults over the signed-in user's rows on every read,
/// writes a change as the one row of the entry it belongs to, and turns what
/// the data source throws into a [CalculatorFailure].
///
/// ## The defaults are laid over, never stored
///
/// A store's rows are the user's additions and changes. On every emission
/// the defaults are walked in Appendix B's order: a default with no row
/// shows as shipped, one with a live row shows as that row, and one with a
/// soft-deleted row is hidden. The user's own entries, the live rows that
/// name no seed, follow. The entries are then put in position order, a
/// default's position being its place in Appendix B and an added entry
/// taking the position after the last, so an entry keeps its place when it
/// is edited. A row whose seed is not among the defaults shown (a changed
/// metric sheet under Imperial, say) is left out. Two live rows for one
/// default can exist when two phones changed it while offline; the newest
/// write stands, which is the server's rule too.
///
/// ## Writes
///
/// An entry with an id is rewritten or soft-deleted by that id. A default
/// has no id until it is changed, so it is written by its seed: the data
/// source rewrites the row that names the seed or inserts it, and a delete
/// writes that row soft-deleted, which hides the default on every phone.
/// An entry with neither is not in the store. The signed-in user's internal
/// id is read from the JWT at every call, the claim the sync stream and the
/// RLS policies filter on; with nobody signed in a watch shows the defaults
/// alone and a write is refused, a guard rather than a state the UI shows,
/// since the calculator sits behind sign-in.
class TradeStoresRepositoryImpl implements TradeStoresRepository {
  static final _logger = AppLogger().tag('TradeStoresRepositoryImpl');

  final LocalTradeStoresDataSource _dataSource;
  final SupabaseWrapper _supabaseWrapper;
  final Clock _clock;

  /// Creates a repository over the local rows, reading who is signed in
  /// from [SupabaseWrapper] and stamping writes from [Clock].
  TradeStoresRepositoryImpl({
    required this._dataSource,
    required this._supabaseWrapper,
    required this._clock,
  });

  @override
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  ) => _watch(_sizes(store, TradeStoreSeeds.sizes(store, system)));

  @override
  Future<Either<Failure, StoredSize>> addSize(StoredSize size) => _add(
    _sizes(size.store, [
      for (final system in MeasurementSystem.values)
        ...TradeStoreSeeds.sizes(size.store, system),
    ]),
    (position) => StoredSize(
      store: size.store,
      width: size.width,
      height: size.height,
      position: position,
    ),
    TradeStoreRowMapper.sizeToRow,
    'adding a size',
  );

  @override
  Future<Either<Failure, StoredSize>> updateSize(StoredSize size) => _update(
    size,
    id: size.id,
    seed: size.seed,
    toRow: TradeStoreRowMapper.sizeToRow,
    fromRow: TradeStoreRowMapper.sizeFromRow,
    what: 'updating a size',
  );

  @override
  Future<Either<Failure, void>> deleteSize(StoredSize size) => _delete(
    size,
    id: size.id,
    seed: size.seed,
    toRow: TradeStoreRowMapper.sizeToRow,
    what: 'deleting a size',
  );

  @override
  Stream<List<StoredSpacing>> watchSpacings() => _watch(_spacings);

  @override
  Future<Either<Failure, StoredSpacing>> addSpacing(StoredSpacing spacing) =>
      _add(
        _spacings,
        (position) =>
            StoredSpacing(spacing: spacing.spacing, position: position),
        TradeStoreRowMapper.spacingToRow,
        'adding a spacing',
      );

  @override
  Future<Either<Failure, StoredSpacing>> updateSpacing(StoredSpacing spacing) =>
      _update(
        spacing,
        id: spacing.id,
        seed: spacing.seed,
        toRow: TradeStoreRowMapper.spacingToRow,
        fromRow: TradeStoreRowMapper.spacingFromRow,
        what: 'updating a spacing',
      );

  @override
  Future<Either<Failure, void>> deleteSpacing(StoredSpacing spacing) => _delete(
    spacing,
    id: spacing.id,
    seed: spacing.seed,
    toRow: TradeStoreRowMapper.spacingToRow,
    what: 'deleting a spacing',
  );

  @override
  Stream<FenceConfiguration> watchFence() => _watch(
    _fence,
  ).map((fences) => fences.isEmpty ? TradeStoreSeeds.fence : fences.first);

  @override
  Future<Either<Failure, FenceConfiguration>> updateFence(
    FenceConfiguration fence,
  ) => _update(
    fence,
    seed: TradeStoreRowMapper.fenceSeed,
    toRow: TradeStoreRowMapper.fenceToRow,
    fromRow: TradeStoreRowMapper.fenceFromRow,
    what: 'updating the fence',
  );

  @override
  Stream<List<StoredWaste>> watchWaste() => _watch(_waste);

  @override
  Future<Either<Failure, StoredWaste>> updateWaste(StoredWaste waste) =>
      _update(
        waste,
        seed: waste.unit.name,
        toRow: TradeStoreRowMapper.wasteToRow,
        fromRow: TradeStoreRowMapper.wasteFromRow,
        what: 'updating a waste factor',
      );

  @override
  Stream<List<StoredDensity>> watchDensities() => _watch(_densities);

  @override
  Future<Either<Failure, StoredDensity>> addDensity(StoredDensity density) =>
      _add(
        _densities,
        (position) => StoredDensity(
          name: density.name,
          poundsPerCubicYard: density.poundsPerCubicYard,
          position: position,
        ),
        TradeStoreRowMapper.densityToRow,
        'adding a material',
      );

  @override
  Future<Either<Failure, StoredDensity>> updateDensity(StoredDensity density) =>
      _update(
        density,
        id: density.id,
        seed: density.seed,
        toRow: TradeStoreRowMapper.densityToRow,
        fromRow: TradeStoreRowMapper.densityFromRow,
        what: 'updating a material',
      );

  @override
  Future<Either<Failure, void>> deleteDensity(StoredDensity density) => _delete(
    density,
    id: density.id,
    seed: density.seed,
    toRow: TradeStoreRowMapper.densityToRow,
    what: 'deleting a material',
  );

  @override
  void dispose() => unawaited(
    _dataSource.dispose().catchError((Object error, StackTrace stackTrace) {
      _logger.warning(
        'Failed to dispose the trade stores data source',
        error,
        stackTrace,
      );
    }),
  );

  _Store<StoredSize> _sizes(SizeStore store, List<StoredSize> seeds) => _Store(
    kind: TradeStoreRowMapper.kindOf(store),
    seeds: seeds,
    fromRow: TradeStoreRowMapper.sizeFromRow,
    seedOf: (size) => size.seed,
    positionOf: (size) => size.position,
  );

  _Store<StoredSpacing> get _spacings => _Store(
    kind: CalculatorStoreKind.onCentreSpacing,
    seeds: TradeStoreSeeds.spacings,
    fromRow: TradeStoreRowMapper.spacingFromRow,
    seedOf: (spacing) => spacing.seed,
    positionOf: (spacing) => spacing.position,
  );

  _Store<FenceConfiguration> get _fence => _Store(
    kind: CalculatorStoreKind.fenceConfig,
    seeds: [TradeStoreSeeds.fence],
    fromRow: TradeStoreRowMapper.fenceFromRow,
    seedOf: (_) => TradeStoreRowMapper.fenceSeed,
    positionOf: (_) => 0,
    acceptsAdded: false,
  );

  _Store<StoredWaste> get _waste => _Store(
    kind: CalculatorStoreKind.waste,
    seeds: TradeStoreSeeds.waste,
    fromRow: TradeStoreRowMapper.wasteFromRow,
    seedOf: (waste) => waste.unit.name,
    positionOf: (waste) => waste.unit.index,
    acceptsAdded: false,
  );

  _Store<StoredDensity> get _densities => _Store(
    kind: CalculatorStoreKind.density,
    seeds: TradeStoreSeeds.densities,
    fromRow: TradeStoreRowMapper.densityFromRow,
    seedOf: (density) => density.seed,
    positionOf: (density) => density.position,
  );

  Stream<List<T>> _watch<T>(_Store<T> store) {
    final userId = _supabaseWrapper.getInternalUserId();
    if (userId == null) return Stream.value(store.seeds);
    return _dataSource
        .watchRows(userId, store.kind)
        .map((rows) => _layOver(store, rows));
  }

  List<T> _layOver<T>(_Store<T> store, List<CalculatorStoreRowDto> rows) {
    final rowBySeed = <String, CalculatorStoreRowDto>{};
    final added = <CalculatorStoreRowDto>[];
    for (final row in rows) {
      final seed = row.seed;
      if (seed == null) {
        if (!row.isDeleted && store.acceptsAdded) added.add(row);
        continue;
      }
      final current = rowBySeed[seed];
      if (current == null || row.updatedAt.isAfter(current.updatedAt)) {
        rowBySeed[seed] = row;
      }
    }
    final entries = <T>[
      for (final seed in store.seeds)
        if (rowBySeed[store.seedOf(seed)] case final row?) ...[
          if (!row.isDeleted) store.fromRow(row),
        ] else
          seed,
      for (final row in added) store.fromRow(row),
    ];
    return _inPositionOrder(entries, store.positionOf);
  }

  // A stable sort: two entries at one position keep their order, the
  // defaults before what the user added.
  List<T> _inPositionOrder<T>(List<T> entries, int Function(T) positionOf) {
    final indexed = entries.indexed.toList()
      ..sort((a, b) {
        final byPosition = positionOf(a.$2).compareTo(positionOf(b.$2));
        return byPosition != 0 ? byPosition : a.$1.compareTo(b.$1);
      });
    return [for (final (_, entry) in indexed) entry];
  }

  Future<Either<Failure, T>> _add<T>(
    _Store<T> store,
    T Function(int position) entryAt,
    _ToRow<T> toRow,
    String what,
  ) => _guard(() async {
    final userId = _signedInUserId();
    final shown = _layOver(
      store,
      await _dataSource.fetchRows(userId, store.kind),
    );
    final last = shown.map(store.positionOf).fold(-1, max);
    final row = await _dataSource.insertRow(
      toRow(entryAt(last + 1), userId: userId, now: _clock.now()),
    );
    return store.fromRow(row);
  }, what);

  Future<Either<Failure, T>> _update<T>(
    T entity, {
    String? id,
    required String? seed,
    required _ToRow<T> toRow,
    required T Function(CalculatorStoreRowDto) fromRow,
    required String what,
  }) => _guard(() async {
    final userId = _signedInUserId();
    final row = toRow(entity, userId: userId, now: _clock.now());
    if (id != null) {
      if (!await _dataSource.updateRow(row)) throw const _NotFound();
      return entity;
    }
    if (seed == null) throw const _NotFound();
    return fromRow(await _dataSource.writeSeedRow(row));
  }, what);

  Future<Either<Failure, void>> _delete<T>(
    T entity, {
    required String? id,
    required String? seed,
    required _ToRow<T> toRow,
    required String what,
  }) => _guard(() async {
    final userId = _signedInUserId();
    final now = _clock.now();
    if (id != null) {
      if (!await _dataSource.softDeleteRow(id, now)) throw const _NotFound();
      return;
    }
    if (seed == null) throw const _NotFound();
    await _dataSource.writeSeedRow(
      toRow(entity, userId: userId, now: now).copyWith(deletedAt: now),
    );
  }, what);

  String _signedInUserId() =>
      _supabaseWrapper.getInternalUserId() ?? (throw const _NotSignedIn());

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() operation,
    String what,
  ) async {
    try {
      return Right(await operation());
    } on _NotSignedIn {
      _logger.warning('Refused $what: nobody is signed in');
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.notSignedIn),
      );
    } on _NotFound {
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.notFound),
      );
    } catch (error, stackTrace) {
      _logger.error('Error $what', error, stackTrace);
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
    }
  }
}

typedef _ToRow<T> =
    CalculatorStoreRowDto Function(
      T entity, {
      required String userId,
      required DateTime now,
    });

// One store as the repository reads it: its rows' kind, Appendix B's
// defaults with how each names its seed and its position, and whether the
// user can add entries of their own to it.
class _Store<T> {
  final CalculatorStoreKind kind;
  final List<T> seeds;
  final T Function(CalculatorStoreRowDto) fromRow;
  final String? Function(T) seedOf;
  final int Function(T) positionOf;
  final bool acceptsAdded;

  const _Store({
    required this.kind,
    required this.seeds,
    required this.fromRow,
    required this.seedOf,
    required this.positionOf,
    this.acceptsAdded = true,
  });
}

class _NotFound implements Exception {
  const _NotFound();
}

class _NotSignedIn implements Exception {
  const _NotSignedIn();
}
