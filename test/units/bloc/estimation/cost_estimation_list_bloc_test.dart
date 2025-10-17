import 'package:construculator/features/estimation/domain/usecases/get_estimations_usecase.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../features/estimation/helpers/test_estimation_data_helper.dart';

void main() {
  group('CostEstimationListBloc', () {
    late CostEstimationListBloc bloc;
    late FakeCostEstimationRepository fakeRepository;
    late GetEstimationsUseCase useCase;
    late FakeClockImpl fakeClock;
    const String testProjectId = 'test-project-123';

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
      useCase = GetEstimationsUseCase(fakeRepository);
      bloc = CostEstimationListBloc(
        getEstimationsUseCase: useCase,
      );
    });

    tearDown(() {
      bloc.close();
      fakeRepository.reset();
    });

    group('Initialization tests', () {
      test('should be initialized with correct dependencies', () {
        expect(bloc, isNotNull);
        expect(bloc.state, isA<CostEstimationListInitial>());
      });

      test('should start with initial state and respond to refresh events', () async {
        final testBloc = CostEstimationListBloc(
          getEstimationsUseCase: useCase,
        );
        
        expect(testBloc.state, isA<CostEstimationListInitial>());
        
        testBloc.add(CostEstimationListRefreshEvent(projectId: testProjectId));
        
        await testBloc.stream.firstWhere((state) => 
          state is CostEstimationListEmpty || 
          state is CostEstimationListLoaded || 
          state is CostEstimationListError
        );
        
        expect(testBloc.state, isNot(isA<CostEstimationListInitial>()));
        
        testBloc.close();
      });
    });

    group('Successful loading scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then loaded state when estimations are available',
        build: () {
          final estimations = [
            TestEstimationDataHelper.createFakeEstimation(
              id: 'est-1',
              estimateName: 'Test Estimation 1',
              totalCost: 10000.0,
            ),
            TestEstimationDataHelper.createFakeEstimation(
              id: 'est-2',
              estimateName: 'Test Estimation 2',
              totalCost: 20000.0,
            ),
          ];
          fakeRepository.addProjectEstimations(testProjectId, estimations);
          return CostEstimationListBloc(
            getEstimationsUseCase: useCase,
          );
        },
        act: (bloc) => bloc.add(CostEstimationListRefreshEvent(projectId: testProjectId)),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
            .having((state) => state.estimates.length, 'estimates length', 2)
            .having((state) => state.estimates[0].estimateName, 'first estimate name', 'Test Estimation 1')
            .having((state) => state.estimates[1].estimateName, 'second estimate name', 'Test Estimation 2'),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then empty state when no estimations exist',
        build: () {
          fakeRepository.shouldReturnEmptyList = true;
          return CostEstimationListBloc(
            getEstimationsUseCase: useCase,
          );
        },
        act: (bloc) => bloc.add(CostEstimationListRefreshEvent(projectId: testProjectId)),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListEmpty>(),
        ],
      );

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should handle refresh event and emit correct states',
        build: () {
          final estimations = [
            TestEstimationDataHelper.createFakeEstimation(
              id: 'est-1',
              estimateName: 'Refreshed Estimation',
              totalCost: 15000.0,
            ),
          ];
          fakeRepository.addProjectEstimations(testProjectId, estimations);
          return CostEstimationListBloc(
            getEstimationsUseCase: useCase,
          );
        },
        act: (bloc) => bloc.add(CostEstimationListRefreshEvent(projectId: testProjectId)),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
            .having((state) => state.estimates.length, 'estimates length', 1)
            .having((state) => state.estimates[0].estimateName, 'estimate name', 'Refreshed Estimation'),
        ],
      );
    });

    group('Error handling scenarios', () {
      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should emit loading then error state when use case fails',
        build: () {
          fakeRepository.shouldThrowOnGetEstimations = true;
          fakeRepository.getEstimationsErrorMessage = 'Network error';
          fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.socket;
          return CostEstimationListBloc(
            getEstimationsUseCase: useCase,
          );
        },
        act: (bloc) => bloc.add(CostEstimationListRefreshEvent(projectId: testProjectId)),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListError>()
            .having((state) => state.message, 'error message', 'Failed to load cost estimations')
            .having((state) => state.estimates, 'empty estimates', isEmpty),
        ],
      );

      test('should handle error states correctly', () async {
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsErrorMessage = 'Server error';
        fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.unknown;
        
        final testBloc = CostEstimationListBloc(
          getEstimationsUseCase: useCase,
        );
        
        testBloc.add(CostEstimationListRefreshEvent(projectId: testProjectId));
        
        final errorState = await testBloc.stream.firstWhere((state) => state is CostEstimationListError);
        
        expect(errorState, isA<CostEstimationListError>());
        expect((errorState as CostEstimationListError).message, equals('Failed to load cost estimations'));
        expect(errorState.estimates, isEmpty);
        
        testBloc.close();
      });
    });

    group('Cases with missing values', () {
      test('should handle refresh events without errors', () async {
        final estimations = [
          TestEstimationDataHelper.createFakeEstimation(
            id: 'est-1',
            estimateName: 'Refresh Test',
            totalCost: 7500.0,
          ),
        ];
        fakeRepository.addProjectEstimations(testProjectId, estimations);
        
        final testBloc = CostEstimationListBloc(
          getEstimationsUseCase: useCase,
        );
        
        testBloc.add(CostEstimationListRefreshEvent(projectId: testProjectId));
        
        await testBloc.stream.firstWhere((state) => state is CostEstimationListLoaded);
        
        testBloc.add(CostEstimationListRefreshEvent(projectId: testProjectId));
        
        await testBloc.stream.firstWhere((state) => 
          state is CostEstimationListLoaded || 
          state is CostEstimationListError
        );
        
        expect(testBloc.state, isA<CostEstimationListWithData>());
        final finalState = testBloc.state as CostEstimationListWithData;
        expect(finalState.estimates.length, equals(1));
        expect(finalState.estimates[0].estimateName, equals('Refresh Test'));
        
        testBloc.close();
      });

      blocTest<CostEstimationListBloc, CostEstimationListState>(
        'should handle estimations with null total cost',
        build: () {
          final estimations = [
            TestEstimationDataHelper.createFakeEstimation(
              id: 'est-1',
              estimateName: 'Uncalculated Estimation',
              totalCost: null,
            ),
          ];
          fakeRepository.addProjectEstimations(testProjectId, estimations);
          return CostEstimationListBloc(
            getEstimationsUseCase: useCase,
          );
        },
        act: (bloc) => bloc.add(CostEstimationListRefreshEvent(projectId: testProjectId)),
        expect: () => [
          isA<CostEstimationListLoading>(),
          isA<CostEstimationListLoaded>()
            .having((state) => state.estimates.length, 'estimates length', 1)
            .having((state) => state.estimates[0].totalCost, 'total cost', isNull),
        ],
      );
    });

    group('State transitions', () {
      test('should handle state equality correctly', () {
        const state1 = CostEstimationListInitial();
        const state2 = CostEstimationListInitial();
        expect(state1, equals(state2));
        
        const loading1 = CostEstimationListLoading();
        const loading2 = CostEstimationListLoading();
        expect(loading1, equals(loading2));
      });

      test('should handle refresh events correctly', () async {
        final testBloc = CostEstimationListBloc(
          getEstimationsUseCase: useCase,
        );
        
        expect(testBloc.state, isA<CostEstimationListInitial>());
        
        testBloc.add(CostEstimationListRefreshEvent(projectId: testProjectId));
        
        final nextState = await testBloc.stream.first;
        expect(nextState, isA<CostEstimationListLoading>());
        
        await testBloc.stream.firstWhere((state) => 
          state is CostEstimationListEmpty || 
          state is CostEstimationListLoaded || 
          state is CostEstimationListError
        );
        
        testBloc.close();
      });
    });
  });
}


