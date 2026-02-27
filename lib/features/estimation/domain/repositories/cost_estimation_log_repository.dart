import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Abstract repository interface for cost estimation log data operations.
///
/// This repository defines the contract for accessing cost estimation logs
/// from various data sources. It follows the repository pattern to abstract
/// data access logic from the domain layer.
abstract class CostEstimationLogRepository {
  /// Fetches the initial page of logs for a specific cost estimation.
  ///
  /// This method resets pagination state and retrieves the first page of logs.
  /// Logs are typically ordered by timestamp (most recent first).
  ///
  /// Parameters:
  /// - [estimateId]: The ID of the estimation to fetch logs for
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or a [List<CostEstimationLog>] for the specified estimation.
  Future<Either<Failure, List<CostEstimationLog>>> fetchInitialLogs(
    String estimateId,
  );

  /// Loads the next page of logs for a specific cost estimation.
  ///
  /// This method fetches additional logs based on the current pagination state.
  /// Returns an empty list if there are no more logs to load.
  ///
  /// Parameters:
  /// - [estimateId]: The ID of the estimation to load more logs for
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or a [List<CostEstimationLog>] representing the next page.
  Future<Either<Failure, List<CostEstimationLog>>> loadMoreLogs(
    String estimateId,
  );

  /// Returns whether there are more logs to load for a specific estimation.
  ///
  /// Parameters:
  /// - [estimateId]: The ID of the estimation to check
  ///
  /// Returns true if more logs can be loaded, false otherwise.
  bool hasMoreLogs(String estimateId);

  /// Disposes resources and cleans up pagination state.
  ///
  /// This method should be called when the repository is no longer needed
  /// to free up memory and prevent memory leaks.
  void dispose();
}
