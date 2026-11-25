import 'dart:async';

import 'package:construculator/libraries/calculation/data/data_source/interfaces/local_calculation_session_data_source.dart';
import 'package:construculator/libraries/calculation/data/models/calculation_session_dto.dart';
import 'package:construculator/libraries/calculation/data/models/calculation_tape_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite_async.dart';

/// [LocalCalculationSessionDataSource] over PowerSync's local SQLite
/// database.
///
/// Both tables are `Table.localOnly`, so a write lands in SQLite and stays
/// there: no upload queue is touched and no sync ever clears it. A session
/// and its tape are written in one write transaction, so a watcher sees
/// the session arrive whole, and the same transaction prunes the user's
/// oldest sessions past [keptSessions] (Full Design Doc, "On the device":
/// the last fifty are kept). Every stream handed out is tracked so
/// [dispose] can end it, as `PowerSyncLocalRecentsDataSource` does; a
/// stream handed out after [dispose] answers once and ends.
///
/// A search is a local `LIKE` over the title and the result text, with
/// `%` and `_` in the query escaped so they match themselves.
class PowerSyncLocalCalculationSessionDataSource
    implements LocalCalculationSessionDataSource {
  /// How many of a user's sessions the phone keeps; the oldest past this
  /// number are removed when a new one is banked.
  static const int keptSessions = 50;

  final PowerSyncDatabase _database;

  /// Live watches, keyed by the controller feeding the caller and valued by
  /// the query subscription feeding it, so [dispose] can end both ends.
  final Map<MultiStreamController<Object?>, StreamSubscription<Object?>>
  _watchers = {};
  var _disposed = false;

  /// Creates a data source over a PowerSync database.
  PowerSyncLocalCalculationSessionDataSource({required this._database});

  static const _sessionColumns =
      '${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.creatorUserIdColumn}, '
      '${DatabaseConstants.titleColumn}, '
      '${DatabaseConstants.resultTextColumn}, '
      '${DatabaseConstants.resultValueColumn}, '
      '${DatabaseConstants.resultDimensionColumn}, '
      '${DatabaseConstants.resultUnitColumn}, '
      '${DatabaseConstants.createdAtColumn}, '
      '${DatabaseConstants.updatedAtColumn}, '
      '${DatabaseConstants.lastCalculationAtColumn}';

  static const _newestFirst =
      'ORDER BY ${DatabaseConstants.lastCalculationAtColumn} DESC';

  static const _sessionsSql =
      'SELECT $_sessionColumns '
      'FROM ${DatabaseConstants.calculatorSessionsTable} '
      'WHERE ${DatabaseConstants.creatorUserIdColumn} = ? $_newestFirst';

  static const _sessionSql =
      'SELECT $_sessionColumns '
      'FROM ${DatabaseConstants.calculatorSessionsTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _searchSql =
      'SELECT $_sessionColumns '
      'FROM ${DatabaseConstants.calculatorSessionsTable} '
      'WHERE ${DatabaseConstants.creatorUserIdColumn} = ? '
      "AND (${DatabaseConstants.titleColumn} LIKE ? ESCAPE '\\' "
      "OR ${DatabaseConstants.resultTextColumn} LIKE ? ESCAPE '\\') "
      '$_newestFirst LIMIT ?';

  static const _sessionIdsSql =
      'SELECT ${DatabaseConstants.idColumn} '
      'FROM ${DatabaseConstants.calculatorSessionsTable} '
      'WHERE ${DatabaseConstants.creatorUserIdColumn} = ? $_newestFirst';

  static const _tapeSql =
      'SELECT ${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.sessionIdColumn}, '
      '${DatabaseConstants.computationColumn}, '
      '${DatabaseConstants.schemaVersionColumn}, '
      '${DatabaseConstants.createdAtColumn} '
      'FROM ${DatabaseConstants.calculatorTapesTable} '
      'WHERE ${DatabaseConstants.sessionIdColumn} = ?';

  static const _insertSessionSql =
      'INSERT INTO ${DatabaseConstants.calculatorSessionsTable} '
      '($_sessionColumns) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';

  static const _insertTapeSql =
      'INSERT INTO ${DatabaseConstants.calculatorTapesTable} '
      '(${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.sessionIdColumn}, '
      '${DatabaseConstants.computationColumn}, '
      '${DatabaseConstants.schemaVersionColumn}, '
      '${DatabaseConstants.createdAtColumn}) VALUES (?, ?, ?, ?, ?)';

  static const _renameSql =
      'UPDATE ${DatabaseConstants.calculatorSessionsTable} '
      'SET ${DatabaseConstants.titleColumn} = ?, '
      '${DatabaseConstants.updatedAtColumn} = ? '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _deleteSessionSql =
      'DELETE FROM ${DatabaseConstants.calculatorSessionsTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _deleteTapeSql =
      'DELETE FROM ${DatabaseConstants.calculatorTapesTable} '
      'WHERE ${DatabaseConstants.sessionIdColumn} = ?';

  @override
  Stream<List<CalculationSessionDto>> watchSessions(String creatorUserId) =>
      _tracked(
        _database
            .watch(
              _sessionsSql,
              parameters: [creatorUserId],
              triggerOnTables: const [
                DatabaseConstants.calculatorSessionsTable,
              ],
            )
            .map(_sessions),
      );

  @override
  Future<CalculationSessionDto?> fetchSessionById(String id) async =>
      _sessions(await _database.getAll(_sessionSql, [id])).firstOrNull;

  @override
  Future<CalculationTapeDto?> fetchTapeBySessionId(String sessionId) async {
    final rows = await _database.getAll(_tapeSql, [sessionId]);
    return rows.map(CalculationTapeDto.fromRow).firstOrNull;
  }

  @override
  Future<void> insertSession(
    CalculationSessionDto session,
    CalculationTapeDto tape,
  ) => _database.writeTransaction((transaction) async {
    await transaction.execute(
      _insertSessionSql,
      _values(session.toRow(), _sessionColumns),
    );
    await transaction.execute(
      _insertTapeSql,
      _values(tape.toRow(), _tapeColumns),
    );
    final ids = await transaction.getAll(_sessionIdsSql, [
      session.creatorUserId,
    ]);
    for (final row in ids.skip(keptSessions)) {
      await _delete(transaction, row[DatabaseConstants.idColumn] as String);
    }
  });

  @override
  Future<bool> renameSession(String id, String title, DateTime updatedAt) =>
      _database.writeTransaction((transaction) async {
        if (!await _exists(transaction, id)) return false;
        await transaction.execute(_renameSql, [
          title,
          updatedAt.toUtc().toIso8601String(),
          id,
        ]);
        return true;
      });

  @override
  Future<bool> deleteSession(String id) =>
      _database.writeTransaction((transaction) async {
        if (!await _exists(transaction, id)) return false;
        await _delete(transaction, id);
        return true;
      });

  @override
  Future<List<CalculationSessionDto>> searchSessions(
    String creatorUserId,
    String query, {
    int limit = 20,
  }) async {
    final pattern = '%${_escaped(query)}%';
    return _sessions(
      await _database.getAll(_searchSql, [
        creatorUserId,
        pattern,
        pattern,
        limit,
      ]),
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    final open = _watchers.entries.toList();
    _watchers.clear();
    await Future.wait(
      open.map((watcher) async {
        try {
          await watcher.value.cancel();
        } finally {
          watcher.key.close();
        }
      }),
    );
  }

  static const _tapeColumns =
      '${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.sessionIdColumn}, '
      '${DatabaseConstants.computationColumn}, '
      '${DatabaseConstants.schemaVersionColumn}, '
      '${DatabaseConstants.createdAtColumn}';

  static List<Object?> _values(Map<String, Object?> row, String columns) => [
    for (final column in columns.split(', ')) row[column],
  ];

  static List<CalculationSessionDto> _sessions(
    List<Map<String, Object?>> rows,
  ) => rows.map(CalculationSessionDto.fromRow).toList(growable: false);

  static String _escaped(String query) => query.replaceAllMapped(
    RegExp(r'[\\%_]'),
    (match) => '\\${match.group(0)}',
  );

  Future<bool> _exists(SqliteWriteContext transaction, String id) async =>
      (await transaction.getAll(_sessionSql, [id])).isNotEmpty;

  Future<void> _delete(SqliteWriteContext transaction, String id) async {
    await transaction.execute(_deleteTapeSql, [id]);
    await transaction.execute(_deleteSessionSql, [id]);
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
    controller.onCancel = () => _watchers.remove(controller)?.cancel();
  });
}
