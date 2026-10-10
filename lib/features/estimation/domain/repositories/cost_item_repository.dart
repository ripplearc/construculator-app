// coverage:ignore-file
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Repository interface for cost item data operations.
abstract class CostItemRepository {
  /// The sum of the totals of every cost item in an estimate, in dollars.
  ///
  /// The database keeps no running total for an estimate, so this is the
  /// estimate's total. Each item total is already rounded to the cent.
  Future<Either<Failure, double>> getEstimateItemsTotal(String estimateId);

  /// Creates a new cost item and returns the persisted entity.
  Future<Either<Failure, CostItem>> createCostItem(CostItem item);
}
