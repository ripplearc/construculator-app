import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/create_project_bloc/create_project_bloc.dart';
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
  group('CreateProjectBloc', () {
    late FakeProjectSettingRepository fakeRepository;

    const testProjectId = 'project-id-1';
    const testProjectName = 'Test Project';
    const testCreatorUserId = 'user-1';

    final tDate = DateTime(2025, 1, 1, 8, 0);
    late Project tProject;

    // Modular is initialised once; each test receives a fresh
    // FakeProjectSettingRepository via replaceInstance so no state bleeds
    // between tests. Modular.get<CreateProjectBloc>() returns a new instance
    // per call because the binding uses i.add (not addLazySingleton).
    setUpAll(() {
      final bootstrap = FakeAppBootstrapFactory.create();
      Modular.init(_CreateProjectBlocTestModule(bootstrap));
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      Modular.replaceInstance<ProjectSettingRepository>(
        FakeProjectSettingRepository(),
      );
      fakeRepository = Modular.get<ProjectSettingRepository>()
          as FakeProjectSettingRepository;

      tProject = Project(
        id: testProjectId,
        projectName: testProjectName,
        creatorUserId: testCreatorUserId,
        createdAt: tDate,
        updatedAt: tDate,
        status: ProjectStatus.active,
      );
    });

    test('initial state is CreateProjectInitial', () {
      final bloc = Modular.get<CreateProjectBloc>();
      expect(bloc.state, const CreateProjectInitial());
      bloc.close();
    });

    group('CreateProjectSubmitted', () {
      blocTest<CreateProjectBloc, CreateProjectState>(
        'emits [InProgress, Success] on create success',
        build: () => Modular.get<CreateProjectBloc>(),
        act: (bloc) => bloc.add(CreateProjectSubmitted(tProject)),
        expect: () => [
          const CreateProjectInProgress(),
          isA<CreateProjectSuccess>()
              .having((s) => s.project.id, 'project.id', testProjectId)
              .having(
                (s) => s.project.projectName,
                'project.projectName',
                testProjectName,
              )
              .having(
                (s) => s.project.creatorUserId,
                'project.creatorUserId',
                testCreatorUserId,
              ),
        ],
        verify: (_) {
          expect(fakeRepository.getMethodCallsFor('createProject'), hasLength(1));
        },
      );

      blocTest<CreateProjectBloc, CreateProjectState>(
        'emits [InProgress, Failure] on create failure',
        build: () {
          fakeRepository.shouldFailOnCreate = true;
          fakeRepository.failureToReturn = const ProjectFailure(
            errorType: ProjectErrorType.connectionError,
          );
          return Modular.get<CreateProjectBloc>();
        },
        act: (bloc) => bloc.add(CreateProjectSubmitted(tProject)),
        expect: () => [
          const CreateProjectInProgress(),
          isA<CreateProjectFailure>().having(
            (s) => s.failure,
            'failure',
            isA<ProjectFailure>(),
          ),
        ],
      );
    });
  });
}

class _CreateProjectBlocTestModule extends Module {
  final AppBootstrap bootstrap;

  _CreateProjectBlocTestModule(this.bootstrap);

  @override
  List<Module> get imports => [DashboardModule(bootstrap)];
}
