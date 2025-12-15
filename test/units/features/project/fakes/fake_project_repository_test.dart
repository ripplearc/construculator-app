import 'dart:async';
import 'package:construculator/features/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeProjectRepository fakeRepository;
  late Clock clock;

  Project createFakeProject({
    String? id,
    String? projectName,
    String? description,
    String? creatorUserId,
    String? owningCompanyId,
    String? exportFolderLink,
    StorageProvider? exportStorageProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectStatus? status,
  }) {
    final now = clock.now();
    return Project(
      id: id ?? 'test-project-${now.millisecondsSinceEpoch}',
      projectName: projectName ?? 'Test Project',
      description: description ?? 'Test project description',
      creatorUserId: creatorUserId ?? 'test-user-123',
      owningCompanyId: owningCompanyId ?? 'test-company-123',
      exportFolderLink:
          exportFolderLink ?? 'https://drive.google.com/test-folder',
      exportStorageProvider:
          exportStorageProvider ?? StorageProvider.googleDrive,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      status: status ?? ProjectStatus.active,
    );
  }

  setUp(() {
    clock = FakeClockImpl();
    fakeRepository = FakeProjectRepository();
  });

  tearDown(() {
    fakeRepository.reset();
  });

  group('Project Retrieval', () {
    test('getProject should track method calls', () async {
      final testProject = createFakeProject(id: 'test-id');
      fakeRepository.addProject('test-id', testProject);

      expect(fakeRepository.getMethodCallsFor('getProject'), isEmpty);

      await fakeRepository.getProject('test-id');

      final calls = fakeRepository.getMethodCallsFor('getProject');
      expect(calls, hasLength(1));
      expect(calls.first['id'], equals('test-id'));
    });

    test('getProject should return project when it exists', () async {
      final testProject = createFakeProject(
        id: 'test-id',
        projectName: 'My Test Project',
        description: 'A test project description',
      );
      fakeRepository.addProject('test-id', testProject);

      final result = await fakeRepository.getProject('test-id');

      expect(result, isNotNull);
      expect(result.id, equals('test-id'));
      expect(result.projectName, equals('My Test Project'));
      expect(result.description, equals('A test project description'));
    });

    test(
      'getProject should throw ServerException when project does not exist',
      () async {
        expect(
          () => fakeRepository.getProject('non-existent-id'),
          throwsA(isA<ServerException>()),
        );

        final calls = fakeRepository.getMethodCallsFor('getProject');
        expect(calls, hasLength(1));
        expect(calls.first['id'], equals('non-existent-id'));
      },
    );

    test(
      'getProject should throw configured exception when shouldThrowOnGetProject is true',
      () async {
        fakeRepository.shouldThrowOnGetProject = true;
        fakeRepository.getProjectErrorMessage = 'Custom error message';

        expect(
          () => fakeRepository.getProject('any-id'),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'getProject should throw TimeoutException when configured with timeout type',
      () async {
        fakeRepository.shouldThrowOnGetProject = true;
        fakeRepository.getProjectExceptionType = SupabaseExceptionType.timeout;
        fakeRepository.getProjectErrorMessage = 'Request timeout';

        expect(
          () => fakeRepository.getProject('any-id'),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test(
      'getProject should throw TypeError when configured with type exception',
      () async {
        fakeRepository.shouldThrowOnGetProject = true;
        fakeRepository.getProjectExceptionType = SupabaseExceptionType.type;

        expect(
          () => fakeRepository.getProject('any-id'),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('getProject should handle delayed operations', () async {
      final testProject = createFakeProject(id: 'test-id');
      fakeRepository.addProject('test-id', testProject);
      fakeRepository.shouldDelayOperations = true;
      fakeRepository.completer = Completer();

      final future = fakeRepository.getProject('test-id');

      bool completedImmediately = false;
      future.then((_) => completedImmediately = true);
      expect(completedImmediately, isFalse);

      fakeRepository.completer!.complete();
      final result = await future;

      expect(result, isNotNull);
      expect(result.id, equals('test-id'));
    });
  });

  group('Test Data Management', () {
    test('addProject should store project data for retrieval', () async {
      final testProject = createFakeProject(
        id: 'stored-project',
        projectName: 'Stored Project',
        status: ProjectStatus.archived,
      );

      fakeRepository.addProject('stored-project', testProject);

      final result = await fakeRepository.getProject('stored-project');
      expect(result.id, equals('stored-project'));
      expect(result.projectName, equals('Stored Project'));
      expect(result.status, equals(ProjectStatus.archived));
    });

    test('clearProject should remove specific project data', () async {
      final testProject = createFakeProject(id: 'to-be-removed');
      fakeRepository.addProject('to-be-removed', testProject);

      final result = await fakeRepository.getProject('to-be-removed');
      expect(result, isNotNull);

      fakeRepository.clearProject('to-be-removed');

      expect(
        () => fakeRepository.getProject('to-be-removed'),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'clearAllData should remove all project data and method calls',
      () async {
        final project1 = createFakeProject(id: 'project-1');
        final project2 = createFakeProject(id: 'project-2');

        fakeRepository.addProject('project-1', project1);
        fakeRepository.addProject('project-2', project2);

        try {
          await fakeRepository.getProject('project-1');
        } catch (e) {
          // Ignore exceptions for this test
        }

        expect(fakeRepository.getMethodCalls(), isNotEmpty);
        expect(fakeRepository.getMethodCallsFor('getProject'), isNotEmpty);

        fakeRepository.clearAllData();

        expect(fakeRepository.getMethodCalls(), isEmpty);
        expect(
          () => fakeRepository.getProject('project-1'),
          throwsA(isA<ServerException>()),
        );
        expect(
          () => fakeRepository.getProject('project-2'),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('Method Call Tracking', () {
    test('getMethodCalls should return all method calls', () async {
      final testProject = createFakeProject(id: 'test-id');
      fakeRepository.addProject('test-id', testProject);

      await fakeRepository.getProject('test-id');
      await fakeRepository.getProject('test-id');

      final allCalls = fakeRepository.getMethodCalls();
      expect(allCalls, hasLength(2));
      expect(allCalls.every((call) => call['method'] == 'getProject'), isTrue);
    });

    test(
      'getLastMethodCall should return the most recent method call',
      () async {
        final testProject1 = createFakeProject(id: 'test-id-1');
        final testProject2 = createFakeProject(id: 'test-id-2');

        fakeRepository.addProject('test-id-1', testProject1);
        fakeRepository.addProject('test-id-2', testProject2);

        await fakeRepository.getProject('test-id-1');
        await fakeRepository.getProject('test-id-2');

        final lastCall = fakeRepository.getLastMethodCall();
        expect(lastCall, isNotNull);
        expect(lastCall!['method'], equals('getProject'));
        expect(lastCall['id'], equals('test-id-2'));
      },
    );

    test('getLastMethodCall should return null when no calls made', () {
      final lastCall = fakeRepository.getLastMethodCall();
      expect(lastCall, isNull);
    });

    test('getMethodCallsFor should return calls for specific method', () async {
      final testProject = createFakeProject(id: 'test-id');
      fakeRepository.addProject('test-id', testProject);

      await fakeRepository.getProject('test-id');
      await fakeRepository.getProject('test-id');

      final getProjectCalls = fakeRepository.getMethodCallsFor('getProject');
      expect(getProjectCalls, hasLength(2));
      expect(
        getProjectCalls.every((call) => call['method'] == 'getProject'),
        isTrue,
      );

      final nonExistentCalls = fakeRepository.getMethodCallsFor(
        'nonExistentMethod',
      );
      expect(nonExistentCalls, isEmpty);
    });

    test('clearMethodCalls should remove all method call tracking', () async {
      final testProject = createFakeProject(id: 'test-id');
      fakeRepository.addProject('test-id', testProject);

      await fakeRepository.getProject('test-id');
      expect(fakeRepository.getMethodCalls(), isNotEmpty);

      fakeRepository.clearMethodCalls();
      expect(fakeRepository.getMethodCalls(), isEmpty);
    });
  });

  group('Repository Reset', () {
    test('reset should clear all configurations and data', () async {
      final testProject = createFakeProject(id: 'test-id');
      fakeRepository.addProject('test-id', testProject);
      fakeRepository.shouldThrowOnGetProject = true;
      fakeRepository.getProjectErrorMessage = 'Test error';
      fakeRepository.getProjectExceptionType = SupabaseExceptionType.timeout;
      fakeRepository.shouldDelayOperations = true;
      fakeRepository.completer = Completer();

      fakeRepository.completer!.complete();
      try {
        await fakeRepository.getProject('test-id');
      } catch (e) {
        // Ignore exceptions
      }

      expect(fakeRepository.shouldThrowOnGetProject, isTrue);
      expect(fakeRepository.getProjectErrorMessage, equals('Test error'));
      expect(
        fakeRepository.getProjectExceptionType,
        equals(SupabaseExceptionType.timeout),
      );
      expect(fakeRepository.shouldDelayOperations, isTrue);
      expect(fakeRepository.completer, isNotNull);
      expect(fakeRepository.getMethodCalls(), isNotEmpty);

      fakeRepository.reset();

      expect(fakeRepository.shouldThrowOnGetProject, isFalse);
      expect(fakeRepository.getProjectErrorMessage, isNull);
      expect(fakeRepository.getProjectExceptionType, isNull);
      expect(fakeRepository.shouldDelayOperations, isFalse);
      expect(fakeRepository.completer, isNull);
      expect(fakeRepository.getMethodCalls(), isEmpty);
      expect(
        () => fakeRepository.getProject('test-id'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
