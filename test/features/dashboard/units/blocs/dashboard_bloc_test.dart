import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('DashboardBloc', () {
    late FakeProjectRepository fakeProjectRepository;
    late FakeCurrentProjectNotifier fakeCurrentProjectNotifier;

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
      fakeProjectRepository = FakeProjectRepository();
      fakeCurrentProjectNotifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      Modular.init(DashboardModule(FakeAppBootstrapFactory.create()));
      Modular.replaceInstance<ProjectRepository>(fakeProjectRepository);
      Modular.replaceInstance<CurrentProjectNotifier>(
        fakeCurrentProjectNotifier,
      );
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeProjectRepository.reset();
      fakeCurrentProjectNotifier.reset(projectId: testProjectId);
      fakeProjectRepository.addProject(testProjectId, testProject);
    });

    test('initial state is DashboardInitial', () {
      final bloc = Modular.get<DashboardBloc>();
      expect(bloc.state, const DashboardInitial());
      bloc.close();
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
            isA<Failure>(),
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

    group('stub events emit no state changes', () {
      blocTest<DashboardBloc, DashboardState>(
        'RecentCalculationsLoadedEvent is a no-op',
        build: () => Modular.get<DashboardBloc>(),
        act: (bloc) => bloc.add(const RecentCalculationsLoadedEvent()),
        expect: () => [],
      );

      blocTest<DashboardBloc, DashboardState>(
        'RecentEstimationsLoadedEvent is a no-op',
        build: () => Modular.get<DashboardBloc>(),
        act: (bloc) => bloc.add(const RecentEstimationsLoadedEvent()),
        expect: () => [],
      );

      blocTest<DashboardBloc, DashboardState>(
        'FavoritesLoadedEvent is a no-op until CA-247',
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
