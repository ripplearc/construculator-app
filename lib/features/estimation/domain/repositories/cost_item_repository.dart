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

  /// Saves [item] on this phone under its own id and returns it. The server
  /// gets the line later, so this never waits for a signal.
  ///
  /// Saving the same id again replaces the line, so a retry never adds a
  /// second one. Returns `Left(EstimationFailure)` when the phone cannot
  /// write or the line has no id.
  Future<Either<Failure, CostItem>> addCostItemOnPhone(CostItem item);

  /// Watches the ids of the lines of [estimateId] on this phone that the
  /// server has not received yet.
  ///
  /// A line leaves the set once the server has it. A line that is not in the
  /// set is on the server or not on this phone, so a screen that lists the
  /// lines marks a line as not synced when its id is in the set.
  ///
  /// Emits now, and again whenever a line is saved or an upload finishes. A
  /// failed read arrives as a `Left` and the stream stays open.
  Stream<Either<Failure, Set<String>>> watchNotSyncedCostItemIds(
    String estimateId,
  );

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
