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
  /// Retrieves the first page of cost estimates for a specific project.
  ///
  /// Resets pagination state and fetches the initial page.
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or a [List<CostEstimate>] associated with the specified
  /// project ID.
  Future<Either<Failure, List<CostEstimate>>> fetchInitialEstimations(
    String projectId,
  );

  /// Loads the next page of cost estimates for a specific project.
  ///
  /// Accumulates results with previously loaded pages.
  /// Returns [Either] containing a [Failure] or [List<CostEstimate>]
  /// representing the full accumulated list.
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId,
  );

  /// Returns whether there are more pages to load for a project.
  bool hasMoreEstimations(String projectId);

  /// Watches all cost estimates for a specific project.
  ///
  /// Returns a [Stream] that emits [Either] containing either a [Failure] or
  /// lists of [CostEstimate] associated with the specified project ID.
  /// The stream will emit new values whenever the estimations change
  /// (e.g., when a new estimation is created or updated).
  ///
  /// The stream includes their markup configurations, lock status, and
  /// calculated totals.
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId,
  );

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
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  );

  /// Changes the lock status of a cost estimation.
  ///
  /// [estimationId] The ID of the estimation to update.
  /// [isLocked] Whether the estimation should be locked or unlocked.
  /// [projectId] The ID of the project the estimation belongs to (required for cache/stream updates).
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or the updated [CostEstimate].
  Future<Either<Failure, CostEstimate>> changeLockStatus({
    required String estimationId,
    required bool isLocked,
    required String projectId,
  });

  /// Disposes of all resources used by the repository.
  ///
  /// This method should be called when the repository is no longer needed.
  /// It will clean up all stream controllers and caches.
  void dispose();
}
