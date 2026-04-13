import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('ProjectDropdownBloc', () {
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl clock;
    const String testUserId = 'user-1';

    setUpAll(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: clock),
      );
      Modular.init(_ProjectDropdownBlocTestModule(bootstrap));
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      fakeSupabaseWrapper.setCurrentUser(
        FakeUser(
          id: testUserId,
          email: 'user-1@example.com',
          createdAt: clock.now().toIso8601String(),
          appMetadata: const {},
          userMetadata: const {},
        ),
      );
    });

    Map<String, dynamic> buildProjectMap({
      required String id,
      required String projectName,
      required String creatorUserId,
      required DateTime updatedAt,
      String? description,
      String status = 'active',
    }) {
      return {
        DatabaseConstants.idColumn: id,
        DatabaseConstants.projectNameColumn: projectName,
        DatabaseConstants.creatorUserIdColumn: creatorUserId,
        DatabaseConstants.updatedAtColumn: updatedAt.toIso8601String(),
        DatabaseConstants.createdAtColumn: DateTime(
          2025,
          1,
          1,
        ).toIso8601String(),
        DatabaseConstants.descriptionColumn: description,
        DatabaseConstants.statusColumn: status,
      };
    }

    Map<String, dynamic> buildProjectMemberMap({
      required String id,
      required String userId,
      required String projectId,
    }) => {
      DatabaseConstants.idColumn: id,
      DatabaseConstants.userIdColumn: userId,
      DatabaseConstants.projectIdColumn: projectId,
    };

    void seedProjectsTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, rows);
    }

    void seedProjectMembersTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(
        DatabaseConstants.projectMembersTable,
        rows,
      );
    }

    test('initial state is ProjectDropdownInitial', () {
      final bloc = Modular.get<ProjectDropdownBloc>();
      expect(bloc.state, const ProjectDropdownInitial());
      bloc.close();
    });

    group('ProjectDropdownStarted', () {
      group('success paths', () {
        blocTest<ProjectDropdownBloc, ProjectDropdownState>(
          'emits loading then success with first project selected',
          build: () {
            seedProjectsTable([
              buildProjectMap(
                id: 'project-2',
                projectName: 'Project 2',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 2),
              ),
              buildProjectMap(
                id: 'project-1',
                projectName: 'Project 1',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 1),
              ),
            ]);
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
                  (state) => state.selectedProject!.id,
                  'selectedProject.id',
                  'project-2',
                ),
          ],
        );

        blocTest<ProjectDropdownBloc, ProjectDropdownState>(
          'emits loading then success with owned and shared projects',
          build: () {
            seedProjectsTable([
              buildProjectMap(
                id: 'owned-project',
                projectName: 'Owned',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 1),
              ),
              buildProjectMap(
                id: 'shared-project',
                projectName: 'Shared',
                creatorUserId: 'other-user',
                updatedAt: DateTime(2025, 1, 2),
              ),
            ]);
            seedProjectMembersTable([
              buildProjectMemberMap(
                id: 'mem-1',
                userId: testUserId,
                projectId: 'shared-project',
              ),
            ]);
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
                  (state) => state.selectedProject!.id,
                  'selectedProject.id',
                  'shared-project',
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
          'emits empty projects when user is unauthenticated',
          build: () {
            fakeSupabaseWrapper.setCurrentUser(null);
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
                .having((state) => state.projects, 'projects', isEmpty)
                .having(
                  (state) => state.selectedProject,
                  'selectedProject',
                  isNull,
                ),
          ],
        );
      });

      group('error paths', () {
        blocTest<ProjectDropdownBloc, ProjectDropdownState>(
          'emits failure when repository watch flow fails during refresh',
          build: () {
            fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
            fakeSupabaseWrapper.selectMultipleExceptionType =
                SupabaseExceptionType.socket;
            return Modular.get<ProjectDropdownBloc>();
          },
          act: (bloc) async {
            bloc.add(const ProjectDropdownStarted());
            await bloc.stream.firstWhere(
              (s) => s is ProjectDropdownLoadFailure,
            );
          },
          expect: () => [
            const ProjectDropdownLoadInProgress(),
            isA<ProjectDropdownLoadFailure>().having(
              (state) => state.message,
              'message',
              isNotEmpty,
            ),
          ],
        );
      });

      group('realtime updates', () {
        blocTest<ProjectDropdownBloc, ProjectDropdownState>(
          'emits updated state when repository stream pushes new list',
          build: () {
            seedProjectsTable([
              buildProjectMap(
                id: 'project-1',
                projectName: 'Project 1',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 1),
              ),
            ]);
            return Modular.get<ProjectDropdownBloc>();
          },
          act: (bloc) async {
            bloc.add(const ProjectDropdownStarted());
            await bloc.stream.firstWhere(
              (s) =>
                  s is ProjectDropdownLoadSuccess &&
                  s.selectedProject!.projectName == 'Project 1',
            );
            seedProjectsTable([
              buildProjectMap(
                id: 'project-1',
                projectName: 'Project 1 Updated',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 2),
              ),
            ]);
            await bloc.stream.firstWhere(
              (s) =>
                  s is ProjectDropdownLoadSuccess &&
                  s.selectedProject!.projectName == 'Project 1 Updated',
            );
          },
          expect: () => [
            const ProjectDropdownLoadInProgress(),
            isA<ProjectDropdownLoadSuccess>().having(
              (state) => state.selectedProject!.projectName,
              'selectedProject.projectName',
              'Project 1',
            ),
            isA<ProjectDropdownLoadSuccess>().having(
              (state) => state.selectedProject!.projectName,
              'selectedProject.projectName',
              'Project 1 Updated',
            ),
          ],
        );

        blocTest<ProjectDropdownBloc, ProjectDropdownState>(
          'resets to LoadInProgress when ProjectDropdownStarted is dispatched again',
          build: () {
            seedProjectsTable([
              buildProjectMap(
                id: 'project-1',
                projectName: 'P1',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 2),
              ),
              buildProjectMap(
                id: 'project-2',
                projectName: 'P2',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 1),
              ),
            ]);
            return Modular.get<ProjectDropdownBloc>();
          },
          act: (bloc) async {
            bloc.add(const ProjectDropdownStarted());
            await bloc.stream.firstWhere(
              (s) => s is ProjectDropdownLoadSuccess,
            );
            bloc.add(const ProjectDropdownSelected('project-2'));
            await bloc.stream.firstWhere(
              (s) =>
                  s is ProjectDropdownLoadSuccess &&
                  s.selectedProject!.id == 'project-2',
            );
            bloc.add(const ProjectDropdownStarted());
          },
          expect: () => [
            const ProjectDropdownLoadInProgress(),
            isA<ProjectDropdownLoadSuccess>().having(
              (state) => state.selectedProject!.id,
              'selectedProject.id',
              'project-1',
            ),
            isA<ProjectDropdownLoadSuccess>().having(
              (state) => state.selectedProject!.id,
              'selectedProject.id',
              'project-2',
            ),
            const ProjectDropdownLoadInProgress(),
            isA<ProjectDropdownLoadSuccess>().having(
              (state) => state.selectedProject!.id,
              'selectedProject.id',
              'project-1',
            ),
          ],
        );

        blocTest<ProjectDropdownBloc, ProjectDropdownState>(
          'falls back to first project when selected project is removed by realtime update',
          build: () {
            seedProjectsTable([
              buildProjectMap(
                id: 'project-1',
                projectName: 'P1',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 2),
              ),
              buildProjectMap(
                id: 'project-2',
                projectName: 'P2',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 1),
              ),
            ]);
            return Modular.get<ProjectDropdownBloc>();
          },
          act: (bloc) async {
            bloc.add(const ProjectDropdownStarted());
            await bloc.stream.firstWhere(
              (s) => s is ProjectDropdownLoadSuccess,
            );
            bloc.add(const ProjectDropdownSelected('project-2'));
            seedProjectsTable([
              buildProjectMap(
                id: 'project-1',
                projectName: 'P1',
                creatorUserId: testUserId,
                updatedAt: DateTime(2025, 1, 3),
              ),
            ]);
            await bloc.stream.firstWhere(
              (s) =>
                  s is ProjectDropdownLoadSuccess &&
                  s.selectedProject!.id == 'project-1' &&
                  s.projects.length == 1,
            );
          },
          expect: () => [
            const ProjectDropdownLoadInProgress(),
            isA<ProjectDropdownLoadSuccess>().having(
              (state) => state.selectedProject!.id,
              'selectedProject.id',
              'project-1',
            ),
            isA<ProjectDropdownLoadSuccess>().having(
              (state) => state.selectedProject!.id,
              'selectedProject.id',
              'project-2',
            ),
            isA<ProjectDropdownLoadSuccess>()
                .having(
                  (state) => state.selectedProject!.id,
                  'selectedProject.id',
                  'project-1',
                )
                .having((state) => state.projects.length, 'projects.length', 1),
          ],
        );
      });
    });

    group('ProjectDropdownSelected', () {
      blocTest<ProjectDropdownBloc, ProjectDropdownState>(
        'ignores ProjectDropdownSelected with unknown project id',
        build: () {
          seedProjectsTable([
            buildProjectMap(
              id: 'project-1',
              projectName: 'P1',
              creatorUserId: testUserId,
              updatedAt: DateTime(2025, 1, 1),
            ),
          ]);
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
            (state) => state.selectedProject!.id,
            'selectedProject.id',
            'project-1',
          ),
        ],
      );

      blocTest<ProjectDropdownBloc, ProjectDropdownState>(
        'updates selected project when ProjectDropdownSelected is dispatched',
        build: () {
          seedProjectsTable([
            buildProjectMap(
              id: 'project-1',
              projectName: 'Project 1',
              creatorUserId: testUserId,
              updatedAt: DateTime(2025, 1, 2),
            ),
            buildProjectMap(
              id: 'project-2',
              projectName: 'Project 2',
              creatorUserId: testUserId,
              updatedAt: DateTime(2025, 1, 1),
            ),
          ]);
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
            (state) => state.selectedProject!.id,
            'selectedProject.id',
            'project-1',
          ),
          isA<ProjectDropdownLoadSuccess>().having(
            (state) => state.selectedProject!.id,
            'selectedProject.id',
            'project-2',
          ),
        ],
      );
    });
  });
}

class _ProjectDropdownBlocTestModule extends Module {
  final AppBootstrap bootstrap;

  _ProjectDropdownBlocTestModule(this.bootstrap);

  @override
  List<Module> get imports => [ClockTestModule(), DashboardModule(bootstrap)];
}
