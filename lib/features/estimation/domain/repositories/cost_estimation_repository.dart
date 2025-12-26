import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';

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
  /// Returns a [Future] that completes with a [List<CostEstimate>] containing
  /// all cost estimates associated with the specified project ID. The estimates
  /// include their markup configurations, lock status, and calculated totals.
  // TODO: https://ripplearc.youtrack.cloud/issue/CA-449/Cost-Estimation-Add-Pagination-for-Fetching-Estimations
  Future<List<CostEstimate>> getEstimations(String projectId);
}
