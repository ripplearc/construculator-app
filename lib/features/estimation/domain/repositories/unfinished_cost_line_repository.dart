// coverage:ignore-file
import 'package:construculator/features/estimation/domain/entities/unfinished_cost_line.dart';

/// Keeps, per account, the one cost line that was being typed when the phone
/// closed the app. Material, Labor and Equipment share it: only one cost form
/// can be open, so a newer line replaces an older one.
abstract class UnfinishedCostLineRepository {
  /// The unfinished line, or null when there is none, it cannot be read, or it
  /// was last changed 7 days ago or more. A line that old is removed.
  Future<UnfinishedCostLine?> read();

  /// Keeps [line] in place of any earlier one.
  Future<void> save(UnfinishedCostLine line);

  /// Removes the unfinished line, if there is one.
  Future<void> remove();
}
