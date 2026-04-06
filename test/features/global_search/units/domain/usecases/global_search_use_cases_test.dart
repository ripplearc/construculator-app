import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/usecases/delete_recent_search_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/get_recent_searches_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/get_search_suggestions_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/perform_search_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/save_recent_search_use_case.dart';
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

import '../../../../estimations/helpers/estimation_test_data_map_factory.dart'
    as estimation_factory;

const String _testUserId = 'use-case-test-user';
const String _testUserEmail = 'usecase@test.com';

Map<String, dynamic> _fakeSearchHistoryData({
  required String userId,
  required String searchTerm,
  SearchScope scope = SearchScope.dashboard,
}) {
  return {
    DatabaseConstants.idColumn: '1',
    DatabaseConstants.userIdColumn: userId,
    DatabaseConstants.searchTermColumn: searchTerm,
    DatabaseConstants.scopeColumn: scope.name,
    DatabaseConstants.searchCountColumn: 1,
    DatabaseConstants.createdAtColumn: '2024-01-01T00:00:00.000Z',
  };
}

void main() {
  group('Global search use cases', () {
    late FakeSupabaseWrapper fakeSupabase;

    setUpAll(() {
      final fakeClock = FakeClockImpl();
      Modular.init(
        GlobalSearchModule(
          AppBootstrap(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
            config: FakeAppConfig(),
            envLoader: FakeEnvLoader(),
          ),
        ),
      );
      fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabase.reset();
    });

    group('PerformSearchUseCase', () {
      test('returns SearchResults when repository succeeds', () async {
        fakeSupabase.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {
            'projects': [
              {
                DatabaseConstants.idColumn: 'p1',
                DatabaseConstants.projectNameColumn: 'Foundation',
                DatabaseConstants.descriptionColumn: '',
                DatabaseConstants.creatorUserIdColumn: _testUserId,
                DatabaseConstants.owningCompanyIdColumn: null,
                DatabaseConstants.exportFolderLinkColumn: null,
                DatabaseConstants.exportStorageProviderColumn: null,
                DatabaseConstants.createdAtColumn:
                    '2024-01-01T00:00:00.000Z',
                DatabaseConstants.updatedAtColumn: '2024-01-01T00:00:00.000Z',
                DatabaseConstants.statusColumn: 'active',
              },
            ],
            'estimations': [
              estimation_factory.EstimationTestDataMapFactory
                  .createFakeEstimationData(estimateName: 'Steel Frame'),
            ],
            'members': [],
          },
        );
        final useCase = Modular.get<PerformSearchUseCase>();

        final result = await useCase(
          SearchParams(query: 'foundation', scope: SearchScope.dashboard),
        );

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (results) {
            expect(results.projects, hasLength(1));
            expect(results.estimations, hasLength(1));
          },
        );
      });

      test('returns Left when RPC throws', () async {
        fakeSupabase.shouldThrowOnRpc = true;
        fakeSupabase.rpcExceptionType = SupabaseExceptionType.socket;
        final useCase = Modular.get<PerformSearchUseCase>();

        final result = await useCase(SearchParams(query: 'q'));

        expect(result.isLeft(), isTrue);
      });
    });

    group('GetRecentSearchesUseCase', () {
      test('returns list of recent searches for the given scope', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.addTableData(
          DatabaseConstants.searchHistoryTable,
          [
            _fakeSearchHistoryData(
              userId: _testUserId,
              searchTerm: 'wall',
            ),
            _fakeSearchHistoryData(
              userId: _testUserId,
              searchTerm: 'concrete',
            ),
          ],
        );
        final useCase = Modular.get<GetRecentSearchesUseCase>();

        final result = await useCase(SearchScope.dashboard);

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (terms) => expect(terms, containsAll(['wall', 'concrete'])),
        );
      });

      test('returns empty list when user is not authenticated', () async {
        fakeSupabase.setCurrentUser(null);
        final useCase = Modular.get<GetRecentSearchesUseCase>();

        final result = await useCase(SearchScope.dashboard);

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (terms) => expect(terms, isEmpty),
        );
      });

      test('returns Left when select throws', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.shouldThrowOnSelectMatch = true;
        fakeSupabase.selectMatchExceptionType = SupabaseExceptionType.timeout;
        final useCase = Modular.get<GetRecentSearchesUseCase>();

        final result = await useCase(SearchScope.dashboard);

        expect(result.isLeft(), isTrue);
      });
    });

    group('SaveRecentSearchUseCase', () {
      test('upserts search term and returns Right', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        final useCase = Modular.get<SaveRecentSearchUseCase>();

        final result = await useCase(
          'steel',
          SearchScope.estimation,
          hasResults: true,
        );

        expect(result.isLeft(), isFalse);
        final upsertCalls = fakeSupabase.getMethodCallsFor('upsert');
        expect(upsertCalls, isNotEmpty);
        final data =
            upsertCalls.first['data'] as Map<String, dynamic>;
        expect(data[DatabaseConstants.searchTermColumn], equals('steel'));
        expect(data[DatabaseConstants.scopeColumn], equals('estimation'));
        expect(data[DatabaseConstants.hasResultsColumn], isTrue);
      });

      test('returns Right without calling upsert when user is not authenticated',
          () async {
        fakeSupabase.setCurrentUser(null);
        final useCase = Modular.get<SaveRecentSearchUseCase>();

        final result = await useCase('steel', SearchScope.dashboard);

        expect(result.isLeft(), isFalse);
        expect(fakeSupabase.getMethodCallsFor('upsert'), isEmpty);
      });

      test('returns Left when upsert throws', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.shouldThrowOnUpsert = true;
        fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
        final useCase = Modular.get<SaveRecentSearchUseCase>();

        final result = await useCase('steel', SearchScope.dashboard);

        expect(result.isLeft(), isTrue);
      });
    });

    group('DeleteRecentSearchUseCase', () {
      test('deletes the term and returns Right', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.addTableData(
          DatabaseConstants.searchHistoryTable,
          [
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'wall'),
          ],
        );
        final useCase = Modular.get<DeleteRecentSearchUseCase>();

        final result = await useCase('wall', SearchScope.dashboard);

        expect(result.isLeft(), isFalse);
        final deleteCalls = fakeSupabase.getMethodCallsFor('deleteMatch');
        expect(deleteCalls, isNotEmpty);
        final filters =
            deleteCalls.first['filters'] as Map<String, dynamic>;
        expect(filters[DatabaseConstants.searchTermColumn], equals('wall'));
      });

      test('returns Left when deleteMatch throws', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.shouldThrowOnDeleteMatch = true;
        fakeSupabase.deleteMatchExceptionType = SupabaseExceptionType.socket;
        final useCase = Modular.get<DeleteRecentSearchUseCase>();

        final result = await useCase('wall', SearchScope.dashboard);

        expect(result.isLeft(), isTrue);
      });
    });

    group('GetSearchSuggestionsUseCase', () {
      test('returns suggestion strings when RPC succeeds', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.setRpcResponse(
          DatabaseConstants.searchSuggestionsRpcFunction,
          ['concrete', 'steel frame'],
        );
        final useCase = Modular.get<GetSearchSuggestionsUseCase>();

        final result = await useCase();

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (suggestions) =>
              expect(suggestions, containsAll(['concrete', 'steel frame'])),
        );
      });

      test('returns empty list when user is not authenticated', () async {
        fakeSupabase.setCurrentUser(null);
        final useCase = Modular.get<GetSearchSuggestionsUseCase>();

        final result = await useCase();

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (suggestions) => expect(suggestions, isEmpty),
        );
      });

      test('returns Left when RPC throws', () async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.shouldThrowOnRpc = true;
        fakeSupabase.rpcExceptionType = SupabaseExceptionType.postgrest;
        final useCase = Modular.get<GetSearchSuggestionsUseCase>();

        final result = await useCase();

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
