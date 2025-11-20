import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Abstract repository interface for cost estimation data operations.
///
/// This repository defines the contract for accessing cost estimation data from various
/// data sources (local storage, remote APIs, etc.). It follows the repository
/// pattern to abstract data access logic from the domain layer.
///
/// The repository provides methods for retrieving cost estimates associated with
/// specific projects, enabling the domain layer to work with cost estimation
/// entities without being coupled to specific data source implementations.
///
/// Details can be found in the detailed design document: https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#heading=h.pvhts1v5ct4j
abstract class CostEstimationRepository {
  /// Retrieves all cost estimates for a specific project.
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or a [List<CostEstimate>] associated with the specified
  /// project ID. The estimates include their markup configurations, lock
  /// status, and calculated totals.
  // TODO: https://ripplearc.youtrack.cloud/issue/CA-449/Cost-Estimation-Add-Pagination-for-Fetching-Estimations
  Future<Either<Failure, List<CostEstimate>>> getEstimations(String projectId);

  /// Creates a new cost estimation.
  ///
  /// Returns a [Future] that completes with the created [CostEstimate] containing
  /// the newly created cost estimation with its assigned ID and timestamps.
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  );

  /// Deletes a cost estimation by its ID.
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] if the deletion fails, or [void] if successful.
  Future<Either<Failure, void>> deleteEstimation(String estimationId);
}
