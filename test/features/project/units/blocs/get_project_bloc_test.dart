import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/domain/entities/project_header_data.dart';
import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/project_module.dart';
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
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Clock clock;
  const testProjectId = 'project-123';
  const testProjectName = 'Sample Construction Project';
  const testDescription = 'A test project for construction estimation';
  const testCreatorUserId = 'user-456';
  Project createTestProject({
    String? id,
    String? projectName,
    String? description,
    String? creatorUserId,
    String? owningCompanyId,
    String? exportFolderLink,
    StorageProvider? exportStorageProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectStatus? status,
  }) {
    return Project(
      id: id ?? testProjectId,
      projectName: projectName ?? testProjectName,
      description: description,
      creatorUserId: creatorUserId ?? testCreatorUserId,
      owningCompanyId: owningCompanyId,
      exportFolderLink: exportFolderLink,
      exportStorageProvider: exportStorageProvider,
      createdAt: createdAt ?? clock.now(),
      updatedAt: updatedAt ?? clock.now(),
      status: status ?? ProjectStatus.active,
    );
  }

  group('GetProjectBloc Tests', () {
    late GetProjectBloc bloc;
    late FakeProjectRepository fakeProjectRepository;

    setUpAll(() {
      clock = FakeClockImpl();
      final appBootstrap = AppBootstrap(
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
        supabaseWrapper: FakeSupabaseWrapper(clock: clock),
      );
      Modular.init(ProjectModule(appBootstrap));
      Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
      Modular.replaceInstance<AuthRepository>(FakeAuthRepository(clock: clock));
      fakeProjectRepository =
          Modular.get<ProjectRepository>() as FakeProjectRepository;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      bloc = Modular.get<GetProjectBloc>();
    });

    tearDown(() {
      fakeProjectRepository.reset();
      bloc.close();
    });

    group('GetProjectByIdLoadRequested', () {
      blocTest<GetProjectBloc, GetProjectState>(
        'emits [GetProjectByIdLoading, GetProjectByIdLoadSuccess] when project loads successfully',
        build: () {
          final testProject = createTestProject(
            description: testDescription,
            owningCompanyId: 'company-789',
            exportFolderLink: 'https://drive.google.com/test',
            exportStorageProvider: StorageProvider.googleDrive,
          );

          fakeProjectRepository.addProject(testProjectId, testProject);

          return bloc;
        },
        act: (bloc) =>
            bloc.add(const GetProjectByIdLoadRequested(testProjectId)),
        expect: () => [
          GetProjectByIdLoading(),
          isA<GetProjectByIdLoadSuccess>()
              .having(
                (state) => state.headerData,
                'headerData',
                isA<ProjectHeaderData>(),
              )
              .having((state) => state.project.id, 'project.id', testProjectId)
              .having(
                (state) => state.project.projectName,
                'project.projectName',
                testProjectName,
              )
              .having(
                (state) => state.project.description,
                'project.description',
                testDescription,
              )
              .having(
                (state) => state.project.creatorUserId,
                'project.creatorUserId',
                testCreatorUserId,
              )
              .having(
                (state) => state.project.status,
                'project.status',
                ProjectStatus.active,
              ),
        ],
      );

      blocTest<GetProjectBloc, GetProjectState>(
        'emits [GetProjectByIdLoading, GetProjectByIdLoadFailure] when project loading fails with unknown exception',
        build: () {
          fakeProjectRepository.shouldThrowOnGetProject = true;
          fakeProjectRepository.getProjectExceptionType =
              SupabaseExceptionType.unknown;
          fakeProjectRepository.getProjectErrorMessage =
              'Failed to fetch project from server';

          return bloc;
        },
        act: (bloc) =>
            bloc.add(const GetProjectByIdLoadRequested(testProjectId)),
        expect: () => [
          GetProjectByIdLoading(),
          isA<GetProjectByIdLoadFailure>().having(
            (state) => state.failure,
            'failure',
            isA<ServerFailure>(),
          ),
        ],
      );

      blocTest<GetProjectBloc, GetProjectState>(
        'emits [GetProjectByIdLoading, GetProjectByIdLoadFailure] when project loading fails with timeout exception',
        build: () {
          fakeProjectRepository.shouldThrowOnGetProject = true;
          fakeProjectRepository.getProjectExceptionType =
              SupabaseExceptionType.timeout;
          fakeProjectRepository.getProjectErrorMessage = 'Request timed out';

          return bloc;
        },
        act: (bloc) =>
            bloc.add(const GetProjectByIdLoadRequested(testProjectId)),
        expect: () => [
          GetProjectByIdLoading(),
          isA<GetProjectByIdLoadFailure>().having(
            (state) => state.failure,
            'failure',
            isA<NetworkFailure>(),
          ),
        ],
      );

      blocTest<GetProjectBloc, GetProjectState>(
        'emits [GetProjectByIdLoading, GetProjectByIdLoadFailure] when project is not found',
        build: () {
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const GetProjectByIdLoadRequested('non-existent-project')),
        expect: () => [
          GetProjectByIdLoading(),
          isA<GetProjectByIdLoadFailure>().having(
            (state) => state.failure,
            'failure',
            isA<ServerFailure>(),
          ),
        ],
      );

      blocTest<GetProjectBloc, GetProjectState>(
        'emits correct states for multiple sequential project loads',
        build: () {
          final testProject1 = createTestProject(
            id: 'project-1',
            projectName: 'Project One',
            description: 'First project',
          );

          final testProject2 = createTestProject(
            id: 'project-2',
            projectName: 'Project Two',
            description: 'Second project',
            status: ProjectStatus.archived,
          );

          fakeProjectRepository.addProject('project-1', testProject1);
          fakeProjectRepository.addProject('project-2', testProject2);

          return bloc;
        },
        act: (bloc) {
          bloc.add(const GetProjectByIdLoadRequested('project-1'));
          bloc.add(const GetProjectByIdLoadRequested('project-2'));
        },
        expect: () => [
          GetProjectByIdLoading(),
          isA<GetProjectByIdLoadSuccess>()
              .having((state) => state.project.id, 'project.id', 'project-1')
              .having(
                (state) => state.project.projectName,
                'project.projectName',
                'Project One',
              ),
          GetProjectByIdLoading(),
          isA<GetProjectByIdLoadSuccess>()
              .having((state) => state.project.id, 'project.id', 'project-2')
              .having(
                (state) => state.project.projectName,
                'project.projectName',
                'Project Two',
              )
              .having(
                (state) => state.project.status,
                'project.status',
                ProjectStatus.archived,
              ),
        ],
      );

      blocTest<GetProjectBloc, GetProjectState>(
        'emits success for project with minimal fields',
        build: () {
          final minimalProject = createTestProject();

          fakeProjectRepository.addProject(testProjectId, minimalProject);

          return bloc;
        },
        act: (bloc) =>
            bloc.add(const GetProjectByIdLoadRequested(testProjectId)),
        expect: () => [
          GetProjectByIdLoading(),
          isA<GetProjectByIdLoadSuccess>()
              .having(
                (state) => state.project.description,
                'project.description',
                null,
              )
              .having(
                (state) => state.project.owningCompanyId,
                'project.owningCompanyId',
                null,
              )
              .having(
                (state) => state.project.exportFolderLink,
                'project.exportFolderLink',
                null,
              )
              .having(
                (state) => state.project.exportStorageProvider,
                'project.exportStorageProvider',
                null,
              ),
        ],
      );
    });

    test('initial state is GetProjectInitial', () {
      expect(bloc.state, isA<GetProjectInitial>());
    });
  });
}
