import 'dart:async';

import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/data/repositories/project_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectRepositoryImpl', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late _FakeProjectDataSource projectDataSource;
    late ProjectRepositoryImpl repository;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 10, 1, 10, 30));
      Modular.init(_ProjectRepositoryTestModule(clock: clock));
      supabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      projectDataSource = Modular.get<_FakeProjectDataSource>();
      repository = Modular.get<ProjectRepositoryImpl>();
    });

    tearDown(() {
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
      test('returns empty list when current user is not available', () async {
        final result = await repository.getProjects();

        expect(result, isEmpty);
        expect(projectDataSource.lastOwnedUserId, isNull);
        expect(projectDataSource.lastSharedUserId, isNull);
      });

      test(
        'merges owned/shared projects, deduplicates, and sorts by updatedAt',
        () async {
          supabaseWrapper.setCurrentUser(
            FakeUser(
              id: 'user-123',
              email: 'test@example.com',
              createdAt: clock.now().toIso8601String(),
            ),
          );

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

          final result = await repository.getProjects();

          expect(projectDataSource.lastOwnedUserId, 'user-123');
          expect(projectDataSource.lastSharedUserId, 'user-123');
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
    });

    group('watchProjects', () {
      test(
        'emits initial projects and realtime updates for shared projects',
        () async {
          supabaseWrapper.setCurrentUser(
            FakeUser(
              id: 'user-123',
              email: 'test@example.com',
              createdAt: clock.now().toIso8601String(),
            ),
          );

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
          final subscription = repository.watchProjects().listen(
            emittedBatches.add,
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          projectDataSource.sharedProjects = [
            _createProjectDto(
              id: 'shared-project',
              projectName: 'Shared V2',
              creatorUserId: 'other-user',
              updatedAt: DateTime(2025, 1, 3),
            ),
          ];
          projectDataSource.emitProjectChange();

          await Future<void>.delayed(const Duration(milliseconds: 10));

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

      test(
        'queues a follow-up refresh when changes arrive mid-refresh',
        () async {
          supabaseWrapper.setCurrentUser(
            FakeUser(
              id: 'user-123',
              email: 'test@example.com',
              createdAt: clock.now().toIso8601String(),
            ),
          );

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
          projectDataSource.nextGetOwnedProjectsCompleter = firstRefreshCompleter;

          final emittedBatches = <List<Project>>[];
          final subscription = repository.watchProjects().listen(
            emittedBatches.add,
          );

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
          await Future<void>.delayed(const Duration(milliseconds: 20));

          await subscription.cancel();

          expect(projectDataSource.getOwnedProjectsCalls, greaterThanOrEqualTo(2));
          expect(emittedBatches.length, greaterThanOrEqualTo(2));
          expect(
            emittedBatches.first.firstWhere((project) => project.id == 'owned-project').projectName,
            'Owned V1',
          );
          expect(
            emittedBatches.last.firstWhere((project) => project.id == 'owned-project').projectName,
            'Owned V2',
          );
        },
      );
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
  int getOwnedProjectsCalls = 0;
  Completer<void>? firstGetOwnedProjectsStartedCompleter;
  Completer<void>? nextGetOwnedProjectsCompleter;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Future<List<ProjectDto>> getOwnedProjects(String userId) async {
    lastOwnedUserId = userId;
    getOwnedProjectsCalls++;

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
}

class _ProjectRepositoryTestModule extends Module {
  final FakeClockImpl clock;

  _ProjectRepositoryTestModule({required this.clock});

  @override
  void binds(Injector i) {
    i.addLazySingleton<SupabaseWrapper>(
      () => FakeSupabaseWrapper(clock: clock),
    );
    i.addLazySingleton<_FakeProjectDataSource>(() => _FakeProjectDataSource());
    i.addLazySingleton<ProjectDataSource>(
      () => i.get<_FakeProjectDataSource>(),
    );
    i.addLazySingleton<ProjectRepositoryImpl>(
      () => ProjectRepositoryImpl(
        projectDataSource: i.get<ProjectDataSource>(),
        supabaseWrapper: i.get<SupabaseWrapper>(),
        clock: clock,
      ),
    );
  }
}
