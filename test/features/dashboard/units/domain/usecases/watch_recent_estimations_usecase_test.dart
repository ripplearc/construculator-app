import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchRecentEstimationsUseCase', () {
    late _FakeCostEstimationRepository repository;
    late WatchRecentEstimationsUseCase useCase;

    setUp(() {
      repository = _FakeCostEstimationRepository();
      useCase = WatchRecentEstimationsUseCase(repository);
    });

    test(
      'delegates to watchEstimations with updatedAt descending and requested limit',
      () async {
        const params = RecentEstimationsParams(
          projectId: 'project-123',
          limit: 3,
        );
        const expectedResult = Right<Failure, List<CostEstimate>>([]);
        repository.streamToReturn = Stream.value(expectedResult);

        final resultStream = useCase(params);

        await expectLater(resultStream, emits(expectedResult));
        expect(repository.lastProjectId, 'project-123');
        expect(repository.lastSortBy, EstimationSortOption.updatedAt);
        expect(repository.lastAscending, isFalse);
        expect(repository.lastLimit, 3);
      },
    );

    test('uses the default limit of 5 when not provided', () async {
      const params = RecentEstimationsParams(projectId: 'project-456');
      const expectedResult = Right<Failure, List<CostEstimate>>([]);
      repository.streamToReturn = Stream.value(expectedResult);

      final resultStream = useCase(params);

      await expectLater(resultStream, emits(expectedResult));
      expect(repository.lastProjectId, 'project-456');
      expect(repository.lastSortBy, EstimationSortOption.updatedAt);
      expect(repository.lastAscending, isFalse);
      expect(repository.lastLimit, 5);
    });
  });
}

class _FakeCostEstimationRepository implements CostEstimationRepository {
  Stream<Either<Failure, List<CostEstimate>>> streamToReturn =
      const Stream.empty();

  String? lastProjectId;
  EstimationSortOption? lastSortBy;
  bool? lastAscending;
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
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) => throw UnimplementedError();

  @override
  void dispose() {}

  @override
  Future<Either<Failure, List<CostEstimate>>> fetchInitialEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => throw UnimplementedError();

  @override
  bool hasMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, CostEstimate>> renameEstimation({
    required String estimationId,
    required String newName,
    required String projectId,
  }) => throw UnimplementedError();
}
