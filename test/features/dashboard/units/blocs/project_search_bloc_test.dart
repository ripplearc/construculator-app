import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

const String _testUserId = 'user-search-test';
const String _testUserEmail = 'search@test.com';

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

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  group('ProjectSearchBloc', () {
    late FakeSupabaseWrapper fakeSupabase;
    late FakeClockImpl fakeClock;

    setUp(() {
      fakeClock = FakeClockImpl();
      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
      );
      Modular.init(_ProjectSearchBlocTestModule(bootstrap));
      fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      fakeSupabase.setCurrentUser(
        FakeUser(
          id: _testUserId,
          email: _testUserEmail,
          createdAt: fakeClock.now().toIso8601String(),
        ),
      );
    });

    tearDown(() {
      fakeSupabase.reset();
      Modular.destroy();
    });

    test('initial state is ProjectSearchInitial', () {
      final bloc = Modular.get<ProjectSearchBloc>();
      expect(bloc.state, const ProjectSearchInitial());
      bloc.close();
    });

    // -------------------------------------------------------------------------
    // ProjectSearchQueryUpdatedEvent
    // -------------------------------------------------------------------------

    group('ProjectSearchQueryUpdatedEvent', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits ProjectSearchInitial when query is empty',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchQueryUpdatedEvent(query: ''),
        ),
        wait: const Duration(milliseconds: 500),
        expect: () => [const ProjectSearchInitial()],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits Initial preserving cached recents when query is cleared after history load',
        setUp: () {
          fakeSupabase.addTableData(
            DatabaseConstants.projectSearchHistoryTable,
            [
              {
                DatabaseConstants.userIdColumn: _testUserId,
                DatabaseConstants.searchTermColumn: 'wall',
                DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
              },
            ],
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.isLoadingHistory,
          );
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: ''));
        },
        wait: const Duration(milliseconds: 500),
        expect: () => [
          const ProjectSearchInitial(isLoadingHistory: true),
          const ProjectSearchInitial(recentSearches: ['wall']),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'fetches suggestions on first non-empty query and emits filtered list',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['foundation', 'foundation repair', 'concrete'],
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) =>
            bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'foundation')),
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having(
                (s) => s.suggestions,
                'suggestions',
                ['foundation', 'foundation repair'],
              ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'reuses cached suggestions on subsequent query updates with no extra RPC',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['Carpentry', 'Carparking', 'Plumbing', 'Concrete'],
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'Car'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.suggestionsLoading,
          );
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'Con'));
        },
        wait: const Duration(milliseconds: 700),
        verify: (_) {
          final rpcCalls = fakeSupabase
              .getMethodCallsFor('rpc')
              .where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectSearchSuggestionsRpcFunction,
              );
          expect(rpcCalls, hasLength(1));
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'caps the filtered suggestions list at 5 items',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7'],
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'C')),
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.suggestionsLoading,
            'loading',
            isTrue,
          ),
          isA<ProjectSearchInitial>().having(
            (s) => s.suggestions,
            'suggestions capped at 5',
            ['C1', 'C2', 'C3', 'C4', 'C5'],
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'does not fetch suggestions when no user is authenticated',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) =>
            bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'foundation')),
        wait: const Duration(milliseconds: 500),
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.query,
            'query',
            'foundation',
          ),
        ],
        verify: (_) {
          expect(
            fakeSupabase
                .getMethodCallsFor('rpc')
                .where(
                  (call) =>
                      call['functionName'] ==
                      DatabaseConstants.projectSearchSuggestionsRpcFunction,
                ),
            isEmpty,
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // ProjectSearchPerformedEvent
    // -------------------------------------------------------------------------

    group('ProjectSearchPerformedEvent', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits ProjectSearchInitial when query is empty',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: '')),
        expect: () => [const ProjectSearchInitial()],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits ProjectSearchInitial when query is whitespace only',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: '   ')),
        expect: () => [const ProjectSearchInitial()],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits [ProjectSearchLoading, ProjectSearchResultsLoaded] immediately on success',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [
                _fakeProjectData(id: 'p-1', projectName: 'Wall Project'),
              ],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchPerformedEvent(query: 'wall'),
        ),
        expect: () => [
          const ProjectSearchLoading(query: 'wall'),
          isA<ProjectSearchResultsLoaded>()
              .having((s) => s.query, 'query', 'wall')
              .having((s) => s.results, 'results', hasLength(1)),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits ProjectSearchResultsLoaded with empty list when no results',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchPerformedEvent(query: 'nonexistent'),
        ),
        expect: () => [
          const ProjectSearchLoading(query: 'nonexistent'),
          isA<ProjectSearchResultsLoaded>()
              .having((s) => s.results, 'results', isEmpty),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits [ProjectSearchLoading, ProjectSearchFailureState] on connection error',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.socket;
          fakeSupabase.rpcErrorMessage = 'Network error';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchPerformedEvent(query: 'wall'),
        ),
        expect: () => [
          const ProjectSearchLoading(query: 'wall'),
          isA<ProjectSearchFailureState>()
              .having((s) => s.query, 'query', 'wall')
              .having(
                (s) => s.failure,
                'failure',
                SearchFailure(errorType: SearchErrorType.connectionError),
              ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits AuthFailure (no loading) when user is not authenticated',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchPerformedEvent(query: 'wall'),
        ),
        expect: () => [
          const ProjectSearchFailureState(
            failure: AuthFailure(errorType: AuthErrorType.userNotFound),
            query: 'wall',
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits [ProjectSearchLoading, ProjectSearchFailureState] on unknown error',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.unknown;
          fakeSupabase.rpcErrorMessage = 'Server error';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchPerformedEvent(query: 'wall'),
        ),
        expect: () => [
          const ProjectSearchLoading(query: 'wall'),
          isA<ProjectSearchFailureState>()
              .having((s) => s.failure, 'failure', isA<UnexpectedFailure>()),
        ],
      );
    });

    // -------------------------------------------------------------------------
    // ProjectSearchHistoryRequestedEvent
    // -------------------------------------------------------------------------

    group('ProjectSearchHistoryRequestedEvent', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits loading then loaded Initial with recents on success '
        '(suggestions are fetched lazily on first keystroke, not on open)',
        setUp: () {
          fakeSupabase.addTableData(
            DatabaseConstants.projectSearchHistoryTable,
            [
              {
                DatabaseConstants.userIdColumn: _testUserId,
                DatabaseConstants.searchTermColumn: 'foundation',
                DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
              },
              {
                DatabaseConstants.userIdColumn: _testUserId,
                DatabaseConstants.searchTermColumn: 'wall',
                DatabaseConstants.updatedAtColumn: '2024-05-01T00:00:00.000Z',
              },
            ],
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) =>
            bloc.add(const ProjectSearchHistoryRequestedEvent()),
        expect: () => [
          const ProjectSearchInitial(isLoadingHistory: true),
          const ProjectSearchInitial(recentSearches: ['foundation', 'wall']),
        ],
        verify: (_) {
          expect(
            fakeSupabase
                .getMethodCallsFor('rpc')
                .where(
                  (call) =>
                      call['functionName'] ==
                      DatabaseConstants.projectSearchSuggestionsRpcFunction,
                ),
            isEmpty,
          );
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits empty Initial without repository calls when no user is authenticated',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) =>
            bloc.add(const ProjectSearchHistoryRequestedEvent()),
        expect: () => [const ProjectSearchInitial()],
        verify: (_) {
          expect(fakeSupabase.getMethodCallsFor('selectMatch'), isEmpty);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'resets stale suggestions cache from a previous session',
        setUp: () {
          fakeSupabase.addTableData(
            DatabaseConstants.projectSearchHistoryTable,
            [
              {
                DatabaseConstants.userIdColumn: _testUserId,
                DatabaseConstants.searchTermColumn: 'foundation',
                DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
              },
            ],
          );
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['stale-suggestion'],
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          // First session: fetch suggestions for a query.
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'stale'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.suggestionsLoading,
          );
          // Re-opening the surface must drop the stale cache.
          bloc.add(const ProjectSearchHistoryRequestedEvent());
        },
        skip: 3,
        expect: () => [
          const ProjectSearchInitial(recentSearches: ['foundation']),
        ],
      );
    });

    // -------------------------------------------------------------------------
    // ProjectSearchHistoryItemDismissedEvent
    // -------------------------------------------------------------------------

    group('ProjectSearchHistoryItemDismissedEvent', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'removes term from cached recents and re-emits Initial on success',
        setUp: () {
          fakeSupabase.addTableData(
            DatabaseConstants.projectSearchHistoryTable,
            [
              {
                DatabaseConstants.userIdColumn: _testUserId,
                DatabaseConstants.searchTermColumn: 'foundation',
                DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
              },
              {
                DatabaseConstants.userIdColumn: _testUserId,
                DatabaseConstants.searchTermColumn: 'wall',
                DatabaseConstants.updatedAtColumn: '2024-05-01T00:00:00.000Z',
              },
            ],
          );
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            <dynamic>[],
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          // Wait for the non-loading Initial to land so the cached recents
          // are populated before we dispatch the dismissal.
          await bloc.stream.firstWhere(
            (state) =>
                state is ProjectSearchInitial && !state.isLoadingHistory,
          );
          bloc.add(
            const ProjectSearchHistoryItemDismissedEvent(
              searchTerm: 'foundation',
            ),
          );
        },
        skip: 2,
        expect: () => [
          const ProjectSearchInitial(
            recentSearches: ['wall'],
            suggestions: [],
          ),
        ],
        verify: (_) {
          expect(
            fakeSupabase.getMethodCallsFor('deleteMatch'),
            hasLength(1),
          );
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits nothing when no user is authenticated',
        setUp: () {
          fakeSupabase.setCurrentUser(null);
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchHistoryItemDismissedEvent(searchTerm: 'wall'),
        ),
        expect: () => <ProjectSearchState>[],
        verify: (_) {
          expect(fakeSupabase.getMethodCallsFor('deleteMatch'), isEmpty);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits nothing when deleteMatch fails',
        setUp: () {
          fakeSupabase.shouldThrowOnDeleteMatch = true;
          fakeSupabase.deleteMatchExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabase.deleteMatchErrorMessage = 'Timeout';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchHistoryItemDismissedEvent(searchTerm: 'wall'),
        ),
        expect: () => <ProjectSearchState>[],
      );
    });

    // -------------------------------------------------------------------------
    // Save-after-search behavior
    // -------------------------------------------------------------------------

    group('save-after-search', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'upserts with hasResults=true when search returns non-empty results',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData(id: 'p-1')],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.lastSaveCompleted;
        },
        verify: (_) {
          final upserts = fakeSupabase
              .getMethodCallsFor('upsert')
              .where(
                (call) =>
                    call['table'] ==
                    DatabaseConstants.projectSearchHistoryTable,
              )
              .toList();
          expect(upserts, hasLength(1));
          final data = upserts.first['data'] as Map<String, dynamic>;
          expect(data[DatabaseConstants.hasResultsColumn], isTrue);
          expect(
            data[DatabaseConstants.searchTermColumn],
            equals('wall'),
          );
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'upserts with hasResults=false when search returns empty results',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchPerformedEvent(query: 'nothing'));
          await bloc.lastSaveCompleted;
        },
        verify: (_) {
          final upserts = fakeSupabase
              .getMethodCallsFor('upsert')
              .where(
                (call) =>
                    call['table'] ==
                    DatabaseConstants.projectSearchHistoryTable,
              )
              .toList();
          expect(upserts, hasLength(1));
          final data = upserts.first['data'] as Map<String, dynamic>;
          expect(data[DatabaseConstants.hasResultsColumn], isFalse);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'does not upsert when search fails',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.timeout;
          fakeSupabase.rpcErrorMessage = 'Timeout';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: 'wall')),
        verify: (_) {
          final upserts = fakeSupabase
              .getMethodCallsFor('upsert')
              .where(
                (call) =>
                    call['table'] ==
                    DatabaseConstants.projectSearchHistoryTable,
              )
              .toList();
          expect(upserts, isEmpty);
        },
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test module
// ---------------------------------------------------------------------------

class _ProjectSearchBlocTestModule extends Module {
  final AppBootstrap bootstrap;

  _ProjectSearchBlocTestModule(this.bootstrap);

  @override
  List<Module> get imports => [ClockTestModule(), DashboardModule(bootstrap)];
}
