import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Repository interface for cost item data operations.
abstract class CostItemRepository {
  /// Creates a new cost item and returns the persisted entity.
  Future<Either<Failure, CostItem>> createCostItem(CostItem item);
}
