// coverage:ignore-file
import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';

/// Reads and writes the `user_calculator_stores` rows the phone holds: the
/// signed-in user's entries, delivered by the auto-subscribed sync stream
/// and written here first for PowerSync to upload.
///
/// Rows, not entities: one store kind is one shape, and which rows stand
/// for which Appendix B default is the repository's business. Reads answer
/// every row of a user's store, soft-deleted ones included, because a
/// deleted default is a row the repository must see to hide the default.
/// Methods throw on failure rather than returning a result type: the
/// repository is the single place that decides what a failure means. An
/// update or delete answers `false` when no row has that id, so the
/// repository can say "not found" without a second read.
abstract class LocalTradeStoresDataSource {
  /// Every row of one user's store, live and soft-deleted, in no order.
  Future<List<CalculatorStoreRowDto>> fetchRows(
    String userId,
    CalculatorStoreKind kind,
  );

  /// [fetchRows], re-run after every change to the table.
  Stream<List<CalculatorStoreRowDto>> watchRows(
    String userId,
    CalculatorStoreKind kind,
  );

  /// Inserts a row with a fresh id and answers it.
  Future<CalculatorStoreRowDto> insertRow(CalculatorStoreRowDto row);

  /// Rewrites the values, unit system, update time and deletion of the row
  /// with the row's id; `false` when there is none.
  Future<bool> updateRow(CalculatorStoreRowDto row);

  /// Soft-deletes the row with that id, stamping [deletedAt]; `false` when
  /// there is none.
  Future<bool> softDeleteRow(String id, DateTime deletedAt);

  /// Writes the one row of a default: rewrites the row of the same user,
  /// store and seed, live or soft-deleted, or inserts it when there is
  /// none, under the id every phone derives for that default, so two
  /// phones' writes of one default are one row on the server too. The
  /// lookup and the write run in one transaction, so two writes of one
  /// default cannot each insert a row. Answers the row with its id.
  Future<CalculatorStoreRowDto> writeSeedRow(CalculatorStoreRowDto row);

  /// Ends every stream handed out; the database stays open.
  Future<void> dispose();
}
