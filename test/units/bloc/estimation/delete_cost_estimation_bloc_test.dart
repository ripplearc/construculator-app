import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/usecases/delete_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeleteCostEstimationBloc', () {
    late DeleteCostEstimationBloc bloc;
    late FakeCostEstimationRepository fakeRepository;
    late DeleteCostEstimationUseCase useCase;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationId = 'test-estimation-123';
    const testEstimationName = 'Test Estimation';

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
      useCase = DeleteCostEstimationUseCase(fakeRepository);
      bloc = DeleteCostEstimationBloc(deleteCostEstimationUseCase: useCase);
    });

    tearDown(() {
      bloc.close();
      fakeRepository.reset();
    });

    group('Initialization', () {
      test('should be initialized with correct dependencies', () {
        expect(bloc, isNotNull);
        expect(bloc.state, isA<DeleteCostEstimationInitial>());
      });

      test('should start in initial state', () {
        expect(bloc.state, isA<DeleteCostEstimationInitial>());
      });
    });

    group('DeleteCostEstimationStarted', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit initial state when started',
        build: () => bloc,
        act: (bloc) => bloc.add(const DeleteCostEstimationStarted()),
        expect: () => [isA<DeleteCostEstimationInitial>()],
      );
    });

    group('DeleteCostEstimationRequested', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit in progress then success when estimation is deleted successfully',
        build: () {
          // Add estimation to repository first
          final estimation = fakeRepository.createSampleEstimation(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
          );
          fakeRepository.addProjectEstimation(testProjectId, estimation);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
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
        'should emit in progress then failure with ServerFailure when repository throws exception',
        build: () {
          fakeRepository.shouldThrowOnDeleteEstimation = true;
          fakeRepository.deleteEstimationErrorMessage =
              'Database connection failed';
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>()
              .having(
                (s) => s.message,
                'message',
                'Failed to delete cost estimation',
              )
              .having(
                (s) => s.failure,
                'failure',
                isA<ServerFailure>(),
              ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit in progress then failure with NetworkFailure when timeout occurs',
        build: () {
          fakeRepository.shouldThrowOnDeleteEstimation = true;
          fakeRepository.deleteEstimationExceptionType =
              SupabaseExceptionType.timeout;
          fakeRepository.deleteEstimationErrorMessage = 'Request timeout';
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>()
              .having(
                (s) => s.message,
                'message',
                'Failed to delete cost estimation',
              )
              .having(
                (s) => s.failure,
                'failure',
                isA<NetworkFailure>(),
              ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit in progress then failure with ClientFailure when type error occurs',
        build: () {
          fakeRepository.shouldThrowOnDeleteEstimation = true;
          fakeRepository.deleteEstimationExceptionType =
              SupabaseExceptionType.type;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>()
              .having(
                (s) => s.message,
                'message',
                'Failed to delete cost estimation',
              )
              .having(
                (s) => s.failure,
                'failure',
                isA<ClientFailure>(),
              ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should successfully delete even if estimation does not exist',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: 'non-existent-id'),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            'non-existent-id',
          ),
        ],
      );
    });

    group('State validation', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should include correct estimation ID in success state',
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
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        verify: (bloc) {
          final successState = bloc.state as DeleteCostEstimationSuccess;
          expect(successState.estimationId, testEstimationId);
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
        ],
      );
    });

    group('Edge cases', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should handle empty estimation ID',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const DeleteCostEstimationRequested(estimationId: '')),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            '',
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should handle very long estimation ID',
        build: () => bloc,
        act: (bloc) {
          final longId = 'A' * 1000;
          return bloc.add(DeleteCostEstimationRequested(estimationId: longId));
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should handle special characters in estimation ID',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(
            estimationId: 'test-id-@#\$%^&*()',
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            'test-id-@#\$%^&*()',
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
            const DeleteCostEstimationRequested(estimationId: 'estimation-1'),
          );
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(
            const DeleteCostEstimationRequested(estimationId: 'estimation-2'),
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

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should handle mixed success and failure events',
        build: () {
          fakeRepository.shouldThrowOnDeleteEstimation = true;
          fakeRepository.deleteEstimationErrorMessage = 'First call fails';

          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const DeleteCostEstimationRequested(
              estimationId: 'failing-estimation',
            ),
          );
          await Future.delayed(const Duration(milliseconds: 10));

          fakeRepository.shouldThrowOnDeleteEstimation = false;

          bloc.add(
            const DeleteCostEstimationRequested(
              estimationId: 'successful-estimation',
            ),
          );
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.message,
            'message',
            'Failed to delete cost estimation',
          ),
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            'successful-estimation',
          ),
        ],
      );
    });

    group('Repository integration', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should actually remove estimation from repository',
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
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        verify: (bloc) async {
          final estimations = await fakeRepository.getEstimations(
            testProjectId,
          );
          expect(estimations, isEmpty);
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should delete only the specified estimation',
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
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: 'estimation-1'),
        ),
        verify: (bloc) async {
          final estimations = await fakeRepository.getEstimations(
            testProjectId,
          );
          expect(estimations, hasLength(1));
          expect(estimations.first.id, 'estimation-2');
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
        ],
      );
    });
  });
}
