import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
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
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart'
    as estimation_factory;
import '../../../../utils/fake_app_bootstrap_factory.dart';

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
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
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

    void seedTags(List<String> names) {
      fakeSupabase.addTableData(
        DatabaseConstants.tagsTable,
        names
            .map(
              (name) => <String, dynamic>{
                DatabaseConstants.idColumn: 'tag-$name',
                DatabaseConstants.nameColumn: name,
              },
            )
            .toList(),
      );
    }

    // Seeds the project owners RPC with one owner per (id, firstName) pair,
    // preserving order so tests can assert the bloc keeps RPC ordering.
    void seedOwners(List<({String id, String firstName})> owners) {
      fakeSupabase.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        owners
            .map(
              (owner) => <String, dynamic>{
                DatabaseConstants.idColumn: owner.id,
                DatabaseConstants.credentialIdColumn: null,
                DatabaseConstants.firstNameColumn: owner.firstName,
                DatabaseConstants.lastNameColumn: 'Doe',
                DatabaseConstants.professionalRoleColumn: 'Engineer',
                DatabaseConstants.profilePhotoUrlColumn: null,
              },
            )
            .toList(),
      );
    }

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
        'emits GlobalSearchRecentsLoadFailure when Supabase throws on getRecentSearches',
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
          isA<GlobalSearchRecentsLoadFailure>().having(
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
          await bloc.stream.firstWhere((s) =>
              s is GlobalSearchReady &&
              s.query == 'stale-query' &&
              !s.suggestionsLoading);
          bloc.add(const GlobalSearchStarted());
        },
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.query,
            'query is reset to empty on fresh start',
            isEmpty,
          ),
        ],
        skip: 2,
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
        'emits GlobalSearchEmptyQuery and skips search when query is empty',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchPerformed(query: '')),
        expect: () => [const GlobalSearchEmptyQuery()],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchEmptyQuery and skips search when query is whitespace only',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchPerformed(query: '   ')),
        expect: () => [const GlobalSearchEmptyQuery()],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'preserves the previous query when an empty query is submitted',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          // Establish a valid current query first.
          bloc.add(const GlobalSearchPerformed(query: 'foundation'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadEmpty);
          // Submit an invalid query; the early-return guard must fire before
          // the bloc's current query is mutated.
          bloc.add(const GlobalSearchPerformed(query: '   '));
          await bloc.stream.firstWhere((s) => s is GlobalSearchEmptyQuery);
          // GlobalSearchTagFiltersApplied echoes the bloc's current query in
          // GlobalSearchReady, exposing any mutation from the empty submission.
          bloc.add(const GlobalSearchTagFiltersApplied(tags: {'Roofing'}));
          // The results surface was still active (the empty submission
          // returned early without deactivating it), so applying the tag
          // re-runs the preserved 'foundation' query (CA-901).
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadEmpty);
        },
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'foundation'),
          const GlobalSearchLoadEmpty(query: 'foundation'),
          const GlobalSearchEmptyQuery(),
          isA<GlobalSearchReady>().having(
            (s) => s.query,
            'query unchanged by the empty submission',
            'foundation',
          ),
          const GlobalSearchLoadInProgress(query: 'foundation'),
          const GlobalSearchLoadEmpty(query: 'foundation'),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'trims surrounding whitespace before searching and reports trimmed query',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchPerformed(query: '  foundation  ')),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'foundation'),
          const GlobalSearchLoadEmpty(query: 'foundation'),
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
          isA<GlobalSearchLoadFailure>()
              .having(
                (s) => s.failure,
                'failure',
                SearchFailure(errorType: SearchErrorType.timeoutError),
              )
              .having((s) => s.query, 'query', 'test'),
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
        'uses the selected scope — forwards estimation to the RPC after a '
        'GlobalSearchScopeChanged',
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
              searchTerm: 'girder',
              scope: SearchScope.estimation,
            ),
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
          bloc.add(
            const GlobalSearchScopeChanged(scope: SearchScope.estimation),
          );
          // Wait for the scope's history reload to land before performing, so
          // its Ready emission cannot interleave with the search states.
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('girder'),
          );
          bloc.add(const GlobalSearchPerformed(query: 'steel'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedScope,
            'selectedScope',
            SearchScope.estimation,
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'recentSearches',
            ['girder'],
          ),
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
            reason: 'the bloc-selected scope must be forwarded to the RPC',
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
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'forwards the alphabetically first selected tag to the RPC when multiple tags are active',
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
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          // Apply two tags; 'Roofing' sorts before 'Wall' alphabetically.
          bloc.add(
            const GlobalSearchTagFiltersApplied(tags: {'Wall', 'Roofing'}),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchPerformed(query: 'steel'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'tags applied',
            containsAll(['Wall', 'Roofing']),
          ),
          const GlobalSearchLoadInProgress(query: 'steel'),
          isA<GlobalSearchLoadEmpty>(),
        ],
        verify: (_) {
          final rpcCalls = fakeSupabase.getMethodCallsFor('rpc');
          final rpcParams = rpcCalls.first['params'] as Map<String, dynamic>;
          expect(
            rpcParams['filter_by_tag'],
            equals('Roofing'),
            reason: 'must forward the alphabetically first tag, not an arbitrary Set element',
          );
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'forwards all selected owner ids to the RPC sorted alphabetically when multiple owners are active',
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
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          // Apply two owners; 'owner-1' sorts before 'owner-2'.
          bloc.add(
            const GlobalSearchOwnerFiltersApplied(
              ownerIds: {'owner-2', 'owner-1'},
            ),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchPerformed(query: 'steel'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'owners applied',
            containsAll(['owner-1', 'owner-2']),
          ),
          const GlobalSearchLoadInProgress(query: 'steel'),
          isA<GlobalSearchLoadEmpty>(),
        ],
        verify: (_) {
          final rpcCalls = fakeSupabase.getMethodCallsFor('rpc');
          final globalSearchCall = rpcCalls.firstWhere(
            (call) =>
                call['functionName'] ==
                DatabaseConstants.globalSearchRpcFunction,
          );
          final rpcParams =
              globalSearchCall['params'] as Map<String, dynamic>;
          expect(
            rpcParams['filter_by_owners'],
            equals(['owner-1', 'owner-2']),
            reason:
                'must forward every selected owner id, sorted so equal '
                'selections always produce the same RPC payload',
          );
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'forwards a null owner filter to the RPC when no owners are selected',
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
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchPerformed(query: 'steel')),
        expect: () => [
          const GlobalSearchLoadInProgress(query: 'steel'),
          isA<GlobalSearchLoadEmpty>(),
        ],
        verify: (_) {
          final rpcCalls = fakeSupabase.getMethodCallsFor('rpc');
          final globalSearchCall = rpcCalls.firstWhere(
            (call) =>
                call['functionName'] ==
                DatabaseConstants.globalSearchRpcFunction,
          );
          final rpcParams =
              globalSearchCall['params'] as Map<String, dynamic>;
          expect(
            rpcParams['filter_by_owners'],
            isNull,
            reason:
                'an empty owner selection must be forwarded as null, the '
                'backend contract for "no owner filter"',
          );
        },
      );
    });

    group('GlobalSearchQueryUpdated', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'fetches suggestions on first non-empty query and emits filtered list',
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
            ['foundation', 'foundation repair', 'concrete'],
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchQueryUpdated(query: 'foundation')),
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having(
                (s) => s.suggestions,
                'suggestions',
                ['foundation', 'foundation repair'],
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits empty suggestions list when query is cleared',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchQueryUpdated(query: '')),
        wait: const Duration(milliseconds: 310),
        expect: () => [const GlobalSearchReady()],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'clears suggestionsLoading when clearing the query cancels the '
        'in-flight fetch',
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
            ['foundation'],
          );
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchQueryUpdated(query: 'foundation'));
          // Wait for the fetch to be in flight, then clear the query — the
          // switchMap transformer cancels the fetch handler, so its
          // completion can never emit. The empty-query emission must not
          // report a loading fetch.
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.suggestionsLoading,
          );
          bloc.add(const GlobalSearchQueryUpdated(query: ''));
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.query.isEmpty,
          );
          // Release the cancelled fetch; its generation-guarded continuation
          // runs to completion during bloc.close() without emitting.
          fakeSupabase.completer!.complete();
        },
        expect: () => [
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', isEmpty)
              .having(
                (s) => s.suggestionsLoading,
                'loading reset with the cancelled fetch',
                isFalse,
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'stale cancelled fetch does not clear the loading flag owned by a '
        'newer fetch',
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
            ['foundation'],
          );
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          final firstFetchGate = fakeSupabase.completer!;
          bloc.add(const GlobalSearchQueryUpdated(query: 'fo'));
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.suggestionsLoading,
          );
          // The second fetch awaits its own gate so the first one can be
          // released while the second is still in flight.
          final secondFetchGate = Completer<void>();
          fakeSupabase.completer = secondFetchGate;
          bloc.add(const GlobalSearchQueryUpdated(query: 'found'));
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.query == 'found',
          );
          // Release the superseded first fetch; its continuation must not
          // touch the flag. A concurrently-handled event emitting afterwards
          // must still see the newer fetch's loading flag.
          firstFetchGate.complete();
          bloc.add(
            const GlobalSearchOwnerFiltersApplied(ownerIds: {'owner-1'}),
          );
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.selectedOwnerIds.contains('owner-1'),
          );
          secondFetchGate.complete();
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && !state.suggestionsLoading,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'fo')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'found')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<GlobalSearchReady>()
              .having((s) => s.selectedOwnerIds, 'selectedOwnerIds', {
                'owner-1',
              })
              .having(
                (s) => s.suggestionsLoading,
                'loading survives the stale fetch completing',
                isTrue,
              ),
          isA<GlobalSearchReady>()
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having((s) => s.suggestions, 'suggestions', ['foundation']),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'a fetch surviving a GlobalSearchStarted reset does not mark '
        'suggestions as fetched — the next keystroke refetches',
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
            ['foundation'],
          );
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          final suggestionsFetchGate = fakeSupabase.completer!;
          bloc.add(const GlobalSearchQueryUpdated(query: 'fo'));
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.suggestionsLoading,
          );
          // Later operations run ungated; only the in-flight suggestions
          // fetch stays parked on the gate.
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && !state.suggestionsLoading,
          );
          // Release the pre-reset fetch; the reset disowned it, so it must
          // not resurrect the cache or mark suggestions as fetched. Its
          // pure-microtask continuation drains before the debounce timer
          // delivers the next keystroke, so no pump loop is needed.
          suggestionsFetchGate.complete();
          bloc.add(const GlobalSearchQueryUpdated(query: 'found'));
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.query == 'found' &&
                !state.suggestionsLoading,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'fo')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query after reset', isEmpty)
              .having((s) => s.suggestionsLoading, 'loading', isFalse),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'found')
              .having(
                (s) => s.suggestionsLoading,
                'post-reset keystroke starts a fresh fetch',
                isTrue,
              ),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query', 'found')
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having((s) => s.suggestions, 'suggestions', ['foundation']),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'skips the suggestions fetch when query is whitespace-only',
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
            ['foundation', 'concrete'],
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchQueryUpdated(query: '   ')),
        wait: const Duration(milliseconds: 310),
        expect: () => [const GlobalSearchReady()],
        verify: (_) {
          final rpcCalls = fakeSupabase
              .getMethodCallsFor('rpc')
              .where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.searchSuggestionsRpcFunction,
              );
          expect(rpcCalls, isEmpty);
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'reuses cached raw suggestions on subsequent query updates with no extra RPC',
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
            ['Carpentry', 'Carparking', 'Plumbing', 'Concrete'],
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchQueryUpdated(query: 'Car'));
          await bloc.stream.firstWhere((s) =>
              s is GlobalSearchReady && !s.suggestionsLoading);
          bloc.add(const GlobalSearchQueryUpdated(query: 'Con'));
        },
        wait: const Duration(milliseconds: 700),
        verify: (_) {
          final rpcCalls = fakeSupabase
              .getMethodCallsFor('rpc')
              .where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.searchSuggestionsRpcFunction,
              );
          expect(rpcCalls, hasLength(1));
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'caps the filtered suggestions list at 5 items',
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
            [
              'C1',
              'C2',
              'C3',
              'C4',
              'C5',
              'C6',
              'C7',
            ],
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchQueryUpdated(query: 'C')),
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.suggestionsLoading,
            'loading',
            isTrue,
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.suggestions,
            'suggestions capped at 5',
            ['C1', 'C2', 'C3', 'C4', 'C5'],
          ),
        ],
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
          fakeSupabase.setRpcResponse(
            DatabaseConstants.searchSuggestionsRpcFunction,
            <String>[],
          );
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
        wait: const Duration(milliseconds: 700),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'recentSearches after Started',
            contains('steel'),
          ),
          isA<GlobalSearchReady>()
              .having((s) => s.query, 'query after QueryUpdated', 'concrete')
              .having((s) => s.suggestionsLoading, 'loading', isTrue)
              .having(
                (s) => s.recentSearches,
                'recentSearches preserved during fetch',
                contains('steel'),
              ),
          isA<GlobalSearchReady>()
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having(
                (s) => s.recentSearches,
                'recentSearches preserved after fetch',
                contains('steel'),
              ),
        ],
      );
    });

    group('GlobalSearchSuggestionsRequested', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits empty suggestions list when no query is set',
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
              .having((s) => s.suggestions, 'suggestions', isEmpty)
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
          isA<GlobalSearchReady>().having(
            (s) => s.suggestionsLoading,
            'suggestionsLoading',
            isFalse,
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

    group('GlobalSearchTagFiltersApplied', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with selectedTags when tags are applied',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          const GlobalSearchTagFiltersApplied(tags: {'Roofing', 'Wall'}),
        ),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'selectedTags',
            containsAll(['Roofing', 'Wall']),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with empty selectedTags when empty set is applied',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          const GlobalSearchTagFiltersApplied(tags: {}),
        ),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'selectedTags',
            isEmpty,
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'preserves query and recentSearches when applying tags',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.first;
          bloc.add(
            const GlobalSearchTagFiltersApplied(tags: {'Flooring'}),
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having((s) => s.query, 'query', isEmpty),
          isA<GlobalSearchReady>()
              .having((s) => s.selectedTags, 'selectedTags', contains('Flooring'))
              .having((s) => s.query, 'query preserved', isEmpty),
        ],
      );
    });

    group('GlobalSearchTagFilterCleared', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with tag removed from selectedTags',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const GlobalSearchTagFiltersApplied(tags: {'Roofing', 'Wall'}),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchTagFilterCleared(tag: 'Roofing'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'two tags selected',
            containsAll(['Roofing', 'Wall']),
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.selectedTags,
                'Roofing removed',
                isNot(contains('Roofing')),
              )
              .having(
                (s) => s.selectedTags,
                'Wall remains',
                contains('Wall'),
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with empty selectedTags when last tag is cleared',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const GlobalSearchTagFiltersApplied(tags: {'Flooring'}),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchTagFilterCleared(tag: 'Flooring'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'one tag selected',
            contains('Flooring'),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'selectedTags empty after last cleared',
            isEmpty,
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'preserves query and recentSearches when clearing a tag',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.first;
          bloc.add(
            const GlobalSearchTagFiltersApplied(tags: {'Carpeting'}),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchTagFilterCleared(tag: 'Carpeting'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having((s) => s.query, 'initial query', isEmpty),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'tag applied',
            contains('Carpeting'),
          ),
          isA<GlobalSearchReady>()
              .having((s) => s.selectedTags, 'tag cleared', isEmpty)
              .having((s) => s.query, 'query preserved', isEmpty),
        ],
      );
    });

    group('GlobalSearchStarted resets selectedTags', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'clears selectedTags when GlobalSearchStarted is dispatched after tags were applied',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const GlobalSearchTagFiltersApplied(tags: {'Roofing'}),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchStarted());
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'tags applied',
            contains('Roofing'),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedTags,
            'tags reset on restart',
            isEmpty,
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'clears availableTags when GlobalSearchStarted is dispatched after '
        'tags were fetched',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
          seedTags(['Roofing']);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && state.availableTags.isEmpty,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTagsLoading,
            'availableTagsLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.availableTags,
            'availableTags',
            ['Roofing'],
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTags,
                'availableTags cleared on restart',
                isEmpty,
              )
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading',
                isFalse,
              ),
        ],
      );
    });

    group('GlobalSearchAvailableTagsRequested', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits loading then tags sorted alphabetically on success',
        setUp: () => seedTags(['Wall', 'Carpeting', 'Roofing']),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchAvailableTagsRequested()),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTagsLoading,
            'availableTagsLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTags,
                'availableTags',
                ['Carpeting', 'Roofing', 'Wall'],
              )
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading',
                isFalse,
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'reuses cached tags without refetching on subsequent requests',
        setUp: () => seedTags(['Roofing']),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
          bloc.add(const GlobalSearchAvailableTagsRequested());
        },
        verify: (_) {
          final selectCalls = fakeSupabase
              .getMethodCallsFor('selectMatch')
              .where(
                (call) => call['table'] == DatabaseConstants.tagsTable,
              );
          expect(selectCalls.length, 1);
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchTagsLoadFailure then recovers to Ready on error',
        setUp: () {
          fakeSupabase.shouldThrowOnSelectMatch = true;
          fakeSupabase.selectMatchExceptionType =
              SupabaseExceptionType.postgrest;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchAvailableTagsRequested()),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTagsLoading,
            'availableTagsLoading',
            isTrue,
          ),
          isA<GlobalSearchTagsLoadFailure>().having(
            (s) => s.failure,
            'failure',
            isA<SearchFailure>(),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.availableTags,
            'availableTags stay empty',
            isEmpty,
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'keeps availableTagsLoading true when a concurrent handler emits '
        'while the tags fetch is in flight',
        setUp: () {
          seedTags(['Roofing']);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableTagsRequested());
          // Wait for the in-flight loading emission, then dispatch an event
          // whose handler emits _readyState() while the fetch is still
          // pending — it must not reset the loading flag.
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.availableTagsLoading,
          );
          bloc.add(
            const GlobalSearchOwnerFiltersApplied(ownerIds: {'owner-1'}),
          );
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.selectedOwnerIds.contains('owner-1'),
          );
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading',
                isTrue,
              )
              .having((s) => s.selectedOwnerIds, 'selectedOwnerIds', isEmpty),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading survives concurrent emission',
                isTrue,
              )
              .having((s) => s.selectedOwnerIds, 'selectedOwnerIds', {
                'owner-1',
              }),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading',
                isFalse,
              )
              .having((s) => s.availableTags, 'availableTags', ['Roofing']),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'does not start a duplicate tags fetch when one is already in flight',
        setUp: () {
          seedTags(['Roofing']);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableTagsRequested());
          // Wait for the in-flight loading emission, then request tags again
          // — the second request must reuse the in-flight fetch instead of
          // starting another, whose earlier completion would clear the
          // loading flag while the later fetch is still running.
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.availableTagsLoading,
          );
          bloc.add(const GlobalSearchAvailableTagsRequested());
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTagsLoading,
            'availableTagsLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading',
                isFalse,
              )
              .having((s) => s.availableTags, 'availableTags', ['Roofing']),
        ],
        verify: (_) {
          final tagFetches = fakeSupabase
              .getMethodCallsFor('selectMatch')
              .where(
                (call) => call['table'] == DatabaseConstants.tagsTable,
              );
          expect(tagFetches, hasLength(1));
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'a tags fetch surviving a GlobalSearchStarted reset neither stomps '
        'the reset flag nor marks tags as fetched — the next sheet open '
        'refetches',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
          seedTags(['Roofing']);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          final tagsFetchGate = fakeSupabase.completer!;
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere(
            (state) => state is GlobalSearchReady && state.availableTagsLoading,
          );
          // Later operations run ungated; only the in-flight tags fetch
          // stays parked on the gate.
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
          // Release the pre-reset fetch; the reset disowned it, so it must
          // not mark tags as fetched or emit over the reset state.
          tagsFetchGate.complete();
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                !state.availableTagsLoading &&
                state.availableTags.isNotEmpty,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTagsLoading,
            'availableTagsLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading reset on restart',
                isFalse,
              )
              .having((s) => s.availableTags, 'availableTags', isEmpty),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTagsLoading,
                'post-reset sheet open starts a fresh fetch',
                isTrue,
              )
              .having((s) => s.availableTags, 'availableTags', isEmpty),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableTagsLoading,
                'availableTagsLoading',
                isFalse,
              )
              .having((s) => s.availableTags, 'availableTags', ['Roofing']),
        ],
        verify: (_) {
          final tagFetches = fakeSupabase
              .getMethodCallsFor('selectMatch')
              .where(
                (call) => call['table'] == DatabaseConstants.tagsTable,
              );
          expect(tagFetches, hasLength(2));
        },
      );
    });

    group('GlobalSearchTagSearchQueryUpdated', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'filters available tags case-insensitively by substring',
        setUp: () => seedTags(['Roofing', 'Carpeting', 'Wall', 'Painting']),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
          bloc.add(const GlobalSearchTagSearchQueryUpdated(query: 'ING'));
        },
        skip: 2,
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTags,
            'filtered tags',
            ['Carpeting', 'Painting', 'Roofing'],
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'restores the full list when the query is cleared',
        setUp: () => seedTags(['Roofing', 'Wall']),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
          bloc.add(const GlobalSearchTagSearchQueryUpdated(query: 'roof'));
          await bloc.stream.first;
          bloc.add(const GlobalSearchTagSearchQueryUpdated(query: ''));
        },
        skip: 3,
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTags,
            'full list restored',
            ['Roofing', 'Wall'],
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'resets the tag search query when the sheet is reopened',
        setUp: () => seedTags(['Roofing', 'Wall']),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableTagsLoading,
          );
          bloc.add(const GlobalSearchTagSearchQueryUpdated(query: 'roof'));
          await bloc.stream.first;
          bloc.add(const GlobalSearchAvailableTagsRequested());
        },
        skip: 3,
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableTags,
            'query reset restores full list',
            ['Roofing', 'Wall'],
          ),
        ],
      );
    });

    group('GlobalSearchOwnerFiltersApplied', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with selectedOwnerIds when owners are applied',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          const GlobalSearchOwnerFiltersApplied(
            ownerIds: {'owner-1', 'owner-2'},
          ),
        ),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'selectedOwnerIds',
            containsAll(['owner-1', 'owner-2']),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with empty selectedOwnerIds when empty set is applied',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) =>
            bloc.add(const GlobalSearchOwnerFiltersApplied(ownerIds: {})),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'selectedOwnerIds',
            isEmpty,
          ),
        ],
      );
    });

    group('GlobalSearchOwnerFilterCleared', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with owner removed from selectedOwnerIds',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const GlobalSearchOwnerFiltersApplied(
              ownerIds: {'owner-1', 'owner-2'},
            ),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchOwnerFilterCleared(ownerId: 'owner-1'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'two owners selected',
            containsAll(['owner-1', 'owner-2']),
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.selectedOwnerIds,
                'owner-1 removed',
                isNot(contains('owner-1')),
              )
              .having(
                (s) => s.selectedOwnerIds,
                'owner-2 remains',
                contains('owner-2'),
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with empty selectedOwnerIds when last owner is cleared',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const GlobalSearchOwnerFiltersApplied(ownerIds: {'owner-1'}),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchOwnerFilterCleared(ownerId: 'owner-1'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'one owner selected',
            contains('owner-1'),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'selectedOwnerIds empty after last cleared',
            isEmpty,
          ),
        ],
      );
    });

    group('GlobalSearchStarted resets selectedOwnerIds', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'clears selectedOwnerIds when GlobalSearchStarted is dispatched after owners were applied',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const GlobalSearchOwnerFiltersApplied(ownerIds: {'owner-1'}),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchStarted());
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'owners applied',
            contains('owner-1'),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedOwnerIds,
            'owners reset on restart',
            isEmpty,
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'clears availableOwners when GlobalSearchStarted is dispatched after '
        'owners were fetched',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
          seedOwners([(id: 'owner-1', firstName: 'John')]);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && state.availableOwners.isEmpty,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwnersLoading,
            'availableOwnersLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwners.map((owner) => owner.id),
            'availableOwners',
            ['owner-1'],
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableOwners,
                'availableOwners cleared on restart',
                isEmpty,
              )
              .having(
                (s) => s.availableOwnersLoading,
                'availableOwnersLoading',
                isFalse,
              ),
        ],
      );
    });

    group('GlobalSearchDateFilterApplied', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with selectedDateRange when a range is applied',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          GlobalSearchDateFilterApplied(
            range: DateRange(
              start: DateTime(2024, 3, 1),
              end: DateTime(2024, 3, 31),
            ),
          ),
        ),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'selectedDateRange',
            DateRange(start: DateTime(2024, 3, 1), end: DateTime(2024, 3, 31)),
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'replaces a previously applied range when a new one is applied',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            GlobalSearchDateFilterApplied(
              range: DateRange(
                start: DateTime(2024, 1, 1),
                end: DateTime(2024, 1, 31),
              ),
            ),
          );
          await bloc.stream.first;
          bloc.add(
            GlobalSearchDateFilterApplied(
              range: DateRange(
                start: DateTime(2024, 3, 1),
                end: DateTime(2024, 3, 31),
              ),
            ),
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'first range applied',
            DateRange(start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 31)),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'second range replaces first',
            DateRange(start: DateTime(2024, 3, 1), end: DateTime(2024, 3, 31)),
          ),
        ],
      );
    });

    group('GlobalSearchDateFilterCleared', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchReady with null selectedDateRange after clearing',
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            GlobalSearchDateFilterApplied(
              range: DateRange(
                start: DateTime(2024, 3, 1),
                end: DateTime(2024, 3, 31),
              ),
            ),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchDateFilterCleared());
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'range applied',
            isNotNull,
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'selectedDateRange cleared',
            isNull,
          ),
        ],
      );
    });

    group('GlobalSearchStarted resets selectedDateRange', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'clears selectedDateRange when GlobalSearchStarted is dispatched after a range was applied',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            GlobalSearchDateFilterApplied(
              range: DateRange(
                start: DateTime(2024, 3, 1),
                end: DateTime(2024, 3, 31),
              ),
            ),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchStarted());
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'range applied',
            isNotNull,
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'range reset on restart',
            isNull,
          ),
        ],
      );
    });

    group('GlobalSearchPerformed forwards date range to the RPC', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'forwards filter_by_date_from and filter_by_date_to when a range is active',
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
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            GlobalSearchDateFilterApplied(
              range: DateRange(
                start: DateTime(2024, 3, 1),
                end: DateTime(2024, 3, 31),
              ),
            ),
          );
          await bloc.stream.first;
          bloc.add(const GlobalSearchPerformed(query: 'steel'));
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.selectedDateRange,
            'range applied',
            isNotNull,
          ),
          const GlobalSearchLoadInProgress(query: 'steel'),
          isA<GlobalSearchLoadEmpty>(),
        ],
        verify: (_) {
          final rpcCalls = fakeSupabase.getMethodCallsFor('rpc');
          final globalSearchCall = rpcCalls.firstWhere(
            (call) =>
                call['functionName'] ==
                DatabaseConstants.globalSearchRpcFunction,
          );
          final rpcParams = globalSearchCall['params'] as Map<String, dynamic>;
          expect(
            rpcParams['filter_by_date_from'],
            equals(DateTime(2024, 3, 1).toIso8601String()),
          );
          expect(
            rpcParams['filter_by_date_to'],
            equals(DateTime(2024, 3, 31).toIso8601String()),
          );
        },
      );
    });

    group('GlobalSearchAvailableOwnersRequested', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits loading then owners in RPC order on success',
        setUp: () => seedOwners([
          (id: 'owner-1', firstName: 'John'),
          (id: 'owner-2', firstName: 'Floyd'),
        ]),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchAvailableOwnersRequested()),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwnersLoading,
            'availableOwnersLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableOwners.map((o) => o.id).toList(),
                'availableOwners',
                ['owner-1', 'owner-2'],
              )
              .having(
                (s) => s.availableOwnersLoading,
                'availableOwnersLoading',
                isFalse,
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'reuses cached owners without refetching on subsequent requests',
        setUp: () => seedOwners([(id: 'owner-1', firstName: 'John')]),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
          bloc.add(const GlobalSearchAvailableOwnersRequested());
        },
        verify: (_) {
          final rpcCalls = fakeSupabase.getMethodCallsFor('rpc').where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectOwnersRpcFunction,
              );
          expect(rpcCalls.length, 1);
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits GlobalSearchOwnersLoadFailure then recovers to Ready on error',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.postgrest;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(const GlobalSearchAvailableOwnersRequested()),
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwnersLoading,
            'availableOwnersLoading',
            isTrue,
          ),
          isA<GlobalSearchOwnersLoadFailure>().having(
            (s) => s.failure,
            'failure',
            isA<SearchFailure>(),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwners,
            'availableOwners stay empty',
            isEmpty,
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        're-fetches owners on the next request after a failed fetch',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.postgrest;
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
          // Recover the backend, then request again: the failed fetch must
          // not have cached, so this second request hits the RPC again.
          fakeSupabase.shouldThrowOnRpc = false;
          seedOwners([(id: 'owner-1', firstName: 'John')]);
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                !state.availableOwnersLoading &&
                state.availableOwners.isNotEmpty,
          );
        },
        verify: (_) {
          final rpcCalls = fakeSupabase.getMethodCallsFor('rpc').where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectOwnersRpcFunction,
              );
          expect(
            rpcCalls.length,
            2,
            reason: 'a failed fetch must not cache; the retry refetches',
          );
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'does not start a duplicate owners fetch when one is already in '
        'flight',
        setUp: () {
          seedOwners([(id: 'owner-1', firstName: 'John')]);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          // Wait for the in-flight loading emission, then request owners
          // again — the second request must reuse the in-flight fetch
          // instead of starting another, whose earlier completion would
          // clear the loading flag while the later fetch is still running.
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && state.availableOwnersLoading,
          );
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwnersLoading,
            'availableOwnersLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableOwnersLoading,
                'availableOwnersLoading',
                isFalse,
              )
              .having(
                (s) => s.availableOwners.map((o) => o.id).toList(),
                'availableOwners',
                ['owner-1'],
              ),
        ],
        verify: (_) {
          final ownerFetches = fakeSupabase.getMethodCallsFor('rpc').where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectOwnersRpcFunction,
              );
          expect(ownerFetches, hasLength(1));
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'an owners fetch surviving a GlobalSearchStarted reset neither '
        'stomps the reset flag nor marks owners as fetched — the next sheet '
        'open refetches',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
          seedOwners([(id: 'owner-1', firstName: 'John')]);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          final ownersFetchGate = fakeSupabase.completer!;
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && state.availableOwnersLoading,
          );
          // Later operations run ungated; only the in-flight owners fetch
          // stays parked on the gate.
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
          // Release the pre-reset fetch; the reset disowned it, so it must
          // not mark owners as fetched or emit over the reset state.
          ownersFetchGate.complete();
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                !state.availableOwnersLoading &&
                state.availableOwners.isNotEmpty,
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwnersLoading,
            'availableOwnersLoading',
            isTrue,
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableOwnersLoading,
                'availableOwnersLoading reset on restart',
                isFalse,
              )
              .having((s) => s.availableOwners, 'availableOwners', isEmpty),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableOwnersLoading,
                'post-reset sheet open starts a fresh fetch',
                isTrue,
              )
              .having((s) => s.availableOwners, 'availableOwners', isEmpty),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.availableOwnersLoading,
                'availableOwnersLoading',
                isFalse,
              )
              .having(
                (s) => s.availableOwners.map((o) => o.id).toList(),
                'availableOwners',
                ['owner-1'],
              ),
        ],
        verify: (_) {
          final ownerFetches = fakeSupabase.getMethodCallsFor('rpc').where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectOwnersRpcFunction,
              );
          expect(ownerFetches, hasLength(2));
        },
      );
    });

    group('GlobalSearchOwnerSearchQueryUpdated', () {
      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'filters available owners case-insensitively by full name substring',
        setUp: () => seedOwners([
          (id: 'owner-1', firstName: 'John'),
          (id: 'owner-2', firstName: 'Johnny'),
          (id: 'owner-3', firstName: 'Floyd'),
        ]),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
          bloc.add(const GlobalSearchOwnerSearchQueryUpdated(query: 'JOHN'));
        },
        skip: 2,
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwners.map((o) => o.id).toList(),
            'filtered owners',
            ['owner-1', 'owner-2'],
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'restores the full list when the query is cleared',
        setUp: () => seedOwners([
          (id: 'owner-1', firstName: 'John'),
          (id: 'owner-2', firstName: 'Floyd'),
        ]),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
          bloc.add(const GlobalSearchOwnerSearchQueryUpdated(query: 'john'));
          await bloc.stream.first;
          bloc.add(const GlobalSearchOwnerSearchQueryUpdated(query: ''));
        },
        skip: 3,
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwners.map((o) => o.id).toList(),
            'full list restored',
            ['owner-1', 'owner-2'],
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'resets the owner search query when the sheet is reopened',
        setUp: () => seedOwners([
          (id: 'owner-1', firstName: 'John'),
          (id: 'owner-2', firstName: 'Floyd'),
        ]),
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchAvailableOwnersRequested());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady && !state.availableOwnersLoading,
          );
          bloc.add(const GlobalSearchOwnerSearchQueryUpdated(query: 'john'));
          await bloc.stream.first;
          bloc.add(const GlobalSearchAvailableOwnersRequested());
        },
        skip: 3,
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.availableOwners.map((o) => o.id).toList(),
            'query reset restores full list',
            ['owner-1', 'owner-2'],
          ),
        ],
      );
    });

    group('GlobalSearchScopeChanged', () {
      void seedUserWithScopedHistory() {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeSearchHistoryData(userId: _testUserId, searchTerm: 'foundation'),
          _fakeSearchHistoryData(
            userId: _testUserId,
            searchTerm: 'girder',
            scope: SearchScope.estimation,
          ),
          _fakeSearchHistoryData(
            userId: _testUserId,
            searchTerm: 'alice',
            scope: SearchScope.member,
          ),
        ]);
      }

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'emits the new scope immediately, then the reloaded history for it',
        setUp: seedUserWithScopedHistory,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('foundation'),
          );
          bloc.add(
            const GlobalSearchScopeChanged(scope: SearchScope.estimation),
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'dashboard history',
            ['foundation'],
          ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.selectedScope,
                'selectedScope',
                SearchScope.estimation,
              )
              .having(
                (s) => s.recentSearches,
                'history kept until the reload lands',
                ['foundation'],
              ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.selectedScope,
                'selectedScope',
                SearchScope.estimation,
              )
              .having(
                (s) => s.recentSearches,
                'estimation history',
                ['girder'],
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'ignores a change to the already selected scope',
        setUp: seedUserWithScopedHistory,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          const GlobalSearchScopeChanged(scope: SearchScope.dashboard),
        ),
        expect: () => <GlobalSearchState>[],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'keeps the previous history and surfaces '
        'GlobalSearchRecentsLoadFailure when the reload fails',
        setUp: seedUserWithScopedHistory,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('foundation'),
          );
          fakeSupabase.shouldThrowOnSelectMatch = true;
          fakeSupabase.selectMatchExceptionType = SupabaseExceptionType.timeout;
          bloc.add(
            const GlobalSearchScopeChanged(scope: SearchScope.estimation),
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'dashboard history',
            ['foundation'],
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedScope,
            'selectedScope',
            SearchScope.estimation,
          ),
          isA<GlobalSearchRecentsLoadFailure>().having(
            (s) => s.failure,
            'failure',
            SearchFailure(errorType: SearchErrorType.timeoutError),
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'previous history preserved',
            ['foundation'],
          ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'a newer scope change disowns the older in-flight history reload',
        setUp: seedUserWithScopedHistory,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('foundation'),
          );
          // Gate the history reloads so the estimation reload is still in
          // flight when the member scope change supersedes it. Completing the
          // gate resumes both reloads FIFO; only the newest may publish.
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
          bloc.add(
            const GlobalSearchScopeChanged(scope: SearchScope.estimation),
          );
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.selectedScope == SearchScope.estimation,
          );
          bloc.add(const GlobalSearchScopeChanged(scope: SearchScope.member));
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.selectedScope == SearchScope.member,
          );
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('alice'),
          );
        },
        expect: () => [
          isA<GlobalSearchReady>().having(
            (s) => s.recentSearches,
            'dashboard history',
            ['foundation'],
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedScope,
            'selectedScope',
            SearchScope.estimation,
          ),
          isA<GlobalSearchReady>().having(
            (s) => s.selectedScope,
            'selectedScope',
            SearchScope.member,
          ),
          // The estimation reload's ['girder'] result never publishes: the
          // member change disowned it via the generation guard.
          isA<GlobalSearchReady>()
              .having(
                (s) => s.selectedScope,
                'selectedScope',
                SearchScope.member,
              )
              .having((s) => s.recentSearches, 'member history', ['alice']),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'a scope change dispatched while GlobalSearchStarted is still '
        'fetching wins: the disowned initial load neither reverts the scope '
        'nor replaces the history',
        setUp: seedUserWithScopedHistory,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          // Gate both history fetches on one completer so the scope change is
          // dispatched while GlobalSearchStarted's own fetch is still in
          // flight. Completing the gate resumes both FIFO: the initial load
          // resumes first while already disowned and must bail; only the
          // scope change's reload may publish.
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
          bloc.add(const GlobalSearchStarted());
          bloc.add(
            const GlobalSearchScopeChanged(scope: SearchScope.estimation),
          );
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.selectedScope == SearchScope.estimation,
          );
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('girder'),
          );
        },
        // Exactly two emissions: the disowned initial load's late completion
        // must not emit at all, so no dashboard-scoped state ever appears.
        expect: () => [
          isA<GlobalSearchReady>()
              .having(
                (s) => s.selectedScope,
                'selectedScope',
                SearchScope.estimation,
              )
              .having(
                (s) => s.recentSearches,
                'history empty until the reload lands',
                isEmpty,
              ),
          isA<GlobalSearchReady>()
              .having(
                (s) => s.selectedScope,
                'selectedScope kept by the scope change',
                SearchScope.estimation,
              )
              .having(
                (s) => s.recentSearches,
                'estimation history',
                ['girder'],
              ),
        ],
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'GlobalSearchStarted resets the selected scope to its own scope',
        setUp: seedUserWithScopedHistory,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const GlobalSearchScopeChanged(scope: SearchScope.estimation),
          );
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('girder'),
          );
          bloc.add(const GlobalSearchStarted());
          await bloc.stream.firstWhere(
            (state) =>
                state is GlobalSearchReady &&
                state.recentSearches.contains('foundation'),
          );
        },
        verify: (bloc) {
          final state = bloc.state as GlobalSearchReady;
          expect(state.selectedScope, SearchScope.dashboard);
          expect(state.recentSearches, ['foundation']);
        },
      );
    });

    group('Filter changes re-run the active search', () {
      List<Map<String, dynamic>> searchCalls() => fakeSupabase
          .getMethodCallsFor('rpc')
          .where(
            (call) =>
                call['functionName'] ==
                DatabaseConstants.globalSearchRpcFunction,
          )
          .toList();

      void seedOneProjectResult() {
        fakeSupabase.setRpcResponse(DatabaseConstants.globalSearchRpcFunction, {
          'projects': [_fakeProjectData()],
          'estimations': <Map<String, dynamic>>[],
          'members': <Map<String, dynamic>>[],
        });
      }

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'applying a date filter while results are shown re-runs the search '
        'with the new range',
        setUp: seedOneProjectResult,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchPerformed(query: 'foundation'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          bloc.add(
            GlobalSearchDateFilterApplied(
              range: DateRange(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 1, 5),
              ),
            ),
          );
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
        },
        verify: (bloc) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(
            params['filter_by_date_from'],
            DateTime(2026, 1, 1).toIso8601String(),
          );
          expect(
            params['filter_by_date_to'],
            DateTime(2026, 1, 5).toIso8601String(),
          );
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'applying a tag filter while results are shown re-runs the search '
        'with the tag',
        setUp: seedOneProjectResult,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchPerformed(query: 'foundation'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          bloc.add(const GlobalSearchTagFiltersApplied(tags: {'Roofing'}));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
        },
        verify: (bloc) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(params['filter_by_tag'], 'Roofing');
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'clearing a tag filter while results are shown re-runs the search '
        'without the tag',
        setUp: seedOneProjectResult,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchTagFiltersApplied(tags: {'Roofing'}));
          bloc.add(const GlobalSearchPerformed(query: 'foundation'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          bloc.add(const GlobalSearchTagFilterCleared(tag: 'Roofing'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
        },
        verify: (bloc) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(params['filter_by_tag'], isNull);
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'changing the scope while results are shown re-runs the search '
        'with the new scope',
        setUp: seedOneProjectResult,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchPerformed(query: 'foundation'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          bloc.add(
            const GlobalSearchScopeChanged(scope: SearchScope.estimation),
          );
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
        },
        verify: (bloc) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(params['scope'], 'estimation');
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'applying a date filter with no active search emits only the ready '
        'state and performs no search',
        setUp: seedOneProjectResult,
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) => bloc.add(
          GlobalSearchDateFilterApplied(
            range: DateRange(
              start: DateTime(2026, 1, 1),
              end: DateTime(2026, 1, 5),
            ),
          ),
        ),
        expect: () => [isA<GlobalSearchReady>()],
        verify: (bloc) {
          expect(searchCalls(), isEmpty);
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        're-runs the search when a filter is applied after the filter sheet '
        'was opened (which emits the ready state)',
        setUp: () {
          seedOneProjectResult();
          fakeSupabase.addTableData(DatabaseConstants.tagsTable, [
            {
              DatabaseConstants.idColumn: 'tag-Roofing',
              DatabaseConstants.nameColumn: 'Roofing',
            },
          ]);
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchPerformed(query: 'foundation'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          // Opening the tags sheet emits the ready state — this must not
          // clear the active-search signal used by the re-run.
          bloc.add(const GlobalSearchAvailableTagsRequested());
          await bloc.stream.firstWhere((s) => s is GlobalSearchReady);
          bloc.add(const GlobalSearchTagFiltersApplied(tags: {'Roofing'}));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
        },
        verify: (bloc) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(params['filter_by_tag'], 'Roofing');
        },
      );

      blocTest<GlobalSearchBloc, GlobalSearchState>(
        'editing the query back to suggestions stops filter changes from '
        're-running the stale search',
        setUp: () {
          seedOneProjectResult();
          fakeSupabase.setRpcResponse(
            DatabaseConstants.searchSuggestionsRpcFunction,
            <String>[],
          );
        },
        build: () => Modular.get<GlobalSearchBloc>(),
        act: (bloc) async {
          bloc.add(const GlobalSearchPerformed(query: 'foundation'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchLoadSuccess);
          bloc.add(const GlobalSearchQueryUpdated(query: 'found'));
          await bloc.stream.firstWhere((s) => s is GlobalSearchReady);
          bloc.add(
            GlobalSearchDateFilterApplied(
              range: DateRange(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 1, 5),
              ),
            ),
          );
          await bloc.stream.firstWhere((s) => s is GlobalSearchReady);
        },
        verify: (bloc) {
          // Only the original search ran; the filter change on the
          // suggestions surface must not resurrect the dismissed results.
          expect(searchCalls(), hasLength(1));
        },
      );
    });
  });
}
