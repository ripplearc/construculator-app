import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/local_jwt_project_permission_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/data/repositories/project_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_data_source.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('ProjectRepositoryImpl', () {
    late FakeClockImpl clock;
    late _FakeProjectDataSource projectDataSource;
    late FakeProjectSettingDataSource projectSettingDataSource;
    late ProjectRepositoryImpl repository;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 10, 1, 10, 30));
      Modular.init(_ProjectRepositoryTestModule(clock: clock));
      projectDataSource = Modular.get<_FakeProjectDataSource>();
      projectSettingDataSource = Modular.get<FakeProjectSettingDataSource>();
      repository = Modular.get<ProjectRepositoryImpl>();
    });

    tearDown(() {
      projectDataSource.dispose();
      projectSettingDataSource.reset();
      Modular.destroy();
    });

    group('getProject', () {
      test('returns mapped domain project from data source', () async {
        projectSettingDataSource.projectToReturn = ProjectDto(
          id: 'project-abc',
          projectName: 'Real Project',
          creatorUserId: 'user-001',
          createdAt: DateTime(2025, 3, 1),
          updatedAt: DateTime(2025, 3, 2),
          status: ProjectStatus.active,
        );

        final result = await repository.getProject('project-abc');

        expect(result, isA<Project>());
        expect(result.id, equals('project-abc'));
        expect(result.projectName, equals('Real Project'));
        expect(result.creatorUserId, equals('user-001'));
        expect(result.status, equals(ProjectStatus.active));
      });

      test(
        'throws ProjectFailure with notFoundError when data source throws NotFoundException',
        () async {
          projectSettingDataSource.fetchExceptionToThrow = NotFoundException(
            Trace.current(),
            Exception('Project not found'),
          );

          await expectLater(
            repository.getProject('missing-project'),
            throwsA(
              isA<ProjectFailure>().having(
                (f) => f.errorType,
                'errorType',
                ProjectErrorType.notFoundError,
              ),
            ),
          );
        },
      );

      test(
        'throws ProjectFailure with timeoutError when data source throws TimeoutException',
        () async {
          projectSettingDataSource.fetchExceptionToThrow = TimeoutException(
            'timed out',
          );

          await expectLater(
            repository.getProject('any-id'),
            throwsA(
              isA<ProjectFailure>().having(
                (f) => f.errorType,
                'errorType',
                ProjectErrorType.timeoutError,
              ),
            ),
          );
        },
      );

      test(
        'throws ProjectFailure with unexpectedDatabaseError when data source throws ServerException',
        () async {
          projectSettingDataSource.shouldThrowOnGet = true;

          await expectLater(
            repository.getProject('any-id'),
            throwsA(
              isA<ProjectFailure>().having(
                (f) => f.errorType,
                'errorType',
                ProjectErrorType.unexpectedDatabaseError,
              ),
            ),
          );
        },
      );
    });

    group('getProjects', () {
      test('returns empty list when userId is empty string', () async {
        final result = await repository.getProjects('');

        expect(result, isEmpty);
        expect(projectDataSource.lastOwnedUserId, isNull);
        expect(projectDataSource.lastSharedUserId, isNull);
      });

      test(
        'merges owned/shared projects, deduplicates, and sorts by updatedAt',
        () async {
          const userId = 'user-123';

          projectDataSource.ownedProjects = [
            _createProjectDto(
              id: 'owned-old',
              projectName: 'Owned Old',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 1),
            ),
            _createProjectDto(
              id: 'duplicate-project',
              projectName: 'Owned Duplicate (older)',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 2),
            ),
          ];

          projectDataSource.sharedProjects = [
            _createProjectDto(
              id: 'shared-new',
              projectName: 'Shared Newest',
              creatorUserId: 'another-user',
              updatedAt: DateTime(2025, 1, 4),
            ),
            _createProjectDto(
              id: 'duplicate-project',
              projectName: 'Shared Duplicate (newer)',
              creatorUserId: 'another-user',
              updatedAt: DateTime(2025, 1, 3),
            ),
          ];

          final result = await repository.getProjects(userId);

          expect(projectDataSource.lastOwnedUserId, userId);
          expect(projectDataSource.lastSharedUserId, userId);
          expect(result.map((project) => project.id).toList(), [
            'shared-new',
            'duplicate-project',
            'owned-old',
          ]);
          expect(
            result
                .firstWhere((project) => project.id == 'duplicate-project')
                .projectName,
            'Shared Duplicate (newer)',
          );
        },
      );

      test('throws ProjectFailure when owned projects fetch fails', () async {
        projectDataSource.getOwnedProjectsError = TimeoutException('timeout');

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

          projectDataSource.ownedProjects = [
            _createProjectDto(
              id: 'owned-project',
              projectName: 'Owned',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 1),
            ),
          ];
          projectDataSource.sharedProjects = [
            _createProjectDto(
              id: 'shared-project',
              projectName: 'Shared V1',
              creatorUserId: 'other-user',
              updatedAt: DateTime(2025, 1, 2),
            ),
          ];

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

          projectDataSource.sharedProjects = [
            _createProjectDto(
              id: 'shared-project',
              projectName: 'Shared V2',
              creatorUserId: 'other-user',
              updatedAt: DateTime(2025, 1, 3),
            ),
          ];
          projectDataSource.emitProjectChange();

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

        projectDataSource.emitError(Exception('realtime failure'));

        await errorReceived.future;
        await subscription.cancel();
      });

      test(
        'queues a follow-up refresh when changes arrive mid-refresh',
        () async {
          const userId = 'user-123';

          projectDataSource.ownedProjects = [
            _createProjectDto(
              id: 'owned-project',
              projectName: 'Owned V1',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 1),
            ),
          ];

          projectDataSource.firstGetOwnedProjectsStartedCompleter =
              Completer<void>();
          final firstRefreshCompleter = Completer<void>();
          projectDataSource.nextGetOwnedProjectsCompleter =
              firstRefreshCompleter;

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

          await projectDataSource.firstGetOwnedProjectsStartedCompleter!.future;

          // While first refresh is in-flight, update data and emit a second tick.
          projectDataSource.ownedProjects = [
            _createProjectDto(
              id: 'owned-project',
              projectName: 'Owned V2',
              creatorUserId: 'user-123',
              updatedAt: DateTime(2025, 1, 2),
            ),
          ];
          projectDataSource.emitProjectChange();

          firstRefreshCompleter.complete();
          await secondEmissionReceived.future;

          await subscription.cancel();

          expect(
            projectDataSource.getOwnedProjectsCalls,
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

ProjectDto _createProjectDto({
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
  String? lastOwnedUserId;
  String? lastSharedUserId;
  Object? getOwnedProjectsError;
  int getOwnedProjectsCalls = 0;
  Completer<void>? firstGetOwnedProjectsStartedCompleter;
  Completer<void>? nextGetOwnedProjectsCompleter;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Future<List<ProjectDto>> getOwnedProjects(String userId) async {
    lastOwnedUserId = userId;
    getOwnedProjectsCalls++;

    final error = getOwnedProjectsError;
    if (error != null) {
      throw error;
    }

    final snapshot = List<ProjectDto>.from(ownedProjects);
    if (firstGetOwnedProjectsStartedCompleter?.isCompleted == false) {
      firstGetOwnedProjectsStartedCompleter?.complete();
    }

    final pendingDelay = nextGetOwnedProjectsCompleter;
    if (pendingDelay != null) {
      nextGetOwnedProjectsCompleter = null;
      await pendingDelay.future;
    }

    return snapshot;
  }

  @override
  Future<List<ProjectDto>> getSharedProjects(String userId) async {
    lastSharedUserId = userId;
    return sharedProjects;
  }

  @override
  Stream<void> watchProjectChanges(String userId) => _changesController.stream;

  void emitProjectChange() {
    _changesController.add(null);
  }

  void emitError(Object error) {
    _changesController.addError(error);
  }

  void dispose() {
    _changesController.close();
  }
}

// TODO: Refactor to use FakeSupabaseWrapper instead of custom _FakeProjectDataSource (https://ripplearc.youtrack.cloud/issue/CA-635/Project-Refactor-projectrepositorytest.dart-to-use-FakeSupabaseWrapper-instead-of-custom-fake)
class _ProjectRepositoryTestModule extends Module {
  final FakeClockImpl clock;

  _ProjectRepositoryTestModule({required this.clock});

  @override
  void binds(Injector i) {
    i.addLazySingleton<_FakeProjectDataSource>(() => _FakeProjectDataSource());
    i.addLazySingleton<ProjectDataSource>(
      () => i.get<_FakeProjectDataSource>(),
    );
    i.addLazySingleton<FakeProjectSettingDataSource>(
      () => FakeProjectSettingDataSource(),
    );
    i.addLazySingleton<ProjectSettingDataSource>(
      () => i.get<FakeProjectSettingDataSource>(),
    );
    i.addLazySingleton<ProjectPermissionDataSource>(
      () => LocalJwtProjectPermissionDataSource(
        supabaseWrapper: FakeSupabaseWrapper(clock: clock),
      ),
    );
    i.addLazySingleton<CurrentProjectNotifier>(
      () => FakeCurrentProjectNotifier(),
    );
    i.addLazySingleton<ProjectRepositoryImpl>(
      () => ProjectRepositoryImpl(
        projectDataSource: i.get<ProjectDataSource>(),
        projectSettingDataSource: i.get<ProjectSettingDataSource>(),
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
