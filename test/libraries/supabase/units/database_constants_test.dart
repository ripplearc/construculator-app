import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseConstants', () {
    group('table names', () {
      test('costEstimatesTable is correct', () {
        expect(DatabaseConstants.costEstimatesTable, 'cost_estimates');
      });

      test('costEstimationLogsTable is correct', () {
        expect(DatabaseConstants.costEstimationLogsTable, 'cost_estimate_logs');
      });

      test('projectsTable is correct', () {
        expect(DatabaseConstants.projectsTable, 'projects');
      });

      test('projectMembersTable is correct', () {
        expect(DatabaseConstants.projectMembersTable, 'project_members');
      });

      test('searchHistoryTable is correct', () {
        expect(DatabaseConstants.searchHistoryTable, 'search_history');
      });
    });

    group('RPC function names', () {
      test('globalSearchRpcFunction is correct', () {
        expect(DatabaseConstants.globalSearchRpcFunction, 'global_search');
      });

      test('searchSuggestionsRpcFunction is correct', () {
        expect(
          DatabaseConstants.searchSuggestionsRpcFunction,
          'get_search_suggestions',
        );
      });
    });

    group('column names', () {
      test('idColumn is correct', () {
        expect(DatabaseConstants.idColumn, 'id');
      });

      test('projectIdColumn is correct', () {
        expect(DatabaseConstants.projectIdColumn, 'project_id');
      });

      test('userIdColumn is correct', () {
        expect(DatabaseConstants.userIdColumn, 'user_id');
      });

      test('createdAtColumn is correct', () {
        expect(DatabaseConstants.createdAtColumn, 'created_at');
      });

      test('estimateNameColumn is correct', () {
        expect(DatabaseConstants.estimateNameColumn, 'estimate_name');
      });

      test('updatedAtColumn is correct', () {
        expect(DatabaseConstants.updatedAtColumn, 'updated_at');
      });

      test('statusColumn is correct', () {
        expect(DatabaseConstants.statusColumn, 'status');
      });

      test('isLockedColumn is correct', () {
        expect(DatabaseConstants.isLockedColumn, 'is_locked');
      });

      test('lockedByUserIdColumn is correct', () {
        expect(DatabaseConstants.lockedByUserIdColumn, 'locked_by_user_id');
      });

      test('lockedAtColumn is correct', () {
        expect(DatabaseConstants.lockedAtColumn, 'locked_at');
      });

      test('projectNameColumn is correct', () {
        expect(DatabaseConstants.projectNameColumn, 'project_name');
      });

      test('descriptionColumn is correct', () {
        expect(DatabaseConstants.descriptionColumn, 'description');
      });

      test('owningCompanyIdColumn is correct', () {
        expect(DatabaseConstants.owningCompanyIdColumn, 'owning_company_id');
      });

      test('exportFolderLinkColumn is correct', () {
        expect(
          DatabaseConstants.exportFolderLinkColumn,
          'export_folder_link',
        );
      });

      test('exportStorageProviderColumn is correct', () {
        expect(
          DatabaseConstants.exportStorageProviderColumn,
          'export_storage_provider',
        );
      });
    });

    group('search history columns', () {
      test('searchTermColumn is correct', () {
        expect(DatabaseConstants.searchTermColumn, 'search_term');
      });

      test('scopeColumn is correct', () {
        expect(DatabaseConstants.scopeColumn, 'scope');
      });

      test('searchCountColumn is correct', () {
        expect(DatabaseConstants.searchCountColumn, 'search_count');
      });

      test('hasResultsColumn is correct', () {
        expect(DatabaseConstants.hasResultsColumn, 'has_results');
      });

      test('searchHistoryUpsertConflictColumns is correct', () {
        expect(
          DatabaseConstants.searchHistoryUpsertConflictColumns,
          'user_id,search_term,scope',
        );
      });
    });

    group('user profile columns', () {
      test('credentialIdColumn is correct', () {
        expect(DatabaseConstants.credentialIdColumn, 'credential_id');
      });

      test('firstNameColumn is correct', () {
        expect(DatabaseConstants.firstNameColumn, 'first_name');
      });

      test('lastNameColumn is correct', () {
        expect(DatabaseConstants.lastNameColumn, 'last_name');
      });

      test('professionalRoleColumn is correct', () {
        expect(DatabaseConstants.professionalRoleColumn, 'professional_role');
      });

      test('profilePhotoUrlColumn is correct', () {
        expect(DatabaseConstants.profilePhotoUrlColumn, 'profile_photo_url');
      });
    });

    group('cost estimation log columns', () {
      test('estimateIdColumn is correct', () {
        expect(DatabaseConstants.estimateIdColumn, 'estimate_id');
      });

      test('activityColumn is correct', () {
        expect(DatabaseConstants.activityColumn, 'activity');
      });

      test('userColumn is correct', () {
        expect(DatabaseConstants.userColumn, 'user');
      });

      test('activityDetailsColumn is correct', () {
        expect(DatabaseConstants.activityDetailsColumn, 'activity_details');
      });

      test('loggedAtColumn is correct', () {
        expect(DatabaseConstants.loggedAtColumn, 'logged_at');
      });
    });
  });
}
