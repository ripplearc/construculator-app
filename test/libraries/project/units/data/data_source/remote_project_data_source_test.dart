import 'package:construculator/libraries/project/data/data_source/remote_project_data_source.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteProjectDataSource', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteProjectDataSource dataSource;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
      supabaseWrapper = FakeSupabaseWrapper(clock: clock);
      dataSource = RemoteProjectDataSource(supabaseWrapper: supabaseWrapper);
    });

    test(
      'getOwnedProjects returns only projects for creator user id',
      () async {
        supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
          _projectRow(
            id: 'project-1',
            projectName: 'Owned Project',
            creatorUserId: 'user-1',
          ),
          _projectRow(
            id: 'project-2',
            projectName: 'Other Project',
            creatorUserId: 'user-2',
          ),
        ]);

        final result = await dataSource.getOwnedProjects('user-1');

        expect(result.length, 1);
        expect(result.first.id, 'project-1');
        expect(result.first.projectName, 'Owned Project');
      },
    );

    test('getSharedProjects resolves project IDs from memberships', () async {
      supabaseWrapper.addTableData(DatabaseConstants.projectMembersTable, [
        {
          DatabaseConstants.idColumn: 'member-1',
          DatabaseConstants.projectIdColumn: 'project-1',
          DatabaseConstants.userIdColumn: 'user-1',
        },
        {
          DatabaseConstants.idColumn: 'member-2',
          DatabaseConstants.projectIdColumn: 'project-2',
          DatabaseConstants.userIdColumn: 'user-1',
        },
        {
          DatabaseConstants.idColumn: 'member-3',
          DatabaseConstants.projectIdColumn: 'project-2',
          DatabaseConstants.userIdColumn: 'user-1',
        },
        {
          DatabaseConstants.idColumn: 'member-4',
          DatabaseConstants.projectIdColumn: 'project-3',
          DatabaseConstants.userIdColumn: 'user-2',
        },
      ]);

      supabaseWrapper.addTableData(DatabaseConstants.projectsTable, [
        _projectRow(
          id: 'project-1',
          projectName: 'Shared One',
          creatorUserId: 'owner-1',
        ),
        _projectRow(
          id: 'project-2',
          projectName: 'Shared Two',
          creatorUserId: 'owner-2',
        ),
        _projectRow(
          id: 'project-3',
          projectName: 'Not Shared To User 1',
          creatorUserId: 'owner-3',
        ),
      ]);

      final result = await dataSource.getSharedProjects('user-1');

      expect(result.map((project) => project.id).toSet(), {
        'project-1',
        'project-2',
      });
      expect(result.length, 2);
    });
  });
}

Map<String, dynamic> _projectRow({
  required String id,
  required String projectName,
  required String creatorUserId,
}) {
  return {
    DatabaseConstants.idColumn: id,
    'project_name': projectName,
    'description': '$projectName description',
    DatabaseConstants.creatorUserIdColumn: creatorUserId,
    'owning_company_id': 'company-1',
    'export_folder_link': null,
    'export_storage_provider': null,
    DatabaseConstants.createdAtColumn: DateTime(2025, 1, 1).toIso8601String(),
    DatabaseConstants.updatedAtColumn: DateTime(2025, 1, 2).toIso8601String(),
    DatabaseConstants.statusColumn: 'active',
  };
}
