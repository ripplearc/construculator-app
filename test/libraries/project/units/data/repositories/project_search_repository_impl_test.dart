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

void _expectRight<L, R>(
  Either<L, R> result,
  void Function(R value) assertions,
) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void _expectLeft<L, R>(
  Either<L, R> result,
  void Function(L error) assertions,
) {
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

      test(
        'returns Right with empty list when RPC returns empty projects',
        () async {
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
        },
      );

      test(
        'returns Right with empty list when query is empty without RPC call',
        () async {
          final result = await repository.searchProjects(
            userId: testUserId,
            query: '',
          );

          expect(result.isRight(), isTrue);
          _expectRight(result, (projects) => expect(projects, isEmpty));
          expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

      test(
        'returns Right with empty list when userId is empty without RPC call',
        () async {
          final result = await repository.searchProjects(
            userId: '',
            query: 'wall',
          );

          expect(result.isRight(), isTrue);
          _expectRight(result, (projects) => expect(projects, isEmpty));
          expect(fakeSupabaseWrapper.getMethodCallsFor('rpc'), isEmpty);
        },
      );

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
        expect(
          params['filter_by_date'],
          equals(filterDate.toIso8601String()),
        );
        expect(params['filter_by_tag'], equals('structural'));
        expect(params['filter_by_owner'], equals('owner-42'));
        expect(params['scope'], equals('dashboard'));
      });

      test(
        'returns timeoutError failure when data source throws TimeoutException',
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
        },
      );

      test(
        'returns connectionError failure when data source throws SocketException',
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
        },
      );

      test(
        'returns parsingError failure when data source throws TypeError',
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
        },
      );

      test(
        'returns connectionError failure when data source throws PostgrestException with connectionFailure code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
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
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
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
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
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
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
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
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
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

      test(
        'returns UnexpectedFailure when data source throws unknown error',
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
        },
      );
    });
  });
}
