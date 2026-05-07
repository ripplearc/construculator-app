import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';

// A stub [CostEstimationRepository] that never emits any data.
// Used in widget tests so consumers can resolve their
// dependencies without hitting a real network or database.
class NeverEstimationRepository implements CostEstimationRepository {
  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => const Stream.empty();

  @override
  Future<Either<Failure, List<CostEstimate>>> fetchInitialEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) async => Right([]);

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) async => Right([]);

  @override
  bool hasMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => false;

  @override
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  ) async => Left(UnexpectedFailure());

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) async => Left(UnexpectedFailure());

  @override
  Future<Either<Failure, CostEstimate>> changeLockStatus({
    required String estimationId,
    required bool isLocked,
    required String projectId,
  }) async => Left(UnexpectedFailure());

  @override
  Future<Either<Failure, CostEstimate>> renameEstimation({
    required String estimationId,
    required String newName,
    required String projectId,
  }) async => Left(UnexpectedFailure());

  @override
  void dispose() {}
}
