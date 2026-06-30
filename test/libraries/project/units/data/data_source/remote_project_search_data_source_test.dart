import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/project/data/data_source/remote_project_search_data_source.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Map<String, dynamic> _fakeProjectData({
  String? id,
  String? projectName,
  String? creatorUserId,
  String? createdAt,
  String? updatedAt,
  String? status,
}) {
  return {
    DatabaseConstants.idColumn: id ?? 'project-1',
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.descriptionColumn: 'Test description',
    DatabaseConstants.creatorUserIdColumn: creatorUserId ?? 'user-1',
    DatabaseConstants.owningCompanyIdColumn: null,
    DatabaseConstants.exportFolderLinkColumn: null,
    DatabaseConstants.exportStorageProviderColumn: null,
    DatabaseConstants.createdAtColumn: createdAt ?? '2024-01-01T00:00:00.000Z',
    DatabaseConstants.updatedAtColumn: updatedAt ?? '2024-01-01T00:00:00.000Z',
    DatabaseConstants.statusColumn: status ?? 'active',
  };
}

void main() {
  group('RemoteProjectSearchDataSource', () {
    late FakeClockImpl clock;
    late FakeSupabaseWrapper supabaseWrapper;
    late RemoteProjectSearchDataSource dataSource;

    setUp(() {
      clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
      supabaseWrapper = FakeSupabaseWrapper(clock: clock);
      dataSource = RemoteProjectSearchDataSource(
        supabaseWrapper: supabaseWrapper,
      );
    });

    tearDown(() {
      supabaseWrapper.reset();
    });

    group('fetchProjectsBySearchQuery', () {
      test('returns mapped ProjectDto list when RPC succeeds with data', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {
            'projects': [
              _fakeProjectData(id: 'p-1', projectName: 'Foundation Work'),
              _fakeProjectData(id: 'p-2', projectName: 'Steel Frame'),
            ],
            'estimations': [],
            'members': [],
          },
        );

        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'foundation',
        );

        expect(result, hasLength(2));
        expect(result.first.id, equals('p-1'));
        expect(result.first.projectName, equals('Foundation Work'));
        expect(result.last.id, equals('p-2'));
        expect(result.last.projectName, equals('Steel Frame'));
      });

      test('returns empty list when RPC returns empty projects array', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'nothing',
        );

        expect(result, isEmpty);
      });

      test('returns empty list without calling RPC when query is empty', () async {
        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: '',
        );

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test(
        'returns empty list without calling RPC when query is whitespace only',
        () async {
          final result = await dataSource.fetchProjectsBySearchQuery(
            userId: 'user-1',
            query: '   ',
          );

          expect(result, isEmpty);
          expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test('returns empty list without calling RPC when userId is empty', () async {
        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: '',
          query: 'wall',
        );

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test(
        'returns empty list without calling RPC when userId is whitespace only',
        () async {
          final result = await dataSource.fetchProjectsBySearchQuery(
            userId: '   ',
            query: 'wall',
          );

          expect(result, isEmpty);
          expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test('always passes scope: dashboard in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall');

        final rpcCalls = supabaseWrapper.getMethodCallsFor('rpc');
        expect(rpcCalls, hasLength(1));
        final params = rpcCalls.first['params'] as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!['scope'], equals(DatabaseConstants.globalSearchDashboardScope));
      });

      test('does not forward userId in RPC params — auth scoping is JWT-based', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall');

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!.containsKey('user_id'), isFalse);
      });

      test('passes limit and offset constants in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall');

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!['limit'], equals(DatabaseConstants.globalSearchDefaultLimit));
        expect(params['offset'], equals(DatabaseConstants.globalSearchDefaultOffset));
      });

      test('passes filterByDate as ISO8601 string in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        final filterDate = DateTime(2024, 6, 1);
        await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'wall',
          filterByDate: filterDate,
        );

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params!['filter_by_date'], equals(filterDate.toIso8601String()));
      });

      test('passes filterByTag and filterByOwner in RPC params', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'wall',
          filterByTag: 'structural',
          filterByOwner: 'owner-42',
        );

        final params = supabaseWrapper.getMethodCallsFor('rpc').first['params']
            as Map<String, dynamic>?;
        expect(params!['filter_by_tag'], equals('structural'));
        expect(params['filter_by_owner'], equals('owner-42'));
      });

      test('ignores estimations and members in RPC response', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {
            'projects': [_fakeProjectData(id: 'p-1')],
            'estimations': [
              {'id': 'e-1', 'estimate_name': 'Some Estimate'},
            ],
            'members': [
              {'id': 'm-1', 'first_name': 'John'},
            ],
          },
        );

        final result = await dataSource.fetchProjectsBySearchQuery(
          userId: 'user-1',
          query: 'wall',
        );

        expect(result, hasLength(1));
        expect(result.first.id, equals('p-1'));
      });

      test('rethrows PostgrestException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
        supabaseWrapper.rpcErrorMessage = 'DB error';

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall'),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('rethrows SocketException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
        supabaseWrapper.rpcErrorMessage = 'Network error';

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall'),
          throwsA(isA<SocketException>()),
        );
      });

      test('rethrows TimeoutException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;
        supabaseWrapper.rpcErrorMessage = 'Timeout';

        await expectLater(
          () => dataSource.fetchProjectsBySearchQuery(userId: 'user-1', query: 'wall'),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('saveRecentProjectSearch', () {
      test('upserts normalized term against project_search_history', () async {
        await dataSource.saveRecentProjectSearch(
          userId: 'user-1',
          searchTerm: '  Foundation  ',
          hasResults: true,
        );

        final calls = supabaseWrapper.getMethodCallsFor('upsert');
        expect(calls, hasLength(1));
        expect(
          calls.first['table'],
          equals(DatabaseConstants.projectSearchHistoryTable),
        );
        expect(
          calls.first['onConflict'],
          equals(DatabaseConstants.projectSearchHistoryUpsertConflictColumns),
        );

        final data = calls.first['data'] as Map<String, dynamic>;
        expect(data[DatabaseConstants.userIdColumn], equals('user-1'));
        expect(data[DatabaseConstants.searchTermColumn], equals('foundation'));
        expect(data[DatabaseConstants.hasResultsColumn], isTrue);
        expect(data.containsKey(DatabaseConstants.searchCountColumn), isFalse);
        expect(data.containsKey(DatabaseConstants.createdAtColumn), isFalse);
      });

      test('defaults hasResults to false when not provided', () async {
        await dataSource.saveRecentProjectSearch(
          userId: 'user-1',
          searchTerm: 'wall',
        );

        final data = supabaseWrapper.getMethodCallsFor('upsert').first['data']
            as Map<String, dynamic>;
        expect(data[DatabaseConstants.hasResultsColumn], isFalse);
      });

      test('does nothing when userId is empty', () async {
        await dataSource.saveRecentProjectSearch(
          userId: '',
          searchTerm: 'wall',
        );

        expect(supabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
      });

      test('does nothing when userId is whitespace only', () async {
        await dataSource.saveRecentProjectSearch(
          userId: '   ',
          searchTerm: 'wall',
        );

        expect(supabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
      });

      test('does nothing when searchTerm is empty', () async {
        await dataSource.saveRecentProjectSearch(
          userId: 'user-1',
          searchTerm: '',
        );

        expect(supabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
      });

      test('does nothing when searchTerm is whitespace only', () async {
        await dataSource.saveRecentProjectSearch(
          userId: 'user-1',
          searchTerm: '   ',
        );

        expect(supabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
      });

      test('rethrows PostgrestException when upsert throws', () async {
        supabaseWrapper.shouldThrowOnUpsert = true;
        supabaseWrapper.upsertExceptionType = SupabaseExceptionType.postgrest;
        supabaseWrapper.upsertErrorMessage = 'DB error';

        await expectLater(
          () => dataSource.saveRecentProjectSearch(
            userId: 'user-1',
            searchTerm: 'wall',
          ),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('rethrows SocketException when upsert throws', () async {
        supabaseWrapper.shouldThrowOnUpsert = true;
        supabaseWrapper.upsertExceptionType = SupabaseExceptionType.socket;
        supabaseWrapper.upsertErrorMessage = 'Network';

        await expectLater(
          () => dataSource.saveRecentProjectSearch(
            userId: 'user-1',
            searchTerm: 'wall',
          ),
          throwsA(isA<SocketException>()),
        );
      });

      test('rethrows TimeoutException when upsert throws', () async {
        supabaseWrapper.shouldThrowOnUpsert = true;
        supabaseWrapper.upsertExceptionType = SupabaseExceptionType.timeout;
        supabaseWrapper.upsertErrorMessage = 'Timeout';

        await expectLater(
          () => dataSource.saveRecentProjectSearch(
            userId: 'user-1',
            searchTerm: 'wall',
          ),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('getRecentProjectSearches', () {
      test(
        'returns most-recent-first list of terms from project_search_history',
        () async {
          supabaseWrapper.addTableData(
            DatabaseConstants.projectSearchHistoryTable,
            [
              {
                DatabaseConstants.userIdColumn: 'user-1',
                DatabaseConstants.searchTermColumn: 'older',
                DatabaseConstants.updatedAtColumn: '2024-01-01T00:00:00.000Z',
              },
              {
                DatabaseConstants.userIdColumn: 'user-1',
                DatabaseConstants.searchTermColumn: 'newer',
                DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
              },
            ],
          );

          final result = await dataSource.getRecentProjectSearches(
            userId: 'user-1',
          );

          expect(result, equals(['newer', 'older']));

          final calls = supabaseWrapper.getMethodCallsFor('selectMatch');
          expect(calls, hasLength(1));
          expect(
            calls.first['table'],
            equals(DatabaseConstants.projectSearchHistoryTable),
          );
          expect(
            calls.first['orderBy'],
            equals(DatabaseConstants.updatedAtColumn),
          );
          expect(calls.first['ascending'], isFalse);
          final filters = calls.first['filters'] as Map<String, dynamic>;
          expect(filters[DatabaseConstants.userIdColumn], equals('user-1'));
        },
      );

      test('drops rows with null or empty search_term', () async {
        supabaseWrapper.addTableData(
          DatabaseConstants.projectSearchHistoryTable,
          [
            {
              DatabaseConstants.userIdColumn: 'user-1',
              DatabaseConstants.searchTermColumn: 'kept',
              DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
            },
            {
              DatabaseConstants.userIdColumn: 'user-1',
              DatabaseConstants.searchTermColumn: '',
              DatabaseConstants.updatedAtColumn: '2024-05-01T00:00:00.000Z',
            },
            {
              DatabaseConstants.userIdColumn: 'user-1',
              DatabaseConstants.searchTermColumn: null,
              DatabaseConstants.updatedAtColumn: '2024-04-01T00:00:00.000Z',
            },
          ],
        );

        final result = await dataSource.getRecentProjectSearches(
          userId: 'user-1',
        );

        expect(result, equals(['kept']));
      });

      test(
        'caps results at recentProjectSearchesMaxResults',
        () async {
          final overLimit =
              DatabaseConstants.recentProjectSearchesMaxResults + 5;
          supabaseWrapper.addTableData(
            DatabaseConstants.projectSearchHistoryTable,
            List.generate(
              overLimit,
              (i) => {
                DatabaseConstants.userIdColumn: 'user-1',
                DatabaseConstants.searchTermColumn: 'term-$i',
                DatabaseConstants.updatedAtColumn:
                    '2024-01-01T00:00:00.000Z',
              },
            ),
          );

          final result = await dataSource.getRecentProjectSearches(
            userId: 'user-1',
          );

          expect(
            result,
            hasLength(DatabaseConstants.recentProjectSearchesMaxResults),
          );
        },
      );

      test('returns empty list without calling wrapper when userId empty', () async {
        final result = await dataSource.getRecentProjectSearches(userId: '');

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('selectMatch'), isEmpty);
      });

      test(
        'returns empty list without calling wrapper when userId is whitespace only',
        () async {
          final result = await dataSource.getRecentProjectSearches(
            userId: '   ',
          );

          expect(result, isEmpty);
          expect(supabaseWrapper.getMethodCallsFor('selectMatch'), isEmpty);
        },
      );

      test('rethrows PostgrestException when selectMatch throws', () async {
        supabaseWrapper.shouldThrowOnSelectMatch = true;
        supabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.postgrest;
        supabaseWrapper.selectMatchErrorMessage = 'DB error';

        await expectLater(
          () => dataSource.getRecentProjectSearches(userId: 'user-1'),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('rethrows TimeoutException when selectMatch throws', () async {
        supabaseWrapper.shouldThrowOnSelectMatch = true;
        supabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.timeout;
        supabaseWrapper.selectMatchErrorMessage = 'Timeout';

        await expectLater(
          () => dataSource.getRecentProjectSearches(userId: 'user-1'),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('rethrows SocketException when selectMatch throws', () async {
        supabaseWrapper.shouldThrowOnSelectMatch = true;
        supabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.socket;
        supabaseWrapper.selectMatchErrorMessage = 'Network';

        await expectLater(
          () => dataSource.getRecentProjectSearches(userId: 'user-1'),
          throwsA(isA<SocketException>()),
        );
      });
    });

    group('deleteRecentProjectSearch', () {
      test(
        'deletes against project_search_history with normalized term',
        () async {
          await dataSource.deleteRecentProjectSearch(
            userId: 'user-1',
            searchTerm: '  Foundation  ',
          );

          final calls = supabaseWrapper.getMethodCallsFor('deleteMatch');
          expect(calls, hasLength(1));
          expect(
            calls.first['table'],
            equals(DatabaseConstants.projectSearchHistoryTable),
          );
          final filters = calls.first['filters'] as Map<String, dynamic>;
          expect(filters[DatabaseConstants.userIdColumn], equals('user-1'));
          expect(
            filters[DatabaseConstants.searchTermColumn],
            equals('foundation'),
          );
        },
      );

      test('does nothing when userId is empty', () async {
        await dataSource.deleteRecentProjectSearch(
          userId: '',
          searchTerm: 'wall',
        );

        expect(supabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
      });

      test('does nothing when userId is whitespace only', () async {
        await dataSource.deleteRecentProjectSearch(
          userId: '   ',
          searchTerm: 'wall',
        );

        expect(supabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
      });

      test('does nothing when searchTerm is empty', () async {
        await dataSource.deleteRecentProjectSearch(
          userId: 'user-1',
          searchTerm: '',
        );

        expect(supabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
      });

      test('does nothing when searchTerm is whitespace only', () async {
        await dataSource.deleteRecentProjectSearch(
          userId: 'user-1',
          searchTerm: '   ',
        );

        expect(supabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
      });

      test('rethrows PostgrestException when deleteMatch throws', () async {
        supabaseWrapper.shouldThrowOnDeleteMatch = true;
        supabaseWrapper.deleteMatchExceptionType =
            SupabaseExceptionType.postgrest;
        supabaseWrapper.deleteMatchErrorMessage = 'DB error';

        await expectLater(
          () => dataSource.deleteRecentProjectSearch(
            userId: 'user-1',
            searchTerm: 'wall',
          ),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('rethrows SocketException when deleteMatch throws', () async {
        supabaseWrapper.shouldThrowOnDeleteMatch = true;
        supabaseWrapper.deleteMatchExceptionType =
            SupabaseExceptionType.socket;
        supabaseWrapper.deleteMatchErrorMessage = 'Network';

        await expectLater(
          () => dataSource.deleteRecentProjectSearch(
            userId: 'user-1',
            searchTerm: 'wall',
          ),
          throwsA(isA<SocketException>()),
        );
      });

      test('rethrows TimeoutException when deleteMatch throws', () async {
        supabaseWrapper.shouldThrowOnDeleteMatch = true;
        supabaseWrapper.deleteMatchExceptionType =
            SupabaseExceptionType.timeout;
        supabaseWrapper.deleteMatchErrorMessage = 'Timeout';

        await expectLater(
          () => dataSource.deleteRecentProjectSearch(
            userId: 'user-1',
            searchTerm: 'wall',
          ),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('getProjectSearchSuggestions', () {
      test('returns string suggestions from RPC, dropping non-strings', () async {
        supabaseWrapper.setRpcResponse(
          DatabaseConstants.projectSearchSuggestionsRpcFunction,
          <dynamic>['foundation', 'wall', 42, null, 'steel'],
        );

        final result = await dataSource.getProjectSearchSuggestions(
          userId: 'user-1',
        );

        expect(result, equals(['foundation', 'wall', 'steel']));

        final calls = supabaseWrapper.getMethodCallsFor('rpc');
        expect(calls, hasLength(1));
        expect(
          calls.first['functionName'] ?? calls.first['function'],
          equals(DatabaseConstants.projectSearchSuggestionsRpcFunction),
        );
        final params = calls.first['params'] as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(
          params![DatabaseConstants.projectSearchSuggestionsUserIdParam],
          equals('user-1'),
        );
      });

      test('returns empty list without calling RPC when userId is empty', () async {
        final result = await dataSource.getProjectSearchSuggestions(
          userId: '',
        );

        expect(result, isEmpty);
        expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test(
        'returns empty list without calling RPC when userId is whitespace only',
        () async {
          final result = await dataSource.getProjectSearchSuggestions(
            userId: '   ',
          );

          expect(result, isEmpty);
          expect(supabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test('rethrows PostgrestException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
        supabaseWrapper.rpcErrorMessage = 'DB error';

        await expectLater(
          () => dataSource.getProjectSearchSuggestions(userId: 'user-1'),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('rethrows TimeoutException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;
        supabaseWrapper.rpcErrorMessage = 'Timeout';

        await expectLater(
          () => dataSource.getProjectSearchSuggestions(userId: 'user-1'),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('rethrows SocketException when RPC throws', () async {
        supabaseWrapper.shouldThrowOnRpc = true;
        supabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
        supabaseWrapper.rpcErrorMessage = 'Network';

        await expectLater(
          () => dataSource.getProjectSearchSuggestions(userId: 'user-1'),
          throwsA(isA<SocketException>()),
        );
      });
    });
  });
}
