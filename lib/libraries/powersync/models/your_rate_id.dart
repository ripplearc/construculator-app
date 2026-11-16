import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
import 'package:powersync/powersync.dart' show uuid;

/// The id of a saved Your rates entry, worked out from what the entry is.
///
/// Every phone and the server's `your_rate_id()` give the same entry the same
/// id, so two phones that save one rate offline end with one row and a later
/// edit always finds it. Case and extra spaces in the name or the label do not
/// change the id. The id is a version 5 UUID of the company, category, name
/// key, pricing method and label key. A second price saved under another label
/// for the same name and method gets its own id, so both prices are kept. No
/// label and a blank label give the same id.
///
/// The examples in `your_rate_id_examples.json` are run here and by the
/// backend's `your_rate_id_test.sql`. Change the rule in both places together.
abstract final class YourRateId {
  static const _namespace = '8cd2f594-2bb2-4396-ac37-762c9e552c65';

  /// The id of the item called [itemName] in [category] of [companyId], priced
  /// by [equipmentMethod] (`day` or `job`, null outside equipment) and saved
  /// under [entryLabel] (null or blank when the rate has no label).
  static String of({
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
    String? entryLabel,
  }) {
    final nameKey = YourRateRefusalKey.normalizeName(itemName);
    final labelKey = YourRateRefusalKey.normalizeLabel(entryLabel) ?? '';
    return uuid.v5(
      _namespace,
      '${companyId.toLowerCase()}|$category|$nameKey|${equipmentMethod ?? ''}|$labelKey',
    );
  }
}
