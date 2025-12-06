import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddCostEstimationUseCase', () {
    late AddCostEstimationUseCase useCase;
    late FakeCostEstimationRepository fakeRepository;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testCreatorUserId = 'test-user-123';
    const testEstimationName = 'Test Estimation';

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeRepository = FakeCostEstimationRepository(clock: fakeClock);
      useCase = AddCostEstimationUseCase(fakeRepository, fakeClock);
    });

    tearDown(() {
      fakeRepository.reset();
    });

    group('Success scenarios', () {
      test('should create cost estimation with default values', () async {
        // Act
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isRight(), true);
        
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (costEstimation) {
            expect(costEstimation.estimateName, testEstimationName);
            expect(costEstimation.projectId, testProjectId);
            expect(costEstimation.creatorUserId, testCreatorUserId);
            expect(costEstimation.id, isNotEmpty); // ID will be set by the repository
            expect(costEstimation.estimateDescription, isNull);
            expect(costEstimation.totalCost, isNull);
            expect(costEstimation.lockStatus, isA<UnlockedStatus>());
            
            // Check default markup configuration
            expect(costEstimation.markupConfiguration.overallType, MarkupType.overall);
            expect(costEstimation.markupConfiguration.overallValue.type, MarkupValueType.percentage);
            expect(costEstimation.markupConfiguration.overallValue.value, 10.0);
            
            // Check timestamps
            expect(costEstimation.createdAt, isA<DateTime>());
            expect(costEstimation.updatedAt, isA<DateTime>());
            expect(costEstimation.createdAt, equals(costEstimation.updatedAt));
          },
        );
      });

      test('should generate unique IDs for different estimations', () async {
        // Act
        final result1 = await useCase(
          estimationName: 'Estimation 1',
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );
        
        // Add a small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 1));
        
        final result2 = await useCase(
          estimationName: 'Estimation 2',
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result1.isRight(), true);
        expect(result2.isRight(), true);
        
        result1.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (estimation1) {
            result2.fold(
              (failure) => fail('Expected success but got failure: $failure'),
              (estimation2) {
                expect(estimation1.id, isNot(equals(estimation2.id)));
              },
            );
          },
        );
      });

      test('should call repository with correct parameters', () async {
        // Act
        await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        final methodCalls = fakeRepository.getMethodCallsFor('createEstimation');
        expect(methodCalls.length, 1);
        
        final call = methodCalls.first;
        expect(call['estimation']['estimateName'], testEstimationName);
        expect(call['estimation']['projectId'], testProjectId);
        expect(call['estimation']['creatorUserId'], testCreatorUserId);
        expect(call['estimation']['id'], isEmpty); // ID is empty when passed to repository
        expect(call['estimation']['isLocked'], false);
      });
    });

    group('Error scenarios', () {
      test('should handle repository exceptions and return appropriate failure', () async {
        // Arrange
        fakeRepository.shouldThrowOnCreateEstimation = true;
        fakeRepository.createEstimationErrorMessage = 'Database connection failed';

        // Act
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isLeft(), true);
        
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (success) => fail('Expected failure but got success: $success'),
        );
      });

      test('should handle timeout exceptions', () async {
        // Arrange
        fakeRepository.shouldThrowOnCreateEstimation = true;
        fakeRepository.createEstimationExceptionType = SupabaseExceptionType.timeout;
        fakeRepository.createEstimationErrorMessage = 'Request timeout';

        // Act
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isLeft(), true);
        
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (success) => fail('Expected failure but got success: $success'),
        );
      });

      test('should handle type exceptions', () async {
        // Arrange
        fakeRepository.shouldThrowOnCreateEstimation = true;
        fakeRepository.createEstimationExceptionType = SupabaseExceptionType.type;

        // Act
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isLeft(), true);
        
        result.fold(
          (failure) {
            expect(failure, isA<ClientFailure>());
          },
          (success) => fail('Expected failure but got success: $success'),
        );
      });
    });

    group('Default values validation', () {
      test('should set correct default markup configuration', () async {
        // Act
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isRight(), true);
        
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (costEstimation) {
            final markupConfig = costEstimation.markupConfiguration;
            
            expect(markupConfig.overallType, MarkupType.overall);
            expect(markupConfig.overallValue.type, MarkupValueType.percentage);
            expect(markupConfig.overallValue.value, 10.0);
            
            // Granular markup fields should be null for overall type
            expect(markupConfig.materialValueType, isNull);
            expect(markupConfig.materialValue, isNull);
            expect(markupConfig.laborValueType, isNull);
            expect(markupConfig.laborValue, isNull);
            expect(markupConfig.equipmentValueType, isNull);
            expect(markupConfig.equipmentValue, isNull);
          },
        );
      });

      test('should set correct default lock status', () async {
        // Act
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isRight(), true);
        
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (costEstimation) {
            expect(costEstimation.lockStatus, isA<UnlockedStatus>());
            expect(costEstimation.lockStatus.isLocked, false);
          },
        );
      });

      test('should set correct timestamps', () async {
        // Arrange
        final beforeCall = fakeClock.now();
        
        // Act
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isRight(), true);
        
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (costEstimation) {
            expect(costEstimation.createdAt, isA<DateTime>());
            expect(costEstimation.updatedAt, isA<DateTime>());
            expect(costEstimation.createdAt, equals(costEstimation.updatedAt));
            expect(costEstimation.createdAt.isAfter(beforeCall) || costEstimation.createdAt.isAtSameMomentAs(beforeCall), true);
          },
        );
      });
    });

    group('Edge cases', () {
      test('should handle empty estimation name', () async {
        // Act
        final result = await useCase(
          estimationName: '',
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isRight(), true);
        
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (costEstimation) {
            expect(costEstimation.estimateName, '');
          },
        );
      });

      test('should handle very long estimation name', () async {
        // Arrange
        final longName = 'A' * 1000;

        // Act
        final result = await useCase(
          estimationName: longName,
          projectId: testProjectId,
          creatorUserId: testCreatorUserId,
        );

        // Assert
        expect(result.isRight(), true);
        
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (costEstimation) {
            expect(costEstimation.estimateName, longName);
          },
        );
      });
    });
  });
}
