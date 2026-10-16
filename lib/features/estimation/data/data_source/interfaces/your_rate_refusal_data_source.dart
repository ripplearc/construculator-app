// coverage:ignore-file
import 'package:construculator/features/estimation/data/models/your_rate_refusal_dto.dart';

/// Reads and updates the record of Your rates defaults the server refused.
/// The upload step writes the records; this only reads them and tracks
/// whether the "Not kept" message was shown. Every call that reads, marks or
/// forgets one item names the user, the company and the category, so one
/// user's refusal is never read as another's. [loadAllRefusals] is the
/// exception: it returns the refusals of every user and company, so a caller
/// must match them by the user and the id of the refused row.
abstract class YourRateRefusalDataSource {
  /// Every refusal kept on the phone.
  ///
  /// Throws an exception if the read fails.
  Future<List<YourRateRefusalDto>> loadAllRefusals();

  /// The refusal kept for the item called [itemName] of [category] in
  /// [companyId] for [userId] priced by [equipmentMethod], or null if the
  /// server has not refused it.
  ///
  /// Throws an exception if the read fails.
  Future<YourRateRefusalDto?> loadRefusalByItem({
    required String userId,
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  });

  /// The refusal kept for the item, now and after every change to it or to
  /// the item's saved prices: null while the server has not refused the item,
  /// once the refusal is forgotten, and while the phone holds a newer price
  /// for the item that is neither the refused nor the last accepted one.
  ///
  /// Emits an error if a read fails.
  Stream<YourRateRefusalDto?> watchRefusalByItem({
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  });

  /// Records that the "Not kept" message for the item was shown. Does
  /// nothing if the item has no refusal.
  ///
  /// Throws an exception if the write fails.
  Future<void> markRefusalShownByItem({
    required String userId,
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  });

  /// Forgets the refusal of the item. Does nothing if it has none.
  ///
  /// Throws an exception if the write fails.
  Future<void> deleteRefusalByItem({
    required String userId,
    required String companyId,
    required String category,
    required String itemName,
    String? equipmentMethod,
  });
}
