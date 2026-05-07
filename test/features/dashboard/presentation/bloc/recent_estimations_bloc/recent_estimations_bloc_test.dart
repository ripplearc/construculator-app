import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecentEstimationsBloc bloc;
  late FakeCostEstimationRepository repository;
  late FakeCurrentProjectNotifier currentProjectNotifier;

  setUpAll(() {
    Modular.init(_RecentEstimationsBlocTestModule());
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    repository =
        Modular.get<CostEstimationRepository>() as FakeCostEstimationRepository;
    currentProjectNotifier =
        Modular.get<CurrentProjectNotifier>() as FakeCurrentProjectNotifier;
    repository.streamToReturn = const Stream.empty();
    currentProjectNotifier.setCurrentProjectId('test_project_id');
    bloc = Modular.get<RecentEstimationsBloc>();
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
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
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
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
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
}

class _RecentEstimationsBlocTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<CostEstimationRepository>(
      () => FakeCostEstimationRepository(),
    );
    i.addLazySingleton<CurrentProjectNotifier>(
      () => FakeCurrentProjectNotifier(initialProjectId: 'test_project_id'),
    );
    i.add<WatchRecentEstimationsUseCase>(
      () => WatchRecentEstimationsUseCase(i(), i()),
    );
    i.add<RecentEstimationsBloc>(
      () => RecentEstimationsBloc(watchRecentEstimationsUseCase: i()),
    );
  }
}
