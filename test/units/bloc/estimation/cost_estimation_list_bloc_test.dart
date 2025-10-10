import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
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

    tearDown(() {
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
              .having(
                (state) => state.estimates[0].estimateName,
                'first estimate name',
                'Test Estimation 1',
              )
              .having(
                (state) => state.estimates[1].estimateName,
                'second estimate name',
                'Test Estimation 2',
              ),
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
        'should emit loading then error state when use case fails',
        build: () {
          fakeRepository.shouldThrowOnGetEstimations = true;
          fakeRepository.getEstimationsErrorMessage = 'Network error';
          fakeRepository.getEstimationsExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationListRefreshEvent(projectId: testProjectId),
        ),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (state) => state.message,
                'error message',
                'Failed to load cost estimations',
              )
              .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );
    });

    group('Edge cases', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should retain existing estimations if present when refresh encounters an error',
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

          fakeRepository.shouldThrowOnGetEstimations = true;

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
                'name',
                'Previous Estimation',
              ),
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
              .having(
                (e) => e.message,
                'error message',
                'Failed to load cost estimations',
              )
              .having((e) => e.estimates.length, 'estimates length', 1)
              .having(
                (e) => e.estimates[0].estimateName,
                'name',
                'Previous Estimation',
              ),
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
