import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecentEstimationsBloc bloc;
  late _FakeCostEstimationRepository repository;
  late FakeCurrentProjectNotifier currentProjectNotifier;
  late WatchRecentEstimationsUseCase useCase;

  setUp(() {
    repository = _FakeCostEstimationRepository();
    currentProjectNotifier = FakeCurrentProjectNotifier(
      initialProjectId: 'test_project_id',
    );
    useCase = WatchRecentEstimationsUseCase(
      repository,
      currentProjectNotifier,
    );
    bloc = RecentEstimationsBloc(
      watchRecentEstimationsUseCase: useCase,
      currentProjectNotifier: currentProjectNotifier,
    );
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
      repository.resultToReturn = Right(tEstimations);
      return bloc;
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      RecentEstimationsLoaded(tEstimations),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'emits [RecentEstimationsLoading, RecentEstimationsError] when data stream fails',
    build: () {
      repository.resultToReturn = Left(ServerFailure());
      return bloc;
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      const RecentEstimationsError('ServerFailure()'),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'preserves lastKnownEstimations when re-watching',
    build: () {
      repository.resultToReturn = Right(tEstimations);
      return bloc;
    },
    seed: () => RecentEstimationsLoaded(tEstimations),
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      RecentEstimationsLoading(lastKnownEstimations: tEstimations),
      RecentEstimationsLoaded(tEstimations),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'emits [RecentEstimationsLoading, RecentEstimationsError] when there is no current project',
    build: () {
      currentProjectNotifier.setCurrentProjectId(null);
      return bloc;
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      const RecentEstimationsError(
        'EstimationFailure(EstimationErrorType.unexpectedError)',
      ),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    're-watches when the current project changes after start',
    build: () {
      repository.streamToReturn = Stream.value(Right(tEstimations));
      return bloc;
    },
    act: (bloc) async {
      bloc.add(const RecentEstimationsWatchStarted());
      await Future<void>.delayed(Duration.zero);
      currentProjectNotifier.setCurrentProjectId('another_project');
    },
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      RecentEstimationsLoaded(tEstimations),
      RecentEstimationsLoading(lastKnownEstimations: tEstimations),
      RecentEstimationsLoaded(tEstimations),
    ],
  );
}

class _FakeCostEstimationRepository implements CostEstimationRepository {
  Either<Failure, List<CostEstimate>> resultToReturn =
      const Right<Failure, List<CostEstimate>>([]);

  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => Stream.value(resultToReturn);

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
