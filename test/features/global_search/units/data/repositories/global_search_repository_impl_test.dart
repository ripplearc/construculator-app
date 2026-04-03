import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/domain/entities/pagination_params.dart';
import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/data/repositories/global_search_repository_impl.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/either/either.dart';
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

import '../../../../estimations/helpers/estimation_test_data_map_factory.dart'
    as estimation_factory;

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _fakeProjectData({
  String? id,
  String? projectName,
  String? creatorUserId,
  String? createdAt,
  String? updatedAt,
  String? status,
}) {
  return {
    DatabaseConstants.idColumn: id ?? 'project-1',
    DatabaseConstants.projectNameColumn: projectName ?? 'Test Project',
    DatabaseConstants.descriptionColumn: 'Test description',
    DatabaseConstants.creatorUserIdColumn: creatorUserId ?? 'user-1',
    DatabaseConstants.owningCompanyIdColumn: null,
    DatabaseConstants.exportFolderLinkColumn: null,
    DatabaseConstants.exportStorageProviderColumn: null,
    DatabaseConstants.createdAtColumn: createdAt ?? '2024-01-01T00:00:00.000Z',
    DatabaseConstants.updatedAtColumn: updatedAt ?? '2024-01-01T00:00:00.000Z',
    DatabaseConstants.statusColumn: status ?? 'active',
  };
}

Map<String, dynamic> _fakeMemberData({String? id, String? firstName}) {
  return {
    'id': id ?? 'member-1',
    'credential_id': null,
    'first_name': firstName ?? 'John',
    'last_name': 'Doe',
    'professional_role': 'Engineer',
    'profile_photo_url': null,
  };
}

Map<String, dynamic> _fakeSearchHistoryData({
  required String userId,
  required String searchTerm,
  required String scope,
  String? id,
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

// ---------------------------------------------------------------------------
// Helpers shared across groups
// ---------------------------------------------------------------------------

void expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void expectLeft<L, R>(Either<L, R> result, void Function(L error) assertions) {
  result.fold(assertions, (_) => fail('Expected Left but got Right'));
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  const String testUserId = 'user-123';
  const String errorMsgServer = 'Server error occurred';
  const String errorMsgTimeout = 'Request timed out';
  const String errorMsgNetwork = 'Network connection failed';

  group('GlobalSearchRepositoryImpl', () {
    late GlobalSearchRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
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
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository =
          Modular.get<GlobalSearchRepository>() as GlobalSearchRepositoryImpl;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    // -----------------------------------------------------------------------
    // search
    // -----------------------------------------------------------------------

    group('search', () {
      test(
        'should return SearchResults with mapped domain entities on success',
        () async {
          final projectData = _fakeProjectData(
            id: 'project-1',
            projectName: 'Foundation Work',
          );
          final estimationData =
              estimation_factory
                  .EstimationTestDataMapFactory.createFakeEstimationData(
                id: 'estimate-1',
                estimateName: 'Steel Frame',
              );
          final memberData = _fakeMemberData(
            id: 'member-1',
            firstName: 'Alice',
          );

          fakeSupabaseWrapper.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {
              'projects': [projectData],
              'estimations': [estimationData],
              'members': [memberData],
            },
          );

          final result = await repository.search(
            const SearchParams(query: 'foundation'),
          );

          expect(result.isRight(), isTrue);
          expectRight(result, (searchResults) {
            expect(searchResults, isA<SearchResults>());
            expect(searchResults.projects, hasLength(1));
            expect(searchResults.projects.first.projectName, 'Foundation Work');
            expect(searchResults.estimations, hasLength(1));
            expect(searchResults.estimations.first.estimateName, 'Steel Frame');
            expect(searchResults.members, hasLength(1));
            expect(searchResults.members.first.firstName, 'Alice');
          });
        },
      );

      test(
        'should return empty SearchResults when RPC returns empty lists',
        () async {
          fakeSupabaseWrapper.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );

          final result = await repository.search(
            const SearchParams(query: 'nonexistent'),
          );

          expect(result.isRight(), isTrue);
          expectRight(result, (searchResults) {
            expect(searchResults.projects, isEmpty);
            expect(searchResults.estimations, isEmpty);
            expect(searchResults.members, isEmpty);
          });
        },
      );

      test(
        'should pass all filter parameters through to the data source',
        () async {
          fakeSupabaseWrapper.setRpcResponse(
            DatabaseConstants.globalSearchRpcFunction,
            {'projects': [], 'estimations': [], 'members': []},
          );

          final filterDate = DateTime(2024, 6, 1);
          final params = SearchParams(
            query: 'concrete',
            filterByTag: 'structural',
            filterByDate: filterDate,
            filterByOwner: 'owner-42',
            scope: SearchScope.estimation,
            pagination: const PaginationParams(offset: 5, limit: 10),
          );

          await repository.search(params);

          final rpcCalls = fakeSupabaseWrapper.getMethodCallsFor('rpc');
          expect(rpcCalls, hasLength(1));
          final rpcParams = rpcCalls.first['params'] as Map<String, dynamic>?;
          expect(rpcParams, isNotNull);
          expect(rpcParams!['query'], equals('concrete'));
          expect(rpcParams['filter_by_tag'], equals('structural'));
          expect(
            rpcParams['filter_by_date'],
            equals(filterDate.toIso8601String()),
          );
          expect(rpcParams['filter_by_owner'], equals('owner-42'));
          expect(rpcParams['scope'], equals('estimation'));
          expect(rpcParams['offset'], equals(5));
          expect(rpcParams['limit'], equals(10));
        },
      );

      test(
        'should return timeoutError failure when data source throws TimeoutException',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgTimeout;

          final result = await repository.search(
            const SearchParams(query: 'test'),
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.timeoutError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgNetwork;

          final result = await repository.search(
            const SearchParams(query: 'test'),
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return parsingError failure when data source throws TypeError',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.type;

          final result = await repository.search(
            const SearchParams(query: 'test'),
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.parsingError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws PostgrestException with connection failure code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.rpcErrorMessage = 'Connection lost';

          final result = await repository.search(
            const SearchParams(query: 'test'),
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return notFoundError failure when data source throws PostgrestException with no data found code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.noDataFound;
          fakeSupabaseWrapper.rpcErrorMessage = 'No data found';

          final result = await repository.search(
            const SearchParams(query: 'test'),
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.notFoundError),
            ),
          );
        },
      );

      test(
        'should return unexpectedDatabaseError failure when data source throws PostgrestException with other code',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.rpcErrorMessage = 'Unique violation';

          final result = await repository.search(
            const SearchParams(query: 'test'),
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError),
            ),
          );
        },
      );

      test(
        'should return UnexpectedFailure when data source throws unknown error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgServer;

          final result = await repository.search(
            const SearchParams(query: 'test'),
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(failure, isA<UnexpectedFailure>()),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // getRecentSearches
    // -----------------------------------------------------------------------

    group('getRecentSearches', () {
      test('should return list of search terms on success', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeSearchHistoryData(
            userId: testUserId,
            searchTerm: 'wall',
            scope: SearchScope.dashboard.name,
          ),
          _fakeSearchHistoryData(
            userId: testUserId,
            searchTerm: 'concrete',
            scope: SearchScope.dashboard.name,
          ),
        ]);

        final result = await repository.getRecentSearches(
          SearchScope.dashboard,
        );

        expect(result.isRight(), isTrue);
        expectRight(result, (terms) {
          expect(terms, hasLength(2));
          expect(terms, containsAll(['wall', 'concrete']));
        });
      });

      test('should return empty list when user is not authenticated', () async {
        fakeSupabaseWrapper.setCurrentUser(null);

        final result = await repository.getRecentSearches(
          SearchScope.dashboard,
        );

        expect(result.isRight(), isTrue);
        expectRight(result, (terms) => expect(terms, isEmpty));
      });

      test(
        'should return empty list when no history exists for the given scope',
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
                  userId: testUserId,
                  searchTerm: 'steel',
                  scope: SearchScope.estimation.name,
                ),
              ]);

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isRight(), isTrue);
          expectRight(result, (terms) => expect(terms, isEmpty));
        },
      );

      test(
        'should return timeoutError failure when data source throws TimeoutException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
          fakeSupabaseWrapper.selectMatchExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.selectMatchErrorMessage = errorMsgTimeout;

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.timeoutError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
          fakeSupabaseWrapper.selectMatchExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.selectMatchErrorMessage = errorMsgNetwork;

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws PostgrestException with connection failure code',
        () async {
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
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.selectMatchErrorMessage = 'Connection lost';

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return unexpectedDatabaseError failure when data source throws PostgrestException with other code',
        () async {
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
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.selectMatchErrorMessage = 'Unique violation';

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError),
            ),
          );
        },
      );

      test(
        'should return notFoundError failure when data source throws PostgrestException with no data found code',
        () async {
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
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.noDataFound;
          fakeSupabaseWrapper.selectMatchErrorMessage = 'No data found';

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.notFoundError),
            ),
          );
        },
      );

      test(
        'should return parsingError failure when data source throws TypeError',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
          fakeSupabaseWrapper.selectMatchExceptionType =
              SupabaseExceptionType.type;

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.parsingError),
            ),
          );
        },
      );

      test(
        'should return UnexpectedFailure when data source throws unknown error',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
          fakeSupabaseWrapper.selectMatchExceptionType =
              SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.selectMatchErrorMessage = errorMsgServer;

          final result = await repository.getRecentSearches(
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(failure, isA<UnexpectedFailure>()),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // saveRecentSearch
    // -----------------------------------------------------------------------

    group('saveRecentSearch', () {
      test('should return Right(null) on success', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );

        final result = await repository.saveRecentSearch(
          'wall',
          SearchScope.dashboard,
        );

        expect(result.isRight(), isTrue);
      });

      test(
        'should return Right(null) without calling upsert when user is not authenticated',
        () async {
          fakeSupabaseWrapper.setCurrentUser(null);

          final result = await repository.saveRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isRight(), isTrue);
          expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
        },
      );

      test(
        'should return Right(null) without calling upsert when search term is empty after trim',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );

          final result = await repository.saveRecentSearch(
            '   ',
            SearchScope.dashboard,
          );

          expect(result.isRight(), isTrue);
          expect(fakeSupabaseWrapper.getMethodCallsFor('upsert'), isEmpty);
        },
      );

      test('should pass hasResults and projectId to the data source', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );

        await repository.saveRecentSearch(
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
      });

      test(
        'should return timeoutError failure when data source throws TimeoutException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnUpsert = true;
          fakeSupabaseWrapper.upsertExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.upsertErrorMessage = errorMsgTimeout;

          final result = await repository.saveRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.timeoutError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnUpsert = true;
          fakeSupabaseWrapper.upsertExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.upsertErrorMessage = errorMsgNetwork;

          final result = await repository.saveRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws PostgrestException with connection failure code',
        () async {
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
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.upsertErrorMessage = 'Connection lost';

          final result = await repository.saveRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return unexpectedDatabaseError failure when data source throws PostgrestException with other code',
        () async {
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
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.upsertErrorMessage = 'DB error';

          final result = await repository.saveRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError),
            ),
          );
        },
      );

      test(
        'should return UnexpectedFailure when data source throws unknown error',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnUpsert = true;
          fakeSupabaseWrapper.upsertExceptionType =
              SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.upsertErrorMessage = errorMsgServer;

          final result = await repository.saveRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(failure, isA<UnexpectedFailure>()),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // deleteRecentSearch
    // -----------------------------------------------------------------------

    group('deleteRecentSearch', () {
      test('should return Right(null) on success', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: testUserId,
            email: 'test@test.com',
            createdAt: fakeClock.now().toIso8601String(),
          ),
        );
        fakeSupabaseWrapper.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeSearchHistoryData(
            userId: testUserId,
            searchTerm: 'wall',
            scope: SearchScope.dashboard.name,
          ),
        ]);

        final result = await repository.deleteRecentSearch(
          'wall',
          SearchScope.dashboard,
        );

        expect(result.isRight(), isTrue);
      });

      test(
        'should return Right(null) without calling deleteMatch when user is not authenticated',
        () async {
          fakeSupabaseWrapper.setCurrentUser(null);

          final result = await repository.deleteRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isRight(), isTrue);
          expect(fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
        },
      );

      test(
        'should return Right(null) without calling deleteMatch when search term is empty after trim',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );

          final result = await repository.deleteRecentSearch(
            '   ',
            SearchScope.dashboard,
          );

          expect(result.isRight(), isTrue);
          expect(fakeSupabaseWrapper.getMethodCallsFor('deleteMatch'), isEmpty);
        },
      );

      test(
        'should call deleteMatch on search_history with correct filters',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );

          await repository.deleteRecentSearch('wall', SearchScope.dashboard);

          final deleteCalls = fakeSupabaseWrapper.getMethodCallsFor(
            'deleteMatch',
          );
          expect(deleteCalls, hasLength(1));
          expect(
            deleteCalls.first['table'],
            equals(DatabaseConstants.searchHistoryTable),
          );
          final filters = deleteCalls.first['filters'] as Map<String, dynamic>;
          expect(filters[DatabaseConstants.userIdColumn], equals(testUserId));
          expect(filters[DatabaseConstants.searchTermColumn], equals('wall'));
          expect(
            filters[DatabaseConstants.scopeColumn],
            equals(SearchScope.dashboard.name),
          );
        },
      );

      test(
        'should return timeoutError failure when data source throws TimeoutException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnDeleteMatch = true;
          fakeSupabaseWrapper.deleteMatchExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.deleteMatchErrorMessage = errorMsgTimeout;

          final result = await repository.deleteRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.timeoutError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnDeleteMatch = true;
          fakeSupabaseWrapper.deleteMatchExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.deleteMatchErrorMessage = errorMsgNetwork;

          final result = await repository.deleteRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws PostgrestException with connection failure code',
        () async {
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
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.deleteMatchErrorMessage = 'Connection lost';

          final result = await repository.deleteRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return unexpectedDatabaseError failure when data source throws PostgrestException with other code',
        () async {
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
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.deleteMatchErrorMessage = 'DB error';

          final result = await repository.deleteRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError),
            ),
          );
        },
      );

      test(
        'should return UnexpectedFailure when data source throws unknown error',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnDeleteMatch = true;
          fakeSupabaseWrapper.deleteMatchExceptionType =
              SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.deleteMatchErrorMessage = errorMsgServer;

          final result = await repository.deleteRecentSearch(
            'wall',
            SearchScope.dashboard,
          );

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(failure, isA<UnexpectedFailure>()),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // getSearchSuggestions
    // -----------------------------------------------------------------------

    group('getSearchSuggestions', () {
      test('should return list of suggestion strings on success', () async {
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

        final result = await repository.getSearchSuggestions();

        expect(result.isRight(), isTrue);
        expectRight(result, (suggestions) {
          expect(suggestions, hasLength(3));
          expect(
            suggestions,
            containsAll(['foundation', 'concrete mix', 'steel frame']),
          );
        });
      });

      test('should return empty list when user is not authenticated', () async {
        fakeSupabaseWrapper.setCurrentUser(null);

        final result = await repository.getSearchSuggestions();

        expect(result.isRight(), isTrue);
        expectRight(result, (suggestions) => expect(suggestions, isEmpty));
        final rpcCalls = fakeSupabaseWrapper.getMethodCallsFor('rpc');
        expect(
          rpcCalls.any(
            (c) =>
                c['functionName'] ==
                DatabaseConstants.searchSuggestionsRpcFunction,
          ),
          isFalse,
        );
      });

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

        final result = await repository.getSearchSuggestions();

        expect(result.isRight(), isTrue);
        expectRight(result, (suggestions) => expect(suggestions, isEmpty));
      });

      test(
        'should return timeoutError failure when data source throws TimeoutException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgTimeout;

          final result = await repository.getSearchSuggestions();

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.timeoutError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws SocketException',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.socket;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgNetwork;

          final result = await repository.getSearchSuggestions();

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return connectionError failure when data source throws PostgrestException with connection failure code',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.connectionFailure;
          fakeSupabaseWrapper.rpcErrorMessage = 'Connection lost';

          final result = await repository.getSearchSuggestions();

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.connectionError),
            ),
          );
        },
      );

      test(
        'should return unexpectedDatabaseError failure when data source throws PostgrestException with other code',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.uniqueViolation;
          fakeSupabaseWrapper.rpcErrorMessage = 'DB error';

          final result = await repository.getSearchSuggestions();

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.unexpectedDatabaseError),
            ),
          );
        },
      );

      test(
        'should return notFoundError failure when data source throws PostgrestException with no data found code',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.noDataFound;
          fakeSupabaseWrapper.rpcErrorMessage = 'No data found';

          final result = await repository.getSearchSuggestions();

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.notFoundError),
            ),
          );
        },
      );

      test(
        'should return parsingError failure when data source throws TypeError',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.type;

          final result = await repository.getSearchSuggestions();

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(
              failure,
              SearchFailure(errorType: SearchErrorType.parsingError),
            ),
          );
        },
      );

      test(
        'should return UnexpectedFailure when data source throws unknown error',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: testUserId,
              email: 'test@test.com',
              createdAt: fakeClock.now().toIso8601String(),
            ),
          );
          fakeSupabaseWrapper.shouldThrowOnRpc = true;
          fakeSupabaseWrapper.rpcExceptionType = SupabaseExceptionType.unknown;
          fakeSupabaseWrapper.rpcErrorMessage = errorMsgServer;

          final result = await repository.getSearchSuggestions();

          expect(result.isLeft(), isTrue);
          expectLeft(
            result,
            (failure) => expect(failure, isA<UnexpectedFailure>()),
          );
        },
      );
    });
  });
}
