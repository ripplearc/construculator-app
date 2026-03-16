import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/data/repositories/project_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectDropdownBloc', () {
    late FakeClockImpl clock;
    late FakeAuthManager authManager;
    late _FakeProjectDataSource projectDataSource;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
      Modular.init(_ProjectDropdownBlocTestModule(clock: clock));
      authManager = Modular.get<AuthManager>() as FakeAuthManager;
      authManager.setCurrentCredential(
        UserCredential(
          id: 'user-1',
          email: 'user-1@example.com',
          metadata: {},
          createdAt: clock.now(),
        ),
      );
      projectDataSource = Modular.get<_FakeProjectDataSource>();
    });

    tearDown(() {
      projectDataSource.dispose();
      Modular.destroy();
    });

    test('initial state is ProjectDropdownInitial', () {
      final bloc = Modular.get<ProjectDropdownBloc>();
      expect(bloc.state, const ProjectDropdownInitial());
      bloc.close();
    });

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'emits loading then success with first project selected',
      build: () {
        projectDataSource.ownedProjects = [
          _projectDto(
            id: 'project-2',
            projectName: 'Project 2',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 2),
          ),
          _projectDto(
            id: 'project-1',
            projectName: 'Project 1',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        return Modular.get<ProjectDropdownBloc>();
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await bloc.stream.firstWhere(
          (s) =>
              s is ProjectDropdownLoadSuccess ||
              s is ProjectDropdownLoadFailure,
        );
      },
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
      build: () => Modular.get<ProjectDropdownBloc>(),
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await bloc.stream.firstWhere(
          (s) =>
              s is ProjectDropdownLoadSuccess ||
              s is ProjectDropdownLoadFailure,
        );
      },
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
      'ignores ProjectDropdownSelected with unknown project id',
      build: () {
        projectDataSource.ownedProjects = [
          _projectDto(
            id: 'project-1',
            projectName: 'P1',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        return Modular.get<ProjectDropdownBloc>();
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await bloc.stream.firstWhere((s) => s is ProjectDropdownLoadSuccess);
        bloc.add(const ProjectDropdownSelected('non-existent-id'));
      },
      expect: () => [
        const ProjectDropdownLoadInProgress(),
        isA<ProjectDropdownLoadSuccess>().having(
          (state) => state.selectedProject?.id,
          'selectedProject.id',
          'project-1',
        ),
      ],
    );

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'updates selected project when ProjectDropdownSelected is dispatched',
      build: () {
        projectDataSource.ownedProjects = [
          _projectDto(
            id: 'project-1',
            projectName: 'Project 1',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 2),
          ),
          _projectDto(
            id: 'project-2',
            projectName: 'Project 2',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        return Modular.get<ProjectDropdownBloc>();
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await bloc.stream.firstWhere((s) => s is ProjectDropdownLoadSuccess);
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
      'emits failure when repository watch flow fails during refresh',
      build: () {
        projectDataSource.shouldThrowOnGetOwnedProjects = true;
        projectDataSource.getOwnedProjectsErrorMessage =
            'Unable to fetch projects';
        return Modular.get<ProjectDropdownBloc>();
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await bloc.stream.firstWhere((s) => s is ProjectDropdownLoadFailure);
      },
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
        projectDataSource.ownedProjects = [
          _projectDto(
            id: 'project-1',
            projectName: 'Project 1',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        return Modular.get<ProjectDropdownBloc>();
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await bloc.stream.firstWhere(
          (s) =>
              s is ProjectDropdownLoadSuccess &&
              s.selectedProject?.projectName == 'Project 1',
        );
        projectDataSource.ownedProjects = [
          _projectDto(
            id: 'project-1',
            projectName: 'Project 1 Updated',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 2),
          ),
        ];
        projectDataSource.emitProjectChange();
        await bloc.stream.firstWhere(
          (s) =>
              s is ProjectDropdownLoadSuccess &&
              s.selectedProject?.projectName == 'Project 1 Updated',
        );
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

    blocTest<ProjectDropdownBloc, ProjectDropdownState>(
      'falls back to first project when selected project is removed by realtime update',
      build: () {
        projectDataSource.ownedProjects = [
          _projectDto(
            id: 'project-1',
            projectName: 'P1',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 2),
          ),
          _projectDto(
            id: 'project-2',
            projectName: 'P2',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];
        return Modular.get<ProjectDropdownBloc>();
      },
      act: (bloc) async {
        bloc.add(const ProjectDropdownStarted());
        await bloc.stream.firstWhere((s) => s is ProjectDropdownLoadSuccess);
        bloc.add(const ProjectDropdownSelected('project-2'));
        projectDataSource.ownedProjects = [
          _projectDto(
            id: 'project-1',
            projectName: 'P1',
            creatorUserId: 'user-1',
            updatedAt: DateTime(2025, 1, 3),
          ),
        ];
        projectDataSource.emitProjectChange();
        await bloc.stream.firstWhere(
          (s) =>
              s is ProjectDropdownLoadSuccess &&
              s.selectedProject?.id == 'project-1' &&
              s.projects.length == 1,
        );
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
        isA<ProjectDropdownLoadSuccess>()
            .having((state) => state.selectedProject?.id, 'selectedProject.id', 'project-1')
            .having((state) => state.projects.length, 'projects.length', 1),
      ],
    );
  });
}

ProjectDto _projectDto({
  required String id,
  required String projectName,
  required String creatorUserId,
  required DateTime updatedAt,
}) {
  return ProjectDto(
    id: id,
    projectName: projectName,
    creatorUserId: creatorUserId,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: updatedAt,
    status: ProjectStatus.active,
  );
}

class _FakeProjectDataSource implements ProjectDataSource {
  List<ProjectDto> ownedProjects = [];
  List<ProjectDto> sharedProjects = [];
  bool shouldThrowOnGetOwnedProjects = false;
  String getOwnedProjectsErrorMessage = 'Get owned projects failed';
  Completer<void>? getOwnedProjectsCompleter;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Future<List<ProjectDto>> getOwnedProjects(String userId) async {
    if (shouldThrowOnGetOwnedProjects) {
      throw Exception(getOwnedProjectsErrorMessage);
    }
    final completer = getOwnedProjectsCompleter;
    if (completer != null) {
      getOwnedProjectsCompleter = null;
      await completer.future;
    }
    return List<ProjectDto>.from(ownedProjects);
  }

  @override
  Future<List<ProjectDto>> getSharedProjects(String userId) async {
    return List<ProjectDto>.from(sharedProjects);
  }

  @override
  Stream<void> watchProjectChanges(String userId) => _changesController.stream;

  void emitProjectChange() {
    _changesController.add(null);
  }

  void dispose() {
    _changesController.close();
  }
}

class _ProjectDropdownBlocTestModule extends Module {
  final FakeClockImpl clock;

  _ProjectDropdownBlocTestModule({required this.clock});

  @override
  void binds(Injector i) {
    i.addLazySingleton<SupabaseWrapper>(
      () => FakeSupabaseWrapper(clock: clock),
    );
    i.addLazySingleton<AuthNotifierController>(() => FakeAuthNotifier());
    i.addLazySingleton<AuthRepository>(() => FakeAuthRepository(clock: clock));
    i.addLazySingleton<AuthManager>(
      () => FakeAuthManager(
        authNotifier: i.get<AuthNotifierController>(),
        authRepository: i.get<AuthRepository>(),
        wrapper: i.get<SupabaseWrapper>(),
        clock: clock,
      ),
    );
    i.addLazySingleton<_FakeProjectDataSource>(() => _FakeProjectDataSource());
    i.addLazySingleton<ProjectDataSource>(
      () => i.get<_FakeProjectDataSource>(),
    );
    i.addLazySingleton<ProjectRepository>(
      () => ProjectRepositoryImpl(
        projectDataSource: i.get<ProjectDataSource>(),
        clock: clock,
      ),
    );
    i.add<ProjectDropdownBloc>(
      () => ProjectDropdownBloc(
        projectRepository: i.get<ProjectRepository>(),
        authManager: i.get<AuthManager>(),
      ),
    );
  }
}
