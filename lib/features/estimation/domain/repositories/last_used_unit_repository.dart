// coverage:ignore-file
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';

/// Remembers, per account, the last unit each item was added with, so the next
/// line for the same item opens with that unit selected.
abstract class LastUsedUnitRepository {
  /// The units this account last used for each item in [category]. Empty when
  /// none are remembered or they can't be read.
  Future<RememberedUnits> getLastUnits(CostItemType category);

  /// Remembers [unit] as the last one this account used for [itemName] in
  /// [category].
  Future<void> saveLastUnit(CostItemType category, String itemName, Unit unit);
}

/// The last unit used for each item name, looked up without regard to capital
/// letters or extra spaces, so `Interior paint` and ` interior  PAINT ` are
/// one item.
class RememberedUnits {
  const RememberedUnits(this.unitsByKey);

  /// No item has a remembered unit.
  static const none = RememberedUnits({});

  /// The units by [keyFor] of the item name, as stored.
  final Map<String, Unit> unitsByKey;

  /// The unit last used for [itemName], or null when none is remembered.
  Unit? forItem(String itemName) => unitsByKey[keyFor(itemName)];

  /// Returns a copy that also remembers [unit] for [itemName].
  RememberedUnits withUnit(String itemName, Unit unit) =>
      RememberedUnits({...unitsByKey, keyFor(itemName): unit});

  /// The key [itemName] is remembered under: trimmed, inner spaces collapsed
  /// to one, and in lower case.
  static String keyFor(String itemName) =>
      itemName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
