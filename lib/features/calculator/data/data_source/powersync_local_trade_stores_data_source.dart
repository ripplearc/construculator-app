import 'dart:async';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite_async.dart';

/// [LocalTradeStoresDataSource] over PowerSync's local SQLite database.
///
/// `user_calculator_stores` is a synced table: a write lands in SQLite at
/// once, PowerSync queues it for upload, and the stream brings the other
/// phones' rows in. Everything else follows `PowerSyncLocalConsentDataSource`:
/// SQL is assembled from `DatabaseConstants`, an added entry's id is minted
/// with the SDK's own `uuid`, and every stream handed out is tracked so
/// [dispose] can end it. Nothing is ordered in SQL: the repository orders
/// entries by the position inside `values`.
///
/// A default's row has the one id every phone derives from the user, the
/// store and the seed (a name-based UUID over the URL namespace), so two
/// phones that change one default while offline write the same row, and the
/// server merges the later upload into it instead of refusing it as a second
/// live row of that default.
///
/// Every write that first looks a row up runs the lookup and the write in
/// one write transaction, so two writes that race cannot both see "no row"
/// and both insert; the one that gets the lock second finds the first's
/// row. A stream handed out after [dispose] answers once and ends, so a late
/// subscriber is never left waiting; one handed out before is tracked and
/// ended by [dispose].
class PowerSyncLocalTradeStoresDataSource
    implements LocalTradeStoresDataSource {
  final PowerSyncDatabase _database;

  final Map<MultiStreamController<Object?>, StreamSubscription<Object?>>
  _watchSubscriptionsByController = {};
  var _disposed = false;

  /// Creates a data source over a PowerSync database.
  PowerSyncLocalTradeStoresDataSource({required this._database});

  static const _rfc9562UrlNamespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  static const _rowsSql =
      'SELECT ${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.userIdColumn}, '
      '${DatabaseConstants.storeKindColumn}, '
      '"${DatabaseConstants.valuesColumn}", '
      '${DatabaseConstants.unitSystemColumn}, '
      '${DatabaseConstants.createdAtColumn}, '
      '${DatabaseConstants.updatedAtColumn}, '
      '${DatabaseConstants.deletedAtColumn} '
      'FROM ${DatabaseConstants.userCalculatorStoresTable} '
      'WHERE ${DatabaseConstants.userIdColumn} = ? '
      'AND ${DatabaseConstants.storeKindColumn} = ?';

  static const _idSql =
      'SELECT ${DatabaseConstants.idColumn} '
      'FROM ${DatabaseConstants.userCalculatorStoresTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _rewriteSql =
      'UPDATE ${DatabaseConstants.userCalculatorStoresTable} '
      'SET "${DatabaseConstants.valuesColumn}" = ?, '
      '${DatabaseConstants.unitSystemColumn} = ?, '
      '${DatabaseConstants.updatedAtColumn} = ?, '
      '${DatabaseConstants.deletedAtColumn} = ? '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _softDeleteSql =
      'UPDATE ${DatabaseConstants.userCalculatorStoresTable} '
      'SET ${DatabaseConstants.deletedAtColumn} = ?, '
      '${DatabaseConstants.updatedAtColumn} = ? '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  @override
  Future<List<CalculatorStoreRowDto>> fetchRows(
    String userId,
    CalculatorStoreKind kind,
  ) async => _rows(await _database.getAll(_rowsSql, [userId, kind.wire]));

  @override
  Stream<List<CalculatorStoreRowDto>> watchRows(
    String userId,
    CalculatorStoreKind kind,
  ) => _tracked(
    _database
        .watch(
          _rowsSql,
          parameters: [userId, kind.wire],
          triggerOnTables: const [DatabaseConstants.userCalculatorStoresTable],
        )
        .map(_rows)
        .distinct(_sameList),
  );

  @override
  Future<CalculatorStoreRowDto> insertRow(CalculatorStoreRowDto row) =>
      _database.writeTransaction((transaction) => _insert(transaction, row));

  @override
  Future<bool> updateRow(CalculatorStoreRowDto row) {
    final id = row.id;
    if (id == null) return Future.value(false);
    return _database.writeTransaction((transaction) async {
      if (!await _exists(transaction, id)) return false;
      await _rewrite(transaction, id, row);
      return true;
    });
  }

  @override
  Future<bool> softDeleteRow(String id, DateTime deletedAt) =>
      _database.writeTransaction((transaction) async {
        if (!await _exists(transaction, id)) return false;
        final stamp = deletedAt.toUtc().toIso8601String();
        await transaction.execute(_softDeleteSql, [stamp, stamp, id]);
        return true;
      });

  @override
  Future<CalculatorStoreRowDto> writeSeedRow(CalculatorStoreRowDto row) async {
    final seed = row.seed;
    if (seed == null) {
      throw ArgumentError.value(row, 'row', 'A default names its seed');
    }
    return _database.writeTransaction((transaction) async {
      final existing = _rows(
        await transaction.getAll(_rowsSql, [row.userId, row.storeKind.wire]),
      ).where((candidate) => candidate.seed == seed).firstOrNull;
      final id = existing?.id;
      if (id == null) {
        return _insert(transaction, row, id: _defaultRowId(row, seed));
      }
      await _rewrite(transaction, id, row);
      return row.copyWith(id: id);
    });
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    final open = _watchSubscriptionsByController.entries.toList();
    _watchSubscriptionsByController.clear();
    await Future.wait(
      open.map((watcher) async {
        await watcher.value.cancel();
        await watcher.key.close();
      }),
    );
  }

  Future<CalculatorStoreRowDto> _insert(
    SqliteWriteContext transaction,
    CalculatorStoreRowDto row, {
    String? id,
  }) async {
    final rowId = id ?? uuid.v4();
    final columns = {DatabaseConstants.idColumn: rowId, ...row.toColumns()};
    await transaction.execute(
      'INSERT INTO ${DatabaseConstants.userCalculatorStoresTable} '
      '(${columns.keys.map(_quoted).join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')})',
      columns.values.toList(),
    );
    return row.copyWith(id: rowId);
  }

  String _defaultRowId(CalculatorStoreRowDto row, String seed) => uuid.v5(
    _rfc9562UrlNamespace,
    '${DatabaseConstants.userCalculatorStoresTable}/${row.userId}/'
    '${row.storeKind.wire}/$seed',
  );

  Future<void> _rewrite(
    SqliteWriteContext transaction,
    String id,
    CalculatorStoreRowDto row,
  ) {
    final columns = row.toColumns();
    return transaction.execute(_rewriteSql, [
      columns[DatabaseConstants.valuesColumn],
      columns[DatabaseConstants.unitSystemColumn],
      columns[DatabaseConstants.updatedAtColumn],
      columns[DatabaseConstants.deletedAtColumn],
      id,
    ]);
  }

  Future<bool> _exists(SqliteWriteContext transaction, String id) async =>
      (await transaction.getAll(_idSql, [id])).isNotEmpty;

  String _quoted(String column) =>
      column == DatabaseConstants.valuesColumn ? '"$column"' : column;

  List<CalculatorStoreRowDto> _rows(Iterable<Map<String, Object?>> rows) =>
      rows.map(CalculatorStoreRowDto.fromRow).toList(growable: false);

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
    _watchSubscriptionsByController[controller] = subscription;
    controller.onCancel = () {
      _watchSubscriptionsByController.remove(controller);
      return subscription.cancel();
    };
  });
}
