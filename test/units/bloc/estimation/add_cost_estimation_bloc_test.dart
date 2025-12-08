import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddCostEstimationBloc', () {
    late AddCostEstimationBloc bloc;
    late FakeCostEstimationRepository fakeRepository;
    late AddCostEstimationUseCase useCase;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testCreatorUserId = 'test-user-123';
    const testEstimationName = 'Test Estimation';

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
      useCase = AddCostEstimationUseCase(fakeRepository, fakeClock);
      bloc = AddCostEstimationBloc(addCostEstimationUseCase: useCase);
    });

    tearDown(() {
      bloc.close();
      fakeRepository.reset();
    });

    group('Initialization', () {
      test('should be initialized with correct dependencies', () {
        expect(bloc, isNotNull);
        expect(bloc.state, isA<AddCostEstimationInitial>());
      });

      test('should start in initial state', () {
        expect(bloc.state, isA<AddCostEstimationInitial>());
      });
    });

    group('AddCostEstimationStarted', () {
      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should emit initial state when started',
        build: () => bloc,
        act: (bloc) => bloc.add(const AddCostEstimationStarted()),
        expect: () => [isA<AddCostEstimationInitial>()],
      );
    });

    group('AddCostEstimationSubmitted', () {
      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should emit in progress then success when estimation is created successfully',
        build: () => bloc,
        act: (bloc) => bloc.add(const AddCostEstimationSubmitted(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>()
              .having((s) => s.costEstimation.estimateName, 'costEstimation.estimateName', testEstimationName)
              .having((s) => s.costEstimation.projectId, 'costEstimation.projectId', testProjectId)
              .having((s) => s.costEstimation.creatorUserId, 'costEstimation.creatorUserId', testCreatorUserId),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should emit in progress then failure when repository throws exception',
        build: () {
          fakeRepository.shouldThrowOnCreateEstimation = true;
          fakeRepository.createEstimationErrorMessage = 'Database connection failed';
          return bloc;
        },
        act: (bloc) => bloc.add(const AddCostEstimationSubmitted(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>()
              .having((s) => s.message, 'message', 'Failed to create cost estimation'),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should emit in progress then failure when timeout occurs',
        build: () {
          fakeRepository.shouldThrowOnCreateEstimation = true;
          fakeRepository.createEstimationExceptionType = SupabaseExceptionType.timeout;
          fakeRepository.createEstimationErrorMessage = 'Request timeout';
          return bloc;
        },
        act: (bloc) => bloc.add(const AddCostEstimationSubmitted(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>()
              .having((s) => s.message, 'message', 'Failed to create cost estimation'),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should emit in progress then failure when type error occurs',
        build: () {
          fakeRepository.shouldThrowOnCreateEstimation = true;
          fakeRepository.createEstimationExceptionType = SupabaseExceptionType.type;
          return bloc;
        },
        act: (bloc) => bloc.add(const AddCostEstimationSubmitted(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>(),
        ],
      );
    });

    group('AddCostEstimationRetried', () {
      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should emit in progress then success when retry succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const AddCostEstimationRetried(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>()
              .having((s) => s.costEstimation.estimateName, 'costEstimation.estimateName', testEstimationName)
              .having((s) => s.costEstimation.projectId, 'costEstimation.projectId', testProjectId)
              .having((s) => s.costEstimation.creatorUserId, 'costEstimation.creatorUserId', testCreatorUserId),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should emit in progress then failure when retry fails',
        build: () {
          fakeRepository.shouldThrowOnCreateEstimation = true;
          fakeRepository.createEstimationErrorMessage = 'Retry failed';
          return bloc;
        },
        act: (bloc) => bloc.add(const AddCostEstimationRetried(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>()
              .having((s) => s.message, 'message', 'Failed to create cost estimation'),
        ],
      );
    });

    group('State validation', () {
      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should create estimation with correct default values',
        build: () => bloc,
        act: (bloc) => bloc.add(const AddCostEstimationSubmitted(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        verify: (bloc) {
          final successState = bloc.state as AddCostEstimationSuccess;
          final costEstimation = successState.costEstimation;
          
          expect(costEstimation.estimateName, testEstimationName);
          expect(costEstimation.projectId, testProjectId);
          expect(costEstimation.creatorUserId, testCreatorUserId);
          expect(costEstimation.id, isNotEmpty);
          expect(costEstimation.estimateDescription, isNull);
          expect(costEstimation.totalCost, isNull);
          
          expect(costEstimation.lockStatus, isA<UnlockedStatus>());
          expect(costEstimation.lockStatus.isLocked, false);
          
          expect(costEstimation.markupConfiguration.overallType, MarkupType.overall);
          expect(costEstimation.markupConfiguration.overallValue.type, MarkupValueType.percentage);
          expect(costEstimation.markupConfiguration.overallValue.value, 0.0);
          
          expect(costEstimation.createdAt, isA<DateTime>());
          expect(costEstimation.updatedAt, isA<DateTime>());
          expect(costEstimation.createdAt, equals(costEstimation.updatedAt));
        },
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>(),
        ],
      );
    });

    group('Edge cases with missing values', () {
      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should handle empty estimation name',
        build: () => bloc,
        act: (bloc) => bloc.add(const AddCostEstimationSubmitted(
          estimationName: '',
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        )),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>()
              .having((s) => s.costEstimation.estimateName, 'costEstimation.estimateName', ''),
        ],
      );
    });

    group('Multiple events handling', () {
      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should handle multiple submitted events correctly',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const AddCostEstimationSubmitted(
            estimationName: 'First Estimation',
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(const AddCostEstimationSubmitted(
            estimationName: 'Second Estimation',
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ));
        },
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>()
              .having((s) => s.costEstimation.estimateName, 'costEstimation.estimateName', 'First Estimation'),
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>()
              .having((s) => s.costEstimation.estimateName, 'costEstimation.estimateName', 'Second Estimation'),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'should handle mixed success and failure events',
        build: () {
          fakeRepository.shouldThrowOnCreateEstimation = true;
          fakeRepository.createEstimationErrorMessage = 'First call fails';
          
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const AddCostEstimationSubmitted(
            estimationName: 'Failing Estimation',
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
          
          fakeRepository.shouldThrowOnCreateEstimation = false;
          
          bloc.add(const AddCostEstimationSubmitted(
            estimationName: 'Successful Estimation',
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ));
        },
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>()
              .having((s) => s.message, 'message', 'Failed to create cost estimation'),
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>()
              .having((s) => s.costEstimation.estimateName, 'costEstimation.estimateName', 'Successful Estimation'),
        ],
      );
    });
  });
}
