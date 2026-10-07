import 'dart:async';

import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:sqlite3/common.dart';

/// A [FakePowerSyncDatabase] that applies the statements
/// [PowerSyncLocalTradeStoresDataSource] issues to in-memory rows.
///
/// Unlike the consent fake this one executes the writes, because the
/// behaviour under test is a round trip: what an insert wrote is what the
/// next read and the open watch see. The SQL shapes recognised are exactly
/// the ones the trade-stores and recents data sources build; anything else
/// is a [StateError], so a changed query fails loudly rather than reading
/// nothing.
class FakeTradeStoresDatabase extends FakePowerSyncDatabase {
  /// Rows by table name, column names as in `schema.dart`.
  final Map<String, List<Map<String, Object?>>> tables = {};

  /// Thrown by the next read when set.
  Object? readError;

  /// Thrown by the next write when set.
  Object? writeError;

  /// Thrown when a watch is cancelled while set, so a caller's dispose
  /// path can be tested against a database that fails to let go.
  Object? cancelError;

  /// Every statement executed, in order.
  final List<String> executed = [];

  final StreamController<String> _changes = StreamController.broadcast();

  /// Closes the change stream, ending any [watch] this fake handed out.
  Future<void> closeChanges() => _changes.close();

  /// Tables changed inside the open transaction, announced once it ends.
  Set<String>? _pending;

  /// Runs [callback] against this fake, holding every change notice until
  /// the callback returns so a watch sees the transaction land whole, as
  /// PowerSync re-runs a watch only after a commit.
  @override
  Future<T> writeTransaction<T>(
    Future<T> Function(SqliteWriteContext tx) callback, {
    Duration? lockTimeout,
  }) async {
    final pending = _pending = {};
    try {
      return await callback(_FakeWriteContext(this));
    } finally {
      _pending = null;
      pending.forEach(_changes.add);
    }
  }

  void _changed(String table) {
    final pending = _pending;
    if (pending != null) {
      pending.add(table);
    } else {
      _changes.add(table);
    }
  }

  @override
  Future<ResultSet> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async => _query(sql, parameters);

  @override
  Future<ResultSet> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    executed.add(sql);
    final error = writeError;
    if (error != null) throw error;
    final insert = RegExp(
      r'^INSERT INTO (\w+) \((.+)\) VALUES',
    ).firstMatch(sql);
    if (insert != null) {
      final columns = insert.group(2)!.split(', ');
      _rows(insert.group(1)!).add({
        for (var i = 0; i < columns.length; i++) columns[i]: parameters[i],
      });
      _changed(insert.group(1)!);
      return _empty();
    }
    final update = RegExp(
      r'^UPDATE (\w+) SET (.+) WHERE id = \?$',
    ).firstMatch(sql);
    if (update != null) {
      final columns = update
          .group(2)!
          .split(', ')
          .map((c) => c.split(' = ').first)
          .toList();
      final row = _rows(
        update.group(1)!,
      ).firstWhere((r) => r['id'] == parameters.last);
      for (var i = 0; i < columns.length; i++) {
        row[columns[i]] = parameters[i];
      }
      _changed(update.group(1)!);
      return _empty();
    }
    final delete = RegExp(
      r'^DELETE FROM (\w+) WHERE (\w+) = \?$',
    ).firstMatch(sql);
    if (delete != null) {
      final column = delete.group(2)!;
      _rows(delete.group(1)!).removeWhere((r) => r[column] == parameters.first);
      _changed(delete.group(1)!);
      return _empty();
    }
    throw StateError('Unexpected statement: $sql');
  }

  @override
  Stream<ResultSet> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = const Duration(milliseconds: 30),
    Iterable<String>? triggerOnTables,
  }) => Stream<ResultSet>.multi((controller) {
    void emit() {
      try {
        controller.add(_query(sql, parameters));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    final subscription = _changes.stream
        .where(
          (table) => triggerOnTables == null || triggerOnTables.contains(table),
        )
        .listen((_) => emit(), onDone: controller.close);
    controller.onCancel = () {
      if (cancelError case final error?) throw error;
      return subscription.cancel();
    };
    emit();
  });

  List<Map<String, Object?>> _rows(String table) =>
      tables.putIfAbsent(table, () => []);

  ResultSet _query(String sql, List<Object?> parameters) {
    final error = readError;
    if (error != null) throw error;
    final select = RegExp(
      r'^SELECT (.+) FROM (\w+)(?: WHERE (.+?))?(?: ORDER BY position)?$',
    ).firstMatch(sql);
    if (select == null) throw StateError('Unexpected statement: $sql');
    final columns = select.group(1)!.split(', ');
    var rows = _rows(select.group(2)!).toList();
    final where = select.group(3);
    if (where != null) {
      final conditions = where
          .split(' AND ')
          .map((c) => c.split(' = ').first)
          .toList();
      rows = rows.where((row) {
        for (var i = 0; i < conditions.length; i++) {
          if (row[conditions[i]] != parameters[i]) return false;
        }
        return true;
      }).toList();
    }
    if (sql.endsWith('ORDER BY position')) {
      rows.sort(
        (a, b) => (a['position']! as int).compareTo(b['position']! as int),
      );
    }
    if (rows.isEmpty) return _empty();
    return ResultSet(columns, null, [
      for (final row in rows) [for (final column in columns) row[column]],
    ]);
  }

  ResultSet _empty() => ResultSet(const [], null, const []);
}

/// The write context a [FakeTradeStoresDatabase] transaction hands its
/// callback: every statement goes back to the fake, whose change notices
/// are held until the transaction ends.
class _FakeWriteContext implements SqliteWriteContext {
  final FakeTradeStoresDatabase _database;

  _FakeWriteContext(this._database);

  @override
  Future<ResultSet> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) => _database.execute(sql, parameters);

  @override
  Future<ResultSet> getAll(String sql, [List<Object?> parameters = const []]) =>
      _database.getAll(sql, parameters);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
