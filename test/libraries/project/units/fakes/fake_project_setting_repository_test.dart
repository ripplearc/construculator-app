import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeProjectSettingRepository', () {
    late FakeProjectSettingRepository fake;

    setUp(() {
      fake = FakeProjectSettingRepository();
    });

    tearDown(() {
      fake.reset();
      fake.dispose();
    });

    group('createProject', () {
      test('returns Right(project) by default', () async {
        final project = _fakeProject(id: 'p-1', projectName: 'New Project');

        final result = await fake.createProject(project);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (p) => expect(p.projectName, equals('New Project')),
        );
      });

      test('records method call with project', () async {
        final project = _fakeProject(id: 'p-1');

        await fake.createProject(project);

        final calls = fake.getMethodCallsFor('createProject');
        expect(calls, hasLength(1));
        expect(calls.first['project'], equals(project));
      });

      test('returns Left when shouldFailOnCreate is true', () async {
        fake.shouldFailOnCreate = true;

        final result = await fake.createProject(_fakeProject(id: 'p-1'));

        expect(result.isLeft(), isTrue);
      });
    });

    group('getProjectSetting', () {
      test('records method call with projectId', () async {
        fake.projectToReturn = _fakeProject(id: 'p-1');

        await fake.getProjectSetting('p-1');

        final calls = fake.getMethodCallsFor('getProjectSetting');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('returns Right(project) when projectToReturn is set', () async {
        fake.projectToReturn = _fakeProject(
          id: 'p-1',
          projectName: 'My Project',
        );

        final result = await fake.getProjectSetting('p-1');

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (project) => expect(project.projectName, equals('My Project')),
        );
      });

      test(
        'returns Left(notFoundError) when projectToReturn is null',
        () async {
          final result = await fake.getProjectSetting('p-1');

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.notFoundError),
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test(
        'returns Left(failureToReturn) when shouldFailOnGet is true',
        () async {
          fake.shouldFailOnGet = true;
          fake.failureToReturn = const ProjectFailure(
            errorType: ProjectErrorType.connectionError,
          );

          final result = await fake.getProjectSetting('p-1');

          expect(result.isLeft(), isTrue);
          expect(
            ((result as Left).value as ProjectFailure).errorType,
            equals(ProjectErrorType.connectionError),
          );
        },
      );
    });

    group('updateProject', () {
      test('records method call with project', () async {
        final project = _fakeProject(id: 'p-1');
        fake.projectToReturn = project;

        await fake.updateProject(project);

        final calls = fake.getMethodCallsFor('updateProject');
        expect(calls, hasLength(1));
        expect(calls.first['project'], equals(project));
      });

      test('returns Right(passed project) and mutates projectToReturn', () async {
        fake.projectToReturn = _fakeProject(id: 'p-1', projectName: 'Old');
        final updated = _fakeProject(id: 'p-1', projectName: 'New');

        final result = await fake.updateProject(updated);

        result.fold(
          (_) => fail('Expected Right'),
          (project) => expect(project.projectName, equals('New')),
        );
        expect(fake.projectToReturn!.projectName, equals('New'));
      });

      test(
        'returns Right(passed project) when projectToReturn is null',
        () async {
          final project = _fakeProject(id: 'p-1', projectName: 'Fallback');

          final result = await fake.updateProject(project);

          result.fold(
            (_) => fail('Expected Right'),
            (p) => expect(p.projectName, equals('Fallback')),
          );
        },
      );

      test('returns Left when shouldFailOnUpdate is true', () async {
        fake.shouldFailOnUpdate = true;

        final result = await fake.updateProject(_fakeProject(id: 'p-1'));

        expect(result.isLeft(), isTrue);
      });
    });

    group('deleteProject', () {
      test('records method call with projectId', () async {
        await fake.deleteProject('p-1');

        final calls = fake.getMethodCallsFor('deleteProject');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('returns Right(null) by default', () async {
        final result = await fake.deleteProject('p-1');

        expect(result.isRight(), isTrue);
      });

      test('returns Left when shouldFailOnDelete is true', () async {
        fake.shouldFailOnDelete = true;

        final result = await fake.deleteProject('p-1');

        expect(result.isLeft(), isTrue);
      });
    });

    group('reset', () {
      test('clears all flags, data, and method calls', () async {
        fake.shouldFailOnCreate = true;
        fake.shouldFailOnGet = true;
        fake.shouldFailOnUpdate = true;
        fake.shouldFailOnDelete = true;
        fake.projectToReturn = _fakeProject(id: 'p-1');
        fake.failureToReturn = const ProjectFailure(
          errorType: ProjectErrorType.connectionError,
        );
        await fake.deleteProject('p-1');

        fake.reset();

        expect(fake.shouldFailOnCreate, isFalse);
        expect(fake.shouldFailOnGet, isFalse);
        expect(fake.shouldFailOnUpdate, isFalse);
        expect(fake.shouldFailOnDelete, isFalse);
        expect(fake.projectToReturn, isNull);
        expect(fake.getMethodCalls(), isEmpty);
        expect(
          fake.failureToReturn,
          equals(
            const ProjectFailure(errorType: ProjectErrorType.unexpectedError),
          ),
        );
      });
    });
  });
}

Project _fakeProject({required String id, String? projectName}) {
  return Project(
    id: id,
    projectName: projectName ?? 'Test Project',
    creatorUserId: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  );
}
