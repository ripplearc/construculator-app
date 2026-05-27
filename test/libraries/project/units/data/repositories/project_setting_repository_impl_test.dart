import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/data/repositories/project_setting_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  group('ProjectSettingRepositoryImpl', () {
    late _FakeProjectSettingDataSource dataSource;
    late _FakeProjectPermissionDataSource permissionDataSource;
    late ProjectSettingRepositoryImpl repository;

    setUp(() {
      dataSource = _FakeProjectSettingDataSource();
      permissionDataSource = _FakeProjectPermissionDataSource();
      repository = ProjectSettingRepositoryImpl(
        dataSource: dataSource,
        permissionDataSource: permissionDataSource,
      );
    });

    tearDown(() {
      repository.dispose();
      dataSource.dispose();
    });

    group('getProjectSetting', () {
      test('returns Right(project) when data source succeeds', () async {
        dataSource.projectToReturn = _fakeDto(
          id: 'p-1',
          projectName: 'Test Project',
        );

        final result = await repository.getProjectSetting('p-1');

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (project) {
            expect(project.id, equals('p-1'));
            expect(project.projectName, equals('Test Project'));
          },
        );
      });

      test('returns Left(notFoundError) on ServerException', () async {
        dataSource.shouldThrowOnGet = true;

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.notFoundError),
            );
          },
          (_) => fail('Expected Left'),
        );
      });

      test('returns Left(timeoutError) on TimeoutException', () async {
        dataSource.exceptionToThrow = TimeoutException('timeout');

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        expect(
          (result as Left).value,
          equals(
            const ProjectFailure(errorType: ProjectErrorType.timeoutError),
          ),
        );
      });

      test('returns Left(UnexpectedFailure) on unknown error', () async {
        dataSource.exceptionToThrow = Exception('unknown');

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        expect((result as Left).value, isA<UnexpectedFailure>());
      });
    });

    group('updateProject — permission check', () {
      test('returns Left(permissionDenied) when editProject permission missing', () async {
        permissionDataSource.setPermissions('p-1', []);

        final result = await repository.updateProject(_fakeProject(id: 'p-1'));

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.permissionDenied),
            );
          },
          (_) => fail('Expected Left'),
        );
      });

      test('does not call data source when editProject permission is missing', () async {
        permissionDataSource.setPermissions('p-1', []);

        await repository.updateProject(_fakeProject(id: 'p-1'));

        expect(dataSource.getMethodCallsFor('updateProject'), isEmpty);
      });
    });

    group('updateProject — happy path', () {
      test('calls data source with correctly constructed ProjectDto', () async {
        permissionDataSource.setPermissions('p-1', [
          PermissionConstants.editProject,
        ]);
        final updated = _fakeDto(id: 'p-1', projectName: 'Updated');
        dataSource.projectToReturn = updated;

        await repository.updateProject(
          _fakeProject(id: 'p-1', projectName: 'Updated'),
        );

        final calls = dataSource.getMethodCallsFor('updateProject');
        expect(calls, hasLength(1));
        final dto = calls.first['dto'] as ProjectDto;
        expect(dto.id, equals('p-1'));
        expect(dto.projectName, equals('Updated'));
      });

      test('returns Right(project) matching data source response', () async {
        permissionDataSource.setPermissions('p-1', [
          PermissionConstants.editProject,
        ]);
        dataSource.projectToReturn = _fakeDto(
          id: 'p-1',
          projectName: 'Server Name',
        );

        final result = await repository.updateProject(
          _fakeProject(id: 'p-1', projectName: 'Client Name'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (project) => expect(project.projectName, equals('Server Name')),
        );
      });

      test('returns Left(connectionError) on SocketException', () async {
        permissionDataSource.setPermissions('p-1', [
          PermissionConstants.editProject,
        ]);
        dataSource.exceptionToThrow = SocketException('no network');

        final result = await repository.updateProject(
          _fakeProject(id: 'p-1'),
        );

        expect(result.isLeft(), isTrue);
        expect(
          (result as Left).value,
          equals(
            const ProjectFailure(
              errorType: ProjectErrorType.connectionError,
            ),
          ),
        );
      });

      test('returns Left(parsingError) on TypeError', () async {
        permissionDataSource.setPermissions('p-1', [
          PermissionConstants.editProject,
        ]);
        dataSource.exceptionToThrow = TypeError();

        final result = await repository.updateProject(_fakeProject(id: 'p-1'));

        expect(result.isLeft(), isTrue);
        expect(
          (result as Left).value,
          equals(const ProjectFailure(errorType: ProjectErrorType.parsingError)),
        );
      });
    });

    group('deleteProject — permission check', () {
      test('returns Left(permissionDenied) when deleteProject permission missing', () async {
        permissionDataSource.setPermissions('p-1', []);

        final result = await repository.deleteProject('p-1');

        expect(result.isLeft(), isTrue);
        expect(
          ((result as Left).value as ProjectFailure).errorType,
          equals(ProjectErrorType.permissionDenied),
        );
      });

      test('does not call data source when deleteProject permission is missing', () async {
        permissionDataSource.setPermissions('p-1', []);

        await repository.deleteProject('p-1');

        expect(dataSource.getMethodCallsFor('deleteProject'), isEmpty);
      });
    });

    group('deleteProject — happy path', () {
      test('calls data source with the correct projectId', () async {
        permissionDataSource.setPermissions('p-1', [
          PermissionConstants.deleteProject,
        ]);

        await repository.deleteProject('p-1');

        final calls = dataSource.getMethodCallsFor('deleteProject');
        expect(calls, hasLength(1));
        expect(calls.first['projectId'], equals('p-1'));
      });

      test('returns Right(null) on success', () async {
        permissionDataSource.setPermissions('p-1', [
          PermissionConstants.deleteProject,
        ]);

        final result = await repository.deleteProject('p-1');

        expect(result.isRight(), isTrue);
      });

      test('returns Left(failure) on data source exception', () async {
        permissionDataSource.setPermissions('p-1', [
          PermissionConstants.deleteProject,
        ]);
        dataSource.shouldThrowOnDelete = true;

        final result = await repository.deleteProject('p-1');

        expect(result.isLeft(), isTrue);
      });
    });

    group('watchProjectSetting', () {
      test('emits current project on subscribe', () async {
        dataSource.projectToReturn = _fakeDto(id: 'p-1', projectName: 'v1');

        final emittedCompleter = Completer<Project>();
        final subscription = repository
            .watchProjectSetting('p-1')
            .listen((result) {
              result.fold(
                (_) {},
                (project) {
                  if (!emittedCompleter.isCompleted) {
                    emittedCompleter.complete(project);
                  }
                },
              );
            });

        final project = await emittedCompleter.future;
        expect(project.projectName, equals('v1'));
        await subscription.cancel();
      });

      test('re-emits on data source change notification', () async {
        dataSource.projectToReturn = _fakeDto(id: 'p-1', projectName: 'v1');

        final secondEmission = Completer<Project>();
        var emissionCount = 0;
        final subscription = repository
            .watchProjectSetting('p-1')
            .listen((result) {
              result.fold((_) {}, (project) {
                emissionCount++;
                if (emissionCount >= 2 && !secondEmission.isCompleted) {
                  secondEmission.complete(project);
                }
              });
            });

        await pumpEventQueue();

        dataSource.projectToReturn = _fakeDto(id: 'p-1', projectName: 'v2');
        dataSource.emitChange();

        final project = await secondEmission.future;
        expect(project.projectName, equals('v2'));
        await subscription.cancel();
      });

      test('emits Left when getProjectSetting fails during watch', () async {
        dataSource.shouldThrowOnGet = true;

        final failureCompleter = Completer<Failure>();
        final subscription = repository
            .watchProjectSetting('p-1')
            .listen((result) {
              result.fold((failure) {
                if (!failureCompleter.isCompleted) {
                  failureCompleter.complete(failure);
                }
              }, (_) {});
            });

        final failure = await failureCompleter.future;
        expect(failure, isA<ProjectFailure>());
        await subscription.cancel();
      });

      test('forwards stream error from data source to subscribers', () async {
        dataSource.projectToReturn = _fakeDto(id: 'p-1');

        final errorCompleter = Completer<Object>();
        final subscription = repository
            .watchProjectSetting('p-1')
            .listen(
              (_) {},
              onError: (Object error, StackTrace _) {
                if (!errorCompleter.isCompleted) errorCompleter.complete(error);
              },
            );

        await pumpEventQueue();
        dataSource.emitError(Exception('stream error'));

        final receivedError = await errorCompleter.future;
        expect(receivedError, isA<Exception>());
        await subscription.cancel();
      });

      test('cleans up resources on dispose', () async {
        dataSource.projectToReturn = _fakeDto(id: 'p-1');

        final subscription = repository.watchProjectSetting('p-1').listen((_) {});
        await pumpEventQueue();
        await subscription.cancel();

        repository.dispose();
        expect(dataSource.getMethodCallsFor('watchProjectChanges'), hasLength(1));
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

class _FakeProjectSettingDataSource implements ProjectSettingDataSource {
  final List<Map<String, dynamic>> _methodCalls = [];

  ProjectDto? projectToReturn;
  bool shouldThrowOnGet = false;
  bool shouldThrowOnDelete = false;
  Object? exceptionToThrow;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Future<ProjectDto> getProjectSetting(String projectId) async {
    _methodCalls.add({'method': 'getProjectSetting', 'projectId': projectId});

    final ex = exceptionToThrow;
    if (ex != null) {
      exceptionToThrow = null;
      throw ex;
    }

    if (shouldThrowOnGet) {
      throw ServerException(
        Trace.current(),
        Exception('Data source get failed'),
      );
    }

    final dto = projectToReturn;
    if (dto == null) {
      throw ServerException(Trace.current(), Exception('Not found'));
    }
    return dto;
  }

  @override
  Future<ProjectDto> updateProject(ProjectDto projectDto) async {
    _methodCalls.add({'method': 'updateProject', 'dto': projectDto});

    final ex = exceptionToThrow;
    if (ex != null) {
      exceptionToThrow = null;
      throw ex;
    }

    return projectToReturn ?? projectDto;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _methodCalls.add({'method': 'deleteProject', 'projectId': projectId});

    final ex = exceptionToThrow;
    if (ex != null) {
      exceptionToThrow = null;
      throw ex;
    }

    if (shouldThrowOnDelete) {
      throw ServerException(Trace.current(), Exception('Delete failed'));
    }
  }

  @override
  Stream<void> watchProjectChanges(String projectId) {
    _methodCalls.add({
      'method': 'watchProjectChanges',
      'projectId': projectId,
    });
    return _changesController.stream;
  }

  void emitChange() => _changesController.add(null);

  void emitError(Object error) => _changesController.addError(error);

  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls
        .where((call) => call['method'] == methodName)
        .toList();
  }

  void dispose() => _changesController.close();
}

class _FakeProjectPermissionDataSource implements ProjectPermissionDataSource {
  final Map<String, List<String>> _permissions = {};

  void setPermissions(String projectId, List<String> permissions) {
    _permissions[projectId] = permissions;
  }

  @override
  List<String> getProjectPermissions(String projectId) {
    return List.from(_permissions[projectId] ?? []);
  }

  @override
  bool hasProjectPermission(String projectId, String permissionKey) {
    return _permissions[projectId]?.contains(permissionKey) ?? false;
  }
}
