import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:equatable/equatable.dart';

/// Parameters for retrieving recent estimations
class RecentEstimationsParams extends Equatable {
  /// The project ID to fetch estimations for
  final String projectId;

  /// The maximum number of recent estimations to return
  final int limit;

  const RecentEstimationsParams({required this.projectId, this.limit = 5});

  @override
  List<Object?> get props => [projectId, limit];
}

/// Use case for streaming recent estimations in the dashboard.
///
/// Retrieves a stream from the [CostEstimationRepository] with strict
/// limits and sort ordering specific to the Dashboard requirements.
class WatchRecentEstimationsUseCase {
  final CostEstimationRepository _repository;

  WatchRecentEstimationsUseCase(this._repository);

  /// Executes the use case to start streaming recent estimations
  Stream<Either<Failure, List<CostEstimate>>> call(
    RecentEstimationsParams params,
  ) {
    return _repository.watchEstimations(
      params.projectId,
      sortBy: EstimationSortOption.updatedAt,
      // Descending order to get the most recent ones
      ascending: false,
      limit: params.limit,
    );
  }
}
