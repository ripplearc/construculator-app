import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseConstants', () {
    group('table names', () {
      test('costEstimatesTable', () => expect(DatabaseConstants.costEstimatesTable, 'cost_estimates'));
      test('costEstimationLogsTable', () => expect(DatabaseConstants.costEstimationLogsTable, 'cost_estimate_logs'));
      test('projectsTable', () => expect(DatabaseConstants.projectsTable, 'projects'));
      test('projectMembersTable', () => expect(DatabaseConstants.projectMembersTable, 'project_members'));
      test('searchHistoryTable', () => expect(DatabaseConstants.searchHistoryTable, 'search_history'));
    });

    group('RPC function names', () {
      test('globalSearchRpcFunction', () => expect(DatabaseConstants.globalSearchRpcFunction, 'global_search'));
      test('searchSuggestionsRpcFunction', () => expect(DatabaseConstants.searchSuggestionsRpcFunction, 'get_search_suggestions'));
    });

    group('column names', () {
      test('idColumn', () => expect(DatabaseConstants.idColumn, 'id'));
      test('projectIdColumn', () => expect(DatabaseConstants.projectIdColumn, 'project_id'));
      test('userIdColumn', () => expect(DatabaseConstants.userIdColumn, 'user_id'));
      test('searchTermColumn', () => expect(DatabaseConstants.searchTermColumn, 'search_term'));
      test('scopeColumn', () => expect(DatabaseConstants.scopeColumn, 'scope'));
    });

    test('searchHistoryUpsertConflictColumns combines user, term, and scope', () {
      expect(
        DatabaseConstants.searchHistoryUpsertConflictColumns,
        '${DatabaseConstants.userIdColumn},${DatabaseConstants.searchTermColumn},${DatabaseConstants.scopeColumn}',
      );
    });
  });
}
