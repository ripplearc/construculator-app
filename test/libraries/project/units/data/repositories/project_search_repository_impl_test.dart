import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/global_search/domain/search_error_type.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_search_data_source.dart';
import 'package:construculator/libraries/project/data/data_source/remote_project_search_data_source.dart';
import 'package:construculator/libraries/project/data/repositories/project_search_repository_impl.dart';
import 'package:construculator/libraries/project/domain/repositories/project_search_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _fakeProjectData({
  String? id,
  String? projectName,
  String? creatorUserId,
}) {
  return {
    DatabaseConstants.idColumn: id ?? 'project-1',
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.descriptionColumn: 'Test description',
    DatabaseConstants.creatorUserIdColumn: creatorUserId ?? 'user-1',
    DatabaseConstants.owningCompanyIdColumn: null,
    DatabaseConstants.exportFolderLinkColumn: null,
    DatabaseConstants.exportStorageProviderColumn: null,
    DatabaseConstants.createdAtColumn: '2024-01-01T00:00:00.000Z',
    DatabaseConstants.updatedAtColumn: '2024-01-01T00:00:00.000Z',
    DatabaseConstants.statusColumn: 'active',
  };
}

void _expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void _expectLeft<L, R>(Either<L, R> result, void Function(L error) assertions) {
  result.fold(assertions, (_) => fail('Expected Left but got Right'));
}

// ---------------------------------------------------------------------------
// Test module
// ---------------------------------------------------------------------------

class _ProjectSearchTestModule extends Module {
  final FakeSupabaseWrapper supabaseWrapper;

  _ProjectSearchTestModule(this.supabaseWrapper);

  @override
  void binds(Injector i) {
    i.addInstance<SupabaseWrapper>(supabaseWrapper);
    i.addLazySingleton<ProjectSearchDataSource>(
      () => RemoteProjectSearchDataSource(
        supabaseWrapper: i.get<SupabaseWrapper>(),
      ),
    );
    i.addLazySingleton<ProjectSearchRepository>(
      () => ProjectSearchRepositoryImpl(
        dataSource: i.get<ProjectSearchDataSource>(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const String testUserId = 'user-123';

  group('ProjectSearchRepositoryImpl', () {
    late ProjectSearchRepository repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    setUp(() {
      fakeSupabaseWrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
      Modular.init(_ProjectSearchTestModule(fakeSupabaseWrapper));
      repository = Modular.get<ProjectSearchRepository>();
    });

    tearDown(() {
      fakeSupabaseWrapper.reset();
      Modular.destroy();
    });

    group('searchProjects', () {
      test('returns Right with mapped domain entities on success', () async {
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {
            'projects': [
              _fakeProjectData(id: 'p-1', projectName: 'Foundation Work'),
            ],
            'estimations': [],
            'members': [],
          },
        );

        final result = await repository.searchProjects(
          userId: testUserId,
          query: 'foundation',
        );

        expect(result.isRight(), isTrue);
        _expectRight(result, (projects) {
          expect(projects, hasLength(1));
          expect(projects.first.id, equals('p-1'));
          expect(projects.first.projectName, equals('Foundation Work'));
          expect(projects.first.creatorUserId, equals('user-1'));
        });
      });

      test('returns Right with empty list when RPC returns empty projects', () async {
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        final result = await repository.searchProjects(
          userId: testUserId,
          query: 'nonexistent',
        );

        expect(result.isRight(), isTrue);
        _expectRight(result, (projects) => expect(projects, isEmpty));
      });

      test('returns Right with empty list when query is empty without RPC call',
          () async {
        final result = await repository.searchProjects(
          userId: testUserId,
          query: '',
        );

        expect(result.isRight(), isTrue);
        _expectRight(result, (projects) => expect(projects, isEmpty));
        expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test('returns Right with empty list when userId is empty without RPC call',
          () async {
        final result = await repository.searchProjects(
          userId: '',
          query: 'wall',
        );

        expect(result.isRight(), isTrue);
        _expectRight(result, (projects) => expect(projects, isEmpty));
        expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
      });

      test(
        'returns Right with empty list when userId is whitespace only without RPC call',
        () async {
          final result = await repository.searchProjects(
            userId: '   ',
            query: 'wall',
          );

          expect(result.isRight(), isTrue);
          _expectRight(result, (projects) => expect(projects, isEmpty));
          expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test(
        'returns Right with empty list when query is whitespace only without RPC call',
        () async {
          final result = await repository.searchProjects(
            userId: testUserId,
            query: '   ',
          );

          expect(result.isRight(), isTrue);
          _expectRight(result, (projects) => expect(projects, isEmpty));
          expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test('passes all filter params through to the data source', () async {
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.globalSearchRpcFunction,
          {'projects': [], 'estimations': [], 'members': []},
        );

        final filterDate = DateTime(2024, 6, 1);
        await repository.searchProjects(
          userId: testUserId,
          query: 'wall',
          filterByDate: filterDate,
          filterByTag: 'structural',
          filterByOwner: 'owner-42',
        );

        final rpcCalls = fakeSupabaseWrapper.getMethodCallsFor('rpc');
        expect(rpcCalls, hasLength(1));
        final params = rpcCalls.first['params'] as Map<String, dynamic>?;
        expect(params, isNotNull);
        expect(params!['query'], equals('wall'));
        expect(params['filter_by_date'], equals(filterDate.toIso8601String()));
        expect(params['filter_by_tag'], equals('structural'));
        expect(params['filter_by_owner'], equals('owner-42'));
        expect(params['scope'], equals('dashboard'));
      });

      test('returns timeoutError failure when data source throws TimeoutException',
          () async {
        fakeSupabaseWrapper.shouldThrowOnRpc = true;
        fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;
        fakeSupabaseWrapper.rpcErrorMessage = 'Request timed out';

        final result = await repository.searchProjects(
          userId: testUserId,
          query: 'wall',
        );

        expect(result.isLeft(), isTrue);
        _expectLeft(
          result,
          (failure) => expect(
            failure,
            SearchFailure(errorType: SearchErrorType.timeoutError),
          ),
        );
      });

      test('returns connectionError failure when data source throws SocketException',
          () async {
        fakeSupabaseWrapper.shouldThrowOnRpc = true;
        fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
        fakeSupabaseWrapper.rpcErrorMessage = 'Network connection failed';

        final result = await repository.searchProjects(
          userId: testUserId,
          query: 'wall',
        );

        expect(result.isLeft(), isTrue);
        _expectLeft(
          result,
          (failure) => expect(
            failure,
            SearchFailure(errorType: SearchErrorType.connectionError),
          ),
        );
      });

      test('returns parsingError failure when data source throws TypeError',
          () async {
        fakeSupabaseWrapper.shouldThrowOnRpc = true;
        fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.type;

        final result = await repository.searchProjects(
          userId: testUserId,
          query: 'wall',
        );

        expect(result.isLeft(), isTrue);
        _expectLeft(
          result,
          (failure) => expect(
            failure,
            SearchFailure(errorType: SearchErrorType.parsingError),
          ),
        );
      });

      test(
        'returns connectionError failure when data source throws PostgrestException with connectionFailure code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.rpcErrorMessage = 'Connection lost';

          final result = await repository.searchProjects(
            userId: testUserId,
            query: 'wall',
          );

          expect(result.isLeft(), isTrue);
          _expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'returns connectionError failure when data source throws PostgrestException with unableToConnect code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.unableToConnect;
          fakeSupabaseWrapper.rpcErrorMessage = 'Unable to connect';

          final result = await repository.searchProjects(
            userId: testUserId,
            query: 'wall',
          );

          expect(result.isLeft(), isTrue);
          _expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'returns connectionError failure when data source throws PostgrestException with connectionDoesNotExist code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionDoesNotExist;
          fakeSupabaseWrapper.rpcErrorMessage = 'Connection does not exist';

          final result = await repository.searchProjects(
            userId: testUserId,
            query: 'wall',
          );

          expect(result.isLeft(), isTrue);
          _expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'returns notFoundError failure when data source throws PostgrestException with noDataFound code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode = PostgresErrorCode.noDataFound;
          fakeSupabaseWrapper.rpcErrorMessage = 'No data found';

          final result = await repository.searchProjects(
            userId: testUserId,
            query: 'wall',
          );

          expect(result.isLeft(), isTrue);
          _expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.notFoundError),
            ),
          );
        },
      );

      test(
        'returns unexpectedDatabaseError failure when data source throws PostgrestException with an unhandled code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.rpcErrorMessage = 'Unique violation';

          final result = await repository.searchProjects(
            userId: testUserId,
            query: 'wall',
          );

          expect(result.isLeft(), isTrue);
          _expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError),
            ),
          );
        },
      );

      test('returns UnexpectedFailure when data source throws unknown error',
          () async {
        fakeSupabaseWrapper.shouldThrowOnRpc = true;
        fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.unknown;

        final result = await repository.searchProjects(
          userId: testUserId,
          query: 'wall',
        );

        expect(result.isLeft(), isTrue);
        _expectLeft(
          result,
          (failure) => expect(failure, isA<UnexpectedFailure>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Shared error-matrix scenarios — used by all four history/suggestion
    // methods. Each scenario configures the FakeSupabaseWrapper and asserts
    // the mapped Failure on the Either<Left>.
    // -----------------------------------------------------------------------

    void configureWrapperToThrowOn({
      required FakeSupabaseWrapper wrapper,
      required _WrapperOp op,
      required SupabaseExceptionType type,
      PostgresErrorCode? postgresCode,
    }) {
      switch (op) {
        case _WrapperOp.rpc:
          wrapper.shouldThrowOnRpc = true;
          wrapper.rpcExceptionType = type;
          wrapper.rpcErrorMessage = 'rpc error';
        case _WrapperOp.upsert:
          wrapper.shouldThrowOnUpsert = true;
          wrapper.upsertExceptionType = type;
          wrapper.upsertErrorMessage = 'upsert error';
        case _WrapperOp.selectMatch:
          wrapper.shouldThrowOnSelectMatch = true;
          wrapper.selectMatchExceptionType = type;
          wrapper.selectMatchErrorMessage = 'select error';
        case _WrapperOp.deleteMatch:
          wrapper.shouldThrowOnDeleteMatch = true;
          wrapper.deleteMatchExceptionType = type;
          wrapper.deleteMatchErrorMessage = 'delete error';
      }
      wrapper.postgrestErrorCode = postgresCode;
    }

    /// Asserts that [action] maps the given thrown exception to [expected].
    Future<void> assertMappedFailure({
      required _WrapperOp op,
      required SupabaseExceptionType throwType,
      PostgresErrorCode? postgresCode,
      required Future<Either<Failure, Object?>> Function() action,
      required Failure expected,
    }) async {
      configureWrapperToThrowOn(
        wrapper: fakeSupabaseWrapper,
        op: op,
        type: throwType,
        postgresCode: postgresCode,
      );
      final result = await action();
      _expectLeft(result, (failure) => expect(failure, expected));
    }

    /// Runs the full _handleError matrix against [action].
    void runErrorMatrix({
      required String label,
      required _WrapperOp op,
      required Future<Either<Failure, Object?>> Function() action,
    }) {
      test('$label — TimeoutException → timeoutError failure', () async {
        await assertMappedFailure(
          op: op,
          throwType: SupabaseExceptionType.timeout,
          action: action,
          expected: SearchFailure(errorType: SearchErrorType.timeoutError),
        );
      });

      test('$label — SocketException → connectionError failure', () async {
        await assertMappedFailure(
          op: op,
          throwType: SupabaseExceptionType.socket,
          action: action,
          expected: SearchFailure(errorType: SearchErrorType.connectionError),
        );
      });

      test('$label — TypeError → parsingError failure', () async {
        await assertMappedFailure(
          op: op,
          throwType: SupabaseExceptionType.type,
          action: action,
          expected: SearchFailure(errorType: SearchErrorType.parsingError),
        );
      });

      test(
        '$label — PostgrestException(noDataFound) → notFoundError failure',
        () async {
          await assertMappedFailure(
            op: op,
            throwType: SupabaseExceptionType.postgrest,
            postgresCode: PostgresErrorCode.noDataFound,
            action: action,
            expected: SearchFailure(errorType: SearchErrorType.notFoundError),
          );
        },
      );

      test(
        '$label — PostgrestException(connectionFailure) → connectionError failure',
        () async {
          await assertMappedFailure(
            op: op,
            throwType: SupabaseExceptionType.postgrest,
            postgresCode: PostgresErrorCode.connectionFailure,
            action: action,
            expected: SearchFailure(
              errorType: SearchErrorType.connectionError,
            ),
          );
        },
      );

      test(
        '$label — PostgrestException(unableToConnect) → connectionError failure',
        () async {
          await assertMappedFailure(
            op: op,
            throwType: SupabaseExceptionType.postgrest,
            postgresCode: PostgresErrorCode.unableToConnect,
            action: action,
            expected: SearchFailure(
              errorType: SearchErrorType.connectionError,
            ),
          );
        },
      );

      test(
        '$label — PostgrestException(connectionDoesNotExist) → connectionError failure',
        () async {
          await assertMappedFailure(
            op: op,
            throwType: SupabaseExceptionType.postgrest,
            postgresCode: PostgresErrorCode.connectionDoesNotExist,
            action: action,
            expected: SearchFailure(
              errorType: SearchErrorType.connectionError,
            ),
          );
        },
      );

      test(
        '$label — PostgrestException(unhandled code) → unexpectedDatabaseError failure',
        () async {
          await assertMappedFailure(
            op: op,
            throwType: SupabaseExceptionType.postgrest,
            postgresCode: PostgresErrorCode.uniqueViolation,
            action: action,
            expected: SearchFailure(
              errorType: SearchErrorType.unexpectedDatabaseError,
            ),
          );
        },
      );

      test('$label — unknown error → UnexpectedFailure', () async {
        configureWrapperToThrowOn(
          wrapper: fakeSupabaseWrapper,
          op: op,
          type: SupabaseExceptionType.unknown,
        );
        final result = await action();
        _expectLeft(result, (failure) => expect(failure, isA<UnexpectedFailure>()));
      });
    }

    group('saveRecentProjectSearch', () {
      test('returns Right(null) on success and upserts via wrapper', () async {
        final result = await repository.saveRecentProjectSearch(
          userId: testUserId,
          searchTerm: 'foundation',
          hasResults: true,
        );

        expect(result.isRight(), isTrue);
        expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), hasLength(1));
      });

      test('returns Right(null) without upsert when userId is empty', () async {
        final result = await repository.saveRecentProjectSearch(
          userId: '',
          searchTerm: 'foundation',
        );

        expect(result.isRight(), isTrue);
        expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
      });

      test(
        'returns Right(null) without upsert when userId is whitespace only',
        () async {
          final result = await repository.saveRecentProjectSearch(
            userId: '   ',
            searchTerm: 'foundation',
          );

          expect(result.isRight(), isTrue);
          expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
        },
      );

      test(
        'returns Right(null) without upsert when searchTerm is empty',
        () async {
          final result = await repository.saveRecentProjectSearch(
            userId: testUserId,
            searchTerm: '',
          );

          expect(result.isRight(), isTrue);
          expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
        },
      );

      test(
        'returns Right(null) without upsert when searchTerm is whitespace only',
        () async {
          final result = await repository.saveRecentProjectSearch(
            userId: testUserId,
            searchTerm: '   ',
          );

          expect(result.isRight(), isTrue);
          expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
        },
      );

      runErrorMatrix(
        label: 'saveRecentProjectSearch',
        op: _WrapperOp.upsert,
        action: () => repository.saveRecentProjectSearch(
          userId: testUserId,
          searchTerm: 'wall',
        ),
      );
    });

    group('getRecentProjectSearches', () {
      test('returns Right with terms in wrapper order on success', () async {
        fakeSupabaseWrapper.addTableData(
          DatabaseConstants.projectSearchHistoryTable,
          [
            {
              DatabaseConstants.userIdColumn: testUserId,
              DatabaseConstants.searchTermColumn: 'older',
              DatabaseConstants.updatedAtColumn: '2024-01-01T00:00:00.000Z',
            },
            {
              DatabaseConstants.userIdColumn: testUserId,
              DatabaseConstants.searchTermColumn: 'newer',
              DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
            },
          ],
        );

        final result = await repository.getRecentProjectSearches(
          userId: testUserId,
        );

        expect(result.isRight(), isTrue);
        _expectRight(
          result,
          (terms) => expect(terms, equals(['newer', 'older'])),
        );
      });

      test(
        'returns Right([]) without selectMatch when userId is empty',
        () async {
          final result = await repository.getRecentProjectSearches(userId: '');

          expect(result.isRight(), isTrue);
          _expectRight(result, (terms) => expect(terms, isEmpty));
          expect(
            fakeSupabaseWrapper.getMethodCallsFor('selectMatch'),
            isEmpty,
          );
        },
      );

      test(
        'returns Right([]) without selectMatch when userId is whitespace only',
        () async {
          final result = await repository.getRecentProjectSearches(
            userId: '   ',
          );

          expect(result.isRight(), isTrue);
          _expectRight(result, (terms) => expect(terms, isEmpty));
          expect(
            fakeSupabaseWrapper.getMethodCallsFor('selectMatch'),
            isEmpty,
          );
        },
      );

      runErrorMatrix(
        label: 'getRecentProjectSearches',
        op: _WrapperOp.selectMatch,
        action: () => repository.getRecentProjectSearches(userId: testUserId),
      );
    });

    group('deleteRecentProjectSearch', () {
      test('returns Right(null) on success and deletes via wrapper', () async {
        final result = await repository.deleteRecentProjectSearch(
          userId: testUserId,
          searchTerm: 'wall',
        );

        expect(result.isRight(), isTrue);
        expect(
          fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'),
          hasLength(1),
        );
      });

      test(
        'returns Right(null) without delete when userId is empty',
        () async {
          final result = await repository.deleteRecentProjectSearch(
            userId: '',
            searchTerm: 'wall',
          );

          expect(result.isRight(), isTrue);
          expect(
            fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'),
            isEmpty,
          );
        },
      );

      test(
        'returns Right(null) without delete when userId is whitespace only',
        () async {
          final result = await repository.deleteRecentProjectSearch(
            userId: '   ',
            searchTerm: 'wall',
          );

          expect(result.isRight(), isTrue);
          expect(
            fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'),
            isEmpty,
          );
        },
      );

      test(
        'returns Right(null) without delete when searchTerm is empty',
        () async {
          final result = await repository.deleteRecentProjectSearch(
            userId: testUserId,
            searchTerm: '',
          );

          expect(result.isRight(), isTrue);
          expect(
            fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'),
            isEmpty,
          );
        },
      );

      test(
        'returns Right(null) without delete when searchTerm is whitespace only',
        () async {
          final result = await repository.deleteRecentProjectSearch(
            userId: testUserId,
            searchTerm: '   ',
          );

          expect(result.isRight(), isTrue);
          expect(
            fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'),
            isEmpty,
          );
        },
      );

      runErrorMatrix(
        label: 'deleteRecentProjectSearch',
        op: _WrapperOp.deleteMatch,
        action: () => repository.deleteRecentProjectSearch(
          userId: testUserId,
          searchTerm: 'wall',
        ),
      );
    });

    group('getProjectSearchSuggestions', () {
      test('returns Right with string suggestions on success', () async {
        fakeSupabaseWrapper.setRpcResponse(
          DatabaseConstants.projectSearchSuggestionsRpcFunction,
          <dynamic>['foundation', 'wall', 42, null, 'steel'],
        );

        final result = await repository.getProjectSearchSuggestions(
          userId: testUserId,
        );

        expect(result.isRight(), isTrue);
        _expectRight(
          result,
          (terms) => expect(terms, equals(['foundation', 'wall', 'steel'])),
        );
      });

      test(
        'returns Right([]) without RPC when userId is empty',
        () async {
          final result = await repository.getProjectSearchSuggestions(
            userId: '',
          );

          expect(result.isRight(), isTrue);
          _expectRight(result, (terms) => expect(terms, isEmpty));
          expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test(
        'returns Right([]) without RPC when userId is whitespace only',
        () async {
          final result = await repository.getProjectSearchSuggestions(
            userId: '   ',
          );

          expect(result.isRight(), isTrue);
          _expectRight(result, (terms) => expect(terms, isEmpty));
          expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      runErrorMatrix(
        label: 'getProjectSearchSuggestions',
        op: _WrapperOp.rpc,
        action: () =>
            repository.getProjectSearchSuggestions(userId: testUserId),
      );
    });
  });
}

enum _WrapperOp { rpc, upsert, selectMatch, deleteMatch }
