/// The one price change on a "Cost file updated" log entry.
class CostFileChangedItem {
  /// The changed item's name, or null when it is not a string.
  final String? itemName;

  /// The rate before the upload, or null when it is not a number.
  final num? oldRate;

  /// The rate after the upload, or null when it is not a number.
  final num? newRate;

  /// Creates a change with the given name and rates.
  const CostFileChangedItem({this.itemName, this.oldRate, this.newRate});
}

/// Reads the `changedItems` of a "Cost file updated" log entry.
///
/// The entry's title and its Rate row both read through this parser, so they
/// always agree on whether the upload changed exactly one price.
class CostFileChangedItemParser {
  /// Returns the single change in `changedItems`.
  ///
  /// Returns null unless `changedItems` is a list holding exactly one map.
  static CostFileChangedItem? singleFrom(Map<String, dynamic> details) {
    final changedItems = details['changedItems'];
    if (changedItems is! List || changedItems.length != 1) return null;
    final changedItem = changedItems.single;
    if (changedItem is! Map) return null;
    final itemName = changedItem['itemName'];
    final oldRate = changedItem['oldRate'];
    final newRate = changedItem['newRate'];
    return CostFileChangedItem(
      itemName: itemName is String ? itemName : null,
      oldRate: oldRate is num ? oldRate : null,
      newRate: newRate is num ? newRate : null,
    );
  }
}
