import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecentEstimationsBloc bloc;
  late _FakeCostEstimationRepository repository;
  late WatchRecentEstimationsUseCase useCase;

  setUp(() {
    repository = _FakeCostEstimationRepository();
    useCase = WatchRecentEstimationsUseCase(repository);
    bloc = RecentEstimationsBloc(watchRecentEstimationsUseCase: useCase);
  });

  final tDate = DateTime.now();
  final tEstimations = [
    CostEstimate.defaultEstimate(
      id: '1',
      projectId: 'test_project_id',
      estimateName: 'Test Estimate',
      totalCost: 100.0,
      createdAt: tDate,
      updatedAt: tDate,
    ),
  ];

  test(
    'initial state should be RecentEstimationsLoading with null estimations',
    () {
      expect(bloc.state, const RecentEstimationsLoading());
    },
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'emits [RecentEstimationsLoading, RecentEstimationsLoaded] when data streams successfully',
    build: () {
      repository.streamToReturn = Stream.value(Right(tEstimations));
      return bloc;
    },
    act: (bloc) =>
        bloc.add(const RecentEstimationsWatchStarted('test_project_id')),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      RecentEstimationsLoaded(tEstimations),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'emits [RecentEstimationsLoading, RecentEstimationsError] when data stream fails',
    build: () {
      repository.streamToReturn = Stream.value(Left(ServerFailure()));
      return bloc;
    },
    act: (bloc) =>
        bloc.add(const RecentEstimationsWatchStarted('test_project_id')),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      const RecentEstimationsError('ServerFailure()'),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'preserves lastKnownEstimations when re-watching',
    build: () {
      repository.streamToReturn = Stream.value(Right(tEstimations));
      return bloc;
    },
    seed: () => RecentEstimationsLoaded(tEstimations),
    act: (bloc) =>
        bloc.add(const RecentEstimationsWatchStarted('another_project')),
    expect: () => [
      RecentEstimationsLoading(lastKnownEstimations: tEstimations),
      RecentEstimationsLoaded(tEstimations),
    ],
  );
}

class _FakeCostEstimationRepository implements CostEstimationRepository {
  Stream<Either<Failure, List<CostEstimate>>> streamToReturn =
      const Stream.empty();

  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => streamToReturn;

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
