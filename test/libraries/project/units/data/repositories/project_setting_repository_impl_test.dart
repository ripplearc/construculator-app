import 'dart:async';

import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/remote_project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/data/repositories/project_setting_repository_impl.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectSettingRepositoryImpl', () {
    late RemoteProjectSettingDataSource dataSource;
    late ProjectSettingRepositoryImpl repository;
    late FakeSupabaseWrapper supabaseWrapper;
    late FakeClockImpl clock;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1));
      supabaseWrapper = FakeSupabaseWrapper(clock: clock);
      dataSource = RemoteProjectSettingDataSource(
        supabaseWrapper: supabaseWrapper,
      );
      repository = ProjectSettingRepositoryImpl(dataSource: dataSource);
    });

    tearDown(() {
      repository.dispose();
      supabaseWrapper.dispose();
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

      test('returns Left(UnexpectedFailure) on unknown error', () async {
        final throwingDataSource = _ThrowingDataSource();
        final repoWithThrowingDs = ProjectSettingRepositoryImpl(
          dataSource: throwingDataSource,
        );

        final result = await repoWithThrowingDs.getProjectSetting('p-1');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<UnexpectedFailure>());
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
    });
  });
}

class _ThrowingDataSource implements ProjectSettingDataSource {
  @override
  Future<ProjectDto> fetchProjectSetting(String projectId) async {
    throw Exception('unknown');
  }

  @override
  Future<ProjectDto> updateProject(ProjectDto projectDto) async =>
      throw Exception('unknown');

  @override
  Future<void> deleteProject(String projectId) async =>
      throw Exception('unknown');

  @override
  Stream<ProjectDto?> watchProjectChanges(String projectId) =>
      Stream.error(Exception('unknown'));
}
