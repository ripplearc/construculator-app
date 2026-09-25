import 'dart:async';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/trade_store_row_mapper.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:powersync/powersync.dart';

/// [LocalTradeStoresDataSource] over PowerSync's local SQLite database.
///
/// The five tables are `Table.localOnly`, so a write lands in SQLite and
/// stays there: no upload queue is touched and no sync ever clears them.
/// Everything else follows `PowerSyncLocalConsentDataSource`: SQL is
/// assembled from `DatabaseConstants`, ids are minted with the SDK's own
/// `uuid`, and every stream handed out is tracked so [dispose] can end it.
///
/// The one `ORDER BY` is on `position`, an integer column, so it is left to
/// SQLite; nothing here sorts text.
///
/// An insert mints the row's id here, as the consent store does: the row is
/// local, so nothing else will ever assign one. An update or delete checks
/// that the row exists and answers `false` rather than writing nothing, so
/// the repository can say "not found". A stream handed out after [dispose]
/// answers once and ends, so a late subscriber is never left waiting; one
/// handed out before is tracked and ended by [dispose].
class PowerSyncLocalTradeStoresDataSource
    implements LocalTradeStoresDataSource {
  final PowerSyncDatabase _database;

  /// Live watches, keyed by the controller feeding the caller and valued by
  /// the query subscription feeding it, so [dispose] can end both ends.
  final Map<MultiStreamController<Object?>, StreamSubscription<Object?>>
  _watchers = {};
  var _disposed = false;

  /// Creates a data source over a PowerSync database.
  PowerSyncLocalTradeStoresDataSource({required this._database});

  static const _sizeColumns =
      '${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.storeColumn}, '
      '${DatabaseConstants.systemColumn}, '
      '${DatabaseConstants.widthTicksColumn}, '
      '${DatabaseConstants.heightTicksColumn}, '
      '${DatabaseConstants.positionColumn}';

  static const _sizesSql =
      'SELECT $_sizeColumns FROM ${DatabaseConstants.calculatorSizesTable} '
      'WHERE ${DatabaseConstants.storeColumn} = ? '
      'AND ${DatabaseConstants.systemColumn} = ? '
      'ORDER BY ${DatabaseConstants.positionColumn}';

  static const _spacingsSql =
      'SELECT ${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.ticksColumn}, '
      '${DatabaseConstants.positionColumn} '
      'FROM ${DatabaseConstants.calculatorSpacingsTable} '
      'ORDER BY ${DatabaseConstants.positionColumn}';

  static const _fenceSql =
      'SELECT ${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.onCentreTicksColumn}, '
      '${DatabaseConstants.railsPerSectionColumn} '
      'FROM ${DatabaseConstants.calculatorFenceTable}';

  static const _ratesSql =
      'SELECT ${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.unitColumn}, '
      '${DatabaseConstants.rateColumn}, '
      '${DatabaseConstants.wastePercentColumn} '
      'FROM ${DatabaseConstants.calculatorRatesTable}';

  static const _densitiesSql =
      'SELECT ${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.nameColumn}, '
      '${DatabaseConstants.poundsPerCubicYardColumn}, '
      '${DatabaseConstants.positionColumn} '
      'FROM ${DatabaseConstants.calculatorDensitiesTable} '
      'ORDER BY ${DatabaseConstants.positionColumn}';

  @override
  Future<List<StoredSize>> fetchSizes(
    SizeStore store,
    MeasurementSystem system,
  ) => _all(_sizesSql, [
    store.name,
    system.name,
  ], TradeStoreRowMapper.sizeFromRow);

  @override
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  ) => _watchAll(
    _sizesSql,
    [store.name, system.name],
    DatabaseConstants.calculatorSizesTable,
    TradeStoreRowMapper.sizeFromRow,
  );

  @override
  Future<StoredSize> insertSize(StoredSize size) async => size.copyWith(
    id: await _insert(
      DatabaseConstants.calculatorSizesTable,
      TradeStoreRowMapper.sizeToRow(size),
    ),
  );

  @override
  Future<bool> updateSize(StoredSize size) => _update(
    DatabaseConstants.calculatorSizesTable,
    size.id,
    TradeStoreRowMapper.sizeToRow(size),
  );

  @override
  Future<bool> deleteSize(String id) =>
      _delete(DatabaseConstants.calculatorSizesTable, id);

  @override
  Future<List<StoredSpacing>> fetchSpacings() =>
      _all(_spacingsSql, const [], TradeStoreRowMapper.spacingFromRow);

  @override
  Stream<List<StoredSpacing>> watchSpacings() => _watchAll(
    _spacingsSql,
    const [],
    DatabaseConstants.calculatorSpacingsTable,
    TradeStoreRowMapper.spacingFromRow,
  );

  @override
  Future<StoredSpacing> insertSpacing(StoredSpacing spacing) async =>
      spacing.copyWith(
        id: await _insert(
          DatabaseConstants.calculatorSpacingsTable,
          TradeStoreRowMapper.spacingToRow(spacing),
        ),
      );

  @override
  Future<bool> updateSpacing(StoredSpacing spacing) => _update(
    DatabaseConstants.calculatorSpacingsTable,
    spacing.id,
    TradeStoreRowMapper.spacingToRow(spacing),
  );

  @override
  Future<bool> deleteSpacing(String id) =>
      _delete(DatabaseConstants.calculatorSpacingsTable, id);

  @override
  Future<FenceConfiguration?> fetchFence() async => _single(
    await _all(_fenceSql, const [], TradeStoreRowMapper.fenceFromRow),
  );

  @override
  Stream<FenceConfiguration?> watchFence() => _tracked(
    _database
        .watch(
          _fenceSql,
          triggerOnTables: const [DatabaseConstants.calculatorFenceTable],
        )
        .map((rows) => _single(rows.map(TradeStoreRowMapper.fenceFromRow)))
        .distinct(),
  );

  @override
  Future<void> upsertFence(FenceConfiguration fence) async {
    final ids = await _database.getAll(
      'SELECT ${DatabaseConstants.idColumn} '
      'FROM ${DatabaseConstants.calculatorFenceTable}',
    );
    await _upsert(
      DatabaseConstants.calculatorFenceTable,
      _firstId(ids),
      TradeStoreRowMapper.fenceToRow(fence),
    );
  }

  @override
  Future<List<StoredRate>> fetchRates() =>
      _all(_ratesSql, const [], TradeStoreRowMapper.rateFromRow);

  @override
  Stream<List<StoredRate>> watchRates() => _watchAll(
    _ratesSql,
    const [],
    DatabaseConstants.calculatorRatesTable,
    TradeStoreRowMapper.rateFromRow,
  );

  @override
  Future<void> upsertRate(StoredRate rate) async {
    final ids = await _database.getAll(
      'SELECT ${DatabaseConstants.idColumn} '
      'FROM ${DatabaseConstants.calculatorRatesTable} '
      'WHERE ${DatabaseConstants.unitColumn} = ?',
      [rate.unit.name],
    );
    await _upsert(
      DatabaseConstants.calculatorRatesTable,
      _firstId(ids),
      TradeStoreRowMapper.rateToRow(rate),
    );
  }

  @override
  Future<List<StoredDensity>> fetchDensities() =>
      _all(_densitiesSql, const [], TradeStoreRowMapper.densityFromRow);

  @override
  Stream<List<StoredDensity>> watchDensities() => _watchAll(
    _densitiesSql,
    const [],
    DatabaseConstants.calculatorDensitiesTable,
    TradeStoreRowMapper.densityFromRow,
  );

  @override
  Future<StoredDensity> insertDensity(StoredDensity density) async =>
      density.copyWith(
        id: await _insert(
          DatabaseConstants.calculatorDensitiesTable,
          TradeStoreRowMapper.densityToRow(density),
        ),
      );

  @override
  Future<bool> updateDensity(StoredDensity density) => _update(
    DatabaseConstants.calculatorDensitiesTable,
    density.id,
    TradeStoreRowMapper.densityToRow(density),
  );

  @override
  Future<bool> deleteDensity(String id) =>
      _delete(DatabaseConstants.calculatorDensitiesTable, id);

  @override
  Future<void> dispose() async {
    _disposed = true;
    final open = _watchers.entries.toList();
    _watchers.clear();
    await Future.wait(
      open.map((watcher) async {
        await watcher.value.cancel();
        await watcher.key.close();
      }),
    );
  }

  Future<List<T>> _all<T>(
    String sql,
    List<Object?> parameters,
    T Function(Map<String, Object?>) fromRow,
  ) async {
    final rows = await _database.getAll(sql, parameters);
    return rows.map(fromRow).toList(growable: false);
  }

  Stream<List<T>> _watchAll<T>(
    String sql,
    List<Object?> parameters,
    String table,
    T Function(Map<String, Object?>) fromRow,
  ) => _tracked(
    _database
        .watch(sql, parameters: parameters, triggerOnTables: [table])
        .map((rows) => rows.map(fromRow).toList(growable: false))
        .distinct(_sameList),
  );

  Future<String> _insert(String table, Map<String, Object> row) async {
    final id = uuid.v4();
    final values = {DatabaseConstants.idColumn: id, ...row};
    await _database.execute(
      'INSERT INTO $table (${values.keys.join(', ')}) '
      'VALUES (${List.filled(values.length, '?').join(', ')})',
      values.values.toList(),
    );
    return id;
  }

  Future<bool> _update(
    String table,
    String? id,
    Map<String, Object> row,
  ) async {
    if (id == null || !await _exists(table, id)) return false;
    await _database.execute(
      'UPDATE $table SET ${row.keys.map((column) => '$column = ?').join(', ')} '
      'WHERE ${DatabaseConstants.idColumn} = ?',
      [...row.values, id],
    );
    return true;
  }

  Future<bool> _delete(String table, String id) async {
    if (!await _exists(table, id)) return false;
    await _database.execute(
      'DELETE FROM $table WHERE ${DatabaseConstants.idColumn} = ?',
      [id],
    );
    return true;
  }

  Future<void> _upsert(
    String table,
    String? id,
    Map<String, Object> row,
  ) async {
    if (id == null) {
      await _insert(table, row);
    } else {
      await _update(table, id, row);
    }
  }

  Future<bool> _exists(String table, String id) async {
    final rows = await _database.getAll(
      'SELECT ${DatabaseConstants.idColumn} FROM $table '
      'WHERE ${DatabaseConstants.idColumn} = ?',
      [id],
    );
    return rows.isNotEmpty;
  }

  String? _firstId(Iterable<Map<String, Object?>> rows) {
    for (final row in rows) {
      if (row[DatabaseConstants.idColumn] case final String id) return id;
    }
    return null;
  }

  T? _single<T>(Iterable<T> items) => items.isEmpty ? null : items.first;

  bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Stream<T> _tracked<T>(Stream<T> source) => Stream<T>.multi((controller) {
    final disposed = _disposed;
    final subscription = (disposed ? source.take(1) : source).listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    if (disposed) {
      controller.onCancel = subscription.cancel;
      return;
    }
    _watchers[controller] = subscription;
    controller.onCancel = () {
      _watchers.remove(controller);
      return subscription.cancel();
    };
  });
}
