import 'package:construculator/features/estimation/domain/usecases/delete_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeleteCostEstimationUseCase', () {
    late DeleteCostEstimationUseCase useCase;
    late FakeCostEstimationRepository fakeRepository;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationId = 'test-estimation-123';
    const testEstimationName = 'Test Estimation';

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
      useCase = DeleteCostEstimationUseCase(fakeRepository);
    });

    tearDown(() {
      fakeRepository.reset();
    });

    group('Success scenarios', () {
      test('should delete cost estimation successfully', () async {
        // Arrange
        final estimation = fakeRepository.createSampleEstimation(
          id: testEstimationId,
          projectId: testProjectId,
          estimateName: testEstimationName,
        );
        fakeRepository.addProjectEstimation(testProjectId, estimation);

        // Verify estimation exists before deletion
        final estimationsBeforeDelete = await fakeRepository.getEstimations(testProjectId);
        expect(estimationsBeforeDelete, hasLength(1));

        // Act
        final result = await useCase(estimationId: testEstimationId);

        // Assert
        expect(result.isRight(), true);

        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (success) {
            // Verify estimation was deleted
            fakeRepository.getEstimations(testProjectId).then((estimations) {
              expect(estimations, isEmpty);
            });
          },
        );
      });

      test('should call repository with correct estimation ID', () async {
        // Act
        await useCase(estimationId: testEstimationId);

        // Assert
        final methodCalls = fakeRepository.getMethodCallsFor('deleteEstimation');
        expect(methodCalls.length, 1);

        final call = methodCalls.first;
        expect(call['estimationId'], testEstimationId);
      });

      test('should delete only the specified estimation', () async {
        // Arrange
        const estimationId1 = 'estimation-1';
        const estimationId2 = 'estimation-2';

        final estimation1 = fakeRepository.createSampleEstimation(
          id: estimationId1,
          projectId: testProjectId,
          estimateName: 'Estimation 1',
        );

        final estimation2 = fakeRepository.createSampleEstimation(
          id: estimationId2,
          projectId: testProjectId,
          estimateName: 'Estimation 2',
        );

        fakeRepository.addProjectEstimation(testProjectId, estimation1);
        fakeRepository.addProjectEstimation(testProjectId, estimation2);

        // Verify both estimations exist
        final estimationsBeforeDelete = await fakeRepository.getEstimations(testProjectId);
        expect(estimationsBeforeDelete, hasLength(2));

        // Act
        final result = await useCase(estimationId: estimationId1);

        // Assert
        expect(result.isRight(), true);

        final estimationsAfterDelete = await fakeRepository.getEstimations(testProjectId);
        expect(estimationsAfterDelete, hasLength(1));
        expect(estimationsAfterDelete.first.id, estimationId2);
      });

      test('should return success when deleting non-existent estimation', () async {
        // Act
        final result = await useCase(estimationId: 'non-existent-id');

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('Error scenarios', () {
      test('should handle repository exceptions and return appropriate failure', () async {
        // Arrange
        fakeRepository.shouldThrowOnDeleteEstimation = true;
        fakeRepository.deleteEstimationErrorMessage = 'Database connection failed';

        // Act
        final result = await useCase(estimationId: testEstimationId);

        // Assert
        expect(result.isLeft(), true);

        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (success) => fail('Expected failure but got success'),
        );
      });

      test('should handle timeout exceptions', () async {
        // Arrange
        fakeRepository.shouldThrowOnDeleteEstimation = true;
        fakeRepository.deleteEstimationExceptionType = SupabaseExceptionType.timeout;
        fakeRepository.deleteEstimationErrorMessage = 'Request timeout';

        // Act
        final result = await useCase(estimationId: testEstimationId);

        // Assert
        expect(result.isLeft(), true);

        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (success) => fail('Expected failure but got success'),
        );
      });

      test('should handle type exceptions', () async {
        // Arrange
        fakeRepository.shouldThrowOnDeleteEstimation = true;
        fakeRepository.deleteEstimationExceptionType = SupabaseExceptionType.type;

        // Act
        final result = await useCase(estimationId: testEstimationId);

        // Assert
        expect(result.isLeft(), true);

        result.fold(
          (failure) {
            expect(failure, isA<ClientFailure>());
          },
          (success) => fail('Expected failure but got success'),
        );
      });

      test('should handle auth exceptions', () async {
        // Arrange
        fakeRepository.shouldThrowOnDeleteEstimation = true;
        fakeRepository.deleteEstimationExceptionType = SupabaseExceptionType.auth;
        fakeRepository.deleteEstimationErrorMessage = 'Auth error';

        // Act
        final result = await useCase(estimationId: testEstimationId);

        // Assert
        expect(result.isLeft(), true);

        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (success) => fail('Expected failure but got success'),
        );
      });

      test('should handle unknown exceptions', () async {
        // Arrange
        fakeRepository.shouldThrowOnDeleteEstimation = true;
        fakeRepository.deleteEstimationExceptionType = SupabaseExceptionType.unknown;
        fakeRepository.deleteEstimationErrorMessage = 'Unknown error';

        // Act
        final result = await useCase(estimationId: testEstimationId);

        // Assert
        expect(result.isLeft(), true);

        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (success) => fail('Expected failure but got success'),
        );
      });
    });

    group('Edge cases', () {
      test('should handle empty estimation ID', () async {
        // Act
        final result = await useCase(estimationId: '');

        // Assert - Should succeed as repository won't find anything to delete
        expect(result.isRight(), true);
      });

      test('should handle very long estimation ID', () async {
        // Arrange
        final longId = 'A' * 1000;

        // Act
        final result = await useCase(estimationId: longId);

        // Assert
        expect(result.isRight(), true);

        final methodCalls = fakeRepository.getMethodCallsFor('deleteEstimation');
        expect(methodCalls.length, 1);
        expect(methodCalls.first['estimationId'], longId);
      });

      test('should handle special characters in estimation ID', () async {
        // Arrange
        const specialId = 'test-id-with-special-chars-@#\$%^&*()';

        // Act
        final result = await useCase(estimationId: specialId);

        // Assert
        expect(result.isRight(), true);

        final methodCalls = fakeRepository.getMethodCallsFor('deleteEstimation');
        expect(methodCalls.length, 1);
        expect(methodCalls.first['estimationId'], specialId);
      });
    });

    group('Multiple operations', () {
      test('should handle multiple deletions in sequence', () async {
        // Arrange
        const estimationId1 = 'estimation-1';
        const estimationId2 = 'estimation-2';
        const estimationId3 = 'estimation-3';

        final estimation1 = fakeRepository.createSampleEstimation(
          id: estimationId1,
          projectId: testProjectId,
          estimateName: 'Estimation 1',
        );

        final estimation2 = fakeRepository.createSampleEstimation(
          id: estimationId2,
          projectId: testProjectId,
          estimateName: 'Estimation 2',
        );

        final estimation3 = fakeRepository.createSampleEstimation(
          id: estimationId3,
          projectId: testProjectId,
          estimateName: 'Estimation 3',
        );

        fakeRepository.addProjectEstimation(testProjectId, estimation1);
        fakeRepository.addProjectEstimation(testProjectId, estimation2);
        fakeRepository.addProjectEstimation(testProjectId, estimation3);

        // Act
        final result1 = await useCase(estimationId: estimationId1);
        final result2 = await useCase(estimationId: estimationId2);
        final result3 = await useCase(estimationId: estimationId3);

        // Assert
        expect(result1.isRight(), true);
        expect(result2.isRight(), true);
        expect(result3.isRight(), true);

        final remainingEstimations = await fakeRepository.getEstimations(testProjectId);
        expect(remainingEstimations, isEmpty);
      });

      test('should handle deletion of same ID multiple times', () async {
        // Arrange
        final estimation = fakeRepository.createSampleEstimation(
          id: testEstimationId,
          projectId: testProjectId,
          estimateName: testEstimationName,
        );
        fakeRepository.addProjectEstimation(testProjectId, estimation);

        // Act
        final result1 = await useCase(estimationId: testEstimationId);
        final result2 = await useCase(estimationId: testEstimationId);

        // Assert
        expect(result1.isRight(), true);
        expect(result2.isRight(), true); // Should succeed even if already deleted

        final methodCalls = fakeRepository.getMethodCallsFor('deleteEstimation');
        expect(methodCalls.length, 2);
      });
    });
  });
}
