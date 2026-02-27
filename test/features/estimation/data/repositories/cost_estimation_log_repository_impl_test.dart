import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/models/cost_estimation_log_dto.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/log_test_data_factory.dart';

void main() {
  group('CostEstimationLogRepositoryImpl', () {
    late CostEstimationLogRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    const testEstimateId = 'estimate-123';
    const defaultPageSize = 10;

    setUpAll(() {
      fakeClock = FakeClockImpl();
      Modular.init(
        EstimationModule(
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
          Modular.get<CostEstimationLogRepository>()
              as CostEstimationLogRepositoryImpl;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      repository.dispose();
      fakeSupabaseWrapper.reset();
    });

    void seedLogTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(
        DatabaseConstants.costEstimationLogsTable,
        rows,
      );
    }

    group('fetchInitialLogs', () {
      test(
        'successfully fetches initial logs and initializes pagination',
        () async {
          final logData = [
            LogTestDataFactory.createLogData(
              id: 'log-1',
              estimateId: testEstimateId,
              activity: 'costEstimationCreated',
            ),
            LogTestDataFactory.createLogData(
              id: 'log-2',
              estimateId: testEstimateId,
              activity: 'costEstimationRenamed',
            ),
          ];
          seedLogTable(logData);

          final expectedLogEntities = logData
              .map((data) => CostEstimationLogDto.fromJson(data).toDomain())
              .toList();

          final result = await repository.fetchInitialLogs(testEstimateId);

          expect(result.isRight(), true);
          final logs = result.getRightOrNull()!;
          expect(logs.length, 2);
          expect(logs, expectedLogEntities);
        },
      );

      test('requests correct parameters for initial page', () async {
        seedLogTable([
          LogTestDataFactory.createLogData(
            id: 'log-1',
            estimateId: testEstimateId,
            activity: 'costEstimationCreated',
          ),
        ]);

        await repository.fetchInitialLogs(testEstimateId);

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectPaginated');
        expect(calls.length, 1);
        final call = calls.first;
        expect(call, {
          'filterValue': testEstimateId,
          'filterColumn': DatabaseConstants.estimateIdColumn,
          'table': DatabaseConstants.costEstimationLogsTable,
          'orderColumn': DatabaseConstants.loggedAtColumn,
          'ascending': false,
          'rangeFrom': 0,
          'rangeTo': defaultPageSize - 1,
          'method': 'selectPaginated',
          'columns': '*, user:user_profiles(*)',
        });
      });

      test('sets hasMore to true when full page is returned', () async {
        seedLogTable(
          LogTestDataFactory.createLogDataList(
            count: defaultPageSize,
            estimateId: testEstimateId,
          ),
        );

        await repository.fetchInitialLogs(testEstimateId);

        expect(repository.hasMoreLogs(testEstimateId), true);
      });

      test('sets hasMore to false when partial page is returned', () async {
        seedLogTable(
          LogTestDataFactory.createLogDataList(
            count: defaultPageSize ~/ 5,
            estimateId: testEstimateId,
          ),
        );

        await repository.fetchInitialLogs(testEstimateId);

        expect(repository.hasMoreLogs(testEstimateId), false);
      });

      test('returns empty list when no logs exist', () async {
        final result = await repository.fetchInitialLogs(testEstimateId);

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isEmpty);
        expect(repository.hasMoreLogs(testEstimateId), false);
      });

      test(
        'handles TimeoutException and returns timeoutError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Timeout';
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;

          final result = await repository.fetchInitialLogs(testEstimateId);

          expect(result.isLeft(), true);
          final failure = result.getLeftOrNull();
          expect(
            failure,
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.timeoutError,
            ),
          );
        },
      );

      test(
        'handles FormatException and returns parsingError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Invalid format';
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.type;

          final result = await repository.fetchInitialLogs(testEstimateId);

          expect(result.isLeft(), true);
          final failure = result.getLeftOrNull();
          expect(
            failure,
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.parsingError,
            ),
          );
        },
      );

      test(
        'handles SocketException and returns connectionError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Connection failed';
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.socket;

          final result = await repository.fetchInitialLogs(testEstimateId);

          expect(result.isLeft(), true);
          final failure = result.getLeftOrNull();
          expect(
            failure,
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.connectionError,
            ),
          );
        },
      );

      test(
        'handles generic Exception and returns unexpectedError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Network error';

          final result = await repository.fetchInitialLogs(testEstimateId);

          expect(result.isLeft(), true);
          final failure = result.getLeftOrNull();
          expect(
            failure,
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.unexpectedError,
            ),
          );
        },
      );

      test(
        'resets pagination state on subsequent calls for same estimate',
        () async {
          seedLogTable([
            LogTestDataFactory.createLogData(
              id: 'log-1',
              estimateId: testEstimateId,
              activity: 'costEstimationCreated',
            ),
          ]);
          await repository.fetchInitialLogs(testEstimateId);
          await repository.loadMoreLogs(testEstimateId);

          await repository.fetchInitialLogs(testEstimateId);

          final calls = fakeSupabaseWrapper.getMethodCallsFor(
            'selectPaginated',
          );
          final lastCall = calls.last;
          expect(lastCall['rangeFrom'], 0);
          expect(lastCall['rangeTo'], defaultPageSize - 1);
        },
      );
    });

    group('loadMoreLogs', () {
      test('fetches next page with correct offset', () async {
        final logData = LogTestDataFactory.createLogDataList(
          count: defaultPageSize + 5,
          estimateId: testEstimateId,
        );
        seedLogTable(logData);

        final expectedEntities = logData
            .map((data) => CostEstimationLogDto.fromJson(data).toDomain())
            .toList()
            .reversed
            .toList();

        final result1 = await repository.fetchInitialLogs(testEstimateId);
        final logs1 = result1.getRightOrNull()!;
        final expectedLogs1 = expectedEntities.sublist(0, defaultPageSize);

        expect(logs1, expectedLogs1);

        final result2 = await repository.loadMoreLogs(testEstimateId);
        final logs2 = result2.getRightOrNull()!;
        final expectedLogs2 = expectedEntities.sublist(defaultPageSize);
        expect(logs2, expectedLogs2);

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectPaginated');
        final lastCall = calls.last;
        expect(lastCall['rangeFrom'], defaultPageSize);
        expect(lastCall['rangeTo'], defaultPageSize * 2 - 1);
      });

      test('returns empty list when pagination state does not exist', () async {
        final result = await repository.loadMoreLogs('nonexistent');

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isEmpty);
      });

      test('returns empty list when hasMore is false', () async {
        seedLogTable([
          LogTestDataFactory.createLogData(
            id: 'log-1',
            estimateId: testEstimateId,
            activity: 'costEstimationCreated',
          ),
        ]);
        await repository.fetchInitialLogs(testEstimateId);

        final result = await repository.loadMoreLogs(testEstimateId);

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isEmpty);
      });

      test('updates hasMore to false when partial page is returned', () async {
        seedLogTable(
          LogTestDataFactory.createLogDataList(
            count: defaultPageSize + 1,
            estimateId: testEstimateId,
          ),
        );
        await repository.fetchInitialLogs(testEstimateId);

        await repository.loadMoreLogs(testEstimateId);

        expect(repository.hasMoreLogs(testEstimateId), false);
      });

      test('updates hasMore to true when full page is returned', () async {
        seedLogTable(
          LogTestDataFactory.createLogDataList(
            count: defaultPageSize * 2,
            estimateId: testEstimateId,
          ),
        );
        await repository.fetchInitialLogs(testEstimateId);

        await repository.loadMoreLogs(testEstimateId);

        expect(repository.hasMoreLogs(testEstimateId), true);
      });

      test(
        'handles TimeoutException and returns timeoutError failure',
        () async {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize,
              estimateId: testEstimateId,
            ),
          );
          await repository.fetchInitialLogs(testEstimateId);

          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Timeout';
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;
          final result = await repository.loadMoreLogs(testEstimateId);

          expect(result.isLeft(), true);
          final failure = result.getLeftOrNull();
          expect(
            failure,
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.timeoutError,
            ),
          );
        },
      );
    });

    group('hasMoreLogs', () {
      test('returns false when pagination state does not exist', () {
        expect(repository.hasMoreLogs('nonexistent'), false);
      });

      test('returns true after fetching full initial page', () async {
        seedLogTable(
          LogTestDataFactory.createLogDataList(
            count: defaultPageSize,
            estimateId: testEstimateId,
          ),
        );
        await repository.fetchInitialLogs(testEstimateId);

        expect(repository.hasMoreLogs(testEstimateId), true);
      });

      test('returns false after fetching partial initial page', () async {
        seedLogTable([
          LogTestDataFactory.createLogData(
            id: 'log-1',
            estimateId: testEstimateId,
            activity: 'costEstimationCreated',
          ),
        ]);
        await repository.fetchInitialLogs(testEstimateId);

        expect(repository.hasMoreLogs(testEstimateId), false);
      });

      test('tracks state independently for different estimates', () async {
        seedLogTable(
          LogTestDataFactory.createLogDataList(
            count: defaultPageSize,
            estimateId: testEstimateId,
          ),
        );
        await repository.fetchInitialLogs(testEstimateId);

        seedLogTable([
          LogTestDataFactory.createLogData(
            id: 'log-other',
            estimateId: 'estimate-456',
            activity: 'costEstimationCreated',
          ),
        ]);
        await repository.fetchInitialLogs('estimate-456');

        expect(repository.hasMoreLogs(testEstimateId), true);
        expect(repository.hasMoreLogs('estimate-456'), false);
      });
    });

    group('dispose', () {
      test('clears all pagination states', () async {
        seedLogTable([
          LogTestDataFactory.createLogData(
            id: 'log-1',
            estimateId: testEstimateId,
            activity: 'costEstimationCreated',
          ),
        ]);
        await repository.fetchInitialLogs(testEstimateId);
        await repository.fetchInitialLogs('estimate-456');

        repository.dispose();

        expect(repository.hasMoreLogs(testEstimateId), false);
        expect(repository.hasMoreLogs('estimate-456'), false);
      });
    });

    group('pagination state management', () {
      test('maintains correct offset across multiple loadMore calls', () async {
        final logData = LogTestDataFactory.createLogDataList(
          count: defaultPageSize + defaultPageSize + 5,
          estimateId: testEstimateId,
        ).reversed.toList();
        seedLogTable(logData);

        final result1 = await repository.fetchInitialLogs(testEstimateId);
        final logs1 = result1.getRightOrNull()!;
        final expectedLogs1 = logData
            .sublist(0, defaultPageSize)
            .map((data) => CostEstimationLogDto.fromJson(data).toDomain())
            .toList();
        expect(logs1, expectedLogs1);

        final result2 = await repository.loadMoreLogs(testEstimateId);
        final logs2 = result2.getRightOrNull()!;
        final expectedLogs2 = logData
            .sublist(defaultPageSize, defaultPageSize * 2)
            .map((data) => CostEstimationLogDto.fromJson(data).toDomain())
            .toList();
        expect(logs2, expectedLogs2);

        final result3 = await repository.loadMoreLogs(testEstimateId);
        final logs3 = result3.getRightOrNull()!;
        final expectedLogs3 = logData
            .sublist(defaultPageSize * 2)
            .map((data) => CostEstimationLogDto.fromJson(data).toDomain())
            .toList();
        expect(logs3, expectedLogs3);

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectPaginated');
        final lastCall = calls.last;
        expect(lastCall['rangeFrom'], defaultPageSize * 2);
        expect(lastCall['rangeTo'], defaultPageSize * 3 - 1);
      });

      test('handles empty page during loadMore correctly', () async {
        seedLogTable(
          LogTestDataFactory.createLogDataList(
            count: defaultPageSize,
            estimateId: testEstimateId,
          ),
        );
        await repository.fetchInitialLogs(testEstimateId);

        await repository.loadMoreLogs(testEstimateId);

        expect(repository.hasMoreLogs(testEstimateId), false);
      });
    });
  });
}
