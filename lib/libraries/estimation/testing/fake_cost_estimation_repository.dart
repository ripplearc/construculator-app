import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';

/// A fake implementation of [CostEstimationRepository] for testing purposes.
///
/// This fake lives in the estimation library so any module that depends on
/// [CostEstimationRepository] can import it directly rather than rolling
/// a bespoke private fake in each consumer test.
class FakeCostEstimationRepository implements CostEstimationRepository {
  /// The stream that [watchEstimations] will return.
  Stream<Either<Failure, List<CostEstimate>>> streamToReturn =
      const Stream.empty();

  /// The last project ID passed to [watchEstimations].
  String? lastProjectId;

  /// The last sort option passed to [watchEstimations].
  EstimationSortOption? lastSortBy;

  /// The last ascending flag passed to [watchEstimations].
  bool? lastAscending;

  /// The last limit passed to [watchEstimations].
  int? lastLimit;

  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) {
    lastProjectId = projectId;
    lastSortBy = sortBy;
    lastAscending = ascending;
    lastLimit = limit;
    return streamToReturn;
  }

  @override
  Future<Either<Failure, CostEstimate>> changeLockStatus({
    required String estimationId,
    required bool isLocked,
    required String projectId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  ) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) =>
      throw UnimplementedError();

  @override
  void dispose() {}

  @override
  Future<Either<Failure, List<CostEstimate>>> fetchInitialEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) =>
      throw UnimplementedError();

  @override
  bool hasMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, CostEstimate>> renameEstimation({
    required String estimationId,
    required String newName,
    required String projectId,
  }) =>
      throw UnimplementedError();
}
