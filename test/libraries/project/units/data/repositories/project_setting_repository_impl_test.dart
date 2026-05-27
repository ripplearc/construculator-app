import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/local_jwt_project_permission_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/remote_project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/repositories/project_setting_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('ProjectSettingRepositoryImpl', () {
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;
    late ProjectSettingRepositoryImpl repository;

    setUp(() {
      fakeClock = FakeClockImpl();
      Modular.init(
        _TestModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository =
          Modular.get<ProjectSettingRepository>()
              as ProjectSettingRepositoryImpl;
      fakeSupabaseWrapper.reset();
    });

    tearDown(() {
      fakeSupabaseWrapper.reset();
      Modular.destroy();
    });

    test('exports the real repository and data source bindings', () {
      expect(
        Modular.get<ProjectSettingRepository>(),
        isA<ProjectSettingRepositoryImpl>(),
      );
      expect(
        Modular.get<ProjectSettingDataSource>(),
        isA<RemoteProjectSettingDataSource>(),
      );
    });

    group('getProjectSetting', () {
      test('returns Right(project) when data source succeeds', () async {
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1', projectName: 'Test Project'),
        ]);

        final result = await repository.getProjectSetting('p-1');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (project) {
          expect(project.id, equals('p-1'));
          expect(project.projectName, equals('Test Project'));
        });
      });

      test('returns Left(unexpectedDatabaseError) on server error', () async {
        fakeSupabaseWrapper.shouldThrowOnSelect = true;

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ProjectFailure>());
          expect(
            (failure as ProjectFailure).errorType,
            equals(ProjectErrorType.unexpectedDatabaseError),
          );
        }, (_) => fail('Expected Left'));
      });

      test('returns Left(timeoutError) on TimeoutException', () async {
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectExceptionType = SupabaseExceptionType.timeout;

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

      test('returns Left(notFoundError) when project does not exist', () async {
        fakeSupabaseWrapper.shouldReturnNullOnSelect = true;

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

      test('returns Left(UnexpectedFailure) on unexpected error', () async {
        // AuthException is not handled by _handleError and falls through to
        // UnexpectedFailure — the only reachable path via FakeSupabaseWrapper.
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectExceptionType = SupabaseExceptionType.auth;

        final result = await repository.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<UnexpectedFailure>());
        }, (_) => fail('Expected Left'));
      });

      test('returns Left(connectionError) on SocketException', () async {
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectExceptionType = SupabaseExceptionType.socket;

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
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectExceptionType = SupabaseExceptionType.type;

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
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectExceptionType = SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.postgrestErrorCode = PostgresErrorCode.noDataFound;

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
          fakeSupabaseWrapper.shouldThrowOnSelect = true;
          fakeSupabaseWrapper.selectExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;

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
          fakeSupabaseWrapper.shouldThrowOnSelect = true;
          fakeSupabaseWrapper.selectExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.unableToConnect;

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
          fakeSupabaseWrapper.shouldThrowOnSelect = true;
          fakeSupabaseWrapper.selectExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionDoesNotExist;

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
          fakeSupabaseWrapper.shouldThrowOnSelect = true;
          fakeSupabaseWrapper.selectExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;

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
          fakeSupabaseWrapper.setProjectPermissions('p-1', [
            PermissionConstants.editProject,
          ]);
          fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            _fakeProjectRow(id: 'p-1', projectName: 'Old Name'),
          ]);

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
          fakeSupabaseWrapper.setProjectPermissions('p-1', [
            PermissionConstants.deleteProject,
          ]);
          fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            _fakeProjectRow(id: 'p-1'),
          ]);

          final result = await repository.deleteProject('p-1');

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (_) => null);
        },
      );
    });

    group('watchProjectSetting', () {
      test('reuses one stream controller per project', () async {
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1'),
        ]);

        final firstStream = repository.watchProjectSetting('p-1');
        final secondStream = repository.watchProjectSetting('p-1');

        final firstCompleter = Completer<Project>();
        final secondCompleter = Completer<Project>();

        final firstSubscription = firstStream.listen((result) {
          result.fold((_) {}, (project) {
            if (!firstCompleter.isCompleted) {
              firstCompleter.complete(project);
            }
          });
        });
        final secondSubscription = secondStream.listen((result) {
          result.fold((_) {}, (project) {
            if (!secondCompleter.isCompleted) {
              secondCompleter.complete(project);
            }
          });
        });

        await firstCompleter.future;
        await secondCompleter.future;

        expect(
          fakeSupabaseWrapper
              .getMethodCalls()
              .where((c) => c['method'] == 'watchTableFiltered')
              .length,
          equals(1),
        );

        await firstSubscription.cancel();
        await secondSubscription.cancel();
      });

      test('emits current project on subscribe', () async {
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1', projectName: 'v1'),
        ]);

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
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1', projectName: 'v1'),
        ]);

        final v2Completer = Completer<Project>();
        final subscription = repository.watchProjectSetting('p-1').listen((
          result,
        ) {
          result.fold((_) {}, (project) {
            if (project.projectName == 'v2' && !v2Completer.isCompleted) {
              v2Completer.complete(project);
            }
          });
        });

        await pumpEventQueue();

        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1', projectName: 'v2'),
        ]);

        final project = await v2Completer.future;
        expect(project.projectName, equals('v2'));
        await subscription.cancel();
      });

      test('emits Left when getProjectSetting fails during watch', () async {
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1'),
        ]);
        fakeSupabaseWrapper.shouldThrowOnSelect = true;

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
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1'),
        ]);

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

        fakeSupabaseWrapper.shouldEmitStreamErrors = true;
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1'),
        ]);

        final receivedError = await errorCompleter.future;
        expect(receivedError, isA<Exception>());
        await subscription.cancel();
      });

      test('can watch multiple projects concurrently', () async {
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1', projectName: 'Alpha'),
          _fakeProjectRow(id: 'p-2', projectName: 'Beta'),
        ]);

        final alphaCompleter = Completer<Project>();
        final betaCompleter = Completer<Project>();

        final sub1 = repository.watchProjectSetting('p-1').listen((result) {
          result.fold((_) {}, (p) {
            if (!alphaCompleter.isCompleted) alphaCompleter.complete(p);
          });
        });
        final sub2 = repository.watchProjectSetting('p-2').listen((result) {
          result.fold((_) {}, (p) {
            if (!betaCompleter.isCompleted) betaCompleter.complete(p);
          });
        });

        final alpha = await alphaCompleter.future;
        final beta = await betaCompleter.future;

        expect(alpha.projectName, equals('Alpha'));
        expect(beta.projectName, equals('Beta'));

        await sub1.cancel();
        await sub2.cancel();
      });

      test('cleans up resources on dispose', () async {
        fakeSupabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _fakeProjectRow(id: 'p-1'),
        ]);

        final subscription = repository
            .watchProjectSetting('p-1')
            .listen((_) {});
        await pumpEventQueue();
        await subscription.cancel();

        repository.dispose();
        expect(
          fakeSupabaseWrapper
              .getMethodCalls()
              .where((c) => c['method'] == 'watchTableFiltered')
              .length,
          equals(1),
        );
      });
    });
  });
}

Map<String, dynamic> _fakeProjectRow({
  required String id,
  String? projectName,
}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.creatorUserIdColumn: 'user-1',
    DatabaseConstants.createdAtColumn: '2025-01-01T00:00:00.000Z',
    DatabaseConstants.updatedAtColumn: '2025-01-02T00:00:00.000Z',
    DatabaseConstants.statusColumn: 'active',
  };
}

class _TestModule extends Module {
  final AppBootstrap _appBootstrap;
  _TestModule(this._appBootstrap);

  @override
  List<Module> get imports => [SupabaseModule(_appBootstrap)];

  @override
  void binds(Injector i) {
    i.addLazySingleton<ProjectSettingDataSource>(
      () => RemoteProjectSettingDataSource(
        supabaseWrapper: Modular.get<SupabaseWrapper>(),
      ),
    );
    i.addLazySingleton<ProjectPermissionDataSource>(
      () => LocalJwtProjectPermissionDataSource(
        supabaseWrapper: Modular.get<SupabaseWrapper>(),
      ),
    );
    i.addLazySingleton<ProjectSettingRepository>(
      () => ProjectSettingRepositoryImpl(
        dataSource: Modular.get<ProjectSettingDataSource>(),
        permissionDataSource: Modular.get<ProjectPermissionDataSource>(),
      ),
      config: BindConfig(onDispose: (r) => r.dispose()),
    );
  }
}
