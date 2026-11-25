import 'dart:async';
import 'dart:convert';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_group_order_data_source.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';

/// [LocalGroupOrderDataSource] over PowerSync's local SQLite database.
///
/// The table is `Table.localOnly`, so a write lands in SQLite and stays
/// there: no upload queue is touched and no sync ever clears it. The phone
/// has one order, kept in one row with a fixed id, rewritten in place or
/// inserted the first time in one write transaction. The order travels as
/// a JSON list of the group ids; a row whose list cannot be read is a
/// [FormatException], because only this class writes it. Every stream
/// handed out is tracked so [dispose] can end it, as the recents data
/// source does; a stream handed out after [dispose] answers once and ends.
class PowerSyncLocalGroupOrderDataSource implements LocalGroupOrderDataSource {
  final PowerSyncDatabase _database;

  /// Live watches, keyed by the controller feeding the caller and valued by
  /// the query subscription feeding it, so [dispose] can end both ends.
  final Map<MultiStreamController<Object?>, StreamSubscription<Object?>>
  _watchers = {};
  var _disposed = false;

  /// Creates a data source over a PowerSync database.
  PowerSyncLocalGroupOrderDataSource({required this._database});

  static const _orderSql =
      'SELECT ${DatabaseConstants.groupOrderColumn} '
      'FROM ${DatabaseConstants.calculatorGroupOrderTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _insertSql =
      'INSERT INTO ${DatabaseConstants.calculatorGroupOrderTable} '
      '(${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.groupOrderColumn}, '
      '${DatabaseConstants.updatedAtColumn}) VALUES (?, ?, ?)';

  static const _updateSql =
      'UPDATE ${DatabaseConstants.calculatorGroupOrderTable} '
      'SET ${DatabaseConstants.groupOrderColumn} = ?, '
      '${DatabaseConstants.updatedAtColumn} = ? '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  @override
  Future<List<String>?> fetchGroupOrder() async => _order(
    await _database.getAll(_orderSql, const [
      DatabaseConstants.calculatorGroupOrderRowId,
    ]),
  );

  @override
  Stream<List<String>?> watchGroupOrder() => _tracked(
    _database
        .watch(
          _orderSql,
          parameters: const [DatabaseConstants.calculatorGroupOrderRowId],
          triggerOnTables: const [DatabaseConstants.calculatorGroupOrderTable],
        )
        .map(_order)
        .distinct(listEquals),
  );

  @override
  Future<void> replaceGroupOrder(List<String> order, DateTime updatedAt) =>
      _database.writeTransaction((transaction) async {
        final json = jsonEncode(order);
        final stamp = updatedAt.toUtc().toIso8601String();
        final existing = await transaction.getAll(_orderSql, const [
          DatabaseConstants.calculatorGroupOrderRowId,
        ]);
        if (existing.isEmpty) {
          await transaction.execute(_insertSql, [
            DatabaseConstants.calculatorGroupOrderRowId,
            json,
            stamp,
          ]);
        } else {
          await transaction.execute(_updateSql, [
            json,
            stamp,
            DatabaseConstants.calculatorGroupOrderRowId,
          ]);
        }
      });

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
          await watcher.key.close();
        }
      }),
    );
  }

  static List<String>? _order(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return null;
    final stored = rows.first[DatabaseConstants.groupOrderColumn];
    if (stored is! String) {
      throw const FormatException('Unreadable group order row');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } catch (_) {
      throw const FormatException('Unreadable group order row');
    }
    if (decoded is List && decoded.every((id) => id is String)) {
      return List.unmodifiable(decoded.cast<String>());
    }
    throw const FormatException('Unreadable group order row');
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
