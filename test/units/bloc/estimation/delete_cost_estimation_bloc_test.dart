import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeleteCostEstimationBloc', () {
    late DeleteCostEstimationBloc bloc;
    late FakeCostEstimationRepository fakeRepository;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationId = 'test-estimation-123';
    const testEstimationName = 'Test Estimation';

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
      bloc = DeleteCostEstimationBloc(costEstimationRepository: fakeRepository);
    });

    tearDown(() {
      bloc.close();
      fakeRepository.reset();
    });

    group('Initialization', () {
      test('should start in initial state', () {
        expect(bloc.state, isA<DeleteCostEstimationInitial>());
      });
    });

    group('DeleteCostEstimationRequested', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit in progress then success when estimation is deleted successfully',
        build: () {
          final estimation = fakeRepository.createSampleEstimation(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
          );
          fakeRepository.addProjectEstimation(testProjectId, estimation);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            testEstimationId,
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit in progress then failure when repository returns failure',
        build: () {
          fakeRepository.shouldReturnFailureOnDeleteEstimation = true;
          fakeRepository.deleteEstimationFailureType =
              EstimationErrorType.connectionError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.connectionError,
            ),
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit failure with timeout error when repository returns timeout error',
        build: () {
          fakeRepository.shouldReturnFailureOnDeleteEstimation = true;
          fakeRepository.deleteEstimationFailureType =
              EstimationErrorType.timeoutError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.timeoutError,
            ),
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit failure with parsing error when repository returns parsing error',
        build: () {
          fakeRepository.shouldReturnFailureOnDeleteEstimation = true;
          fakeRepository.deleteEstimationFailureType =
              EstimationErrorType.parsingError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.parsingError,
            ),
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should successfully delete even if estimation does not exist',
        build: () => bloc,
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: 'non-existent-id',
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.notFoundError,
            ),
          ),
        ],
      );
    });

    group('Multiple events handling', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should handle multiple deletion events correctly',
        build: () {
          final estimation1 = fakeRepository.createSampleEstimation(
            id: 'estimation-1',
            projectId: testProjectId,
            estimateName: 'Estimation 1',
          );
          final estimation2 = fakeRepository.createSampleEstimation(
            id: 'estimation-2',
            projectId: testProjectId,
            estimateName: 'Estimation 2',
          );
          fakeRepository.addProjectEstimation(testProjectId, estimation1);
          fakeRepository.addProjectEstimation(testProjectId, estimation2);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            DeleteCostEstimationRequested(
              estimationId: 'estimation-1',
              projectId: testProjectId,
            ),
          );
          bloc.add(
            DeleteCostEstimationRequested(
              estimationId: 'estimation-2',
              projectId: testProjectId,
            ),
          );
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            'estimation-1',
          ),
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            'estimation-2',
          ),
        ],
      );
    });

    group('Repository integration', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should call deleteEstimation with correct ids and succeed',
        build: () {
          final estimation = fakeRepository.createSampleEstimation(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
          );
          fakeRepository.addProjectEstimation(testProjectId, estimation);
          return bloc;
        },
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        verify: (bloc) {
          final calls = fakeRepository.getMethodCallsFor('deleteEstimation');
          expect(calls, hasLength(1));
          expect(calls.first['estimationId'], testEstimationId);
          expect(calls.first['projectId'], testProjectId);
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
        ],
      );
    });
  });
}
