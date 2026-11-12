// coverage:ignore-file
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';

/// Reads and writes the remembered values held on the device, one drawer
/// at a time.
///
/// Methods throw on failure rather than returning a result type: the
/// repository is the single place that decides what a failure means. A
/// drawer's values are a list, newest first; replacing the list is the one
/// write, because which values a drawer keeps (three deep, no duplicates,
/// the reused one moved to the front) is the engine's rule, not the
/// table's. Every `watch` emits the drawer as it is now and again after
/// each change.
abstract class LocalRecentsDataSource {
  /// The values of one drawer, newest first; empty when nothing was filed.
  Future<List<Quantity>> fetchRecents(String drawer);

  /// [fetchRecents], re-run after every change to the recents table.
  Stream<List<Quantity>> watchRecents(String drawer);

  /// Replaces the drawer's values with [values], newest first.
  Future<void> replaceRecents(String drawer, List<Quantity> values);

  /// Ends every stream handed out.
  Future<void> dispose();
}
