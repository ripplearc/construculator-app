import 'dart:async';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_recents_data_source.dart';
import 'package:construculator/features/calculator/data/models/recent_row_mapper.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:powersync/powersync.dart';

/// [LocalRecentsDataSource] over PowerSync's local SQLite database.
///
/// The table is `Table.localOnly`, so a write lands in SQLite and stays
/// there: no upload queue is touched and no sync ever clears it. SQL is
/// assembled from `DatabaseConstants`, ids are minted with the SDK's own
/// `uuid`, and every stream handed out is tracked so [dispose] can end it,
/// as `PowerSyncLocalTradeStoresDataSource` does.
///
/// Replacing a drawer deletes its rows and inserts the new list, newest
/// first by position, in one write transaction, so a watcher sees the
/// drawer swap and never a drawer half-written. The one `ORDER BY` is on
/// `position`, an integer column, so it is left to SQLite. A stream handed
/// out after [dispose] answers once and ends.
class PowerSyncLocalRecentsDataSource implements LocalRecentsDataSource {
  final PowerSyncDatabase _database;

  /// Live watches, keyed by the controller feeding the caller and valued by
  /// the query subscription feeding it, so [dispose] can end both ends.
  final Map<MultiStreamController<Object?>, StreamSubscription<Object?>>
  _watchers = {};
  var _disposed = false;

  /// Creates a data source over a PowerSync database.
  PowerSyncLocalRecentsDataSource({required this._database});

  static const _recentsSql =
      'SELECT ${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.drawerColumn}, '
      '${DatabaseConstants.positionColumn}, '
      '${DatabaseConstants.dimensionColumn}, '
      '${DatabaseConstants.magnitudeColumn}, '
      '${DatabaseConstants.unitColumn} '
      'FROM ${DatabaseConstants.calculatorRecentsTable} '
      'WHERE ${DatabaseConstants.drawerColumn} = ? '
      'ORDER BY ${DatabaseConstants.positionColumn}';

  static const _clearDrawerSql =
      'DELETE FROM ${DatabaseConstants.calculatorRecentsTable} '
      'WHERE ${DatabaseConstants.drawerColumn} = ?';

  @override
  Future<List<Quantity>> fetchRecents(String drawer) async {
    final rows = await _database.getAll(_recentsSql, [drawer]);
    return rows.map(RecentRowMapper.quantityFromRow).toList(growable: false);
  }

  @override
  Stream<List<Quantity>> watchRecents(String drawer) => _tracked(
    _database
        .watch(
          _recentsSql,
          parameters: [drawer],
          triggerOnTables: const [DatabaseConstants.calculatorRecentsTable],
        )
        .map(
          (rows) =>
              rows.map(RecentRowMapper.quantityFromRow).toList(growable: false),
        )
        .distinct(_sameList),
  );

  @override
  Future<void> replaceRecents(String drawer, List<Quantity> values) =>
      _database.writeTransaction((transaction) async {
        await transaction.execute(_clearDrawerSql, [drawer]);
        for (final (position, value) in values.indexed) {
          final row = {
            DatabaseConstants.idColumn: uuid.v4(),
            ...RecentRowMapper.toRow(drawer, position, value),
          };
          await transaction.execute(
            'INSERT INTO ${DatabaseConstants.calculatorRecentsTable} '
            '(${row.keys.join(', ')}) '
            'VALUES (${List.filled(row.length, '?').join(', ')})',
            row.values.toList(),
          );
        }
      });

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

  bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
