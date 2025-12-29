import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  group('CostEstimationListBloc', () {
    late CostEstimationListBloc bloc;
    late FakeCostEstimationRepository fakeRepository;
    late FakeClockImpl fakeClock;
    const String testProjectId = 'test-project-123';

    setUpAll(() {
      fakeClock = FakeClockImpl();
      final bootstrap = AppBootstrap(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
      );
      Modular.init(_TestModule(bootstrap));
      Modular.replaceInstance<CostEstimationRepository>(
        FakeCostEstimationRepository(clock: fakeClock),
      );

      fakeRepository =
          Modular.get<CostEstimationRepository>()
              as FakeCostEstimationRepository;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      bloc = Modular.get<CostEstimationListBloc>();
    });

    tearDown(() {
      bloc.close();
      fakeRepository.reset();
    });

    group('Successful loading scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then loaded state when estimations are available',
        build: () {
          final estimations = [
            CostEstimate.defaultEstimate(
              id: 'est-1',
              estimateName: 'Test Estimation 1',
              totalCost: 10000.0,
            ),
            CostEstimate.defaultEstimate(
              id: 'est-2',
              estimateName: 'Test Estimation 2',
              totalCost: 20000.0,
            ),
          ];
          fakeRepository.addProjectEstimations(testProjectId, estimations);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationListRefreshEvent(projectId: testProjectId),
        ),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((state) => state.estimates.length, 'estimates length', 2)
              .having((state) => state.estimates, 'estimates', [
                CostEstimate.defaultEstimate(
                  id: 'est-1',
                  estimateName: 'Test Estimation 1',
                  totalCost: 10000.0,
                ),
                CostEstimate.defaultEstimate(
                  id: 'est-2',
                  estimateName: 'Test Estimation 2',
                  totalCost: 20000.0,
                ),
              ]),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then empty state when no estimations exist',
        build: () {
          fakeRepository.shouldReturnEmptyList = true;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationListRefreshEvent(projectId: testProjectId),
        ),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListEmpty>(),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should handle refresh event and emit correct states',
        build: () {
          final estimations = [
            CostEstimate.defaultEstimate(
              id: 'est-1',
              estimateName: 'Refreshed Estimation',
              totalCost: 15000.0,
            ),
          ];
          fakeRepository.addProjectEstimations(testProjectId, estimations);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationListRefreshEvent(projectId: testProjectId),
        ),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((state) => state.estimates.length, 'estimates length', 1)
              .having(
                (state) => state.estimates[0].estimateName,
                'estimate name',
                'Refreshed Estimation',
              ),
        ],
      );
    });

    group('Error handling scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state with connection error when repository returns connection failure',
        build: () {
          fakeRepository.getEstimationsFailureType =
              EstimationErrorType.connectionError;
          fakeRepository.shouldReturnFailureOnGetEstimations = true;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationListRefreshEvent(projectId: testProjectId),
        ),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (state) => state.failure,
                'failure',
                EstimationFailure(
                  errorType: EstimationErrorType.connectionError,
                ),
              )
              .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state with parsing error when repository returns parsing failure',
        build: () {
          fakeRepository.shouldReturnFailureOnGetEstimations = true;
          fakeRepository.getEstimationsFailureType =
              EstimationErrorType.parsingError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationListRefreshEvent(projectId: testProjectId),
        ),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (state) => state.failure,
                'failure',
                EstimationFailure(errorType: EstimationErrorType.parsingError),
              )
              .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state with timeout error when repository returns timeout failure',
        build: () {
          fakeRepository.shouldReturnFailureOnGetEstimations = true;
          fakeRepository.getEstimationsFailureType =
              EstimationErrorType.timeoutError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationListRefreshEvent(projectId: testProjectId),
        ),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (state) => state.failure,
                'failure',
                EstimationFailure(errorType: EstimationErrorType.timeoutError),
              )
              .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );
    });

    group('Edge cases', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should retain existing estimations when refresh returns a failure',
        build: () {
          final estimations = [
            CostEstimate.defaultEstimate(
              id: 'est-prev-1',
              estimateName: 'Previous Estimation',
              totalCost: 3000.0,
            ),
          ];
          fakeRepository.addProjectEstimations(testProjectId, estimations);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const CostEstimationListRefreshEvent(projectId: testProjectId),
          );

          await bloc.stream.firstWhere((s) => s is CostEstimationListLoaded);

          fakeRepository.shouldReturnFailureOnGetEstimations = true;

          bloc.add(
            const CostEstimationListRefreshEvent(projectId: testProjectId),
          );
        },
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
              .having((s) => s.estimates.length, 'estimates length', 1)
              .having(
                (s) => s.estimates[0].estimateName,
                'estimate name',
                'Previous Estimation',
              ),
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (e) => e.failure,
                'failure',
                EstimationFailure(
                  errorType: EstimationErrorType.unexpectedError,
                ),
              )
              .having((e) => e.estimates.length, 'estimates length', 1)
              .having((e) => e.estimates, 'estimates', [
                CostEstimate.defaultEstimate(
                  id: 'est-prev-1',
                  estimateName: 'Previous Estimation',
                  totalCost: 3000.0,
                ),
              ]),
        ],
      );
    });
  });
}

class _TestModule extends Module {
  final AppBootstrap bootstrap;
  _TestModule(this.bootstrap);
  @override
  List<Module> get imports => [ClockTestModule(), EstimationModule(bootstrap)];
}
