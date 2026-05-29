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
        expect(fake.projectToReturn?.projectName, equals('New Name'));
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

      test('propagates the updated dto to the watch stream', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1', projectName: 'Initial');
        final updated = _fakeDto(id: 'p-1', projectName: 'Updated');

        final future = expectLater(
          fake.watchProjectChanges('p-1'),
          emitsThrough(updated),
        );
        await fake.updateProject(updated);
        await future;
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

      test('clears projectToReturn so subsequent fetch throws', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');

        await fake.deleteProject('p-1');

        await expectLater(
          fake.fetchProjectSetting('p-1'),
          throwsA(isA<ServerException>()),
        );
      });

      test('emits null to the watch stream before closing it', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');

        final future = expectLater(
          fake.watchProjectChanges('p-1'),
          emitsThrough(isNull),
        );
        await fake.deleteProject('p-1');
        await future;
      });

      test('closes the project stream on deletion', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');
        final isDone = Completer<void>();

        fake
            .watchProjectChanges('p-1')
            .listen((_) {}, onDone: isDone.complete);

        await fake.deleteProject('p-1');

        await expectLater(isDone.future, completes);
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
        fake.projectToReturn = _fakeDto(id: 'p-1');
        fake.watchProjectChanges('p-1').listen((_) {});

        final calls = fake.getMethodCallsFor('watchProjectChanges');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('emits current snapshot immediately on subscription', () async {
        final dto = _fakeDto(id: 'p-1');
        fake.projectToReturn = dto;

        final first = await fake.watchProjectChanges('p-1').first;

        expect(first, equals(dto));
      });

      test('emits null snapshot when projectToReturn is null', () async {
        final first = await fake.watchProjectChanges('p-1').first;

        expect(first, isNull);
      });

      test('emits updated value when emitChange is called', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1', projectName: 'Initial');
        final emittedValues = <ProjectDto?>[];

        final subscription = fake
            .watchProjectChanges('p-1')
            .listen(emittedValues.add);
        await expectLater(
          fake.watchProjectChanges('p-1'),
          emits(_fakeDto(id: 'p-1', projectName: 'Initial')),
        );

        final updated = _fakeDto(id: 'p-1', projectName: 'Updated');
        fake.projectToReturn = updated;
        fake.emitChange('p-1');
        await expectLater(fake.watchProjectChanges('p-1'), emits(updated));

        expect(emittedValues, contains(updated));
        await subscription.cancel();
      });

      test('isolates streams per project', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');
        final p1Values = <ProjectDto?>[];
        final p2Values = <ProjectDto?>[];

        final s1 = fake.watchProjectChanges('p-1').listen(p1Values.add);
        final s2 = fake.watchProjectChanges('p-2').listen(p2Values.add);
        await expectLater(
          fake.watchProjectChanges('p-1'),
          emits(_fakeDto(id: 'p-1')),
        );

        fake.emitChange('p-1');
        await expectLater(fake.watchProjectChanges('p-1'), emits(anything));

        expect(p1Values.length, greaterThan(1)); // seed + emitChange emission
        expect(p2Values, hasLength(1)); // only the BehaviorSubject seed, never p1's emit

        await s1.cancel();
        await s2.cancel();
      });

      test('forwards errors when emitError is called', () async {
        fake.projectToReturn = _fakeDto(id: 'p-1');
        final errorCompleter = Completer<Object>();

        final subscription = fake
            .watchProjectChanges('p-1')
            .listen(
              (_) {},
              onError: (Object error, StackTrace _) {
                if (!errorCompleter.isCompleted) errorCompleter.complete(error);
              },
            );

        fake.emitError(Exception('test error'), 'p-1');

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
