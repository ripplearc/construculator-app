import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/estimation_test_data_map_factory.dart';

void main() {
  group('AddCostEstimationUseCase', () {
    late AddCostEstimationUseCase useCase;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationName = 'Test Estimation';
    const testUserId = 'test-user-123';
    const testCredentialId = 'test-credential-123';
    const testUserEmail = 'test@example.com';

    void seedUserProfile({String? userId = testUserId}) {
      fakeSupabaseWrapper.addTableData('users', [
        {
          'id': userId,
          'credential_id': testCredentialId,
          'email': testUserEmail,
          'phone': null,
          'first_name': 'Test',
          'last_name': 'User',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': fakeClock.now().toIso8601String(),
          'updated_at': fakeClock.now().toIso8601String(),
          'user_status': 'active',
          'user_preferences': <String, dynamic>{},
        },
      ]);
    }

    void setCurrentUser() {
      fakeSupabaseWrapper.setCurrentUser(
        FakeUser(
          id: testCredentialId,
          email: testUserEmail,
          createdAt: fakeClock.now().toIso8601String(),
          appMetadata: const {},
          userMetadata: const {},
        ),
      );
    }

    void createEstimation() {
      final data = EstimationTestDataMapFactory.createFakeEstimationData(
        estimateName: testEstimationName,
        projectId: testProjectId,
        creatorUserId: testUserId,
      );
      fakeSupabaseWrapper.addTableData('cost_estimates', [data]);
    }

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

    setUpAll(() {
      fakeClock = FakeClockImpl();

      Modular.init(
        EstimationModule(
          AppBootstrap(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
            config: FakeAppConfig(),
            envLoader: FakeEnvLoader(),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;

      useCase = Modular.get<AddCostEstimationUseCase>();
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    test(
      'creates cost estimation successfully with authenticated user',
      () async {
        setCurrentUser();
        seedUserProfile();
        createEstimation();

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
              totalCost: 0,
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
        fakeSupabaseWrapper.setCurrentUser(null);
        seedUserProfile();

        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
        );

        expectAuthenticationError(result);
      },
    );

    test('returns authentication error when user profile is null', () async {
      fakeSupabaseWrapper.shouldThrowOnSelect = true;
      setCurrentUser();

      final result = await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expectAuthenticationError(result);
    });

    test('returns authentication error when user profile is null', () async {
      setCurrentUser();

      final result = await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expectAuthenticationError(result);
    });

    test(
      'returns authentication error when get user profile throws an error',
      () async {
        setCurrentUser();
        fakeSupabaseWrapper.shouldThrowOnSelect = true;

        final result = await useCase(
          estimationName: testEstimationName,
          projectId: testProjectId,
        );

        expectAuthenticationError(result);
      },
    );

    test('returns authentication error when user ID is empty', () async {
      seedUserProfile(userId: '');
      setCurrentUser();

      final result = await useCase(
        estimationName: testEstimationName,
        projectId: testProjectId,
      );

      expectAuthenticationError(result);
    });

    test('returns estimation error when create fails', () async {
      setCurrentUser();
      seedUserProfile();
      createEstimation();

      fakeSupabaseWrapper.shouldThrowOnInsert = true;
      fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.socket;

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
  });
}
