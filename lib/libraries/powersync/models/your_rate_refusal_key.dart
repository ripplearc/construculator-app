/// Identifies a Your rates item for one user of one company by its category,
/// name and pricing method. The name rule matches the server's `item_name_key`: it
/// ignores case and extra spaces.
abstract final class YourRateRefusalKey {
  /// [name] with outer spaces removed, runs of spaces made one, in lower case.
  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// [label] the way [normalizeName] writes a name, or null when [label] is
  /// null or has nothing left after trimming.
  static String? normalizeLabel(String? label) {
    if (label == null) return null;
    final key = normalizeName(label);
    return key.isEmpty ? null : key;
  }

  /// The key of the item called [itemName] in [category] priced by
  /// [equipmentMethod], for [userId] of the company [companyId].
  static String of({
    required String userId,
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  }) =>
      '$userId|$companyId|$category|${normalizeName(itemName)}|${equipmentMethod ?? ''}';
}
