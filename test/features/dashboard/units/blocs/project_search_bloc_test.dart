import 'dart:async';

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
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

const String _testUserId = 'user-search-test';
const String _testUserEmail = 'search@test.com';

// Yields microtasks until [condition] holds, bounded by [maxTurns]. Unlike
// pumpEventQueue this uses no wall-clock Future.delayed: bloc event dispatch
// settles within a few microtask turns, so this is a deterministic gate for
// handlers whose only observable effect is an Equatable-suppressed re-emit.
Future<void> _untilHandlerRuns(
  bool Function() condition, {
  int maxTurns = 100,
}) async {
  for (var turn = 0; turn < maxTurns; turn++) {
    if (condition()) return;
    await Future<void>.microtask(() {});
  }
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
        act: (bloc) =>
            bloc.add(const ProjectSearchQueryUpdatedEvent(query: '')),
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
              .having((s) => s.suggestions, 'suggestions', [
                'foundation',
                'foundation repair',
              ]),
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
        act: (bloc) =>
            bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'C')),
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
        'keeps suggestionsLoading true when a concurrent handler emits '
        'while the suggestions fetch is in flight',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['foundation'],
          );
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'foundation'));
          // Wait for the in-flight loading emission, then dispatch an event
          // whose handler emits _initialFromCache() while the fetch is still
          // pending. It must not reset the loading flag — with the flag held
          // as instance state, the emission is identical to the current state
          // and is deduplicated instead of stomping the spinner.
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.suggestionsLoading,
          );
          bloc.add(const ProjectSearchPerformedEvent(query: '   '));
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.suggestionsLoading,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>()
              .having(
                (s) => s.suggestionsLoading,
                'loading cleared only after fetch completes',
                isFalse,
              )
              .having((s) => s.suggestions, 'suggestions', ['foundation']),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'clears suggestionsLoading when clearing the query cancels the '
        'in-flight fetch',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['foundation'],
          );
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'foundation'));
          // Wait for the fetch to be in flight, then clear the query — the
          // switchMap transformer cancels the fetch handler, so its
          // completion can never emit. The empty-query emission must not
          // report a loading fetch.
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.suggestionsLoading,
          );
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: ''));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.query.isEmpty,
          );
          // Release the cancelled fetch; its generation-guarded continuation
          // runs to completion during bloc.close() without emitting.
          fakeSupabase.completer!.complete();
        },
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', isEmpty)
              .having(
                (s) => s.suggestionsLoading,
                'loading reset with the cancelled fetch',
                isFalse,
              ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'stale cancelled fetch does not clear the loading flag owned by a '
        'newer fetch',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['foundation'],
          );
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          final firstFetchGate = fakeSupabase.completer!;
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'fo'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.suggestionsLoading,
          );
          // The second fetch awaits its own gate so the first one can be
          // released while the second is still in flight.
          final secondFetchGate = Completer<void>();
          fakeSupabase.completer = secondFetchGate;
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'found'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.query == 'found',
          );
          // Release the superseded fetch, then the newer one. The stale
          // continuation resumes first (completed first, identical async
          // path), so it runs its generation check while the newer fetch is
          // still in flight — it must not touch the newer fetch's flag.
          firstFetchGate.complete();
          secondFetchGate.complete();
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.suggestionsLoading,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'fo')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'found')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'found')
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having((s) => s.suggestions, 'suggestions', ['foundation']),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'a fetch surviving a history-request reset does not mark suggestions '
        'as fetched — the next keystroke refetches',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['foundation'],
          );
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          final suggestionsFetchGate = fakeSupabase.completer!;
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'fo'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.suggestionsLoading,
          );
          // Later operations run ungated; only the in-flight suggestions
          // fetch stays parked on the gate.
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                !s.isLoadingHistory &&
                !s.suggestionsLoading &&
                s.query.isEmpty,
          );
          // Release the pre-reset fetch; the reset disowned it, so it must
          // not resurrect the cache or mark suggestions as fetched. Its
          // pure-microtask continuation drains before the debounce timer
          // delivers the next keystroke, so no pump loop is needed.
          suggestionsFetchGate.complete();
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'found'));
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                s.query == 'found' &&
                !s.suggestionsLoading,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'fo')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>().having(
            (s) => s.isLoadingHistory,
            'isLoadingHistory',
            isTrue,
          ),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query after reset', isEmpty)
              .having((s) => s.isLoadingHistory, 'isLoadingHistory', isFalse),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'found')
              .having(
                (s) => s.suggestionsLoading,
                'post-reset keystroke starts a fresh fetch',
                isTrue,
              ),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'found')
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having((s) => s.suggestions, 'suggestions', ['foundation']),
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

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'stops loading with empty suggestions when the fetch fails and '
        're-fetches on the next query update',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.timeout;
          fakeSupabase.rpcErrorMessage = 'Timeout';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'foundation'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.suggestionsLoading,
          );
          // The failed fetch must not latch the fetched flag — the next
          // keystroke retries against a now-healthy backend.
          fakeSupabase.shouldThrowOnRpc = false;
          fakeSupabase.setRpcResponse(
            DatabaseConstants.projectSearchSuggestionsRpcFunction,
            ['foundation'],
          );
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'found'));
        },
        wait: const Duration(milliseconds: 700),
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>()
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having(
                (s) => s.suggestions,
                'suggestions after failure',
                isEmpty,
              ),
          isA<ProjectSearchInitial>()
              .having((s) => s.query, 'query', 'found')
              .having((s) => s.suggestionsLoading, 'loading', isTrue),
          isA<ProjectSearchInitial>()
              .having((s) => s.suggestionsLoading, 'loading', isFalse)
              .having(
                (s) => s.suggestions,
                'suggestions after retry',
                ['foundation'],
              ),
        ],
      );
    });

    // -------------------------------------------------------------------------
    // ProjectSearchPerformedEvent
    // -------------------------------------------------------------------------

    group('ProjectSearchPerformedEvent', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits ProjectSearchInitial when query is empty',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(const ProjectSearchPerformedEvent(query: '')),
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
        'preserves cached recents when query is empty after history has loaded',
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
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData(id: 'p-1', projectName: 'Wall')],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.isLoadingHistory,
          );
          // Leave the idle surface via a real search, then submit an empty
          // query: the idle view must come back with its recents intact.
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          bloc.add(const ProjectSearchPerformedEvent(query: '   '));
        },
        skip: 4,
        expect: () => [
          // 'wall' is prepended by the save-after-search of the submit above;
          // the pre-existing 'foundation' entry must survive the empty submit.
          isA<ProjectSearchInitial>().having(
            (s) => s.recentSearches,
            'recentSearches',
            ['wall', 'foundation'],
          ),
        ],
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
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: 'wall')),
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
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: 'nonexistent')),
        expect: () => [
          const ProjectSearchLoading(query: 'nonexistent'),
          isA<ProjectSearchResultsLoaded>().having(
            (s) => s.results,
            'results',
            isEmpty,
          ),
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
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: 'wall')),
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
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: 'wall')),
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
        act: (bloc) =>
            bloc.add(const ProjectSearchPerformedEvent(query: 'wall')),
        expect: () => [
          const ProjectSearchLoading(query: 'wall'),
          isA<ProjectSearchFailureState>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
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
        act: (bloc) => bloc.add(const ProjectSearchHistoryRequestedEvent()),
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
        act: (bloc) => bloc.add(const ProjectSearchHistoryRequestedEvent()),
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

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'keeps previously cached recents when the history fetch fails',
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
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.isLoadingHistory,
          );
          fakeSupabase.shouldThrowOnSelectMatch = true;
          fakeSupabase.selectMatchExceptionType = SupabaseExceptionType.timeout;
          fakeSupabase.selectMatchErrorMessage = 'Timeout';
          bloc.add(const ProjectSearchHistoryRequestedEvent());
        },
        expect: () => [
          const ProjectSearchInitial(isLoadingHistory: true),
          const ProjectSearchInitial(recentSearches: ['foundation']),
          const ProjectSearchInitial(
            recentSearches: ['foundation'],
            isLoadingHistory: true,
          ),
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
            (state) => state is ProjectSearchInitial && !state.isLoadingHistory,
          );
          bloc.add(
            const ProjectSearchHistoryItemDismissedEvent(
              searchTerm: 'foundation',
            ),
          );
        },
        skip: 2,
        expect: () => [
          const ProjectSearchInitial(recentSearches: ['wall'], suggestions: []),
        ],
        verify: (_) {
          expect(fakeSupabase.getMethodCallsFor('deleteMatch'), hasLength(1));
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'updates cache without emitting when current state is not Initial',
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
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData(id: 'p-1', projectName: 'Wall')],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.isLoadingHistory,
          );
          // Dismiss while showing search results: the deletion must go
          // through, but the results view must not be replaced by Initial.
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          bloc.add(
            const ProjectSearchHistoryItemDismissedEvent(
              searchTerm: 'foundation',
            ),
          );
          await _untilHandlerRuns(
            () => fakeSupabase.getMethodCallsFor('deleteMatch').isNotEmpty,
          );
        },
        skip: 4,
        expect: () => <ProjectSearchState>[],
        verify: (bloc) {
          expect(bloc.state, isA<ProjectSearchResultsLoaded>());
          expect(fakeSupabase.getMethodCallsFor('deleteMatch'), hasLength(1));
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
          fakeSupabase.deleteMatchExceptionType = SupabaseExceptionType.timeout;
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
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
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
          expect(data[DatabaseConstants.searchTermColumn], equals('wall'));
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
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
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
        act: (bloc) async {
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchFailureState);
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
          expect(upserts, isEmpty);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'keeps cached recents unchanged when the history save fails',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData(id: 'p-1')],
              'estimations': [],
              'members': [],
            },
          );
          fakeSupabase.shouldThrowOnUpsert = true;
          fakeSupabase.upsertExceptionType = SupabaseExceptionType.timeout;
          fakeSupabase.upsertErrorMessage = 'Timeout';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          await bloc.lastSaveCompleted;
          // Clearing the query surfaces the recents cache — the failed save
          // must not have added the search term to it.
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: ''));
        },
        wait: const Duration(milliseconds: 500),
        expect: () => [
          isA<ProjectSearchLoading>(),
          isA<ProjectSearchResultsLoaded>(),
          const ProjectSearchInitial(),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'caps cached recents at 20 terms after a successful save',
        setUp: () {
          fakeSupabase.addTableData(
            DatabaseConstants.projectSearchHistoryTable,
            List.generate(
              20,
              (i) => {
                DatabaseConstants.userIdColumn: _testUserId,
                DatabaseConstants.searchTermColumn:
                    'term-${(i + 1).toString().padLeft(2, '0')}',
                DatabaseConstants.updatedAtColumn:
                    '2024-06-${(20 - i).toString().padLeft(2, '0')}'
                        'T00:00:00.000Z',
              },
            ),
          );
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
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.isLoadingHistory,
          );
          bloc.add(const ProjectSearchPerformedEvent(query: 'newest'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          await bloc.lastSaveCompleted;
          // Clearing the query surfaces the recents cache with the new term.
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: ''));
        },
        wait: const Duration(milliseconds: 500),
        expect: () => [
          const ProjectSearchInitial(isLoadingHistory: true),
          isA<ProjectSearchInitial>().having(
            (s) => s.recentSearches.length,
            'fetched recents count',
            20,
          ),
          isA<ProjectSearchLoading>(),
          isA<ProjectSearchResultsLoaded>(),
          isA<ProjectSearchInitial>()
              .having((s) => s.recentSearches.length, 'capped length', 20)
              .having((s) => s.recentSearches.first, 'newest first', 'newest')
              .having(
                (s) => s.recentSearches,
                'oldest term evicted',
                isNot(contains('term-20')),
              ),
        ],
      );
    });

    // -------------------------------------------------------------------------
    // Filters: Tags / Owner / Modified date
    // -------------------------------------------------------------------------

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

    void seedOwners(
      List<({String id, String firstName, String lastName})> owners,
    ) {
      fakeSupabase.setRpcResponse(
        DatabaseConstants.projectOwnersRpcFunction,
        owners
            .map(
              (owner) => <String, dynamic>{
                DatabaseConstants.idColumn: owner.id,
                DatabaseConstants.credentialIdColumn: null,
                DatabaseConstants.firstNameColumn: owner.firstName,
                DatabaseConstants.lastNameColumn: owner.lastName,
                DatabaseConstants.professionalRoleColumn: 'Engineer',
                DatabaseConstants.profilePhotoUrlColumn: null,
              },
            )
            .toList(),
      );
    }

    Map<String, dynamic> lastSearchRpcParams() {
      final calls = fakeSupabase
          .getMethodCallsFor('rpc')
          .where(
            (call) =>
                call['functionName'] ==
                DatabaseConstants.globalSearchRpcFunction,
          )
          .toList();
      expect(
        calls,
        isNotEmpty,
        reason: 'expected a global_search RPC call to have been made',
      );
      return calls.last['params'] as Map<String, dynamic>;
    }

    group('Tag filters', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'fetches available tags on first request and caches them',
        setUp: () => seedTags(['Concrete', 'Steel']),
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableTagsLoading,
          );
          // Second request must serve the cache — no extra table query. Its
          // re-emit is Equatable-suppressed, so gate on the handler-run
          // counter instead of a wall-clock wait: a timer could elapse before
          // the event is even dequeued, letting a broken cache pass.
          final runsBefore = bloc.availableTagsHandlerRuns;
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await _untilHandlerRuns(
            () => bloc.availableTagsHandlerRuns > runsBefore,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.availableTagsLoading,
            'loading',
            isTrue,
          ),
          isA<ProjectSearchInitial>()
              .having((s) => s.availableTagsLoading, 'loading', isFalse)
              .having((s) => s.availableTags, 'tags', ['Concrete', 'Steel']),
        ],
        verify: (_) {
          final tagReads = fakeSupabase
              .getMethodCallsFor('selectMatch')
              .where((call) => call['table'] == DatabaseConstants.tagsTable)
              .toList();
          expect(tagReads, hasLength(1));
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'does not start a duplicate tags fetch when one is already in flight',
        setUp: () {
          seedTags(['Concrete', 'Steel']);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          // Wait for the in-flight loading emission, then request tags again
          // while the first fetch is still parked on the completer — the
          // second request must reuse the in-flight fetch (loading-flag gate)
          // instead of starting another, guarding against the
          // duplicate-fetch/stray-failure-toast race.
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableTagsLoading,
          );
          final runsBefore = bloc.availableTagsHandlerRuns;
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await _untilHandlerRuns(
            () => bloc.availableTagsHandlerRuns > runsBefore,
          );
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableTagsLoading,
          );
        },
        verify: (_) {
          final tagReads = fakeSupabase
              .getMethodCallsFor('selectMatch')
              .where((call) => call['table'] == DatabaseConstants.tagsTable)
              .toList();
          expect(
            tagReads,
            hasLength(1),
            reason: 'the in-flight gate must absorb the duplicate request',
          );
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'keeps availableTagsLoading true when a concurrent handler emits '
        'while the tags fetch is in flight',
        setUp: () {
          seedTags(['Concrete']);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          // Wait for the in-flight loading emission, then dispatch an event
          // whose handler rebuilds the state while the fetch is still
          // pending — it must not reset the loading flag.
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableTagsLoading,
          );
          bloc.add(
            const ProjectSearchOwnerFiltersAppliedEvent(ownerIds: {'owner-1'}),
          );
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                s.selectedOwnerIds.contains('owner-1'),
          );
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableTagsLoading,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.availableTagsLoading, 'loading', isTrue)
              .having((s) => s.selectedOwnerIds, 'selectedOwnerIds', isEmpty),
          isA<ProjectSearchInitial>()
              .having(
                (s) => s.availableTagsLoading,
                'loading survives concurrent emission',
                isTrue,
              )
              .having((s) => s.selectedOwnerIds, 'selectedOwnerIds', {
                'owner-1',
              }),
          isA<ProjectSearchInitial>()
              .having((s) => s.availableTagsLoading, 'loading', isFalse)
              .having((s) => s.availableTags, 'tags', ['Concrete']),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits ProjectSearchTagsLoadFailure then recovers to initial on fetch error',
        setUp: () {
          fakeSupabase.shouldThrowOnSelectMatch = true;
          fakeSupabase.selectExceptionType = SupabaseExceptionType.timeout;
          fakeSupabase.selectErrorMessage = 'Timeout';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          // Gate on the recovery state landing instead of a wall-clock wait,
          // so a slow CI runner cannot cut the observation window short.
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableTagsLoading,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.availableTagsLoading,
            'loading',
            isTrue,
          ),
          isA<ProjectSearchTagsLoadFailure>(),
          isA<ProjectSearchInitial>().having(
            (s) => s.availableTagsLoading,
            'loading',
            isFalse,
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'filters available tags by the tag search query and restores on clear',
        setUp: () => seedTags(['Concrete', 'Steel', 'Confetti']),
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableTagsLoading,
          );
          bloc.add(const ProjectSearchTagSearchQueryUpdatedEvent(query: 'con'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableTags.length == 2,
          );
          bloc.add(const ProjectSearchTagSearchQueryUpdatedEvent(query: ''));
        },
        skip: 2,
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.availableTags,
            'filtered tags (case-insensitive contains)',
            ['Concrete', 'Confetti'],
          ),
          isA<ProjectSearchInitial>().having(
            (s) => s.availableTags,
            // The tag data source orders by name, so the unfiltered list is
            // alphabetical regardless of seed order.
            'all tags restored on empty query',
            ['Concrete', 'Confetti', 'Steel'],
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'applying tag filters exposes them on the initial state',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchTagFiltersAppliedEvent(
            tags: {'Concrete', 'Steel'},
          ),
        ),
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedTags,
            'selectedTags',
            {'Concrete', 'Steel'},
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'clearing a single tag removes only that tag',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const ProjectSearchTagFiltersAppliedEvent(
              tags: {'Concrete', 'Steel'},
            ),
          );
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.selectedTags.length == 2,
          );
          bloc.add(const ProjectSearchTagFilterClearedEvent(tag: 'Concrete'));
        },
        skip: 1,
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedTags,
            'selectedTags',
            {'Steel'},
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'threads the selected tag into the search RPC',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            <String, dynamic>{'projects': <dynamic>[]},
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const ProjectSearchTagFiltersAppliedEvent(
              tags: {'Steel', 'Concrete'},
            ),
          );
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.selectedTags.isNotEmpty,
          );
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
        },
        verify: (_) {
          // Selection is sorted for determinism → 'Concrete' wins.
          expect(lastSearchRpcParams()['filter_by_tag'], 'Concrete');
        },
      );
    });

    group('Owner filters', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'fetches available owners on first request and caches them',
        setUp: () => seedOwners([
          (id: 'owner-1', firstName: 'Ada', lastName: 'Lovelace'),
          (id: 'owner-2', firstName: 'Alan', lastName: 'Turing'),
        ]),
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableOwnersLoading,
          );
          // Cache-hit re-emit is Equatable-suppressed — gate on the counter,
          // not a wall clock (see the tag equivalent above).
          final runsBefore = bloc.availableOwnersHandlerRuns;
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await _untilHandlerRuns(
            () => bloc.availableOwnersHandlerRuns > runsBefore,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.availableOwnersLoading,
            'loading',
            isTrue,
          ),
          isA<ProjectSearchInitial>()
              .having((s) => s.availableOwnersLoading, 'loading', isFalse)
              .having(
                (s) => s.availableOwners.map((o) => o.fullName).toList(),
                'owners',
                ['Ada Lovelace', 'Alan Turing'],
              ),
        ],
        verify: (_) {
          final ownerCalls = fakeSupabase
              .getMethodCallsFor('rpc')
              .where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectOwnersRpcFunction,
              )
              .toList();
          expect(ownerCalls, hasLength(1));
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'does not start a duplicate owners fetch when one is already in flight',
        setUp: () {
          seedOwners([
            (id: 'owner-1', firstName: 'Ada', lastName: 'Lovelace'),
            (id: 'owner-2', firstName: 'Alan', lastName: 'Turing'),
          ]);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          // See the tag equivalent: the second request arriving mid-fetch
          // must be absorbed by the loading-flag gate, not fetch again.
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableOwnersLoading,
          );
          final runsBefore = bloc.availableOwnersHandlerRuns;
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await _untilHandlerRuns(
            () => bloc.availableOwnersHandlerRuns > runsBefore,
          );
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableOwnersLoading,
          );
        },
        verify: (_) {
          final ownerCalls = fakeSupabase
              .getMethodCallsFor('rpc')
              .where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectOwnersRpcFunction,
              )
              .toList();
          expect(
            ownerCalls,
            hasLength(1),
            reason: 'the in-flight gate must absorb the duplicate request',
          );
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'keeps availableOwnersLoading true when a concurrent handler emits '
        'while the owners fetch is in flight',
        setUp: () {
          seedOwners([
            (id: 'owner-1', firstName: 'Ada', lastName: 'Lovelace'),
          ]);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          // See the tag equivalent: a concurrent handler rebuilding the
          // state must not reset the in-flight owners loading flag.
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableOwnersLoading,
          );
          bloc.add(
            const ProjectSearchTagFiltersAppliedEvent(tags: {'Concrete'}),
          );
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                s.selectedTags.contains('Concrete'),
          );
          fakeSupabase.completer!.complete();
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableOwnersLoading,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>()
              .having((s) => s.availableOwnersLoading, 'loading', isTrue)
              .having((s) => s.selectedTags, 'selectedTags', isEmpty),
          isA<ProjectSearchInitial>()
              .having(
                (s) => s.availableOwnersLoading,
                'loading survives concurrent emission',
                isTrue,
              )
              .having((s) => s.selectedTags, 'selectedTags', {'Concrete'}),
          isA<ProjectSearchInitial>()
              .having((s) => s.availableOwnersLoading, 'loading', isFalse)
              .having((s) => s.availableOwners.map((o) => o.fullName).toList(),
                  'owners', ['Ada Lovelace']),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits ProjectSearchOwnersLoadFailure then recovers to initial on fetch error',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.timeout;
          fakeSupabase.rpcErrorMessage = 'Timeout';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          // Gate on the recovery state landing instead of a wall-clock wait,
          // so a slow CI runner cannot cut the observation window short.
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableOwnersLoading,
          );
        },
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.availableOwnersLoading,
            'loading',
            isTrue,
          ),
          isA<ProjectSearchOwnersLoadFailure>(),
          isA<ProjectSearchInitial>().having(
            (s) => s.availableOwnersLoading,
            'loading',
            isFalse,
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'filters available owners by full name via the owner search query',
        setUp: () => seedOwners([
          (id: 'owner-1', firstName: 'Ada', lastName: 'Lovelace'),
          (id: 'owner-2', firstName: 'Alan', lastName: 'Turing'),
        ]),
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableOwnersLoading,
          );
          bloc.add(
            const ProjectSearchOwnerSearchQueryUpdatedEvent(query: 'turing'),
          );
        },
        skip: 2,
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.availableOwners.map((o) => o.fullName).toList(),
            'filtered owners (case-insensitive full-name contains)',
            ['Alan Turing'],
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'clearing a single owner removes only that owner id',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const ProjectSearchOwnerFiltersAppliedEvent(
              ownerIds: {'owner-1', 'owner-2'},
            ),
          );
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.selectedOwnerIds.length == 2,
          );
          bloc.add(
            const ProjectSearchOwnerFilterClearedEvent(ownerId: 'owner-1'),
          );
        },
        skip: 1,
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedOwnerIds,
            'selectedOwnerIds',
            {'owner-2'},
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'threads the selected owner into the search RPC',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            <String, dynamic>{'projects': <dynamic>[]},
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const ProjectSearchOwnerFiltersAppliedEvent(
              ownerIds: {'owner-2', 'owner-1'},
            ),
          );
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.selectedOwnerIds.isNotEmpty,
          );
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
        },
        verify: (_) {
          // The RPC takes an owner-id array; the single-owner selection is
          // wrapped, and sorted for determinism → 'owner-1' wins.
          expect(lastSearchRpcParams()['filter_by_owners'], ['owner-1']);
        },
      );
    });

    group('Modified date filter', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'applying and clearing a date range updates the initial state',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            ProjectSearchDateFilterAppliedEvent(
              range: DateRange(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 1, 31),
              ),
            ),
          );
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.selectedDateRange != null,
          );
          bloc.add(const ProjectSearchDateFilterClearedEvent());
        },
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedDateRange,
            'range',
            DateRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
          ),
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedDateRange,
            'range',
            isNull,
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'threads both date range bounds into the search RPC',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            <String, dynamic>{'projects': <dynamic>[]},
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            ProjectSearchDateFilterAppliedEvent(
              range: DateRange(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 1, 31),
              ),
            ),
          );
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.selectedDateRange != null,
          );
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
        },
        verify: (_) {
          final params = lastSearchRpcParams();
          expect(
            params['filter_by_date_from'],
            DateTime(2026, 1, 1).toIso8601String(),
          );
          expect(
            params['filter_by_date_to'],
            DateTime(2026, 1, 31).toIso8601String(),
          );
        },
      );
    });

    group('Filter reset on page reopen', () {
      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'clears all selected filters when history is requested again',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const ProjectSearchTagFiltersAppliedEvent(tags: {'Concrete'}),
          );
          bloc.add(
            const ProjectSearchOwnerFiltersAppliedEvent(ownerIds: {'owner-1'}),
          );
          bloc.add(
            ProjectSearchDateFilterAppliedEvent(
              range: DateRange(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 1, 5),
              ),
            ),
          );
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.selectedDateRange != null,
          );
          // Mirrors GlobalSearchStarted: a fresh page open starts unfiltered.
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.isLoadingHistory,
          );
        },
        verify: (bloc) {
          final state = bloc.state as ProjectSearchInitial;
          expect(state.selectedTags, isEmpty);
          expect(state.selectedOwnerIds, isEmpty);
          expect(state.selectedDateRange, isNull);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'clears the fetched tag catalog on page reopen — a fresh open '
        'refetches instead of serving a stale cache',
        setUp: () => seedTags(['Concrete', 'Steel']),
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableTags.isNotEmpty,
          );
          // Reopening the page resets catalogs along with selections,
          // mirroring GlobalSearchStarted — a fresh session refetches.
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                !s.isLoadingHistory &&
                s.availableTags.isEmpty,
          );
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableTags.isNotEmpty,
          );
        },
        verify: (bloc) {
          final tagReads = fakeSupabase
              .getMethodCallsFor('selectMatch')
              .where((call) => call['table'] == DatabaseConstants.tagsTable)
              .toList();
          expect(
            tagReads,
            hasLength(2),
            reason: 'the reopened page must refetch the cleared tag catalog',
          );
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'a tags fetch surviving a page reopen neither stomps the reset '
        'loading flag nor resurrects the pre-reset catalog',
        setUp: () {
          seedTags(['Concrete', 'Steel']);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          final tagsFetchGate = fakeSupabase.completer!;
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableTagsLoading,
          );
          // Later operations run ungated; only the in-flight tags fetch
          // stays parked on the gate.
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                !s.isLoadingHistory &&
                !s.availableTagsLoading,
          );
          // Release the pre-reset fetch; the reset disowned it, so it must
          // not mark tags as fetched or emit over the reset state.
          final runsBefore = bloc.availableTagsHandlerRuns;
          tagsFetchGate.complete();
          await _untilHandlerRuns(
            () => bloc.availableTagsHandlerRuns > runsBefore,
          );
          bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                !s.availableTagsLoading &&
                s.availableTags.isNotEmpty,
          );
        },
        verify: (bloc) {
          final tagReads = fakeSupabase
              .getMethodCallsFor('selectMatch')
              .where((call) => call['table'] == DatabaseConstants.tagsTable)
              .toList();
          expect(
            tagReads,
            hasLength(2),
            reason:
                'the disowned fetch must not count as fetched — the next '
                'sheet open starts a fresh fetch',
          );
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'an owners fetch surviving a page reopen neither stomps the reset '
        'loading flag nor resurrects the pre-reset catalog',
        setUp: () {
          seedOwners([
            (id: 'owner-1', firstName: 'Ada', lastName: 'Lovelace'),
          ]);
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          final ownersFetchGate = fakeSupabase.completer!;
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && s.availableOwnersLoading,
          );
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const ProjectSearchHistoryRequestedEvent());
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                !s.isLoadingHistory &&
                !s.availableOwnersLoading,
          );
          final runsBefore = bloc.availableOwnersHandlerRuns;
          ownersFetchGate.complete();
          await _untilHandlerRuns(
            () => bloc.availableOwnersHandlerRuns > runsBefore,
          );
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await bloc.stream.firstWhere(
            (s) =>
                s is ProjectSearchInitial &&
                !s.availableOwnersLoading &&
                s.availableOwners.isNotEmpty,
          );
        },
        verify: (bloc) {
          final ownerCalls = fakeSupabase
              .getMethodCallsFor('rpc')
              .where(
                (call) =>
                    call['functionName'] ==
                    DatabaseConstants.projectOwnersRpcFunction,
              )
              .toList();
          expect(
            ownerCalls,
            hasLength(2),
            reason:
                'the disowned fetch must not count as fetched — the next '
                'sheet open starts a fresh fetch',
          );
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
          'projects': [_fakeProjectData(id: 'p-1', projectName: 'Wall')],
          'estimations': <Map<String, dynamic>>[],
          'members': <Map<String, dynamic>>[],
        });
      }

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'applying a date filter while results are shown re-runs the search '
        'with the new range',
        setUp: seedOneProjectResult,
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          bloc.add(
            ProjectSearchDateFilterAppliedEvent(
              range: DateRange(
                start: DateTime(2026, 1, 1),
                end: DateTime(2026, 1, 5),
              ),
            ),
          );
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
        },
        // The interim idle state (carrying the new range) must be emitted
        // before the re-run's loading state — pins the handler's
        // emit-then-re-run ordering, not just the RPC call count.
        expect: () => [
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedDateRange,
            'selectedDateRange',
            isNotNull,
          ),
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
        ],
        verify: (_) {
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

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'applying an owner filter while results are shown re-runs the '
        'search with the owner',
        setUp: seedOneProjectResult,
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          bloc.add(
            const ProjectSearchOwnerFiltersAppliedEvent(ownerIds: {'owner-1'}),
          );
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
        },
        // See the date-filter test above: the sequence pins the
        // emit-then-re-run ordering.
        expect: () => [
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedOwnerIds,
            'selectedOwnerIds',
            {'owner-1'},
          ),
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
        ],
        verify: (_) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(params['filter_by_owners'], ['owner-1']);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'clearing a tag filter while results are shown re-runs the search '
        'without the tag',
        setUp: seedOneProjectResult,
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(
            const ProjectSearchTagFiltersAppliedEvent(tags: {'Roofing'}),
          );
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          bloc.add(const ProjectSearchTagFilterClearedEvent(tag: 'Roofing'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
        },
        // See the date-filter test above: the sequence pins the
        // emit-then-re-run ordering.
        expect: () => [
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedTags,
            'selectedTags',
            {'Roofing'},
          ),
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedTags,
            'selectedTags',
            isEmpty,
          ),
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
        ],
        verify: (_) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(params['filter_by_tag'], isNull);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        're-runs the search when an owner filter is applied after the owner '
        'sheet was opened (which emits the idle state)',
        setUp: () {
          seedOneProjectResult();
          seedOwners([
            (id: 'owner-1', firstName: 'Ada', lastName: 'Lovelace'),
          ]);
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
          // Opening the owner sheet emits the idle state — this must not
          // clear the active-search signal used by the re-run.
          bloc.add(const ProjectSearchAvailableOwnersRequestedEvent());
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchInitial && !s.availableOwnersLoading,
          );
          bloc.add(
            const ProjectSearchOwnerFiltersAppliedEvent(ownerIds: {'owner-1'}),
          );
          await bloc.stream.firstWhere((s) => s is ProjectSearchResultsLoaded);
        },
        // Pins the emit-then-re-run ordering: results, sheet-open idle
        // (loading then loaded), filter-applied idle, then the re-run pair.
        expect: () => [
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
          isA<ProjectSearchInitial>().having(
            (s) => s.availableOwnersLoading,
            'availableOwnersLoading',
            true,
          ),
          isA<ProjectSearchInitial>()
              .having(
                (s) => s.availableOwnersLoading,
                'availableOwnersLoading',
                false,
              )
              .having((s) => s.selectedOwnerIds, 'selectedOwnerIds', isEmpty),
          isA<ProjectSearchInitial>().having(
            (s) => s.selectedOwnerIds,
            'selectedOwnerIds',
            {'owner-1'},
          ),
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchResultsLoaded>(),
        ],
        verify: (_) {
          final calls = searchCalls();
          expect(calls, hasLength(2));
          final params = calls.last['params'] as Map<String, dynamic>;
          expect(params['filter_by_owners'], ['owner-1']);
        },
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'a search dispatched while an older one is still in flight wins: '
        'the older RPC resolving last cannot publish stale results',
        setUp: seedOneProjectResult,
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          // Park the older search's RPC on a gate. Its loading state is
          // emitted before the RPC await, so once that state is observed the
          // older search is parked.
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
          final olderSearchGate = fakeSupabase.completer!;
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchLoading && s.query == 'wall',
          );
          // The newer search runs ungated and publishes first.
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const ProjectSearchPerformedEvent(query: 'bridge'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchResultsLoaded && s.query == 'bridge',
          );
          // Release the disowned older search; its generation-guarded
          // continuation runs to completion during bloc.close() without
          // emitting.
          olderSearchGate.complete();
        },
        // Exactly three emissions: the older search's late completion must
        // not publish a stale ResultsLoaded('wall') over the newer results.
        expect: () => [
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'bridge'),
          isA<ProjectSearchResultsLoaded>().having(
            (s) => s.query,
            'query',
            'bridge',
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'editing the query back while a search is in flight disowns it: the '
        'late RPC completion cannot publish stale results over the '
        'suggestions surface',
        setUp: seedOneProjectResult,
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) async {
          // Park the search's RPC on a gate. Its loading state is emitted
          // before the RPC await, so once that state is observed the search
          // is parked.
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
          final searchGate = fakeSupabase.completer!;
          bloc.add(const ProjectSearchPerformedEvent(query: 'wall'));
          await bloc.stream.firstWhere(
            (s) => s is ProjectSearchLoading && s.query == 'wall',
          );
          // Clearing the field navigates back to the history surface while
          // the search RPC is still parked; the edit must disown it.
          fakeSupabase.shouldDelayOperations = false;
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: ''));
          await bloc.stream.firstWhere((s) => s is ProjectSearchInitial);
          // Release the disowned search; its generation-guarded continuation
          // runs to completion during bloc.close() without emitting.
          searchGate.complete();
        },
        // Exactly two emissions: the disowned search's late completion must
        // not publish a stale ResultsLoaded over the suggestions surface.
        expect: () => [
          isA<ProjectSearchLoading>().having((s) => s.query, 'query', 'wall'),
          isA<ProjectSearchInitial>(),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'applying a date filter with no active search emits only the idle '
        'state and performs no search',
        setUp: seedOneProjectResult,
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          ProjectSearchDateFilterAppliedEvent(
            range: DateRange(
              start: DateTime(2026, 1, 1),
              end: DateTime(2026, 1, 5),
            ),
          ),
        ),
        expect: () => [isA<ProjectSearchInitial>()],
        verify: (_) {
          expect(searchCalls(), isEmpty);
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
