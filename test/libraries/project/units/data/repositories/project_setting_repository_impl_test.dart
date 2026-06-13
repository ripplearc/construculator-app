import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/data/repositories/project_setting_repository_impl.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/project/domain/repositories/project_setting_repository.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('ProjectSettingRepositoryImpl', () {
    late ProjectSettingRepositoryImpl repository;
    late FakeSupabaseWrapper supabaseWrapper;

    setUp(() {
      final clock = FakeClockImpl(DateTime(2025, 1, 1));
      Modular.init(
        _TestAppModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: clock),
          ),
        ),
      );
      supabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository =
          Modular.get<ProjectSettingRepository>()
              as ProjectSettingRepositoryImpl;
      supabaseWrapper.reset();
    });

    tearDown(() {
      Modular.destroy();
    });

    group('getProjectSetting', () {
      test('returns Right(project) when data source succeeds', () async {
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          {
            DatabaseConstants.idColumn: 'p-1',
            DatabaseConstants.projectNameColumn: 'Test Project',
            DatabaseConstants.creatorUserIdColumn: 'user-1',
            DatabaseConstants.createdAtColumn: DateTime(2025, 1, 1),
            DatabaseConstants.updatedAtColumn: DateTime(2025, 1, 2),
            DatabaseConstants.statusColumn: 'active',
          },
        ]);

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
          supabaseWrapper.shouldThrowOnSelect = true;

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
        supabaseWrapper.shouldThrowOnSelect = true;
        supabaseWrapper.selectExceptionType = SupabaseExceptionType.timeout;

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
        supabaseWrapper.shouldThrowOnSelect = true;
        supabaseWrapper.selectExceptionType = SupabaseExceptionType.auth;

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
        supabaseWrapper.shouldReturnNullOnSelect = true;

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
        supabaseWrapper.shouldThrowOnSelect = true;
        supabaseWrapper.selectExceptionType = SupabaseExceptionType.socket;

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
        supabaseWrapper.shouldThrowOnSelect = true;
        supabaseWrapper.selectExceptionType = SupabaseExceptionType.network;

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
        supabaseWrapper.shouldThrowOnSelect = true;
        supabaseWrapper.selectExceptionType = SupabaseExceptionType.type;

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
        supabaseWrapper.shouldThrowOnSelect = true;
        supabaseWrapper.selectExceptionType = SupabaseExceptionType.postgrest;
        supabaseWrapper.postgrestErrorCode = PostgresErrorCode.noDataFound;

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
          supabaseWrapper.shouldThrowOnSelect = true;
          supabaseWrapper.selectExceptionType = SupabaseExceptionType.postgrest;
          supabaseWrapper.postgrestErrorCode =
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
          supabaseWrapper.shouldThrowOnSelect = true;
          supabaseWrapper.selectExceptionType = SupabaseExceptionType.postgrest;
          supabaseWrapper.postgrestErrorCode =
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
          supabaseWrapper.shouldThrowOnSelect = true;
          supabaseWrapper.selectExceptionType = SupabaseExceptionType.postgrest;
          supabaseWrapper.postgrestErrorCode =
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
          supabaseWrapper.shouldThrowOnSelect = true;
          supabaseWrapper.selectExceptionType = SupabaseExceptionType.postgrest;
          supabaseWrapper.postgrestErrorCode =
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
          supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            {
              DatabaseConstants.idColumn: 'p-1',
              DatabaseConstants.projectNameColumn: 'Old Name',
              DatabaseConstants.creatorUserIdColumn: 'user-1',
              DatabaseConstants.createdAtColumn: DateTime(2025, 1, 1),
              DatabaseConstants.updatedAtColumn: DateTime(2025, 1, 2),
              DatabaseConstants.statusColumn: 'active',
            },
          ]);

          supabaseWrapper.setProjectPermissions('p-1', [
            PermissionConstants.editProject,
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

    group('createProject', () {
      test('returns Right(project) on success', () async {
        final project = Project(
          id: 'p-1',
          projectName: 'New Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          status: ProjectStatus.active,
        );

        final result = await repository.createProject(project);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (p) {
          expect(p.projectName, equals('New Project'));
          expect(p.creatorUserId, equals('user-1'));
        });
      });

      test('returns Left(unexpectedDatabaseError) on ServerException', () async {
        supabaseWrapper.shouldThrowOnInsert = true;

        final project = Project(
          id: 'p-1',
          projectName: 'New Project',
          creatorUserId: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          status: ProjectStatus.active,
        );

        final result = await repository.createProject(project);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ProjectFailure>());
          expect(
            (failure as ProjectFailure).errorType,
            equals(ProjectErrorType.unexpectedDatabaseError),
          );
        }, (_) => fail('Expected Left'));
      });
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
          supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
            {
              DatabaseConstants.idColumn: 'p-1',
              DatabaseConstants.projectNameColumn: 'ToDelete',
              DatabaseConstants.creatorUserIdColumn: 'user-1',
              DatabaseConstants.createdAtColumn: DateTime(2025, 1, 1),
              DatabaseConstants.updatedAtColumn: DateTime(2025, 1, 2),
              DatabaseConstants.statusColumn: 'active',
            },
          ]);

          supabaseWrapper.setProjectPermissions('p-1', [
            PermissionConstants.deleteProject,
          ]);

          final result = await repository.deleteProject('p-1');

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected Right'), (_) => null);

          // ensure row removed from fake supabase
          final row = await supabaseWrapper.selectSingle(
            table: DatabaseConstants.projectsTable,
            filterColumn: DatabaseConstants.idColumn,
            filterValue: 'p-1',
          );
          expect(row, isNull);
        },
      );
    });
  });
}

class _TestAppModule extends Module {
  final AppBootstrap appBootstrap;
  _TestAppModule(this.appBootstrap);

  @override
  List<Module> get imports => [ProjectLibraryModule(appBootstrap)];
}
