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

  /// The name of the estimate holding the newest equipment line called
  /// [itemName] that is priced by [pricingMethod] at exactly [rateAmount]
  /// (the daily rate under day pricing, the job amount under job pricing).
  ///
  /// Returns `Right(null)` when no line keeps that price. Needs a signal,
  /// since cost lines are not kept on the phone.
  Future<Either<Failure, String?>> getEstimateNameKeepingEquipmentRate({
    required String itemName,
    required EquipmentPricingMethod pricingMethod,
    required double rateAmount,
  });
}
