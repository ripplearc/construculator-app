import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('ProjectSettingsBloc', () {
    late FakeProjectSettingRepository fakeRepository;

    const testProjectId = 'project-id-1';
    const testProjectName = 'Test Project';

    final tDate = DateTime(2025, 1, 1, 8, 0);
    late Project tProject;

    setUpAll(() {
      final bootstrap = FakeAppBootstrapFactory.create();
      Modular.init(_ProjectSettingsBlocTestModule(bootstrap));
      Modular.replaceInstance<ProjectSettingRepository>(
        FakeProjectSettingRepository(),
      );
      fakeRepository =
          Modular.get<ProjectSettingRepository>() as FakeProjectSettingRepository;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeRepository.reset();
      tProject = Project(
        id: testProjectId,
        projectName: testProjectName,
        creatorUserId: 'user-1',
        createdAt: tDate,
        updatedAt: tDate,
        status: ProjectStatus.active,
      );
      fakeRepository.projectToReturn = tProject;
    });

    test('initial state is ProjectSettingsInitial', () {
      final bloc = Modular.get<ProjectSettingsBloc>();
      expect(bloc.state, const ProjectSettingsInitial());
      bloc.close();
    });

    group('ProjectSettingsWatchStarted', () {
      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [Loading, Loaded] when stream delivers a project',
        build: () => Modular.get<ProjectSettingsBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSettingsWatchStarted(testProjectId));
          await bloc.stream.firstWhere((s) => s is ProjectSettingsLoading);
          fakeRepository.emitProject(tProject);
        },
        expect: () => [
          const ProjectSettingsLoading(),
          isA<ProjectSettingsLoaded>()
              .having((s) => s.project.id, 'project.id', testProjectId)
              .having(
                (s) => s.project.projectName,
                'project.projectName',
                testProjectName,
              ),
        ],
      );

      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [Loading, Error] when stream delivers a failure',
        build: () => Modular.get<ProjectSettingsBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSettingsWatchStarted(testProjectId));
          await bloc.stream.firstWhere((s) => s is ProjectSettingsLoading);
          fakeRepository.emitFailure(
            const ProjectFailure(errorType: ProjectErrorType.connectionError),
          );
        },
        expect: () => [
          const ProjectSettingsLoading(),
          isA<ProjectSettingsError>().having(
            (s) => s.failure,
            'failure',
            isA<ProjectFailure>(),
          ),
        ],
      );

      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [Loading, Error] when stream emits an error event',
        build: () => Modular.get<ProjectSettingsBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSettingsWatchStarted(testProjectId));
          await bloc.stream.firstWhere((s) => s is ProjectSettingsLoading);
          fakeRepository.emitStreamError(Exception('unexpected stream error'));
        },
        expect: () => [
          const ProjectSettingsLoading(),
          isA<ProjectSettingsError>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        ],
      );

      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'preserves lastProject in Error when previously in Loaded state',
        build: () => Modular.get<ProjectSettingsBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSettingsWatchStarted(testProjectId));
          await bloc.stream.firstWhere((s) => s is ProjectSettingsLoading);
          fakeRepository.emitProject(tProject);
          await bloc.stream.firstWhere((s) => s is ProjectSettingsLoaded);
          fakeRepository.emitFailure(
            const ProjectFailure(errorType: ProjectErrorType.connectionError),
          );
        },
        expect: () => [
          const ProjectSettingsLoading(),
          isA<ProjectSettingsLoaded>(),
          isA<ProjectSettingsError>()
              .having((s) => s.lastProject, 'lastProject', tProject),
        ],
      );
    });

    group('ProjectSettingsEditingStarted', () {
      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [Editing] when state is Loaded',
        build: () => Modular.get<ProjectSettingsBloc>(),
        seed: () => ProjectSettingsLoaded(tProject),
        act: (bloc) =>
            bloc.add(ProjectSettingsEditingStarted(tProject)),
        expect: () => [
          isA<ProjectSettingsEditing>()
              .having(
                (s) => s.project.id,
                'project.id',
                testProjectId,
              )
              .having(
                (s) => s.originalProject.id,
                'originalProject.id',
                testProjectId,
              ),
        ],
      );

      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'is ignored when state is not Loaded',
        build: () => Modular.get<ProjectSettingsBloc>(),
        seed: () => const ProjectSettingsLoading(),
        act: (bloc) => bloc.add(ProjectSettingsEditingStarted(tProject)),
        expect: () => [],
      );
    });

    group('ProjectSettingsUpdateSubmitted', () {
      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [Saving, Loaded] on update success',
        build: () => Modular.get<ProjectSettingsBloc>(),
        seed: () => ProjectSettingsEditing(
          project: tProject,
          originalProject: tProject,
        ),
        act: (bloc) => bloc.add(ProjectSettingsUpdateSubmitted(tProject)),
        expect: () => [
          isA<ProjectSettingsSaving>()
              .having((s) => s.project.id, 'project.id', testProjectId),
          isA<ProjectSettingsLoaded>()
              .having((s) => s.project.id, 'project.id', testProjectId),
        ],
      );

      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [Saving, Error] with originalProject on update failure',
        build: () {
          fakeRepository.shouldFailOnUpdate = true;
          fakeRepository.failureToReturn = const ProjectFailure(
            errorType: ProjectErrorType.permissionDenied,
          );
          return Modular.get<ProjectSettingsBloc>();
        },
        seed: () => ProjectSettingsEditing(
          project: tProject,
          originalProject: tProject,
        ),
        act: (bloc) => bloc.add(ProjectSettingsUpdateSubmitted(tProject)),
        expect: () => [
          isA<ProjectSettingsSaving>(),
          isA<ProjectSettingsError>()
              .having(
                (s) => s.failure,
                'failure',
                isA<ProjectFailure>(),
              )
              .having(
                (s) => s.lastProject,
                'lastProject',
                tProject,
              ),
        ],
      );
    });

    group('ProjectSettingsDeleteRequested', () {
      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [DeleteInProgress, Initial] on delete success',
        build: () => Modular.get<ProjectSettingsBloc>(),
        seed: () => ProjectSettingsLoaded(tProject),
        act: (bloc) =>
            bloc.add(const ProjectSettingsDeleteRequested(testProjectId)),
        expect: () => [
          const ProjectSettingsDeleteInProgress(),
          const ProjectSettingsInitial(),
        ],
      );

      blocTest<ProjectSettingsBloc, ProjectSettingsState>(
        'emits [DeleteInProgress, Error] on delete failure',
        build: () {
          fakeRepository.shouldFailOnDelete = true;
          fakeRepository.failureToReturn = const ProjectFailure(
            errorType: ProjectErrorType.permissionDenied,
          );
          return Modular.get<ProjectSettingsBloc>();
        },
        seed: () => ProjectSettingsLoaded(tProject),
        act: (bloc) =>
            bloc.add(const ProjectSettingsDeleteRequested(testProjectId)),
        expect: () => [
          const ProjectSettingsDeleteInProgress(),
          isA<ProjectSettingsError>().having(
            (s) => s.failure,
            'failure',
            isA<ProjectFailure>(),
          ),
        ],
      );
    });
  });
}

class _ProjectSettingsBlocTestModule extends Module {
  final AppBootstrap bootstrap;

  _ProjectSettingsBlocTestModule(this.bootstrap);

  @override
  List<Module> get imports => [DashboardModule(bootstrap)];
}
