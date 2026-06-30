import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/widgets/date_range_bottom_sheet.dart';

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
        'forwards the alphabetically first selected owner id to the RPC when multiple owners are active',
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
            rpcParams['filter_by_owner'],
            equals('owner-1'),
            reason:
                'must forward the alphabetically first owner id, not an arbitrary Set element',
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
  });
}
