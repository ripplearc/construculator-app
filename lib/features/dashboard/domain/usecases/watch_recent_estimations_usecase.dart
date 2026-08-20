import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';

/// Parameters for retrieving recent estimations
class RecentEstimationsParams extends Equatable {
  /// The maximum number of recent estimations to return
  final int limit;

  /// Creates params for [WatchRecentEstimationsUseCase].
  ///
  /// [limit] defaults to 5 if not specified.
  const RecentEstimationsParams({this.limit = 5});

  @override
  List<Object?> get props => [limit];
}

/// Use case for streaming recent estimations in the dashboard.
///
/// Retrieves a stream from the [CostEstimationRepository] with strict
/// limits and sort ordering specific to the Dashboard requirements.
class WatchRecentEstimationsUseCase {
  static final _logger = AppLogger().tag('WatchRecentEstimationsUseCase');
  final CostEstimationRepository _repository;
  final CurrentProjectNotifier _currentProjectNotifier;

  /// Creates a [WatchRecentEstimationsUseCase] with the given [repository]
  /// and [currentProjectNotifier].
  WatchRecentEstimationsUseCase(this._repository, this._currentProjectNotifier);

  /// Executes the use case to start streaming recent estimations
  Stream<Either<Failure, List<CostEstimate>>> call(
    RecentEstimationsParams params,
  ) {
    final projectId = _currentProjectNotifier.currentProjectId;

    if (projectId == null || projectId.isEmpty) {
      // Warning, not error: right after login this is an expected transient
      // (the project dropdown's auto-selection has not landed yet), so it
      // must leave a breadcrumb without paging Sentry.
      _logger.warning(
        'Current project ID is null or empty, cannot watch recent estimations',
      );
      return Stream.value(
        const Left(
          EstimationFailure(errorType: EstimationErrorType.unexpectedError),
        ),
      );
    }

    return _repository.watchEstimations(
      projectId,
      sortBy: EstimationSortOption.updatedAt,
      ascending: false,
      limit: params.limit,
    );
  }
}
