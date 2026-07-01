import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/local_jwt_project_permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/remote_project_data_source.dart';
import 'package:construculator/libraries/project/data/repositories/project_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('ProjectRepositoryImpl', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late ProjectRepositoryImpl repository;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 10, 1, 10, 30));
      Modular.init(_ProjectRepositoryTestModule(clock: clock));
      supabaseWrapper = Modular.get<FakeSupabaseWrapper>();
      repository = Modular.get<ProjectRepositoryImpl>();
    });

    tearDown(() {
      supabaseWrapper.dispose();
      Modular.destroy();
    });

    group('getProject', () {
      test('should return dummy project data with correct structure', () async {
        // Arrange
        const projectId = 'test-project-123';

        // Act
        final result = await repository.getProject(projectId);

        // Assert
        expect(result, isA<Project>());
        expect(result.id, equals(projectId));
        expect(result.projectName, equals('Sample Construction Project'));
        expect(
          result.description,
          equals('A sample construction project for testing purposes'),
        );
        expect(result.creatorUserId, equals('user_123'));
        expect(result.owningCompanyId, equals('company_456'));
        expect(
          result.exportFolderLink,
          equals('https://drive.google.com/sample-folder'),
        );
        expect(
          result.exportStorageProvider,
          equals(StorageProvider.googleDrive),
        );
        expect(result.status, equals(ProjectStatus.active));
        expect(result.createdAt, equals(DateTime(2025, 10, 1, 10, 30)));
        expect(result.updatedAt, equals(DateTime(2025, 10, 1, 10, 30)));
      });

      test(
        'should return project with same dummy data regardless of input id',
        () async {
          // Arrange
          const projectId1 = 'different-id-1';
          const projectId2 = 'different-id-2';

          // Act
          final result1 = await repository.getProject(projectId1);
          final result2 = await repository.getProject(projectId2);

          // Assert
          expect(result1.id, equals(projectId1));
          expect(result2.id, equals(projectId2));

          // All other fields should be identical dummy data
          expect(result1.projectName, equals(result2.projectName));
          expect(result1.description, equals(result2.description));
          expect(result1.creatorUserId, equals(result2.creatorUserId));
          expect(result1.owningCompanyId, equals(result2.owningCompanyId));
          expect(result1.exportFolderLink, equals(result2.exportFolderLink));
          expect(
            result1.exportStorageProvider,
            equals(result2.exportStorageProvider),
          );
          expect(result1.status, equals(result2.status));
          expect(result1.createdAt, equals(result2.createdAt));
          expect(result1.updatedAt, equals(result2.updatedAt));
        },
      );
    });

    group('getProjects', () {
      test('returns empty list when userId is empty string', () async {
        final result = await repository.getProjects('');

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('select'), isEmpty);
      });

      test(
        'merges owned and shared projects, deduplicates, and sorts by updatedAt',
        () async {
          const userId = 'user-123';

          supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            _createProjectRow(
              id: 'project-a',
              projectName: 'Oldest',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 1),
            ),
            _createProjectRow(
              id: 'project-b',
              projectName: 'Middle',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 3),
            ),
            _createProjectRow(
              id: 'project-c',
              projectName: 'Newest',
              creatorUserId: 'other-user',
              updatedAt: DateTime(2025, 1, 4),
            ),
          ]);
          // project-b appears in both owned (creator) and shared (membership),
          // project-c is shared only — verifies deduplication and sort.
          supabaseWrapper.addTableData(DatabaseConstants.projectMembersTable, [
            {
              DatabaseConstants.idColumn: 'member-1',
              DatabaseConstants.userIdColumn: 'user-123',
              DatabaseConstants.projectIdColumn: 'project-b',
            },
            {
              DatabaseConstants.idColumn: 'member-2',
              DatabaseConstants.userIdColumn: 'user-123',
              DatabaseConstants.projectIdColumn: 'project-c',
            },
          ]);

          final result = await repository.getProjects(userId);

          final selectCalls = supabaseWrapper.getMethodCallsFor('select');
          expect(
            selectCalls.any(
              (c) =>
                  c['table'] == DatabaseConstants.projectsTable &&
                  c['filterColumn'] ==
                      DatabaseConstants.creatorUserIdColumn &&
                  c['filterValue'] == userId,
            ),
            isTrue,
          );
          expect(
            selectCalls.any(
              (c) =>
                  c['table'] == DatabaseConstants.projectMembersTable &&
                  c['filterColumn'] == DatabaseConstants.userIdColumn &&
                  c['filterValue'] == userId,
            ),
            isTrue,
          );
          expect(result.map((p) => p.id).toList(), [
            'project-c',
            'project-b',
            'project-a',
          ]);
        },
      );

      test('throws ProjectFailure when owned projects fetch fails', () async {
        supabaseWrapper.shouldThrowOnSelectMultiple = true;
        supabaseWrapper.selectMultipleExceptionType =
            SupabaseExceptionType.timeout;

        expect(
          () => repository.getProjects('user-123'),
          throwsA(isA<ProjectFailure>()),
        );
      });
    });

    group('watchProjects', () {
      test('emits empty list when userId is empty', () async {
        final emittedBatches = <List<Project>>[];
        final emissionReceived = Completer<void>();
        final subscription = repository.watchProjects('').listen((batch) {
          emittedBatches.add(batch);
          if (!emissionReceived.isCompleted) {
            emissionReceived.complete();
          }
        });

        await emissionReceived.future;
        await subscription.cancel();

        expect(emittedBatches, hasLength(1));
        expect(emittedBatches.single, isEmpty);
      });

      test(
        'emits initial projects and realtime updates for shared projects',
        () async {
          const userId = 'user-123';

          supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            _createProjectRow(
              id: 'owned-project',
              projectName: 'Owned',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 1),
            ),
            _createProjectRow(
              id: 'shared-project',
              projectName: 'Shared V1',
              creatorUserId: 'other-user',
              updatedAt: DateTime(2025, 1, 2),
            ),
          ]);
          supabaseWrapper.addTableData(DatabaseConstants.projectMembersTable, [
            {
              DatabaseConstants.idColumn: 'member-1',
              DatabaseConstants.userIdColumn: 'user-123',
              DatabaseConstants.projectIdColumn: 'shared-project',
            },
          ]);

          final emittedBatches = <List<Project>>[];
          final firstEmissionReceived = Completer<void>();
          final secondEmissionReceived = Completer<void>();
          var emissionCount = 0;
          final subscription = repository.watchProjects(userId).listen((batch) {
            emittedBatches.add(batch);
            emissionCount++;
            if (emissionCount == 1) {
              firstEmissionReceived.complete();
            } else if (emissionCount >= 2 &&
                !secondEmissionReceived.isCompleted) {
              secondEmissionReceived.complete();
            }
          });

          await firstEmissionReceived.future;

          supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            _createProjectRow(
              id: 'owned-project',
              projectName: 'Owned',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 1),
            ),
            _createProjectRow(
              id: 'shared-project',
              projectName: 'Shared V2',
              creatorUserId: 'other-user',
              updatedAt: DateTime(2025, 1, 3),
            ),
          ]);

          await secondEmissionReceived.future;

          await subscription.cancel();

          expect(emittedBatches.length, greaterThanOrEqualTo(2));
          expect(emittedBatches.first.length, 2);
          expect(
            emittedBatches.last
                .firstWhere((project) => project.id == 'shared-project')
                .projectName,
            'Shared V2',
          );
        },
      );

      test('propagates error from watchProjectChanges stream', () async {
        const userId = 'user-123';

        final firstEmission = Completer<void>();
        final errorReceived = Completer<void>();
        final subscription = repository
            .watchProjects(userId)
            .listen(
              (_) {
                if (!firstEmission.isCompleted) firstEmission.complete();
              },
              onError: (error, _) {
                expect(error, isA<ProjectFailure>());
                if (!errorReceived.isCompleted) errorReceived.complete();
              },
            );
        await firstEmission.future;

        supabaseWrapper.shouldEmitStreamErrors = true;
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, []);

        await errorReceived.future;
        await subscription.cancel();
      });

      test(
        'queues a follow-up refresh when changes arrive mid-refresh',
        () async {
          const userId = 'user-123';

          supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            _createProjectRow(
              id: 'owned-project',
              projectName: 'Owned V1',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 1),
            ),
          ]);

          supabaseWrapper.shouldDelayOperations = true;
          final firstRefreshCompleter = Completer<void>();
          supabaseWrapper.completer = firstRefreshCompleter;

          final emittedBatches = <List<Project>>[];
          final secondEmissionReceived = Completer<void>();
          var emissionCount = 0;
          final subscription = repository.watchProjects(userId).listen((batch) {
            emittedBatches.add(batch);
            emissionCount++;
            if (emissionCount >= 2 && !secondEmissionReceived.isCompleted) {
              secondEmissionReceived.complete();
            }
          });

          // By the time .listen() returns, select() has already taken its V1
          // snapshot and is blocking on firstRefreshCompleter. Updating now
          // triggers a watch event that queues a follow-up refresh.
          supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            _createProjectRow(
              id: 'owned-project',
              projectName: 'Owned V2',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 2),
            ),
          ]);

          firstRefreshCompleter.complete();
          await secondEmissionReceived.future;

          await subscription.cancel();

          expect(
            supabaseWrapper
                .getMethodCallsFor('select')
                .where(
                  (c) =>
                      c['table'] == DatabaseConstants.projectsTable &&
                      c['filterColumn'] ==
                          DatabaseConstants.creatorUserIdColumn,
                )
                .length,
            greaterThanOrEqualTo(2),
          );
          expect(emittedBatches.length, greaterThanOrEqualTo(2));
          expect(
            emittedBatches.first
                .firstWhere((project) => project.id == 'owned-project')
                .projectName,
            'Owned V1',
          );
          expect(
            emittedBatches.last
                .firstWhere((project) => project.id == 'owned-project')
                .projectName,
            'Owned V2',
          );
        },
      );
    });
  });

  group('ProjectRepositoryImpl - Permissions', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late ProjectRepository repository;

    setUpAll(() {
      clock = FakeClockImpl(DateTime(2025, 10, 1, 10, 30));
      final testSupabaseWrapper = FakeSupabaseWrapper(clock: clock);

      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: testSupabaseWrapper,
      );

      Modular.init(_PermissionsTestModule(bootstrap, clock));

      supabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository = Modular.get<ProjectRepository>() as ProjectRepositoryImpl;
    });

    tearDownAll(() {
      supabaseWrapper.reset();
      Modular.destroy();
    });

    setUp(() {
      supabaseWrapper.reset();
    });

    group('getProjectPermissions', () {
      test('returns all permissions assigned to the project', () {
        supabaseWrapper.setProjectPermissions('project-1', [
          'read',
          'write',
          'delete',
        ]);

        final result = repository.getProjectPermissions('project-1');

        expect(result, ['read', 'write', 'delete']);
      });

      test('returns empty list when project has no permissions', () {
        final result = repository.getProjectPermissions(
          'project-without-perms',
        );

        expect(result, isEmpty);
      });

      test('returns different permissions for different projects', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read']);
        supabaseWrapper.setProjectPermissions('project-2', ['read', 'write']);

        final result1 = repository.getProjectPermissions('project-1');
        final result2 = repository.getProjectPermissions('project-2');

        expect(result1, ['read']);
        expect(result2, ['read', 'write']);
      });
    });

    group('hasProjectPermission', () {
      test('returns true when user has the permission', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read', 'write']);

        final result = repository.hasProjectPermission('project-1', 'read');

        expect(result, isTrue);
      });

      test('returns false when user does not have the permission', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read']);

        final result = repository.hasProjectPermission('project-1', 'write');

        expect(result, isFalse);
      });

      test('returns false when project has no permissions', () {
        final result = repository.hasProjectPermission('project-1', 'read');

        expect(result, isFalse);
      });

      test('is case-sensitive for permission keys', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read']);

        expect(repository.hasProjectPermission('project-1', 'read'), isTrue);
        expect(repository.hasProjectPermission('project-1', 'Read'), isFalse);
        expect(repository.hasProjectPermission('project-1', 'READ'), isFalse);
      });

      test('is case-sensitive for project IDs', () {
        supabaseWrapper.setProjectPermissions('project-1', ['read']);

        expect(repository.hasProjectPermission('project-1', 'read'), isTrue);
        expect(repository.hasProjectPermission('Project-1', 'read'), isFalse);
        expect(repository.hasProjectPermission('PROJECT-1', 'read'), isFalse);
      });
    });
  });
}

Map<String, dynamic> _createProjectRow({
  required String id,
  required String projectName,
  required String creatorUserId,
  required DateTime updatedAt,
}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.projectNameColumn: projectName,
    DatabaseConstants.creatorUserIdColumn: creatorUserId,
    DatabaseConstants.createdAtColumn: DateTime(2025, 1, 1),
    DatabaseConstants.updatedAtColumn: updatedAt,
    DatabaseConstants.statusColumn: 'active',
  };
}

class _ProjectRepositoryTestModule extends Module {
  final FakeClockImpl clock;

  _ProjectRepositoryTestModule({required this.clock});

  @override
  void binds(Injector i) {
    i.addLazySingleton<FakeSupabaseWrapper>(
      () => FakeSupabaseWrapper(clock: clock),
    );
    i.addLazySingleton<ProjectDataSource>(
      () => RemoteProjectDataSource(
        supabaseWrapper: i.get<FakeSupabaseWrapper>(),
      ),
    );
    i.addLazySingleton<ProjectPermissionDataSource>(
      () => LocalJwtProjectPermissionDataSource(
        supabaseWrapper: i.get<FakeSupabaseWrapper>(),
      ),
    );
    i.addLazySingleton<CurrentProjectNotifier>(
      () => FakeCurrentProjectNotifier(),
    );
    i.addLazySingleton<ProjectRepositoryImpl>(
      () => ProjectRepositoryImpl(
        projectDataSource: i.get<ProjectDataSource>(),
        clock: clock,
        permissionDataSource: i.get<ProjectPermissionDataSource>(),
        currentProjectNotifier: i.get<CurrentProjectNotifier>(),
      ),
    );
  }
}

class _PermissionsTestModule extends Module {
  final AppBootstrap _bootstrap;
  final FakeClockImpl _clock;

  _PermissionsTestModule(this._bootstrap, this._clock);

  @override
  List<Module> get imports => [ProjectLibraryModule(_bootstrap)];

  @override
  void binds(Injector i) {
    i.addInstance<Clock>(_clock);
  }
}
