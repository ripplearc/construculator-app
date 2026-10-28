// coverage:ignore-file
import 'package:construculator/features/estimation/data/models/your_rate_refusal_dto.dart';

/// Reads and updates the record of Your rates defaults the server refused.
/// The upload step writes the records; this only reads them and tracks
/// whether the "Not kept" message was shown.
abstract class YourRateRefusalDataSource {
  /// Every refusal kept on the phone.
  ///
  /// Throws an exception if the read fails.
  Future<List<YourRateRefusalDto>> loadAllRefusals();

  /// The refusal kept for the item called [itemName] priced by
  /// [equipmentMethod], or null if the server has not refused it.
  ///
  /// Throws an exception if the read fails.
  Future<YourRateRefusalDto?> loadRefusalByItem(
    String itemName,
    String? equipmentMethod,
  );

  /// Records that the "Not kept" message for the item was shown. Does
  /// nothing if the item has no refusal.
  ///
  /// Throws an exception if the write fails.
  Future<void> markRefusalShownByItem(String itemName, String? equipmentMethod);

  /// Forgets the refusal of the item. Does nothing if it has none.
  ///
  /// Throws an exception if the write fails.
  Future<void> deleteRefusalByItem(String itemName, String? equipmentMethod);
}
