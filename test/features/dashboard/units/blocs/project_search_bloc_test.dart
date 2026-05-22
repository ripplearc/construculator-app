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
        'emits ProjectSearchInitial when query is whitespace only',
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchQueryUpdatedEvent(query: '   '),
        ),
        wait: const Duration(milliseconds: 500),
        expect: () => [const ProjectSearchInitial()],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits [ProjectSearchLoading, ProjectSearchResultsLoaded] on success after debounce',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [
                _fakeProjectData(id: 'p-1', projectName: 'Foundation Work'),
              ],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchQueryUpdatedEvent(query: 'foundation'),
        ),
        wait: const Duration(milliseconds: 500),
        expect: () => [
          const ProjectSearchLoading(query: 'foundation'),
          isA<ProjectSearchResultsLoaded>()
              .having((s) => s.query, 'query', 'foundation')
              .having((s) => s.results, 'results', hasLength(1))
              .having(
                (s) => s.results.first.projectName,
                'first result name',
                'Foundation Work',
              ),
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
          const ProjectSearchQueryUpdatedEvent(query: 'nothing'),
        ),
        wait: const Duration(milliseconds: 500),
        expect: () => [
          const ProjectSearchLoading(query: 'nothing'),
          isA<ProjectSearchResultsLoaded>()
              .having((s) => s.results, 'results', isEmpty)
              .having((s) => s.query, 'query', 'nothing'),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'emits [ProjectSearchLoading, ProjectSearchFailureState] on timeout error',
        setUp: () {
          fakeSupabase.shouldThrowOnRpc = true;
          fakeSupabase.rpcExceptionType = SupabaseExceptionType.timeout;
          fakeSupabase.rpcErrorMessage = 'Timeout';
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) => bloc.add(
          const ProjectSearchQueryUpdatedEvent(query: 'wall'),
        ),
        wait: const Duration(milliseconds: 500),
        expect: () => [
          const ProjectSearchLoading(query: 'wall'),
          isA<ProjectSearchFailureState>()
              .having((s) => s.query, 'query', 'wall')
              .having(
                (s) => s.failure,
                'failure',
                SearchFailure(errorType: SearchErrorType.timeoutError),
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
          const ProjectSearchQueryUpdatedEvent(query: 'foundation'),
        ),
        wait: const Duration(milliseconds: 500),
        expect: () => [
          const ProjectSearchFailureState(
            failure: AuthFailure(errorType: AuthErrorType.userNotFound),
            query: 'foundation',
          ),
        ],
      );

      blocTest<ProjectSearchBloc, ProjectSearchState>(
        'second rapid query cancels first — only last result emitted',
        setUp: () {
          fakeSupabase.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [_fakeProjectData(id: 'p-last', projectName: 'Last')],
              'estimations': [],
              'members': [],
            },
          );
        },
        build: () => Modular.get<ProjectSearchBloc>(),
        act: (bloc) {
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'first'));
          bloc.add(const ProjectSearchQueryUpdatedEvent(query: 'last'));
        },
        wait: const Duration(milliseconds: 400),
        expect: () => [
          const ProjectSearchLoading(query: 'last'),
          isA<ProjectSearchResultsLoaded>()
              .having((s) => s.query, 'query', 'last'),
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
