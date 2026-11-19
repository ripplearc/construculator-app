// coverage:ignore-file
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';

/// Abstract interface for the cost lines kept in the phone's own database.
///
/// A write lands on the phone at once and is sent to the server later, so
/// none of these calls waits for a signal.
abstract class LocalCostItemDataSource {
  /// Writes [dto] to the phone under `dto.id`, replacing the row that already
  /// has that id, so saving the same line twice leaves one row.
  ///
  /// Throws an exception if the write fails.
  Future<void> saveCostItemOnPhone(CostItemDto dto);

  /// Loads the lines of [estimateId] that are on the phone, oldest first.
  ///
  /// Throws an exception if the read fails.
  Future<List<CostItemDto>> loadCostItemsByEstimateId(String estimateId);

  /// Loads the totals of the lines of [estimateId] that the server refused for
  /// good and whose phone row was kept in a refusal record, by line id. Each
  /// total is the `item_total_cost` the line had on the phone, and is 0 when
  /// the line had none.
  ///
  /// A line the server refuses stays in the estimate's total until the user
  /// moves or discards it, and the next sync checkpoint removes its row from
  /// the phone, so the refusal record is where its total is still found.
  ///
  /// Throws an exception if the read fails.
  Future<Map<String, double>> loadRefusedLineTotalsByEstimateId(
    String estimateId,
  );

  /// Watches the ids of the lines of [estimateId] on the phone whose upload to
  /// the server is still waiting.
  ///
  /// A line leaves the set when the server has taken it. A line that is not in
  /// the set is either on the server or not on the phone, because no sync
  /// stream keeps an uploaded line on the phone.
  ///
  /// Emits now, and again whenever a line is saved or an upload finishes.
  Stream<Set<String>> watchCostItemIdsWithPendingUpload(String estimateId);
}
