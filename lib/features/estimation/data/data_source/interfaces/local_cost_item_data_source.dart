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
  /// The upload leaves out null fields, so a field cleared by a later save
  /// keeps its old value on the server. Use an update to clear a field.
  ///
  /// Throws an exception if the write fails.
  Future<void> saveCostItemOnPhone(CostItemDto dto);

  /// Loads the lines of [estimateId] that are on the phone, oldest first.
  ///
  /// No sync stream holds `cost_items`, so a line leaves the phone at the next
  /// checkpoint after it uploads. A read finds the lines that have not
  /// uploaded yet, plus uploaded lines until that checkpoint. A caller that
  /// needs every line adds the lines from the server.
  ///
  /// Oldest first sorts the `created_at` text, so every row must use UTC ISO
  /// 8601 ending in `Z`. Lines with the same `created_at` are ordered by id.
  ///
  /// Throws an exception if the read fails.
  Future<List<CostItemDto>> loadCostItemsByEstimateId(String estimateId);

  /// Watches the ids of the lines of [estimateId] on the phone whose upload to
  /// the server is still waiting.
  ///
  /// A line leaves the set when the server has taken it, and also when the
  /// server refused it for good (an RLS denial, code 42501), because the
  /// connector then drops the queue entry. This set alone cannot tell those two
  /// apart. A line that is not in the set is on the server, was refused, or is
  /// not on the phone, because no sync stream keeps an uploaded line on the
  /// phone.
  ///
  /// Emits now, and again whenever a line is saved or an upload finishes.
  Stream<Set<String>> watchCostItemIdsWithPendingUpload(String estimateId);
}
