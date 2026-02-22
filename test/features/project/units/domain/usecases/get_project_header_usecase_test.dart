import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GetProjectHeaderUseCase', () {
    late GetProjectHeaderUseCase useCase;
    late FakeProjectRepository fakeProjectRepository;
    late FakeAuthRepository fakeAuthRepository;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testUserId = 'test-user-123';
    const testCredentialId = 'test-credential-123';
    const testUserEmail = 'test@example.com';

    late Project testProject;
    late User testUser;
    late UserCredential testCredential;

    setUpAll(() {
      fakeClock = FakeClockImpl();
      fakeProjectRepository = FakeProjectRepository();
      fakeAuthRepository = FakeAuthRepository(clock: fakeClock);

      Modular.init(
        ProjectModule(
          AppBootstrap(
            envLoader: FakeEnvLoader(),
            config: FakeAppConfig(),
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );

      Modular.replaceInstance<ProjectRepository>(fakeProjectRepository);
      Modular.replaceInstance<AuthRepository>(fakeAuthRepository);

      useCase = Modular.get<GetProjectHeaderUseCase>();
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      testProject = Project(
        id: testProjectId,
        projectName: 'Test Project',
        description: 'A test project',
        creatorUserId: testUserId,
        owningCompanyId: 'company-123',
        exportFolderLink: 'https://example.com/export',
        exportStorageProvider: StorageProvider.googleDrive,
        createdAt: fakeClock.now(),
        updatedAt: fakeClock.now(),
        status: ProjectStatus.active,
      );

      testUser = User(
        id: testUserId,
        credentialId: testCredentialId,
        email: testUserEmail,
        phone: null,
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        profilePhotoUrl: 'https://example.com/avatar.jpg',
        createdAt: fakeClock.now(),
        updatedAt: fakeClock.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: const {},
      );

      testCredential = UserCredential(
        id: testCredentialId,
        email: testUserEmail,
        metadata: const {},
        createdAt: fakeClock.now(),
      );
    });

    tearDown(() {
      fakeProjectRepository.reset();
      fakeAuthRepository.reset();
    });

    test(
      'returns ProjectHeaderData with project and user profile when both exist',
      () async {
        fakeProjectRepository.addProject(testProjectId, testProject);
        fakeAuthRepository.setCurrentCredentials(testCredential);
        fakeAuthRepository.setUserProfile(testUser);

        final result = await useCase(testProjectId);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (headerData) {
            expect(headerData.project, testProject);
            expect(headerData.userProfile, testUser);
            expect(headerData.userAvatarUrl, testUser.profilePhotoUrl);
          },
        );
      },
    );

    test(
      'returns ProjectHeaderData with project and null user profile when credentials are null',
      () async {
        fakeProjectRepository.addProject(testProjectId, testProject);

        final result = await useCase(testProjectId);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (headerData) {
            expect(headerData.project, testProject);
            expect(headerData.userProfile, null);
            expect(headerData.userAvatarUrl, null);
          },
        );
      },
    );

    test(
      'returns ProjectHeaderData with project and null user profile when user profile does not exist',
      () async {
        fakeProjectRepository.addProject(testProjectId, testProject);
        fakeAuthRepository.setCurrentCredentials(testCredential);
        fakeAuthRepository.returnNullUserProfile = true;

        final result = await useCase(testProjectId);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (headerData) {
            expect(headerData.project, testProject);
            expect(headerData.userProfile, null);
            expect(headerData.userAvatarUrl, null);
          },
        );
      },
    );

    test(
      'returns NetworkFailure when project repository throws TimeoutException',
      () async {
        fakeProjectRepository.shouldThrowOnGetProject = true;
        fakeProjectRepository.getProjectExceptionType =
            SupabaseExceptionType.timeout;
        fakeProjectRepository.getProjectErrorMessage = 'Network timeout';

        final result = await useCase(testProjectId);

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<NetworkFailure>());
        }, (headerData) => fail('Expected failure but got success'));
      },
    );

    test(
      'returns ServerFailure when project repository throws ServerException',
      () async {
        fakeProjectRepository.shouldThrowOnGetProject = true;
        fakeProjectRepository.getProjectExceptionType =
            SupabaseExceptionType.socket;
        fakeProjectRepository.getProjectErrorMessage = 'Server error';

        final result = await useCase(testProjectId);

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
        }, (headerData) => fail('Expected failure but got success'));
      },
    );

    test(
      'returns ServerFailure when auth repository throws ServerException on getUserProfile',
      () async {
        fakeProjectRepository.addProject(testProjectId, testProject);
        fakeAuthRepository.setCurrentCredentials(testCredential);
        fakeAuthRepository.shouldThrowOnGetUserProfile = true;
        fakeAuthRepository.exceptionMessage = 'Database error';

        final result = await useCase(testProjectId);

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
        }, (headerData) => fail('Expected failure but got success'));
      },
    );

    test(
      'returns ServerFailure when auth repository throws ServerException on getCurrentCredentials',
      () async {
        fakeProjectRepository.addProject(testProjectId, testProject);
        fakeAuthRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Auth error',
        );

        final result = await useCase(testProjectId);

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
        }, (headerData) => fail('Expected failure but got success'));
      },
    );

    test(
      'returns UnexpectedFailure when an unexpected exception occurs',
      () async {
        fakeProjectRepository.shouldThrowOnGetProject = true;
        fakeProjectRepository.getProjectExceptionType =
            SupabaseExceptionType.type;

        final result = await useCase(testProjectId);

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<UnexpectedFailure>());
        }, (headerData) => fail('Expected failure but got success'));
      },
    );

    test(
      'fetches user profile using credential id when credentials are available',
      () async {
        fakeProjectRepository.addProject(testProjectId, testProject);
        fakeAuthRepository.setCurrentCredentials(testCredential);
        fakeAuthRepository.setUserProfile(testUser);

        await useCase(testProjectId);

        expect(fakeAuthRepository.getUserProfileCalls.length, 1);
        expect(fakeAuthRepository.getUserProfileCalls.first, testCredentialId);
      },
    );

    test('does not fetch user profile when credentials are null', () async {
      fakeProjectRepository.addProject(testProjectId, testProject);
      await useCase(testProjectId);
      expect(fakeAuthRepository.getUserProfileCalls.isEmpty, true);
    });

    test(
      'calls project repository getProject with correct project id',
      () async {
        fakeProjectRepository.addProject(testProjectId, testProject);

        await useCase(testProjectId);

        final methodCalls = fakeProjectRepository.getMethodCallsFor(
          'getProject',
        );
        expect(methodCalls.length, 1);
        expect(methodCalls.first['id'], testProjectId);
      },
    );
  });
}
