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

  /// Every cost item of an estimate, oldest first.
  ///
  /// Returns an empty list for an estimate with no items. This reads from the
  /// network, so it fails while the device is offline.
  Future<Either<Failure, List<CostItem>>> getCostItemsForEstimate(
    String estimateId,
  );

  /// Creates a new cost item and returns the persisted entity.
  Future<Either<Failure, CostItem>> createCostItem(CostItem item);

  /// Saves the changed fields of an existing cost item and returns it as
  /// stored. The item is found by its id.
  ///
  /// This asks the server, so it fails while the device is offline.
  Future<Either<Failure, CostItem>> updateCostItem(CostItem item);

  /// Removes the cost item with [itemId] from its estimate.
  ///
  /// This asks the server, so it fails while the device is offline.
  Future<Either<Failure, void>> deleteCostItem(String itemId);

  /// The name of the estimate of [companyId]'s projects holding the newest
  /// equipment line called [itemName] that is priced by [pricingMethod] at
  /// exactly [rateAmount] (the daily rate under day pricing, the job amount
  /// under job pricing).
  ///
  /// Returns `Right(null)` when no line keeps that price.
  ///
  /// Cost lines are not stored on the phone, so this asks the server. With no
  /// network it returns `Left(EstimationFailure)` after a few seconds, with no
  /// retry. A caller must not wait for it before showing the refusal message.
  Future<Either<Failure, String?>> getEstimateNameKeepingEquipmentRate({
    required String companyId,
    required String itemName,
    required EquipmentPricingMethod pricingMethod,
    required double rateAmount,
  });
}
