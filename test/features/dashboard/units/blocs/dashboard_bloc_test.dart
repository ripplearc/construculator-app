import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('DashboardBloc', () {
    late FakeProjectRepository fakeProjectRepository;
    late FakeCurrentProjectNotifier fakeCurrentProjectNotifier;
    late FakeAuthNotifier fakeAuthNotifier;
    late FakeAuthManager fakeAuthManager;
    late FakeAuthRepository fakeAuthRepository;
    late FakeClockImpl clock;

    const testProjectId = 'project-1';
    final testProject = Project(
      id: testProjectId,
      projectName: 'Test Project',
      creatorUserId: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      status: ProjectStatus.active,
    );

    setUpAll(() {
      clock = FakeClockImpl();
      fakeProjectRepository = FakeProjectRepository();
      fakeCurrentProjectNotifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      fakeAuthNotifier = FakeAuthNotifier();
      fakeAuthRepository = FakeAuthRepository(clock: clock);
      fakeAuthManager = FakeAuthManager(
        authNotifier: fakeAuthNotifier,
        authRepository: fakeAuthRepository,
        wrapper: FakeSupabaseWrapper(clock: clock),
        clock: clock,
      );

      Modular.init(DashboardModule(FakeAppBootstrapFactory.create()));
      Modular.replaceInstance<ProjectRepository>(fakeProjectRepository);
      Modular.replaceInstance<CurrentProjectNotifier>(fakeCurrentProjectNotifier);
      Modular.replaceInstance<AuthNotifierController>(fakeAuthNotifier);
      Modular.replaceInstance<AuthNotifier>(fakeAuthNotifier);
      Modular.replaceInstance<AuthManager>(fakeAuthManager);
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeProjectRepository.reset();
      fakeCurrentProjectNotifier.reset(projectId: testProjectId);
      fakeProjectRepository.addProject(testProjectId, testProject);
      fakeAuthManager.reset();
      fakeAuthNotifier.reset();
      fakeAuthRepository.returnNullUserProfile = false;
    });

    final testCredential = UserCredential(
      id: 'cred-1',
      email: 'test@example.com',
      metadata: {},
      createdAt: DateTime(2025, 1, 1),
    );

    final testUser = User(
      id: 'user-1',
      credentialId: 'cred-1',
      email: 'test@example.com',
      firstName: 'Jane',
      lastName: 'Smith',
      professionalRole: 'Engineer',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
    );

    test('initial state is DashboardInitial', () {
      final bloc = Modular.get<DashboardBloc>();
      expect(bloc.state, const DashboardInitial());
      bloc.close();
    });

    group('DashboardStarted', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardNavigateToLogin when no credentials',
        build: () => Modular.get<DashboardBloc>(),
        act: (bloc) => bloc.add(const DashboardStarted()),
        expect: () => [const DashboardNavigateToLogin()],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardUserLoaded with full name when profile is found',
        build: () {
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthRepository.setUserProfile(testUser);
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) => bloc.add(const DashboardStarted()),
        expect: () => [
          DashboardUserLoaded(userDisplayName: 'Jane Smith!'),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardNavigateToCreateAccount when profile returns null',
        build: () {
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthRepository.returnNullUserProfile = true;
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) => bloc.add(const DashboardStarted()),
        expect: () => [
          DashboardNavigateToCreateAccount(testCredential.email),
        ],
      );
    });

    group('DashboardLogoutRequested', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardNavigateToLogin after logout',
        build: () {
          fakeAuthManager.setCurrentCredential(testCredential);
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) => bloc.add(const DashboardLogoutRequested()),
        expect: () => [const DashboardNavigateToLogin()],
        verify: (_) => expect(fakeAuthManager.logoutAttempts, hasLength(1)),
      );
    });

    group('profile stream changes', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardNavigateToCreateAccount when profile stream emits null',
        build: () {
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthRepository.setUserProfile(testUser);
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) async {
          bloc.add(const DashboardStarted());
          await bloc.stream.firstWhere((s) => s is DashboardUserLoaded);
          fakeAuthNotifier.emitUserProfileChanged(null);
        },
        expect: () => [
          DashboardUserLoaded(userDisplayName: 'Jane Smith!'),
          DashboardNavigateToCreateAccount(testCredential.email),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits DashboardUserLoaded with new name when profile stream updates',
        build: () {
          fakeAuthManager.setCurrentCredential(testCredential);
          fakeAuthRepository.setUserProfile(testUser);
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) async {
          bloc.add(const DashboardStarted());
          await bloc.stream.firstWhere((s) => s is DashboardUserLoaded);
          fakeAuthNotifier.emitUserProfileChanged(
            testUser.copyWith(firstName: 'Updated', lastName: 'Name'),
          );
        },
        expect: () => [
          DashboardUserLoaded(userDisplayName: 'Jane Smith!'),
          DashboardUserLoaded(userDisplayName: 'Updated Name!'),
        ],
      );
    });

    group('DashboardLoadedEvent', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] when project is found',
        build: () => Modular.get<DashboardBloc>(),
        act: (bloc) => bloc.add(const DashboardLoadedEvent()),
        expect: () => [
          const DashboardLoading(),
          DashboardLoaded(currentProject: testProject),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when no project is selected',
        build: () {
          fakeCurrentProjectNotifier.reset(projectId: null);
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) => bloc.add(const DashboardLoadedEvent()),
        expect: () => [
          const DashboardLoading(),
          isA<DashboardError>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when project id is empty',
        build: () {
          fakeCurrentProjectNotifier.reset(projectId: '');
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) => bloc.add(const DashboardLoadedEvent()),
        expect: () => [
          const DashboardLoading(),
          isA<DashboardError>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when project fetch throws',
        build: () {
          fakeProjectRepository.shouldThrowOnGetProject = true;
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) => bloc.add(const DashboardLoadedEvent()),
        expect: () => [
          const DashboardLoading(),
          isA<DashboardError>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        ],
      );
    });

    group('DashboardRefreshedEvent', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] when project is found',
        build: () => Modular.get<DashboardBloc>(),
        act: (bloc) => bloc.add(const DashboardRefreshedEvent()),
        expect: () => [
          const DashboardLoading(),
          DashboardLoaded(currentProject: testProject),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when no project selected',
        build: () {
          fakeCurrentProjectNotifier.reset(projectId: null);
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) => bloc.add(const DashboardRefreshedEvent()),
        expect: () => [
          const DashboardLoading(),
          isA<DashboardError>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        ],
      );
    });

    group('FavoritesLoadedEvent', () {
      blocTest<DashboardBloc, DashboardState>(
        'is a no-op until CA-247',
        build: () => Modular.get<DashboardBloc>(),
        act: (bloc) => bloc.add(const FavoritesLoadedEvent()),
        expect: () => [],
      );
    });

    group('project switch', () {
      blocTest<DashboardBloc, DashboardState>(
        're-loads dashboard when current project changes',
        build: () {
          const otherId = 'project-2';
          final otherProject = Project(
            id: otherId,
            projectName: 'Other Project',
            creatorUserId: 'user-1',
            createdAt: DateTime(2025, 1, 2),
            updatedAt: DateTime(2025, 1, 2),
            status: ProjectStatus.active,
          );
          fakeProjectRepository.addProject(otherId, otherProject);
          return Modular.get<DashboardBloc>();
        },
        act: (bloc) async {
          bloc.add(const DashboardLoadedEvent());
          await bloc.stream.firstWhere((s) => s is DashboardLoaded);
          fakeCurrentProjectNotifier.setCurrentProjectId('project-2');
        },
        expect: () => [
          const DashboardLoading(),
          isA<DashboardLoaded>().having(
            (s) => s.currentProject.id,
            'currentProject.id',
            testProjectId,
          ),
          const DashboardLoading(),
          isA<DashboardLoaded>().having(
            (s) => s.currentProject.id,
            'currentProject.id',
            'project-2',
          ),
        ],
      );
    });
  });
}
