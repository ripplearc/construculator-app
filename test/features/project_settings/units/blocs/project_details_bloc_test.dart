import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_details_bloc/project_details_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test module that provides [ProjectDetailsBloc] as a factory (`i.add`) so
/// each `blocTest` resolves a fresh instance via `Modular.get`, backed by a
/// shared [FakeProjectRepository] for stubbing.
class _ProjectDetailsBlocTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<ProjectRepository>(FakeProjectRepository.new);
    i.add<ProjectDetailsBloc>(() => ProjectDetailsBloc(projectRepository: i()));
  }
}

void main() {
  const projectId = 'project-1';

  Project buildProject({String id = projectId}) {
    return Project(
      id: id,
      projectName: 'Material of building',
      description: 'A short description.',
      creatorUserId: 'user-1',
      createdAt: DateTime(2024, 10, 12, 14, 30),
      updatedAt: DateTime(2024, 10, 12, 14, 30),
      status: ProjectStatus.active,
      exportStorageProvider: StorageProvider.googleDrive,
      exportFolderLink: 'Cost estimation',
    );
  }

  late FakeProjectRepository fakeProjectRepository;

  setUpAll(() {
    Modular.init(_ProjectDetailsBlocTestModule());
    fakeProjectRepository =
        Modular.get<ProjectRepository>() as FakeProjectRepository;
  });

  tearDownAll(() {
    Modular.dispose();
  });

  tearDown(() {
    fakeProjectRepository.reset();
  });

  ProjectDetailsBloc buildBloc() => Modular.get<ProjectDetailsBloc>();

  group('ProjectDetailsBloc', () {
    test('initial state is ProjectDetailsInitial', () {
      expect(buildBloc().state, const ProjectDetailsInitial());
    });

    blocTest<ProjectDetailsBloc, ProjectDetailsState>(
      'emits [Loading, Loaded] when the project loads on ProjectDetailsStarted',
      setUp: () => fakeProjectRepository.addProject(projectId, buildProject()),
      build: buildBloc,
      act: (bloc) => bloc.add(const ProjectDetailsStarted(projectId)),
      expect: () => [
        const ProjectDetailsLoading(),
        ProjectDetailsLoaded(project: buildProject()),
      ],
    );

    blocTest<ProjectDetailsBloc, ProjectDetailsState>(
      'emits [Loading, LoadFailure] when the repository throws',
      setUp: () => fakeProjectRepository.shouldThrowOnGetProject = true,
      build: buildBloc,
      act: (bloc) => bloc.add(const ProjectDetailsStarted(projectId)),
      expect: () => [
        const ProjectDetailsLoading(),
        ProjectDetailsLoadFailure(UnexpectedFailure()),
      ],
    );

    blocTest<ProjectDetailsBloc, ProjectDetailsState>(
      'passes the typed Failure through when the repository throws one',
      setUp: () => fakeProjectRepository.getProjectFailure = NetworkFailure(),
      build: buildBloc,
      act: (bloc) => bloc.add(const ProjectDetailsStarted(projectId)),
      expect: () => [
        const ProjectDetailsLoading(),
        ProjectDetailsLoadFailure(NetworkFailure()),
      ],
    );

    blocTest<ProjectDetailsBloc, ProjectDetailsState>(
      'refetches on ProjectDetailsStarted when a different project is loaded',
      setUp: () => fakeProjectRepository.addProject(projectId, buildProject()),
      build: buildBloc,
      seed: () =>
          ProjectDetailsLoaded(project: buildProject(id: 'other-project')),
      act: (bloc) => bloc.add(const ProjectDetailsStarted(projectId)),
      expect: () => [
        const ProjectDetailsLoading(),
        ProjectDetailsLoaded(project: buildProject()),
      ],
    );

    blocTest<ProjectDetailsBloc, ProjectDetailsState>(
      'skips the fetch when the same project is already loaded',
      setUp: () => fakeProjectRepository.addProject(projectId, buildProject()),
      build: buildBloc,
      seed: () => ProjectDetailsLoaded(project: buildProject()),
      act: (bloc) => bloc.add(const ProjectDetailsStarted(projectId)),
      expect: () => const <ProjectDetailsState>[],
    );

    blocTest<ProjectDetailsBloc, ProjectDetailsState>(
      'refetches on ProjectDetailsRefreshed even when already loaded',
      setUp: () => fakeProjectRepository.addProject(projectId, buildProject()),
      build: buildBloc,
      seed: () => ProjectDetailsLoaded(project: buildProject()),
      act: (bloc) => bloc.add(const ProjectDetailsRefreshed(projectId)),
      expect: () => [
        const ProjectDetailsLoading(),
        ProjectDetailsLoaded(project: buildProject()),
      ],
    );
  });
}
