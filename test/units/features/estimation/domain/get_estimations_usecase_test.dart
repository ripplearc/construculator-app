import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/usecases/get_estimations_usecase.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GetEstimationsUseCase', () {
    late GetEstimationsUseCase useCase;
    late FakeCostEstimationRepository fakeRepository;
    late FakeClockImpl fakeClock;

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
      useCase = GetEstimationsUseCase(fakeRepository);
    });

    tearDown(() {
      fakeRepository.reset();
    });

    group('Success scenarios', () {
      test('should return estimations when repository returns data', () async {
        // Arrange
        const projectId = 'test-project-123';
        final estimations = [
          fakeRepository.createSampleEstimation(
            projectId: projectId,
            estimateName: 'Test Estimation 1',
            totalCost: 10000.0,
          ),
          fakeRepository.createSampleEstimation(
            projectId: projectId,
            estimateName: 'Test Estimation 2',
            totalCost: 20000.0,
          ),
        ];
        fakeRepository.addProjectEstimations(projectId, estimations);

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (returnedEstimations) {
            expect(returnedEstimations, hasLength(2));
            expect(returnedEstimations[0].estimateName, equals('Test Estimation 1'));
            expect(returnedEstimations[0].totalCost, equals(10000.0));
            expect(returnedEstimations[1].estimateName, equals('Test Estimation 2'));
            expect(returnedEstimations[1].totalCost, equals(20000.0));
          },
        );
      });

      test('should return empty list when repository returns empty list', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldReturnEmptyList = true;

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (estimations) => expect(estimations, isEmpty),
        );
      });

      test('should return estimations with different markup configurations', () async {
        // Arrange
        const projectId = 'test-project-123';
        final overallMarkupEstimation = fakeRepository.createSampleOverallMarkupEstimation(
          projectId: projectId,
          estimateName: 'Overall Markup Estimation',
          overallMarkupValue: 25.0,
        );
        final granularMarkupEstimation = fakeRepository.createSampleGranularMarkupEstimation(
          projectId: projectId,
          estimateName: 'Granular Markup Estimation',
          materialMarkupValue: 15.0,
          laborMarkupValue: 30.0,
          equipmentMarkupValue: 20.0,
        );
        fakeRepository.addProjectEstimations(projectId, [
          overallMarkupEstimation,
          granularMarkupEstimation,
        ]);

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (estimations) {
            expect(estimations, hasLength(2));
            
            // Check overall markup estimation
            final overallEstimation = estimations.firstWhere(
              (e) => e.estimateName == 'Overall Markup Estimation',
            );
            expect(overallEstimation.markupConfiguration.overallType, equals(MarkupType.overall));
            expect(overallEstimation.markupConfiguration.overallValue.value, equals(25.0));
            
            // Check granular markup estimation
            final granularEstimation = estimations.firstWhere(
              (e) => e.estimateName == 'Granular Markup Estimation',
            );
            expect(granularEstimation.markupConfiguration.overallType, equals(MarkupType.granular));
            expect(granularEstimation.markupConfiguration.materialValue?.value, equals(15.0));
            expect(granularEstimation.markupConfiguration.laborValue?.value, equals(30.0));
            expect(granularEstimation.markupConfiguration.equipmentValue?.value, equals(20.0));
          },
        );
      });
    });

    group('Failure scenarios', () {
      test('should return ServerFailure when repository throws ServerException', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsErrorMessage = 'Database connection failed';

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (estimations) => fail('Expected failure but got success: $estimations'),
        );
      });

      test('should return NetworkFailure when repository throws timeout exception', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.timeout;
        fakeRepository.getEstimationsErrorMessage = 'Request timeout';

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (estimations) => fail('Expected failure but got success: $estimations'),
        );
      });

      test('should return ClientFailure when repository throws type exception', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.type;

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ClientFailure>());
          },
          (estimations) => fail('Expected failure but got success: $estimations'),
        );
      });

      test('should return NetworkFailure when repository throws NetworkException', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.socket;
        fakeRepository.getEstimationsErrorMessage = 'Network connection lost';

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (estimations) => fail('Expected failure but got success: $estimations'),
        );
      });

      test('should return ClientFailure when repository throws ClientException', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.postgrest;
        fakeRepository.getEstimationsErrorMessage = 'Invalid request parameters';

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ClientFailure>());
          },
          (estimations) => fail('Expected failure but got success: $estimations'),
        );
      });

      test('should return ServerFailure when repository throws unknown exception', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldThrowOnGetEstimations = true;
        fakeRepository.getEstimationsExceptionType = SupabaseExceptionType.unknown;
        fakeRepository.getEstimationsErrorMessage = 'Unknown error occurred';

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (estimations) => fail('Expected failure but got success: $estimations'),
        );
      });

      test('should return UnexpectedFailure when repository throws completely unexpected exception', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.shouldThrowOnGetEstimations = true;

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
          },
          (estimations) => fail('Expected failure but got success: $estimations'),
        );
      });
    });

    group('Repository interaction', () {
      test('should call repository with correct project ID', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.addProjectEstimations(projectId, []);

        // Act
        await useCase.call(projectId);

        // Assert
        final methodCalls = fakeRepository.getMethodCallsFor('getEstimations');
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first['projectId'], equals(projectId));
      });

      test('should call repository only once per use case call', () async {
        // Arrange
        const projectId = 'test-project-123';
        fakeRepository.addProjectEstimations(projectId, []);

        // Act
        await useCase.call(projectId);

        // Assert
        final methodCalls = fakeRepository.getMethodCalls();
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first['method'], equals('getEstimations'));
      });

      test('should handle multiple calls with different project IDs', () async {
        // Arrange
        const projectId1 = 'test-project-123';
        const projectId2 = 'test-project-456';
        fakeRepository.addProjectEstimations(projectId1, []);
        fakeRepository.addProjectEstimations(projectId2, []);

        // Act
        await useCase.call(projectId1);
        await useCase.call(projectId2);

        // Assert
        final methodCalls = fakeRepository.getMethodCallsFor('getEstimations');
        expect(methodCalls, hasLength(2));
        expect(methodCalls[0]['projectId'], equals(projectId1));
        expect(methodCalls[1]['projectId'], equals(projectId2));
      });
    });

    group('Edge cases', () {
      test('should handle default total cost in estimations', () async {
        // Arrange
        const projectId = 'test-project-123';
        final estimationWithDefaultCost = fakeRepository.createSampleEstimation(
          projectId: projectId,
          estimateName: 'Estimation with default cost',
        );
        fakeRepository.addProjectEstimations(projectId, [estimationWithDefaultCost]);

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (estimations) {
            expect(estimations, hasLength(1));
            expect(estimations.first.totalCost, equals(50000.0)); // Default value from fake
          },
        );
      });

      test('should handle estimation with default description', () async {
        // Arrange
        const projectId = 'test-project-123';
        final estimationWithDefaultDescription = fakeRepository.createSampleEstimation(
          projectId: projectId,
          estimateName: 'Estimation with default description',
        );
        fakeRepository.addProjectEstimations(projectId, [estimationWithDefaultDescription]);

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (estimations) {
            expect(estimations, hasLength(1));
            expect(estimations.first.estimateDescription, equals('Test estimation description')); // Default value from fake
          },
        );
      });

      test('should preserve estimation timestamps', () async {
        // Arrange
        const projectId = 'test-project-123';
        final createdAt = DateTime(2023, 1, 1, 10, 0, 0);
        final updatedAt = DateTime(2023, 1, 2, 15, 30, 0);
        fakeClock.set(createdAt);
        final estimation = fakeRepository.createSampleEstimation(
          projectId: projectId,
          estimateName: 'Estimation with specific timestamps',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        fakeRepository.addProjectEstimations(projectId, [estimation]);

        // Act
        final result = await useCase.call(projectId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (estimations) {
            expect(estimations, hasLength(1));
            expect(estimations.first.createdAt, equals(createdAt));
            expect(estimations.first.updatedAt, equals(updatedAt));
          },
        );
      });
    });
  });
}
