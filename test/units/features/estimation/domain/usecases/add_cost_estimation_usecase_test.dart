import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddCostEstimationUseCase', () {
    late AddCostEstimationUseCase useCase;
    late FakeCostEstimationRepository fakeCostEstimationRepository;
    late FakeAuthRepository fakeAuthRepository;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationName = 'Test Estimation';
    const testUserId = 'test-user-123';
    const testCredentialId = 'test-credential-123';
    const testUserEmail = 'test@example.com';

    UserCredential createCredential() => UserCredential(
      id: testCredentialId,
      email: testUserEmail,
      metadata: {},
      createdAt: fakeClock.now(),
    );

    User createUser({String? id = testUserId}) => User(
      id: id,
      email: testUserEmail,
      credentialId: testCredentialId,
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'Developer',
      userStatus: UserProfileStatus.active,
      userPreferences: {},
      createdAt: fakeClock.now(),
      updatedAt: fakeClock.now(),
    );

    void expectAuthenticationError(Either<Failure, CostEstimate> result) {
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<EstimationFailure>());
        expect(
          (failure as EstimationFailure).errorType,
          EstimationErrorType.authenticationError,
        );
      }, (estimation) => fail('Expected failure but got success'));
    }

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeCostEstimationRepository = FakeCostEstimationRepository(
        clock: fakeClock,
      );
      fakeAuthRepository = FakeAuthRepository(clock: fakeClock);

      useCase = AddCostEstimationUseCase(
        fakeCostEstimationRepository,
        fakeAuthRepository,
        fakeClock,
      );

      fakeAuthRepository.setCurrentCredentials(createCredential());
      fakeAuthRepository.setUserProfile(createUser());
    });

    test(
      'creates cost estimation successfully with authenticated user',
      () async {
        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (estimation) {
            final expectedEstimation = CostEstimate(
              id: estimation.id,
              projectId: testProjectId,
              estimateName: testEstimationName,
              estimateDescription: null,
              creatorUserId: testUserId,
              markupConfiguration: MarkupConfiguration(
                overallType: MarkupType.overall,
                overallValue: MarkupValue(
                  type: MarkupValueType.percentage,
                  value: 0.0,
                ),
              ),
              totalCost: null,
              lockStatus: const UnlockedStatus(),
              createdAt: fakeClock.now(),
              updatedAt: fakeClock.now(),
            );
            expect(estimation, expectedEstimation);
          },
        );
      },
    );

    test(
      'returns authentication error when user credentials are null',
      () async {
        fakeAuthRepository.setAuthResponse(succeed: false);

        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
        );

        expectAuthenticationError(result);
      },
    );

    test('returns authentication error when user profile is null', () async {
      fakeAuthRepository.returnNullUserProfile = true;

      final result = await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expectAuthenticationError(result);
    });

    test('returns authentication error when user ID is null', () async {
      fakeAuthRepository.setCurrentCredentials(createCredential());
      fakeAuthRepository.setUserProfile(createUser(id: null));

      final result = await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expectAuthenticationError(result);
    });

    test('returns authentication error when user ID is empty', () async {
      fakeAuthRepository.setCurrentCredentials(createCredential());
      fakeAuthRepository.setUserProfile(createUser(id: ''));

      final result = await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expectAuthenticationError(result);
    });

    test('returns estimation error when repository fails', () async {
      fakeCostEstimationRepository.shouldReturnFailureOnCreateEstimation = true;
      fakeCostEstimationRepository.createEstimationFailureType =
          EstimationErrorType.connectionError;

      final result = await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<EstimationFailure>());
        expect(
          (failure as EstimationFailure).errorType,
          EstimationErrorType.connectionError,
        );
      }, (estimation) => fail('Expected failure but got success'));
    });

    test('calls auth repository to get credentials', () async {
      fakeAuthRepository.getCurrentUserCallCount = 0;

      await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expect(fakeAuthRepository.getCurrentUserCallCount, 1);
    });

    test(
      'calls auth repository to get user profile with credential ID',
      () async {
        fakeAuthRepository.getUserProfileCalls.clear();

        await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
        );

        expect(fakeAuthRepository.getUserProfileCalls.length, 1);
        expect(fakeAuthRepository.getUserProfileCalls.first, testCredentialId);
      },
    );
  });
}
