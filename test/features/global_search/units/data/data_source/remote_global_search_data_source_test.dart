import 'dart:io';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/data/data_source/interfaces/global_search_data_source.dart';
import 'package:construculator/features/global_search/data/data_source/remote_global_search_data_source.dart';
import 'package:construculator/features/global_search/data/models/pagination_params.dart';
import 'package:construculator/features/global_search/data/models/search_params.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../estimations/helpers/estimation_test_data_map_factory.dart'
    as estimation_factory;

Map<String, dynamic> _fakeSearchHistoryData({
  String? id,
  required String userId,
  required String searchTerm,
  required String scope,
  String? createdAt,
}) {
  return {
    DatabaseConstants.idColumn: id ?? '1',
    DatabaseConstants.userIdColumn: userId,
    DatabaseConstants.searchTermColumn: searchTerm,
    DatabaseConstants.scopeColumn: scope,
    DatabaseConstants.searchCountColumn: 1,
    DatabaseConstants.createdAtColumn: createdAt ?? '2024-01-01T00:00:00.000Z',
  };
}

Map<String, dynamic> _fakeProjectData({
  String? id,
  String? projectName,
  String? description,
  String? creatorUserId,
  String? createdAt,
  String? updatedAt,
  String? status,
}) {
  return {
    DatabaseConstants.idColumn: id ?? 'project-1',
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.descriptionColumn: description ?? 'Test description',
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
  const String testUserId = 'user-123';
  const String errorMsgDbConnection = 'Database connection failed';
  const String errorMsgAuth = 'Authentication failed';
  const String errorMsgNetwork = 'Network connection failed';
  const String errorMsgTimeout = 'Request timeout';

  group('RemoteGlobalSearchDataSource', () {
    late RemoteGlobalSearchDataSource dataSource;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    setUpAll(() {
      fakeClock = FakeClockImpl();
      Modular.init(
        GlobalSearchModule(
          AppBootstrap(
            config: FakeAppConfig(),
            envLoader: FakeEnvLoader(),
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      dataSource =
          Modular.get<GlobalSearchDataSource>() as RemoteGlobalSearchDataSource;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    group('search', () {
      test(
        'should return SearchResultsDto when RPC succeeds with projects and estimations',
        () async {
          final projectData = _fakeProjectData(
            id: 'project-1',
            projectName: 'Test Project',
          );
          final estimationData =
              estimation_factory
                  .EstimationTestDataMapFactory.createFakeEstimationData(
                id: 'estimate-1',
                estimateName: 'Test Estimate',
              );

          fakeSupabaseWrapper.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [projectData],
              'estimations': [estimationData],
              'members': [],
            },
          );

          final params = const SearchParams(query: 'test');
          final result = await dataSource.search(params);

          expect(result.projects, hasLength(1));
          expect(result.projects.first.projectName, equals('Test Project'));
          expect(result.estimations, hasLength(1));
          expect(
            result.estimations.first.estimateName,
            equals('Test Estimate'),
          );
        },
      );

      test('should return empty results when RPC returns empty', () async {
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        final params = const SearchParams(query: 'empty');
        final result = await dataSource.search(params);

        expect(result.projects, isEmpty);
        expect(result.estimations, isEmpty);
        expect(result.members, isEmpty);
      });

      test(
        'should use default pagination (offset 0, limit 20) when not specified',
        () async {
          fakeSupabaseWrapper.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );

          const params = SearchParams(query: 'test');

          await dataSource.search(params);

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('rpc');
          expect(methodCalls, hasLength(1));

          final paramsMap =
              methodCalls.first['params'] as Map<String, dynamic>?;
          expect(paramsMap, isNotNull);
          expect(paramsMap!['offset'], equals(0));
          expect(paramsMap['limit'], equals(20));
        },
      );

      test(
        'should call rpc with correct params including serialized DateTime and scope',
        () async {
          fakeSupabaseWrapper.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );

          final filterDate = DateTime(2024, 3, 15);
          final params = SearchParams(
            query: 'wall',
            filterByTag: 'construction',
            filterByDate: filterDate,
            filterByOwner: 'owner-1',
            scope: SearchScope.estimation,
            pagination: const PaginationParams(offset: 10, limit: 25),
          );

          await dataSource.search(params);

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('rpc');
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(
            call['functionName'],
            equals(DatabaseConstants.globalSearchRpcFunction),
          );

          final paramsMap = call['params'] as Map<String, dynamic>?;
          expect(paramsMap, isNotNull);
          expect(paramsMap!['query'], equals('wall'));
          expect(paramsMap['filter_by_tag'], equals('construction'));
          expect(
            paramsMap['filter_by_date'],
            equals(filterDate.toIso8601String()),
          );
          expect(paramsMap['filter_by_owner'], equals('owner-1'));
          expect(paramsMap['scope'], equals('estimation'));
          expect(paramsMap['offset'], equals(10));
          expect(paramsMap['limit'], equals(25));
        },
      );

      test('should rethrow PostgrestException when RPC throws', () async {
        fakeSupabaseWrapper.shouldThrowOnRpc = true;
        fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.rpcErrorMessage = errorMsgDbConnection;

        expect(
          () => dataSource.search(const SearchParams(query: 'test')),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('should rethrow AuthException when RPC throws auth error', () async {
        fakeSupabaseWrapper.shouldThrowOnRpc = true;
        fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.auth;
        fakeSupabaseWrapper.rpcErrorMessage = errorMsgAuth;

        expect(
          () => dataSource.search(const SearchParams(query: 'test')),
          throwsA(isA<supabase.AuthException>()),
        );
      });

      test(
        'should rethrow socket exception when RPC throws network error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgNetwork;

          expect(
            () => dataSource.search(const SearchParams(query: 'test')),
            throwsA(isA<SocketException>()),
          );
        },
      );

      test(
        'should rethrow timeout exception when RPC throws timeout error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgTimeout;

          expect(
            () => dataSource.search(const SearchParams(query: 'test')),
            throwsA(isA<Exception>()),
          );
        },
      );
    });

    group('getSearchSuggestions', () {
      test('should return list of strings when RPC succeeds', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.searchSuggestionsRpcFunction,
          ['foundation', 'concrete mix', 'steel frame'],
        );

        final result = await dataSource.getSearchSuggestions();

        expect(result, hasLength(3));
        expect(
          result,
          containsAll(['foundation', 'concrete mix', 'steel frame']),
        );
      });

      test('should pass user_id to RPC', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.searchSuggestionsRpcFunction,
          ['foundation'],
        );

        await dataSource.getSearchSuggestions();

        final rpcCalls = fakeSupabaseWrapper.getMethodCallsFor('rpc');
        final suggestionsCall = rpcCalls.lastWhere(
          (c) =>
              c['functionName'] ==
              DatabaseConstants.searchSuggestionsRpcFunction,
        );
        final params = suggestionsCall['params'] as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params![DatabaseConstants.userIdColumn], equals(testUserId));
      });

      test(
        'should return empty list without calling RPC when user not authenticated',
        () async {
          fakeSupabaseWrapper.setCurrentUser(null);

          final result = await dataSource.getSearchSuggestions();

          expect(result, isEmpty);
          final rpcCalls = fakeSupabaseWrapper.getMethodCallsFor('rpc');
          expect(
            rpcCalls.any(
              (c) =>
                  c['functionName'] ==
                  DatabaseConstants.searchSuggestionsRpcFunction,
            ),
            isFalse,
          );
        },
      );

      test('should return empty list when RPC returns empty', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.searchSuggestionsRpcFunction,
          [],
        );

        final result = await dataSource.getSearchSuggestions();

        expect(result, isEmpty);
      });

      test('should rethrow PostgrestException when RPC throws', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.shouldThrowOnRpc = true;
        fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.rpcErrorMessage = errorMsgDbConnection;

        expect(
          () => dataSource.getSearchSuggestions(),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });

    group('getRecentSearches', () {
      test('should return recent search terms when data exists', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeSearchHistoryData(
            id: '1',
            userId: testUserId,
            searchTerm: 'wall',
            scope: SearchScope.dashboard.name,
          ),
          _fakeSearchHistoryData(
            id: '2',
            userId: testUserId,
            searchTerm: 'concrete',
            scope: SearchScope.dashboard.name,
          ),
        ]);

        final result = await dataSource.getRecentSearches(
          SearchScope.dashboard,
        );

        expect(result, hasLength(2));
        expect(result, containsAll(['wall', 'concrete']));
      });

      test('should return empty list when no user logged in', () async {
        fakeSupabaseWrapper.setCurrentUser(null);

        final result = await dataSource.getRecentSearches(
          SearchScope.dashboard,
        );

        expect(result, isEmpty);
      });

      test('should return empty list when no data for scope', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeSearchHistoryData(
            id: '1',
            userId: testUserId,
            searchTerm: 'wall',
            scope: SearchScope.estimation.name,
          ),
        ]);

        final result = await dataSource.getRecentSearches(
          SearchScope.dashboard,
        );

        expect(result, isEmpty);
      });

      test(
        'should delegate sorting to DB via orderBy created_at descending',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper
              .addTableData(DatabaseConstants.searchHistoryTable, [
                _fakeSearchHistoryData(
                  id: '1',
                  userId: testUserId,
                  searchTerm: 'oldest',
                  scope: SearchScope.dashboard.name,
                  createdAt: '2024-01-01T00:00:00.000Z',
                ),
                _fakeSearchHistoryData(
                  id: '2',
                  userId: testUserId,
                  searchTerm: 'newest',
                  scope: SearchScope.dashboard.name,
                  createdAt: '2024-03-20T12:00:00.000Z',
                ),
                _fakeSearchHistoryData(
                  id: '3',
                  userId: testUserId,
                  searchTerm: 'middle',
                  scope: SearchScope.dashboard.name,
                  createdAt: '2024-02-15T00:00:00.000Z',
                ),
              ]);

          final result = await dataSource.getRecentSearches(
            SearchScope.dashboard,
          );

          final selectCall = fakeSupabaseWrapper
              .getMethodCallsFor('selectMatch')
              .last;
          expect(
            selectCall['orderBy'],
            equals(DatabaseConstants.createdAtColumn),
          );
          expect(selectCall['ascending'], isFalse);

          expect(result, hasLength(3));
          expect(result[0], equals('newest'));
          expect(result[1], equals('middle'));
          expect(result[2], equals('oldest'));
        },
      );

      test('should rethrow when select throws', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.selectMatchErrorMessage = errorMsgDbConnection;

        await expectLater(
          () => dataSource.getRecentSearches(SearchScope.dashboard),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });

    group('saveRecentSearch', () {
      test('should normalize search term to lowercase', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );

        await dataSource.saveRecentSearch('WALL', SearchScope.dashboard);

        final upsertCalls = fakeSupabaseWrapper.getMethodCallsFor('upsert');
        final historyCall = upsertCalls.firstWhere(
          (c) => c['table'] == DatabaseConstants.searchHistoryTable,
        );
        final data = historyCall['data'] as Map<String, dynamic>;
        expect(data[DatabaseConstants.searchTermColumn], equals('wall'));
      });

      test(
        'should return early when search term is empty after trim',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );

          await dataSource.saveRecentSearch('   ', SearchScope.dashboard);

          expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
        },
      );

      test('should return early when user not logged in', () async {
        fakeSupabaseWrapper.setCurrentUser(null);

        await dataSource.saveRecentSearch('wall', SearchScope.dashboard);

        expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
      });

      test('should upsert to search_history with correct params', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );

        await dataSource.saveRecentSearch('wall', SearchScope.dashboard);

        final upsertCalls = fakeSupabaseWrapper.getMethodCallsFor('upsert');
        expect(upsertCalls, hasLength(1));
        final historyCall = upsertCalls.first;
        expect(
          historyCall['table'],
          equals(DatabaseConstants.searchHistoryTable),
        );
        expect(
          historyCall['onConflict'],
          equals(DatabaseConstants.searchHistoryUpsertConflictColumns),
        );
        final data = historyCall['data'] as Map<String, dynamic>;
        expect(data[DatabaseConstants.userIdColumn], equals(testUserId));
        expect(data[DatabaseConstants.searchTermColumn], equals('wall'));
        expect(data[DatabaseConstants.scopeColumn], equals('dashboard'));
        expect(data.containsKey(DatabaseConstants.searchCountColumn), isFalse);
        expect(data[DatabaseConstants.hasResultsColumn], isFalse);
        expect(data[DatabaseConstants.projectIdColumn], isNull);
        expect(
          data.containsKey(DatabaseConstants.createdAtColumn),
          isFalse,
          reason: 'created_at must not be sent — DB DEFAULT and trigger own it',
        );
      });

      test(
        'should set has_results true and project_id when provided',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );

          await dataSource.saveRecentSearch(
            'concrete',
            SearchScope.dashboard,
            hasResults: true,
            projectId: 'project-42',
          );

          final upsertCalls = fakeSupabaseWrapper.getMethodCallsFor('upsert');
          expect(upsertCalls, hasLength(1));
          final data = upsertCalls.first['data'] as Map<String, dynamic>;
          expect(data[DatabaseConstants.hasResultsColumn], isTrue);
          expect(data[DatabaseConstants.projectIdColumn], equals('project-42'));
        },
      );

      test(
        'should only upsert to search_history — never to search_analytics',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );

          await dataSource.saveRecentSearch(
            'steel',
            SearchScope.dashboard,
            hasResults: true,
          );

          final upsertCalls = fakeSupabaseWrapper.getMethodCallsFor('upsert');
          expect(upsertCalls, hasLength(1));
          expect(
            upsertCalls.first['table'],
            equals(DatabaseConstants.searchHistoryTable),
          );
        },
      );

      test('should rethrow when upsert throws', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.shouldThrowOnUpsert = true;
        fakeSupabaseWrapper.upsertExceptionType =
            SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.upsertErrorMessage = errorMsgDbConnection;

        expect(
          () => dataSource.saveRecentSearch('wall', SearchScope.dashboard),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });

    group('deleteRecentSearch', () {
      test('should delete row from search_history when it exists', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeSearchHistoryData(
            id: '1',
            userId: testUserId,
            searchTerm: 'wall',
            scope: SearchScope.dashboard.name,
          ),
        ]);

        await dataSource.deleteRecentSearch('wall', SearchScope.dashboard);

        final deleteCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'deleteMatch',
        );
        expect(deleteCalls, hasLength(1));
        final filters = deleteCalls.first['filters'] as Map<String, dynamic>;
        expect(
          deleteCalls.first['table'],
          equals(DatabaseConstants.searchHistoryTable),
        );
        expect(filters[DatabaseConstants.userIdColumn], equals(testUserId));
        expect(filters[DatabaseConstants.searchTermColumn], equals('wall'));
        expect(
          filters[DatabaseConstants.scopeColumn],
          equals(SearchScope.dashboard.name),
        );
      });

      test('should normalize search term when deleting', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeSearchHistoryData(
            id: '1',
            userId: testUserId,
            searchTerm: 'wall',
            scope: SearchScope.dashboard.name,
          ),
        ]);

        await dataSource.deleteRecentSearch('WALL', SearchScope.dashboard);

        final deleteCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'deleteMatch',
        );
        expect(deleteCalls, hasLength(1));
        final filters = deleteCalls.first['filters'] as Map<String, dynamic>;
        expect(filters[DatabaseConstants.searchTermColumn], equals('wall'));
      });

      test('should return early when no user logged in', () async {
        fakeSupabaseWrapper.setCurrentUser(null);

        await dataSource.deleteRecentSearch('wall', SearchScope.dashboard);

        expect(fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
      });

      test(
        'should return early when search term is empty after trim',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );

          await dataSource.deleteRecentSearch('   ', SearchScope.dashboard);

          expect(fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
        },
      );

      test(
        'should only delete from search_history — never from other tables',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper
              .addTableData(DatabaseConstants.searchHistoryTable, [
                _fakeSearchHistoryData(
                  id: '1',
                  userId: testUserId,
                  searchTerm: 'wall',
                  scope: SearchScope.dashboard.name,
                ),
              ]);

          await dataSource.deleteRecentSearch('wall', SearchScope.dashboard);

          final deleteCalls = fakeSupabaseWrapper.getMethodCallsFor(
            'deleteMatch',
          );
          expect(deleteCalls, hasLength(1));
          expect(
            deleteCalls.first['table'],
            equals(DatabaseConstants.searchHistoryTable),
          );
        },
      );

      test('should rethrow when deleteMatch throws', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.shouldThrowOnDeleteMatch = true;
        fakeSupabaseWrapper.deleteMatchExceptionType =
            SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.deleteMatchErrorMessage = errorMsgDbConnection;

        await expectLater(
          () => dataSource.deleteRecentSearch('wall', SearchScope.dashboard),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });
  });
}
