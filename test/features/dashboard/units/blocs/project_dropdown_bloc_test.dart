import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectDropdownBloc', () {
    late FakeProjectRepository fakeProjectRepository;

    setUp(() {
      fakeProjectRepository = FakeProjectRepository();
    });

    Project project({
      required String id,
      required String name,
      required DateTime updatedAt,
    }) {
      return Project(
        id: id,
        projectName: name,
        creatorUserId: 'user-1',
        createdAt: updatedAt,
        updatedAt: updatedAt,
        status: ProjectStatus.active,
      );
    }

    test('initial state is ProjectDropdownInitial', () {
      final bloc = ProjectDropdownBloc(
        projectRepository: fakeProjectRepository,
      );
      expect(bloc.state, const ProjectDropdownInitial());
      bloc.close();
    });

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'emits loading then success with first project selected',
      build: () {
        fakeProjectRepository.setAccessibleProjects([
          project(
            id: 'project-2',
            name: 'Project 2',
            updatedAt: DateTime(2025, 1, 2),
          ),
          project(
            id: 'project-1',
            name: 'Project 1',
            updatedAt: DateTime(2025, 1, 1),
          ),
        ]);
        return ProjectDropdownBloc(projectRepository: fakeProjectRepository);
      },
      act: (bloc) => bloc.add(const ProjectDropdownStarted()),
      expect: () => [
        const ProjectDropdownLoadInProgress(),
        isA<ProjectDropdownLoadSuccess>()
            .having((state) => state.projects.length, 'projects.length', 2)
            .having(
              (state) => state.selectedProject?.id,
              'selectedProject.id',
              'project-2',
            ),
      ],
    );

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'emits loading then success with empty projects list',
      build: () =>
          ProjectDropdownBloc(projectRepository: fakeProjectRepository),
      act: (bloc) => bloc.add(const ProjectDropdownStarted()),
      expect: () => [
        const ProjectDropdownLoadInProgress(),
        isA<ProjectDropdownLoadSuccess>()
            .having((state) => state.projects, 'projects', isEmpty)
            .having(
              (state) => state.selectedProject,
              'selectedProject',
              isNull,
            ),
      ],
    );

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'updates selected project when ProjectDropdownSelected is dispatched',
      build: () {
        fakeProjectRepository.setAccessibleProjects([
          project(
            id: 'project-1',
            name: 'Project 1',
            updatedAt: DateTime(2025, 1, 1),
          ),
          project(
            id: 'project-2',
            name: 'Project 2',
            updatedAt: DateTime(2025, 1, 2),
          ),
        ]);
        return ProjectDropdownBloc(projectRepository: fakeProjectRepository);
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ProjectDropdownSelected('project-2'));
      },
      expect: () => [
        const ProjectDropdownLoadInProgress(),
        isA<ProjectDropdownLoadSuccess>().having(
          (state) => state.selectedProject?.id,
          'selectedProject.id',
          'project-1',
        ),
        isA<ProjectDropdownLoadSuccess>().having(
          (state) => state.selectedProject?.id,
          'selectedProject.id',
          'project-2',
        ),
      ],
    );

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'emits failure when watchProjects throws',
      build: () {
        fakeProjectRepository.shouldThrowOnWatchProjects = true;
        fakeProjectRepository.watchProjectsErrorMessage =
            'Unable to fetch projects';
        return ProjectDropdownBloc(projectRepository: fakeProjectRepository);
      },
      act: (bloc) => bloc.add(const ProjectDropdownStarted()),
      expect: () => [
        const ProjectDropdownLoadInProgress(),
        isA<ProjectDropdownLoadFailure>().having(
          (state) => state.message,
          'message',
          contains('Unable to fetch projects'),
        ),
      ],
    );

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'emits updated state when repository stream pushes new list',
      build: () {
        fakeProjectRepository.setAccessibleProjects([
          project(
            id: 'project-1',
            name: 'Project 1',
            updatedAt: DateTime(2025, 1, 1),
          ),
        ]);
        return ProjectDropdownBloc(projectRepository: fakeProjectRepository);
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        fakeProjectRepository.setAccessibleProjects([
          project(
            id: 'project-1',
            name: 'Project 1 Updated',
            updatedAt: DateTime(2025, 1, 2),
          ),
        ]);
      },
      expect: () => [
        const ProjectDropdownLoadInProgress(),
        isA<ProjectDropdownLoadSuccess>().having(
          (state) => state.selectedProject?.projectName,
          'selectedProject.projectName',
          'Project 1',
        ),
        isA<ProjectDropdownLoadSuccess>().having(
          (state) => state.selectedProject?.projectName,
          'selectedProject.projectName',
          'Project 1 Updated',
        ),
      ],
    );
  });
}
