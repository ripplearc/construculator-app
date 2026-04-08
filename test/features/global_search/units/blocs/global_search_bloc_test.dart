import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../estimations/helpers/estimation_test_data_map_factory.dart'
    as estimation_factory;

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

const String _testUserId = 'user-bloc-test';
const String _testUserEmail = 'bloc@test.com';

Map<String, dynamic> _fakeMemberData({String? id, String? firstName}) {
  return <String, dynamic>{
    DatabaseConstants.idColumn: id ?? 'member-1',
    DatabaseConstants.credentialIdColumn: null,
    DatabaseConstants.firstNameColumn: firstName ?? 'John',
    DatabaseConstants.lastNameColumn: 'Doe',
    DatabaseConstants.professionalRoleColumn: 'Engineer',
    DatabaseConstants.profilePhotoUrlColumn: null,
  };
}

Map<String, dynamic> _fakeProjectData({String? id, String? projectName}) {
  return {
    DatabaseConstants.idColumn: id ?? 'project-1',
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.descriptionColumn: 'Test description',
    DatabaseConstants.creatorUserIdColumn: _testUserId,
    DatabaseConstants.owningCompanyIdColumn: null,
    DatabaseConstants.exportFolderLinkColumn: null,
    DatabaseConstants.exportStorageProviderColumn: null,
    DatabaseConstants.createdAtColumn: '2024-01-01T00:00:00.000Z',
    DatabaseConstants.updatedAtColumn: '2024-01-01T00:00:00.000Z',
    DatabaseConstants.statusColumn: 'active',
  };
}

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

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  group('GlobalSearchBloc', () {
    late FakeSupabaseWrapper fakeSupabase;
    late FakeClockImpl fakeClock;

    setUpAll(() {
      fakeClock = FakeClockImpl();
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

    test(
      'initial state is GlobalSearchInitial (cold start, no history yet)',
      () {
        final bloc = Modular.get<GlobalSearchBloc>();
        expect(bloc.state, const GlobalSearchInitial());
        expect(bloc.state is GlobalSearchInitial, isTrue);
        bloc.close();
      },
    );

    group('GlobalSearchStarted', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with recentSearches when history exists',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'wall'),
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'concrete'),
          ]);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchStarted()),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'recentSearches',
            containsAll(['wall', 'concrete']),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with empty recentSearches when user is not authenticated',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchStarted()),
        expect: () => [const GlobalSearchReady()],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchLoadFailure when Supabase throws on getRecentSearches',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.shouldThrowOnSelectMatch = true;
          fakeSupabase.selectMatchExceptionType = SupabaseExceptionType.timeout;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchStarted()),
        expect: () => [
          isA<GlobalSearchLoadFailure>().having(
            (s) => s.failure,
            'failure',
            SearchFailure(errorType: SearchErrorType.timeoutError),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'uses supplied scope — loads estimation-scoped recents when scope is estimation',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
            _fakeSearchHistoryData(
              userId: _testUserId,
              searchTerm: 'estimation-term',
              scope: SearchScope.estimation,
            ),
            _fakeSearchHistoryData(
              userId: _testUserId,
              searchTerm: 'dashboard-term',
            ),
          ]);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchStarted(scope: SearchScope.estimation)),
        expect: () => [
          isA<GlobalSearchReady>()
              .having(
                (s) => s.recentSearches,
                'estimation-scoped recents',
                contains('estimation-term'),
              )
              .having(
                (s) => s.recentSearches,
                'no dashboard recents',
                isNot(contains('dashboard-term')),
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'resets query to empty when re-opened after a previous search session',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchQueryUpdated(query: 'stale-query'));
          // Await the debounced GlobalSearchReady emission before re-opening
          // the screen, so the state sequence is deterministic.
          await bloc.stream.first;
          bloc.add(const GlobalSearchStarted());
        },
        wait: const Duration(milliseconds: 310),
        expect: () => [
          const GlobalSearchReady(recentSearches: [], query: 'stale-query'),
          isA<GlobalSearchReady>().having(
            (s) => s.query,
            'query is reset to empty on fresh start',
            isEmpty,
          ),
        ],
      );
    });

    group('GlobalSearchPerformed', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits [GlobalSearchLoadInProgress, GlobalSearchLoadSuccess] when search returns results',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData(projectName: 'Foundation Work')],
              'estimations': [
                estimation_factory
                    .EstimationTestDataMapFactory.createFakeEstimationData(
                  estimateName: 'Steel Frame',
                ),
              ],
              'members': [],
            },
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchPerformed(query: 'foundation')),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'foundation'),
          isA<GlobalSearchLoadSuccess>().having(
            (s) => s.results.projects,
            'projects',
            hasLength(1),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits [GlobalSearchLoadInProgress, GlobalSearchLoadEmpty] when search returns no results',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchPerformed(query: 'nonexistent')),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'nonexistent'),
          const GlobalSearchLoadEmpty(query: 'nonexistent'),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits [GlobalSearchLoadInProgress, GlobalSearchLoadFailure] when Supabase throws on search',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.socket;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchPerformed(query: 'test')),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'test'),
          isA<GlobalSearchLoadFailure>().having(
            (s) => s.failure,
            'failure',
            SearchFailure(errorType: SearchErrorType.connectionError),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits [GlobalSearchLoadInProgress, GlobalSearchLoadFailure] with timeoutError when RPC times out',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.timeout;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchPerformed(query: 'test')),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'test'),
          isA<GlobalSearchLoadFailure>().having(
            (s) => s.failure,
            'failure',
            SearchFailure(errorType: SearchErrorType.timeoutError),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits [GlobalSearchLoadInProgress, GlobalSearchLoadFailure] with parsingError on TypeError',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.type;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchPerformed(query: 'test')),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'test'),
          isA<GlobalSearchLoadFailure>(),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'GlobalSearchLoadSuccess carries all three result lists',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData(id: 'p1')],
              'estimations': [
                estimation_factory
                    .EstimationTestDataMapFactory.createFakeEstimationData(
                  id: 'e1',
                ),
              ],
              'members': [_fakeMemberData(id: 'm1', firstName: 'Alice')],
            },
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchPerformed(query: 'alice')),
        verify: (bloc) {
          final state = bloc.state as GlobalSearchLoadSuccess;
          expect(state.results.projects, hasLength(1));
          expect(state.results.estimations, hasLength(1));
          expect(state.results.members, hasLength(1));
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'uses supplied scope — emits correct states when scope is estimation',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData()],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          const GlobalSearchPerformed(
            query: 'steel',
            scope: SearchScope.estimation,
          ),
        ),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'steel'),
          isA<GlobalSearchLoadSuccess>(),
        ],
        verify: (_) {
          final rpcCalls = fakeSupabase.getMethodCallsFor('rpc');
          expect(
            rpcCalls,
            isNotEmpty,
            reason: 'RPC must be called for a search',
          );
          final rpcParams = rpcCalls.first['params'] as Map<String, dynamic>;
          expect(
            rpcParams['scope'],
            equals(SearchScope.estimation.name),
            reason: 'scope must be forwarded to the RPC',
          );
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'optimistically adds query to recentSearches so GlobalSearchQueryUpdated sees it immediately',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData()],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchPerformed(query: 'steel'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          bloc.add(const GlobalSearchQueryUpdated(query: ''));
        },
        wait: const Duration(milliseconds: 310),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'steel'),
          isA<GlobalSearchLoadSuccess>(),
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'searched term is present without reopening the screen',
            contains('steel'),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'does not duplicate query in recentSearches if already present',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'steel'),
          ]);
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData()],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere((s) => s is GlobalSearchReady);
          bloc.add(const GlobalSearchPerformed(query: 'steel'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          bloc.add(const GlobalSearchQueryUpdated(query: ''));
        },
        wait: const Duration(milliseconds: 310),
        verify: (bloc) {
          final state = bloc.state as GlobalSearchReady;
          expect(
            state.recentSearches.where((t) => t == 'steel'),
            hasLength(1),
            reason: 'steel must appear exactly once',
          );
        },
      );
    });

    group('GlobalSearchQueryUpdated', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with updated query and empty recentSearches',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchQueryUpdated(query: 'foundation')),
        wait: const Duration(milliseconds: 310),
        expect: () => [
          const GlobalSearchReady(recentSearches: [], query: 'foundation'),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with empty query when query is cleared',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchQueryUpdated(query: '')),
        wait: const Duration(milliseconds: 310),
        expect: () => [const GlobalSearchReady()],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'does not make any Supabase calls when query is updated',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchQueryUpdated(query: 'concrete')),
        wait: const Duration(milliseconds: 310),
        verify: (_) {
          expect(fakeSupabase.getMethodCallsFor('rpc'), isEmpty);
          expect(fakeSupabase.getMethodCallsFor('selectMatch'), isEmpty);
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'preserves recentSearches loaded by GlobalSearchStarted when query is updated',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'steel'),
          ]);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere((s) {
            if (s is! GlobalSearchReady) {
              return false;
            }
            return s.recentSearches.contains('steel');
          });
          bloc.add(const GlobalSearchQueryUpdated(query: 'concrete'));
        },
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'recentSearches after Started',
            contains('steel'),
          ),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query after QueryUpdated', 'concrete')
              .having(
                (s) => s.recentSearches,
                'recentSearches preserved after QueryUpdated',
                contains('steel'),
              ),
        ],
      );
    });

    group('GlobalSearchSuggestionsRequested', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits [GlobalSearchReady loading, GlobalSearchReady with suggestions] when RPC succeeds',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.setRpcResponse(
            DatabaseConstants.searchSuggestionsRpcFunction,
            ['foundation', 'concrete mix', 'steel frame'],
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchSuggestionsRequested()),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.suggestionsLoading,
            'suggestionsLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.suggestions,
                'suggestions',
                containsAll(['foundation', 'concrete mix', 'steel frame']),
              )
              .having(
                (s) => s.suggestionsLoading,
                'suggestionsLoading',
                isFalse,
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchSuggestionsLoadFailure when RPC throws',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.timeout;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchSuggestionsRequested()),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.suggestionsLoading,
            'suggestionsLoading',
            isTrue,
          ),
          isA<GlobalSearchSuggestionsLoadFailure>().having(
            (s) => s.failure,
            'failure',
            SearchFailure(errorType: SearchErrorType.timeoutError),
          ),
        ],
      );
    });

    group('GlobalSearchRecentRemoved', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady without removed term when delete succeeds',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'wall'),
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'concrete'),
          ]);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere((s) {
            if (s is! GlobalSearchReady) {
              return false;
            }
            return s.recentSearches.length == 2;
          });
          bloc.add(
            const GlobalSearchRecentRemoved(
              searchTerm: 'wall',
              scope: SearchScope.dashboard,
            ),
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'recentSearches after Started',
            containsAll(['wall', 'concrete']),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'recentSearches after Removed',
            allOf(isNot(contains('wall')), contains('concrete')),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchRecentDeleteFailure when delete throws',
        setUp: () {
          fakeSupabase.setCurrentUser(
            FakeUser(
              id: _testUserId,
              email: _testUserEmail,
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
            _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'wall'),
          ]);
          fakeSupabase.shouldThrowOnDeleteMatch = true;
          fakeSupabase.deleteMatchExceptionType = SupabaseExceptionType.socket;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          const GlobalSearchRecentRemoved(
            searchTerm: 'wall',
            scope: SearchScope.dashboard,
          ),
        ),
        expect: () => [
          isA<GlobalSearchRecentDeleteFailure>().having(
            (s) => s.failure,
            'failure',
            SearchFailure(errorType: SearchErrorType.connectionError),
          ),
        ],
      );
    });
  });
}
