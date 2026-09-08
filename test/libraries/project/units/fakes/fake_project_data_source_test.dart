import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/testing/fake_project_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeProjectDataSource', () {
    late FakeProjectDataSource fake;

    setUp(() {
      fake = FakeProjectDataSource();
    });

    tearDown(() {
      fake.dispose();
    });

    group('getOwnedProjects', () {
      test('returns ownedProjects list', () async {
        fake.ownedProjects = [_fakeDto(id: 'p-1'), _fakeDto(id: 'p-2')];

        final result = await fake.getOwnedProjects('user-1');

        expect(result, hasLength(2));
        expect(result.first.id, equals('p-1'));
      });

      test('returns empty list by default', () async {
        final result = await fake.getOwnedProjects('user-1');

        expect(result, isEmpty);
      });

      test('throws ServerException when shouldThrowOnGetOwned is true',
          () async {
        fake.shouldThrowOnGetOwned = true;

        await expectLater(
          fake.getOwnedProjects('user-1'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getSharedProjects', () {
      test('returns sharedProjects list', () async {
        fake.sharedProjects = [_fakeDto(id: 'p-3')];

        final result = await fake.getSharedProjects('user-1');

        expect(result, hasLength(1));
        expect(result.first.id, equals('p-3'));
      });

      test('returns empty list by default', () async {
        final result = await fake.getSharedProjects('user-1');

        expect(result, isEmpty);
      });

      test('throws ServerException when shouldThrowOnGetShared is true',
          () async {
        fake.shouldThrowOnGetShared = true;

        await expectLater(
          fake.getSharedProjects('user-1'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('watchProjectChanges', () {
      test('emits event when emitProjectChange is called', () async {
        final stream = fake.watchProjectChanges('user-1');
        final future = stream.first;

        fake.emitProjectChange();

        await expectLater(future, completes);
      });

      test('emits error when emitError is called', () async {
        final stream = fake.watchProjectChanges('user-1');
        final future = expectLater(stream, emitsError(isA<Exception>()));

        fake.emitError(Exception('watch error'));

        await future;
      });
    });

    group('getProject', () {
      test('returns projectToReturn when set', () async {
        final dto = _fakeDto(id: 'p-1', projectName: 'My Project');
        fake.projectToReturn = dto;

        final result = await fake.getProject('p-1');

        expect(result.id, equals('p-1'));
        expect(result.projectName, equals('My Project'));
      });

      test(
        'throws getProjectExceptionToThrow when set, before other checks',
        () async {
          fake.projectToReturn = _fakeDto(id: 'p-1');
          fake.getProjectExceptionToThrow = TimeoutException('timed out');

          await expectLater(
            fake.getProject('p-1'),
            throwsA(isA<TimeoutException>()),
          );
        },
      );

      test('throws ServerException when shouldThrowOnGetProject is true',
          () async {
        fake.shouldThrowOnGetProject = true;

        await expectLater(
          fake.getProject('p-1'),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NotFoundException when projectToReturn is null', () async {
        await expectLater(
          fake.getProject('p-1'),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('reset', () {
      test('clears all state', () async {
        fake.ownedProjects = [_fakeDto(id: 'p-1')];
        fake.sharedProjects = [_fakeDto(id: 'p-2')];
        fake.projectToReturn = _fakeDto(id: 'p-3');
        fake.getProjectExceptionToThrow = Exception('err');
        fake.shouldThrowOnGetOwned = true;
        fake.shouldThrowOnGetShared = true;
        fake.shouldThrowOnGetProject = true;

        fake.reset();

        expect(fake.ownedProjects, isEmpty);
        expect(fake.sharedProjects, isEmpty);
        expect(fake.projectToReturn, isNull);
        expect(fake.getProjectExceptionToThrow, isNull);
        expect(fake.shouldThrowOnGetOwned, isFalse);
        expect(fake.shouldThrowOnGetShared, isFalse);
        expect(fake.shouldThrowOnGetProject, isFalse);
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
