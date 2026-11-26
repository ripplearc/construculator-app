import 'dart:async';

import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:sqlite3/common.dart';

/// A [FakePowerSyncDatabase] that keeps the two session tables in memory
/// and answers the statements `PowerSyncLocalCalculationSessionDataSource`
/// makes: a `SELECT` with equality conditions, a `LIKE` pair in brackets,
/// `ORDER BY … DESC` and `LIMIT`; an `INSERT`; the rename `UPDATE`; and a
/// `DELETE` by one column. Writes inside a transaction report their table
/// changes when the transaction ends, so a watch sees a session and its
/// tape arrive together, as SQLite's watch does.
class FakeCalculationSessionsDatabase extends FakePowerSyncDatabase {
  /// The rows of each table, as inserted.
  final Map<String, List<Map<String, Object?>>> tables = {};

  /// Thrown by every read when set.
  Object? readError;

  /// Thrown by every write when set.
  Object? writeError;

  /// Thrown when a watch is cancelled, when set.
  Object? cancelError;

  /// Every statement executed, in order.
  final List<String> executed = [];

  final StreamController<String> _changes = StreamController.broadcast();

  Future<void> _writeLock = Future.value();

  Set<String>? _pending;

  /// Ends the change stream, so every watch closes.
  Future<void> closeChanges() => _changes.close();

  @override
  Future<T> writeTransaction<T>(
    Future<T> Function(SqliteWriteContext tx) callback, {
    Duration? lockTimeout,
  }) {
    final previous = _writeLock;
    final completer = Completer<void>();
    _writeLock = completer.future;
    return previous.then((_) async {
      final pending = _pending = {};
      try {
        return await callback(_FakeWriteContext(this));
      } finally {
        _pending = null;
        pending.forEach(_changes.add);
        completer.complete();
      }
    });
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
      final columns = [
        for (final assignment in update.group(2)!.split(', '))
          assignment.split(' = ').first,
      ];
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

  void _changed(String table) {
    final pending = _pending;
    if (pending != null) {
      pending.add(table);
    } else {
      _changes.add(table);
    }
  }

  List<Map<String, Object?>> _rows(String table) =>
      tables.putIfAbsent(table, () => []);

  ResultSet _query(String sql, List<Object?> parameters) {
    final error = readError;
    if (error != null) throw error;
    final select = RegExp(
      r'^SELECT (.+) FROM (\w+)(?: WHERE (.+?))?(?: ORDER BY (\w+)( DESC)?)?(?: LIMIT \?)?$',
    ).firstMatch(sql);
    if (select == null) throw StateError('Unexpected statement: $sql');
    final columns = select.group(1)!.split(', ');
    var rows = _rows(select.group(2)!).toList();
    var next = 0;
    final where = select.group(3);
    if (where != null) {
      for (final condition in where.split(' AND ')) {
        final equality = RegExp(r'^(\w+) = \?$').firstMatch(condition);
        if (equality != null) {
          final value = parameters[next++];
          rows = rows.where((r) => r[equality.group(1)!] == value).toList();
          continue;
        }
        final like = RegExp(
          r"^\((\w+) LIKE \? ESCAPE '\\' OR (\w+) LIKE \? ESCAPE '\\'\)$",
        ).firstMatch(condition);
        if (like != null) {
          final first = _needle(parameters[next++] as String);
          final second = _needle(parameters[next++] as String);
          rows = rows.where((r) {
            final a = r[like.group(1)!];
            final b = r[like.group(2)!];
            return (a is String && first.hasMatch(a)) ||
                (b is String && second.hasMatch(b));
          }).toList();
          continue;
        }
        throw StateError('Unexpected condition: $condition');
      }
    }
    final orderBy = select.group(4);
    if (orderBy != null) {
      rows.sort(
        (a, b) => (a[orderBy]! as String).compareTo(b[orderBy]! as String),
      );
      if (select.group(5) != null) rows = rows.reversed.toList();
    }
    if (sql.endsWith('LIMIT ?')) {
      rows = rows.take(parameters[next] as int).toList();
    }
    if (rows.isEmpty) return _empty();
    return ResultSet(columns, null, [
      for (final row in rows) [for (final column in columns) row[column]],
    ]);
  }

  /// A LIKE pattern read as SQLite reads it: `%` stands for any run of
  /// characters, `_` for any one, a `\`-escaped `%`, `_` or `\` for itself,
  /// and ASCII case does not count.
  static RegExp _needle(String pattern) {
    final needle = StringBuffer('^');
    for (var i = 0; i < pattern.length; i++) {
      final char = pattern[i];
      if (char == r'\' && i + 1 < pattern.length) {
        needle.write(RegExp.escape(pattern[++i]));
      } else if (char == '%') {
        needle.write('.*');
      } else if (char == '_') {
        needle.write('.');
      } else {
        needle.write(RegExp.escape(char));
      }
    }
    needle.write(r'$');
    return RegExp(needle.toString(), caseSensitive: false, dotAll: true);
  }

  ResultSet _empty() => ResultSet(const [], null, const []);
}

class _FakeWriteContext implements SqliteWriteContext {
  final FakeCalculationSessionsDatabase _database;

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
