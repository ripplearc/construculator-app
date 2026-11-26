// coverage:ignore-file

/// The order of the function-key groups set in View all, as this phone
/// keeps it: the rows of the local-only `calculator_group_order` table.
/// Every method throws what the store throws; the repository turns that
/// into a failure.
abstract class LocalGroupOrderDataSource {
  /// The group ids in the order set, or `null` when none was set yet.
  Future<List<String>?> fetchGroupOrder();

  /// The order now and after every change; `null` while none is set.
  Stream<List<String>?> watchGroupOrder();

  /// Keeps [order] as the one order, stamped [updatedAt].
  Future<void> replaceGroupOrder(List<String> order, DateTime updatedAt);

  /// Ends every watch handed out.
  Future<void> dispose();
}
