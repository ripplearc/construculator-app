import 'dart:async';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/data_source/remote_project_setting_data_source.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('RemoteProjectSettingDataSource', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteProjectSettingDataSource dataSource;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
      supabaseWrapper = FakeSupabaseWrapper(clock: clock);
      dataSource = RemoteProjectSettingDataSource(
        supabaseWrapper: supabaseWrapper,
      );
    });

    tearDown(() {
      supabaseWrapper.reset();
    });

    group('getProjectSetting', () {
      test('returns ProjectDto when project exists', () async {
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(id: 'project-1', projectName: 'My Project'),
        ]);

        final result = await dataSource.fetchProjectSetting('project-1');

        expect(result.id, equals('project-1'));
        expect(result.projectName, equals('My Project'));
      });

      test('throws NotFoundException when project does not exist', () async {
        await expectLater(
          dataSource.fetchProjectSetting('non-existent'),
          throwsA(isA<NotFoundException>()),
        );
      });

      test(
        'rethrows when selectSingle throws due to shouldReturnNullOnSelect',
        () async {
          supabaseWrapper.shouldReturnNullOnSelect = true;

          await expectLater(
            dataSource.fetchProjectSetting('project-1'),
            throwsA(isA<NotFoundException>()),
          );
        },
      );

      test('rethrows PostgrestException from supabaseWrapper', () async {
        supabaseWrapper.shouldThrowOnSelect = true;
        supabaseWrapper.selectExceptionType = SupabaseExceptionType.postgrest;

        await expectLater(
          dataSource.fetchProjectSetting('project-1'),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });

    group('updateProject', () {
      test('calls update with correct table, data map, and filter', () async {
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(id: 'project-1', projectName: 'Old Name'),
        ]);

        final dto = _projectDto(id: 'project-1', projectName: 'New Name');
        final result = await dataSource.updateProject(dto);

        expect(result.id, equals('project-1'));
        expect(result.projectName, equals('New Name'));

        final updateCalls = supabaseWrapper.getMethodCallsFor('update');
        expect(updateCalls, hasLength(1));
        expect(
          updateCalls.first['table'],
          equals(DatabaseConstants.projectsTable),
        );
        expect(
          updateCalls.first['filterColumn'],
          equals(DatabaseConstants.idColumn),
        );
        expect(updateCalls.first['filterValue'], equals('project-1'));
      });

      test('includes description in data map when provided', () async {
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(
            id: 'project-1',
            projectName: 'Project',
            description: 'Old desc',
          ),
        ]);

        final dto = _projectDto(
          id: 'project-1',
          projectName: 'Project',
          description: 'New desc',
        );
        await dataSource.updateProject(dto);

        final updateCalls = supabaseWrapper.getMethodCallsFor('update');
        final data = updateCalls.first['data'] as Map<String, dynamic>;
        expect(data[DatabaseConstants.descriptionColumn], equals('New desc'));
      });

      test('rethrows PostgrestException on shouldThrowOnUpdate', () async {
        supabaseWrapper.shouldThrowOnUpdate = true;
        supabaseWrapper.updateExceptionType = SupabaseExceptionType.postgrest;

        final dto = _projectDto(id: 'project-1', projectName: 'Name');
        await expectLater(
          dataSource.updateProject(dto),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });

    group('deleteProject', () {
      test('calls deleteMatch with correct table and filters', () async {
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(id: 'project-1', projectName: 'To Delete'),
        ]);

        await dataSource.deleteProject('project-1');

        final deleteMatchCalls = supabaseWrapper.getMethodCallsFor(
          'deleteMatch',
        );
        expect(deleteMatchCalls, hasLength(1));
        expect(
          deleteMatchCalls.first['table'],
          equals(DatabaseConstants.projectsTable),
        );
        expect(
          (deleteMatchCalls.first['filters']
              as Map<String, dynamic>)[DatabaseConstants.idColumn],
          equals('project-1'),
        );
      });

      test('rethrows on shouldThrowOnDeleteMatch', () async {
        supabaseWrapper.shouldThrowOnDeleteMatch = true;
        supabaseWrapper.deleteMatchExceptionType =
            SupabaseExceptionType.postgrest;

        await expectLater(
          dataSource.deleteProject('project-1'),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });

    group('watchProjectChanges', () {
      test('emits when project row changes', () async {
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(id: 'project-1', projectName: 'Initial'),
        ]);

        final emissions = <ProjectDto?>[];
        final emissionCompleter = Completer<void>();
        var emissionCount = 0;
        final subscription = dataSource.watchProjectChanges('project-1').listen(
          (projectDto) {
            emissions.add(projectDto);
            emissionCount++;
            if (emissionCount >= 2 && !emissionCompleter.isCompleted) {
              emissionCompleter.complete();
            }
          },
        );

        await pumpEventQueue();

        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(id: 'project-1', projectName: 'Updated'),
        ]);

        await expectLater(emissionCompleter.future, completes);
        expect(emissions.first?.projectName, equals('Initial'));
        expect(emissions.last?.projectName, equals('Updated'));
        await subscription.cancel();
      });

      test('forwards stream errors to subscribers', () async {
        final errorCompleter = Completer<Object>();
        final subscription = dataSource
            .watchProjectChanges('project-1')
            .listen(
              (_) {},
              onError: (Object error, StackTrace _) {
                if (!errorCompleter.isCompleted) errorCompleter.complete(error);
              },
            );

        await pumpEventQueue();

        supabaseWrapper.shouldEmitStreamErrors = true;
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(id: 'project-1', projectName: 'Trigger'),
        ]);

        final receivedError = await errorCompleter.future;
        expect(receivedError, isA<ServerException>());
        await subscription.cancel();
      });
    });
  });
}

Map<String, dynamic> _projectRow({
  required String id,
  required String projectName,
  String? description,
}) {
  return {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.projectNameColumn: projectName,
    DatabaseConstants.descriptionColumn:
        description ?? '$projectName description',
    DatabaseConstants.creatorUserIdColumn: 'user-1',
    DatabaseConstants.owningCompanyIdColumn: 'company-1',
    DatabaseConstants.exportFolderLinkColumn: null,
    DatabaseConstants.exportStorageProviderColumn: null,
    DatabaseConstants.createdAtColumn: DateTime(2025, 1, 1).toIso8601String(),
    DatabaseConstants.updatedAtColumn: DateTime(2025, 1, 2).toIso8601String(),
    DatabaseConstants.statusColumn: 'active',
  };
}

ProjectDto _projectDto({
  required String id,
  required String projectName,
  String? description,
}) {
  return ProjectDto(
    id: id,
    projectName: projectName,
    description: description,
    creatorUserId: 'user-1',
    owningCompanyId: 'company-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  );
}
