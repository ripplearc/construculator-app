/// Identifies a Your rates item for one company by its category, name and
/// pricing method. The name rule matches the server's `item_name_key`: it
/// ignores case and extra spaces.
class YourRateRefusalKey {
  const YourRateRefusalKey._();

  /// [name] with outer spaces removed, runs of spaces made one, in lower case.
  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// The key of the item called [itemName] in [category] priced by
  /// [equipmentMethod], for the company [companyId].
  static String of({
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  }) =>
      '$companyId|$category|${normalizeName(itemName)}|${equipmentMethod ?? ''}';
}
