import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/testing/fake_project_setting_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeProjectSettingDataSource', () {
    late FakeProjectSettingDataSource fake;

    setUp(() {
      fake = FakeProjectSettingDataSource();
    });

    tearDown(() {
      fake.reset();
      fake.dispose();
    });

    group('createProject', () {
      test('returns the provided ProjectDto', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'New Project');

        final result = await fake.createProject(dto);

        expect(result, equals(dto));
      });

      test('records method call', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'New Project');

        await fake.createProject(dto);

        final calls = fake.getMethodCallsFor('createProject');
        expect(calls, hasLength(1));
        expect(calls.first['projectDto'], equals(dto));
      });

      test('throws ServerException when shouldThrowOnCreate is true', () async {
        fake.shouldThrowOnCreate = true;

        await expectLater(
          fake.createProject(_fakeDto(id: 'p-1')),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('fetchProjectSetting', () {
      test('records method call with projectId', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');

        await fake.fetchProjectSetting('p-1');

        final calls = fake.getMethodCallsFor('fetchProjectSetting');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('returns projectToReturn when set', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'My Project');
        fake.projectToReturn = dto;

        final result = await fake.fetchProjectSetting('p-1');

        expect(result.id, equals('p-1'));
        expect(result.projectName, equals('My Project'));
      });

      test('throws ServerException when shouldThrowOnGet is true', () async {
        fake.shouldThrowOnGet = true;

        await expectLater(
          fake.fetchProjectSetting('p-1'),
          throwsA(isA<ServerException>()),
        );
      });

      test(
        'throws ServerException with custom message when getErrorMessage is set',
        () async {
          fake.shouldThrowOnGet = true;
          fake.getErrorMessage = 'Custom get error';

          await expectLater(
            fake.fetchProjectSetting('p-1'),
            throwsA(isA<ServerException>()),
          );
        },
      );

      test(
        'throws ServerException when projectToReturn is null and no error flag',
        () async {
          await expectLater(
            fake.fetchProjectSetting('p-1'),
            throwsA(isA<ServerException>()),
          );
        },
      );

      test('fetchExceptionToThrow takes precedence over shouldThrowOnGet',
          () async {
        fake.shouldThrowOnGet = true;
        fake.fetchExceptionToThrow = TimeoutException('timed out');

        await expectLater(
          fake.fetchProjectSetting('p-1'),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('updateProject', () {
      test('records method call with projectDto', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'Updated');
        fake.projectToReturn = dto;

        await fake.updateProject(dto);

        final calls = fake.getMethodCallsFor('updateProject');
        expect(calls, hasLength(1));
        expect(calls.first['projectDto'], equals(dto));
      });

      test('always returns the passed dto, overriding pre-set projectToReturn',
          () async {
        final preExisting = _fakeDto(id: 'p-1', projectName: 'Old Name');
        fake.projectToReturn = preExisting;
        final newDto = _fakeDto(id: 'p-1', projectName: 'New Name');

        final result = await fake.updateProject(newDto);

        expect(result.projectName, equals('New Name'));
        expect(fake.projectToReturn!.projectName, equals('New Name'));
      });

      test('returns the passed dto when projectToReturn is null', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'Fallback');

        final result = await fake.updateProject(dto);

        expect(result.projectName, equals('Fallback'));
      });

      test(
        'persists result so subsequent fetchProjectSetting returns it',
        () async {
          final dto = _fakeDto(id: 'p-1', projectName: 'Written');

          await fake.updateProject(dto);
          final fetched = await fake.fetchProjectSetting('p-1');

          expect(fetched.projectName, equals('Written'));
        },
      );

      test('throws ServerException when shouldThrowOnUpdate is true', () async {
        fake.shouldThrowOnUpdate = true;

        await expectLater(
          fake.updateProject(_fakeDto(id: 'p-1')),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('deleteProject', () {
      test('records method call with projectId', () async {
        await fake.deleteProject('p-1');

        final calls = fake.getMethodCallsFor('deleteProject');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('completes successfully by default', () async {
        await expectLater(fake.deleteProject('p-1'), completes);
      });

      test('clears projectToReturn so subsequent fetch throws', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');

        await fake.deleteProject('p-1');

        await expectLater(
          fake.fetchProjectSetting('p-1'),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException when shouldThrowOnDelete is true', () async {
        fake.shouldThrowOnDelete = true;

        await expectLater(
          fake.deleteProject('p-1'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('reset', () {
      test('clears all flags and recorded calls', () async {
        fake.shouldThrowOnCreate = true;
        fake.shouldThrowOnGet = true;
        fake.shouldThrowOnUpdate = true;
        fake.shouldThrowOnDelete = true;
        fake.createErrorMessage = 'create error';
        fake.getErrorMessage = 'get error';
        fake.projectToReturn = _fakeDto(id: 'p-1');

        fake.reset();

        expect(fake.shouldThrowOnCreate, isFalse);
        expect(fake.shouldThrowOnGet, isFalse);
        expect(fake.shouldThrowOnUpdate, isFalse);
        expect(fake.shouldThrowOnDelete, isFalse);
        expect(fake.createErrorMessage, isNull);
        expect(fake.getErrorMessage, isNull);
        expect(fake.projectToReturn, isNull);
        expect(fake.getMethodCalls(), isEmpty);
      });
    });
  });
}

ProjectDto _fakeDto({required String id, String? projectName}) {
  return ProjectDto(
    id: id,
    projectName: projectName ?? 'Test Project',
    creatorUserId: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  );
}
