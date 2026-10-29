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
class FakeCostEstimatesDatabase extends FakePowerSyncDatabaseWrapper {
  final List<Map<String, dynamic>> _rows = [];
  final StreamController<void> _rowsChanged = StreamController.broadcast();

  static final _orderBy = RegExp(r'ORDER BY (\w+) (ASC|DESC)');

  /// When set, every new [watch] subscription fails with it.
  Object? watchError;

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
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = kDefaultWatchThrottle,
  }) {
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
  }

  @override
  void dispose() {
    super.dispose();
    _rowsChanged.close();
  }

  List<Map<String, dynamic>> _select(String sql, List<Object?> parameters) {
    final order = _orderBy.firstMatch(sql)!;
    final column = order.group(1)!;
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
