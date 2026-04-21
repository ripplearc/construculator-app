import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchRecentEstimationsUseCase extends Mock
    implements WatchRecentEstimationsUseCase {}

void main() {
  late RecentEstimationsBloc bloc;
  late MockWatchRecentEstimationsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockWatchRecentEstimationsUseCase();
    bloc = RecentEstimationsBloc(watchRecentEstimationsUseCase: mockUseCase);
  });

  setUpAll(() {
    registerFallbackValue(
      const RecentEstimationsParams(projectId: 'test_project_id'),
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
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) => Stream.value(Right(tEstimations)));
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
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) => Stream.value(Left(ServerFailure())));
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
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) => Stream.value(Right(tEstimations)));
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
