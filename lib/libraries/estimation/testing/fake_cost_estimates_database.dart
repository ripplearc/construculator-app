import 'dart:async';

import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';

/// A [FakePowerSyncDatabaseWrapper] that keeps the `cost_estimates` rows on
/// the fake phone, so a `watch` returns what the SQL it was given would select.
///
/// The base fake answers by SQL text only. This one reads the project id and
/// the optional limit from the parameters and the sort column and direction
/// from the SQL, and it emits again each time the rows change. Calls are still
/// recorded in [watchCalls].
///
/// A write the data source makes through [execute] changes the stored rows the
/// way SQLite would and sends the new rows to every open watch, as the real
/// database does for a local write. It understands the `INSERT`, the
/// single-column `UPDATE ... WHERE id = ?` and the `DELETE ... WHERE id = ?`
/// that the estimate data source writes, and answers the data source's read of
/// one row by id.
class FakeCostEstimatesDatabase extends FakePowerSyncDatabaseWrapper {
  final List<Map<String, dynamic>> _rows = [];
  final StreamController<void> _rowsChanged = StreamController.broadcast();

  static final _orderBy = RegExp(r'ORDER BY (\w+) (ASC|DESC)');
  static final _insert = RegExp(r'^INSERT INTO cost_estimates \((.+)\) VALUES');
  static final _update = RegExp(
    r'^UPDATE cost_estimates SET (\w+) = \? WHERE id = \?$',
  );
  static final _delete = RegExp(r'^DELETE FROM cost_estimates WHERE id = \?$');
  static const _selectById =
      'SELECT * FROM cost_estimates WHERE id = ? LIMIT 1';

  /// When set, every new [watch] subscription fails with it.
  Object? watchError;

  /// When set, a write is recorded in [executeCalls] at once but waits for this
  /// completer before it fails with [executeError] or changes the rows.
  Completer<void>? executeGate;

  /// Puts [rows] on the phone as though sync had delivered them.
  void seedRows(List<Map<String, dynamic>> rows) {
    _rows.addAll(rows.map(_asStoredRow));
    _rowsChanged.add(null);
  }

  /// Replaces the stored row that has the same id as [row], as a sync would.
  void replaceRow(Map<String, dynamic> row) {
    final index = _rows.indexWhere((stored) => stored['id'] == row['id']);
    _rows[index] = _asStoredRow(row);
    _rowsChanged.add(null);
  }

  /// Removes the stored row with [id], as a sync would.
  void removeRow(String id) {
    _rows.removeWhere((stored) => stored['id'] == id);
    _rowsChanged.add(null);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    if (sql != _selectById) return super.getAll(sql, parameters);
    await super.getAll(sql, parameters);
    return [
      for (final row in _rows)
        if (row['id'] == parameters.single) {...row},
    ];
  }

  @override
  Future<void> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    executeCalls.add((sql: sql, parameters: parameters));
    await executeGate?.future;
    final error = executeError;
    if (error != null) throw error;
    final insert = _insert.firstMatch(sql);
    final update = _update.firstMatch(sql);
    if (insert != null) {
      final columns = (insert[1] as String).split(', ');
      _rows.add({
        for (var i = 0; i < columns.length; i++) columns[i]: parameters[i],
      });
    } else if (update != null) {
      final row = _rows.firstWhere((stored) => stored['id'] == parameters[1]);
      row[update[1] as String] = parameters[0];
    } else if (_delete.hasMatch(sql)) {
      _rows.removeWhere((stored) => stored['id'] == parameters.single);
    } else {
      return;
    }
    _rowsChanged.add(null);
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = kDefaultWatchThrottle,
  }) {
    _orderOf(sql);
    super.watch(sql, parameters: parameters, throttle: throttle);
    return Stream.multi((listener) {
      final error = watchError;
      if (error != null) {
        listener.addError(error);
        listener.close();
        return;
      }
      listener.add(_select(sql, parameters));
      final subscription = _rowsChanged.stream.listen(
        (_) => listener.add(_select(sql, parameters)),
      );
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  void reset() {
    super.reset();
    _rows.clear();
    watchError = null;
    executeGate = null;
  }

  @override
  void dispose() {
    super.dispose();
    _rowsChanged.close();
  }

  RegExpMatch _orderOf(String sql) {
    final order = _orderBy.firstMatch(sql);
    if (order == null) {
      throw ArgumentError.value(sql, 'sql', 'has no ORDER BY clause');
    }
    return order;
  }

  List<Map<String, dynamic>> _select(String sql, List<Object?> parameters) {
    final order = _orderOf(sql);
    final column = order.group(1) as String;
    final ascending = order.group(2) == 'ASC';
    final limit = parameters.length > 1 ? parameters[1] as int : null;
    final matching =
        _rows.where((row) => row['project_id'] == parameters.first).toList()
          ..sort((a, b) {
            final byColumn = (a[column] as String).compareTo(
              b[column] as String,
            );
            return ascending ? byColumn : -byColumn;
          });
    return [
      for (final row in matching.take(limit ?? matching.length)) {...row},
    ];
  }

  Map<String, dynamic> _asStoredRow(Map<String, dynamic> row) => {
    ...row,
    'is_locked': (row['is_locked'] as bool? ?? false) ? 1 : 0,
  };
}
