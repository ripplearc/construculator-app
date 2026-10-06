/// Identifies a Your rates item by its name and pricing method, the way the
/// server does: the name ignores case and extra spaces.
class YourRateRefusalKey {
  const YourRateRefusalKey._();

  /// The key of the item called [itemName] priced by [equipmentMethod].
  static String of(String itemName, String? equipmentMethod) {
    final name = itemName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return '$name|${equipmentMethod ?? ''}';
  }
}
