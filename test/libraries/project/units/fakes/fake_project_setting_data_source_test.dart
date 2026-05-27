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

    group('getProjectSetting', () {
      test('records method call with projectId', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');

        await fake.getProjectSetting('p-1');

        final calls = fake.getMethodCallsFor('getProjectSetting');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('returns projectToReturn when set', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'My Project');
        fake.projectToReturn = dto;

        final result = await fake.getProjectSetting('p-1');

        expect(result.id, equals('p-1'));
        expect(result.projectName, equals('My Project'));
      });

      test('throws ServerException when shouldThrowOnGet is true', () async {
        fake.shouldThrowOnGet = true;

        await expectLater(
          fake.getProjectSetting('p-1'),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException with custom message when getErrorMessage is set', () async {
        fake.shouldThrowOnGet = true;
        fake.getErrorMessage = 'Custom get error';

        await expectLater(
          fake.getProjectSetting('p-1'),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException when projectToReturn is null and no error flag', () async {
        await expectLater(
          fake.getProjectSetting('p-1'),
          throwsA(isA<ServerException>()),
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

      test('returns projectToReturn when set', () async {
        final updated = _fakeDto(id: 'p-1', projectName: 'Returned Name');
        fake.projectToReturn = updated;

        final result = await fake.updateProject(_fakeDto(id: 'p-1'));

        expect(result.projectName, equals('Returned Name'));
      });

      test('returns the passed dto when projectToReturn is null', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'Fallback');

        final result = await fake.updateProject(dto);

        expect(result.projectName, equals('Fallback'));
      });

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

      test('throws ServerException when shouldThrowOnDelete is true', () async {
        fake.shouldThrowOnDelete = true;

        await expectLater(
          fake.deleteProject('p-1'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('watchProjectChanges', () {
      test('records method call with projectId', () {
        fake.watchProjectChanges('p-1').listen((_) {});

        final calls = fake.getMethodCallsFor('watchProjectChanges');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('emits when emitChange is called', () async {
        final emittedCompleter = Completer<void>();
        final subscription = fake.watchProjectChanges('p-1').listen((_) {
          if (!emittedCompleter.isCompleted) emittedCompleter.complete();
        });

        fake.emitChange();

        await expectLater(emittedCompleter.future, completes);
        await subscription.cancel();
      });

      test('forwards errors when emitError is called', () async {
        final errorCompleter = Completer<Object>();
        final subscription = fake.watchProjectChanges('p-1').listen(
          (_) {},
          onError: (Object error, StackTrace _) {
            if (!errorCompleter.isCompleted) errorCompleter.complete(error);
          },
        );

        fake.emitError(Exception('test error'));

        final receivedError = await errorCompleter.future;
        expect(receivedError, isA<Exception>());
        await subscription.cancel();
      });

      test('throws ServerException when shouldThrowOnWatch is true', () {
        fake.shouldThrowOnWatch = true;

        expect(
          () => fake.watchProjectChanges('p-1'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('reset', () {
      test('clears all flags and recorded calls', () async {
        fake.shouldThrowOnGet = true;
        fake.shouldThrowOnUpdate = true;
        fake.shouldThrowOnDelete = true;
        fake.getErrorMessage = 'error';
        fake.projectToReturn = _fakeDto(id: 'p-1');
        fake.getMethodCallsFor('deleteProject');

        fake.reset();

        expect(fake.shouldThrowOnGet, isFalse);
        expect(fake.shouldThrowOnUpdate, isFalse);
        expect(fake.shouldThrowOnDelete, isFalse);
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
