import 'dart:async';
import 'dart:io';

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
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('ProjectSettingRepositoryImpl', () {
    late _FakeProjectPermissionDataSource permissionDataSource;
    late ProjectSettingRepository repository;
    late _FakeProjectSettingDataSource fakeDataSource;

    setUp(() {
      Modular.init(_ProjectSettingRepositoryTestModule());
      fakeDataSource = Modular.get<_FakeProjectSettingDataSource>();
      permissionDataSource = Modular.get<_FakeProjectPermissionDataSource>();
      repository = Modular.get<ProjectSettingRepository>();
    });

    tearDown(() {
      repository.dispose();
      fakeDataSource.dispose();
      Modular.destroy();
    });

    group('getProjectSetting', () {
      test('returns Right(project) when data source succeeds', () async {
        fakeDataSource.projectToReturn = _fakeDto(
          id: 'p-1',
          projectName: 'Test Project',
        );

        final result = await repository.getProjectSetting('p-1');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (project) {
          expect(project.id, equals('p-1'));
          expect(project.projectName, equals('Test Project'));
        });
      });

      test(
        'returns Left(unexpectedDatabaseError) on ServerException',
        () async {
          fakeDataSource.shouldThrowOnGet = true;

          final result = await repository.getProjectSetting('p-1');

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.unexpectedDatabaseError),
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test('returns Left(timeoutError) on TimeoutException', () async {
        fakeDataSource.shouldThrowOnGet = true;
        fakeDataSource.exceptionToThrow = TimeoutException('Select failed');

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(
            failure,
            equals(
              const ProjectFailure(errorType: ProjectErrorType.timeoutError),
            ),
          );
        }, (_) => fail('Expected Left'));
      });

      test('returns Left(unexpectedError) on unknown error', () async {
        fakeDataSource.exceptionToThrow = Exception('unknown');

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ProjectFailure>());
          expect(
            (failure as ProjectFailure).errorType,
            equals(ProjectErrorType.unexpectedError),
          );
        }, (_) => fail('Expected Left'));
      });

      test('returns Left(notFoundError) on NotFoundException', () async {
        fakeDataSource.exceptionToThrow = NotFoundException(
          Trace.current(),
          Exception('not found'),
        );

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(
            failure,
            equals(
              const ProjectFailure(errorType: ProjectErrorType.notFoundError),
            ),
          );
        }, (_) => fail('Expected Left'));
      });

      test('returns Left(connectionError) on SocketException', () async {
        fakeDataSource.exceptionToThrow = const SocketException('socket error');

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(
            failure,
            equals(
              const ProjectFailure(errorType: ProjectErrorType.connectionError),
            ),
          );
        }, (_) => fail('Expected Left'));
      });

      test('returns Left(connectionError) on NetworkException', () async {
        fakeDataSource.exceptionToThrow = NetworkException(
          Trace.current(),
          Exception('network error'),
        );

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(
            failure,
            equals(
              const ProjectFailure(errorType: ProjectErrorType.connectionError),
            ),
          );
        }, (_) => fail('Expected Left'));
      });

      test('returns Left(parsingError) on TypeError', () async {
        fakeDataSource.exceptionToThrow = _typeError();

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(
            failure,
            equals(
              const ProjectFailure(errorType: ProjectErrorType.parsingError),
            ),
          );
        }, (_) => fail('Expected Left'));
      });

      test('maps PostgrestException PGRST116 to notFoundError', () async {
        fakeDataSource.exceptionToThrow = supabase.PostgrestException(
          message: 'Select failed',
          code: PostgresErrorCode.noDataFound.toString(),
        );

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ProjectFailure>());
          expect(
            (failure as ProjectFailure).errorType,
            equals(ProjectErrorType.notFoundError),
          );
        }, (_) => fail('Expected Left'));
      });

      test(
        'maps PostgrestException connection codes to connectionError',
        () async {
          fakeDataSource.exceptionToThrow = supabase.PostgrestException(
            message: 'Select failed',
            code: PostgresErrorCode.connectionFailure.toString(),
          );

          final result = await repository.getProjectSetting('p-1');

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.connectionError),
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test(
        'maps PostgrestException unableToConnect to connectionError',
        () async {
          fakeDataSource.exceptionToThrow = supabase.PostgrestException(
            message: 'connection refused',
            code: PostgresErrorCode.unableToConnect.toString(),
          );

          final result = await repository.getProjectSetting('p-1');

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.connectionError),
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test(
        'maps PostgrestException connectionDoesNotExist to connectionError',
        () async {
          fakeDataSource.exceptionToThrow = supabase.PostgrestException(
            message: 'connection does not exist',
            code: PostgresErrorCode.connectionDoesNotExist.toString(),
          );

          final result = await repository.getProjectSetting('p-1');

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.connectionError),
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test(
        'maps PostgrestException unknown code to unexpectedDatabaseError',
        () async {
          fakeDataSource.exceptionToThrow = supabase.PostgrestException(
            message: 'unique violation',
            code: PostgresErrorCode.uniqueViolation.toString(),
          );

          final result = await repository.getProjectSetting('p-1');

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<ProjectFailure>());
            expect(
              (failure as ProjectFailure).errorType,
              equals(ProjectErrorType.unexpectedDatabaseError),
            );
          }, (_) => fail('Expected Left'));
        },
      );
    });

    group('updateProject', () {
      test('returns Left(permissionDenied) when permission missing', () async {
        final project = Project(
          id: 'p-1',
          projectName: 'Name',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          status: ProjectStatus.active,
        );

        final result = await repository.updateProject(project);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ProjectFailure>());
          expect(
            (failure as ProjectFailure).errorType,
            equals(ProjectErrorType.permissionDenied),
          );
        }, (_) => fail('Expected Left'));
      });

      test(
        'returns Right(project) when permission present and update succeeds',
        () async {
          permissionDataSource.setPermissions('p-1', [
            PermissionConstants.editProject,
          ]);

          fakeDataSource.projectToReturn = _fakeDto(
            id: 'p-1',
            projectName: 'New Name',
          );

          final project = Project(
            id: 'p-1',
            projectName: 'New Name',
            creatorUserId: 'user-1',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 3),
            status: ProjectStatus.active,
          );

          final result = await repository.updateProject(project);

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (p) {
            expect(p.id, equals('p-1'));
            expect(p.projectName, equals('New Name'));
          });
        },
      );
    });

    group('deleteProject', () {
      test('returns Left(permissionDenied) when permission missing', () async {
        final result = await repository.deleteProject('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ProjectFailure>());
          expect(
            (failure as ProjectFailure).errorType,
            equals(ProjectErrorType.permissionDenied),
          );
        }, (_) => fail('Expected Left'));
      });

      test(
        'returns Right(null) when permission present and delete succeeds',
        () async {
          permissionDataSource.setPermissions('p-1', [
            PermissionConstants.deleteProject,
          ]);

          final result = await repository.deleteProject('p-1');

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (_) => null);
        },
      );
    });

    group('watchProjectSetting', () {
      test('emits current project on subscribe', () async {
        fakeDataSource.projectToReturn = _fakeDto(id: 'p-1', projectName: 'v1');

        final emittedCompleter = Completer<Project>();
        final subscription = repository.watchProjectSetting('p-1').listen((
          result,
        ) {
          result.fold((_) {}, (project) {
            if (!emittedCompleter.isCompleted) {
              emittedCompleter.complete(project);
            }
          });
        });

        final project = await emittedCompleter.future;
        expect(project.projectName, equals('v1'));
        await subscription.cancel();
      });

      test('re-emits on data source change notification', () async {
        fakeDataSource.projectToReturn = _fakeDto(id: 'p-1', projectName: 'v1');

        final secondEmission = Completer<Project>();
        var emissionCount = 0;
        final subscription = repository.watchProjectSetting('p-1').listen((
          result,
        ) {
          result.fold((_) {}, (project) {
            emissionCount++;
            if (emissionCount >= 2 && !secondEmission.isCompleted) {
              secondEmission.complete(project);
            }
          });
        });

        await pumpEventQueue();

        fakeDataSource.projectToReturn = _fakeDto(id: 'p-1', projectName: 'v2');
        fakeDataSource.emitChange();

        final project = await secondEmission.future;
        expect(project.projectName, equals('v2'));
        await subscription.cancel();
      });

      test('emits Left when getProjectSetting fails during watch', () async {
        fakeDataSource.shouldThrowOnGet = true;

        final failureCompleter = Completer<Failure>();
        final subscription = repository.watchProjectSetting('p-1').listen((
          result,
        ) {
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
        fakeDataSource.projectToReturn = _fakeDto(id: 'p-1');

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
        fakeDataSource.emitError(Exception('stream error'));

        final receivedError = await errorCompleter.future;
        expect(receivedError, isA<Exception>());
        await subscription.cancel();
      });

      test('cleans up resources on dispose', () async {
        fakeDataSource.projectToReturn = _fakeDto(id: 'p-1');

        final subscription = repository
            .watchProjectSetting('p-1')
            .listen((_) {});
        await pumpEventQueue();
        await subscription.cancel();

        repository.dispose();
        expect(
          fakeDataSource.getMethodCallsFor('watchProjectChanges'),
          hasLength(1),
        );
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

TypeError _typeError() {
  try {
    final Object value = 'not an int';
    value as int;
  } on TypeError catch (error) {
    return error;
  }
  throw StateError('Expected cast to throw TypeError');
}

class _FakeProjectSettingDataSource implements ProjectSettingDataSource {
  final List<Map<String, dynamic>> _methodCalls = [];

  ProjectDto? projectToReturn;
  bool shouldThrowOnGet = false;
  bool shouldThrowOnDelete = false;
  Object? exceptionToThrow;

  final StreamController<ProjectDto?> _changesController =
      StreamController<ProjectDto?>.broadcast();

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
  Stream<ProjectDto?> watchProjectChanges(String projectId) {
    _methodCalls.add({'method': 'watchProjectChanges', 'projectId': projectId});
    return _changesController.stream;
  }

  void emitChange() => _changesController.add(projectToReturn);

  void emitError(Object error) => _changesController.addError(error);

  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  void dispose() => _changesController.close();

  @override
  Future<ProjectDto> fetchProjectSetting(String projectId) {
    _methodCalls.add({'method': 'fetchProjectSetting', 'projectId': projectId});

    final ex = exceptionToThrow;
    if (ex != null) {
      exceptionToThrow = null;
      throw ex;
    }

    if (shouldThrowOnGet) {
      throw ServerException(Trace.current(), Exception('Select failed'));
    }

    if (projectToReturn != null) return Future.value(projectToReturn);

    throw ServerException(
      Trace.current(),
      Exception('No project configured in FakeProjectSettingDataSource'),
    );
  }
}

class _FakeProjectPermissionDataSource implements ProjectPermissionDataSource {
  final Map<String, List<String>> _permissions = {};

  void setPermissions(String projectId, List<String> permissions) {
    _permissions[projectId] = List<String>.from(permissions);
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

class _ProjectSettingRepositoryTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<_FakeProjectSettingDataSource>(
      () => _FakeProjectSettingDataSource(),
    );
    i.addLazySingleton<ProjectSettingDataSource>(
      () => i.get<_FakeProjectSettingDataSource>(),
    );
    i.addLazySingleton<_FakeProjectPermissionDataSource>(
      () => _FakeProjectPermissionDataSource(),
    );
    i.addLazySingleton<ProjectPermissionDataSource>(
      () => i.get<_FakeProjectPermissionDataSource>(),
    );
    i.addLazySingleton<ProjectSettingRepository>(
      () => ProjectSettingRepositoryImpl(
        dataSource: i.get<ProjectSettingDataSource>(),
        permissionDataSource: i.get<ProjectPermissionDataSource>(),
      ),
    );
  }
}
