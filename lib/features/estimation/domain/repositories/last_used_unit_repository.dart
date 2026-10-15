import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';

/// Remembers, per account and per cost category, the last unit a line was
/// added with, so the next form for that category opens with it selected.
abstract class LastUsedUnitRepository {
  /// The unit last used by this account for [category], or null when none is
  /// remembered or it can't be read.
  Future<Unit?> getLastUnit(CostItemType category);

  /// Remembers [unit] as the last one used by this account for [category].
  Future<void> saveLastUnit(CostItemType category, Unit unit);
}
