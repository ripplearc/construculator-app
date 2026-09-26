import 'dart:async';

import 'package:construculator/features/estimation/data/models/cost_estimation_log_dto.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';

import 'package:construculator/libraries/app_lifecycle/testing/fake_app_lifecycle_wrapper.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../helpers/log_test_data_factory.dart';

void main() {
  group('CostEstimationLogRepositoryImpl', () {
    late CostEstimationLogRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;
    late FakeAppLifecycleWrapper fakeAppLifecycle;

    const testEstimateId = 'estimate-123';
    final defaultPageSize = CostEstimationLogRepositoryImpl.defaultPageSize;

    setUpAll(() {
      fakeClock = FakeClockImpl();
      fakeAppLifecycle = FakeAppLifecycleWrapper();
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
            appLifecycleWrapper: fakeAppLifecycle,
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
      fakeSupabaseWrapper.reset();
      fakeAppLifecycle.reset();
      repository.dispose();
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

      test(
        'sets hasMore to false when returned row count is less than page size',
        () async {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize - 1,
              estimateId: testEstimateId,
            ),
          );

          await repository.fetchInitialLogs(testEstimateId);

          expect(repository.hasMoreLogs(testEstimateId), false);
        },
      );

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
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize,
              estimateId: testEstimateId,
            ),
          );
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

        // Since the datasource reverses the order to show newest first, we need to reverse the expected entities as well
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

      test(
        'handles SocketException and returns connectionError failure',
        () async {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize,
              estimateId: testEstimateId,
            ),
          );
          await repository.fetchInitialLogs(testEstimateId);

          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Connection failed';
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.socket;
          final result = await repository.loadMoreLogs(testEstimateId);

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
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize,
              estimateId: testEstimateId,
            ),
          );
          await repository.fetchInitialLogs(testEstimateId);

          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Network error';
          final result = await repository.loadMoreLogs(testEstimateId);

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
        final logsForEstimate1 = LogTestDataFactory.createLogDataList(
          count: defaultPageSize,
          estimateId: testEstimateId,
        );
        final logsForEstimate2 = LogTestDataFactory.createLogDataList(
          count: defaultPageSize,
          estimateId: 'estimate-456',
        );
        seedLogTable([...logsForEstimate1, ...logsForEstimate2]);

        await repository.fetchInitialLogs(testEstimateId);
        await repository.fetchInitialLogs('estimate-456');

        expect(repository.hasMoreLogs(testEstimateId), true);
        expect(repository.hasMoreLogs('estimate-456'), true);

        repository.dispose();

        expect(repository.hasMoreLogs(testEstimateId), false);
        expect(repository.hasMoreLogs('estimate-456'), false);
      });
    });

    group('load timeout', () {
      // Elapsed with literal durations rather than logLoadTimeout so the
      // 15-second cutoff the ticket specifies is pinned by the test, not
      // re-derived from whatever the constant happens to say.
      const justBeforeCutoff = Duration(seconds: 14);
      const restOfCutoff = Duration(seconds: 1);

      test('gives up on a stalled initial load once the timeout elapses', () {
        fakeAsync((async) {
          fakeSupabaseWrapper.shouldDelayOperations = true;
          fakeSupabaseWrapper.completer = Completer<void>();

          Either<Failure, List<CostEstimationLog>>? result;
          unawaited(
            repository
                .fetchInitialLogs(testEstimateId)
                .then((value) => result = value),
          );

          async.elapse(justBeforeCutoff);
          expect(
            result,
            isNull,
            reason: 'the request must still be given its full 15 seconds',
          );

          async.elapse(restOfCutoff);

          expect(
            result,
            isA<Left<Failure, List<CostEstimationLog>>>().having(
              (left) => left.value,
              'value',
              isA<EstimationFailure>().having(
                (f) => f.errorType,
                'errorType',
                EstimationErrorType.timeoutError,
              ),
            ),
          );
        });
      });

      test('does not count background time on the initial load', () {
        fakeAsync((async) {
          fakeSupabaseWrapper.shouldDelayOperations = true;
          fakeSupabaseWrapper.completer = Completer<void>();

          Either<Failure, List<CostEstimationLog>>? result;
          unawaited(
            repository
                .fetchInitialLogs(testEstimateId)
                .then((value) => result = value),
          );

          async.elapse(const Duration(seconds: 10));
          fakeAppLifecycle.setInForeground(false);
          async.elapse(const Duration(minutes: 1));
          fakeAppLifecycle.setInForeground(true);
          async.elapse(const Duration(seconds: 4));
          expect(
            result,
            isNull,
            reason: 'only 14 of the 15 seconds were spent in the foreground',
          );

          async.elapse(restOfCutoff);

          expect(result, isA<Left<Failure, List<CostEstimationLog>>>());
        });
      });

      test('gives up on a stalled load more once the timeout elapses', () {
        fakeAsync((async) {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize + 1,
              estimateId: testEstimateId,
            ),
          );

          Either<Failure, List<CostEstimationLog>>? initial;
          unawaited(
            repository
                .fetchInitialLogs(testEstimateId)
                .then((value) => initial = value),
          );
          async.flushMicrotasks();
          expect(initial, isA<Right<Failure, List<CostEstimationLog>>>());

          fakeSupabaseWrapper.shouldDelayOperations = true;
          fakeSupabaseWrapper.completer = Completer<void>();

          Either<Failure, List<CostEstimationLog>>? result;
          unawaited(
            repository
                .loadMoreLogs(testEstimateId)
                .then((value) => result = value),
          );

          async.elapse(justBeforeCutoff);
          expect(result, isNull);

          async.elapse(restOfCutoff);

          expect(
            result,
            isA<Left<Failure, List<CostEstimationLog>>>().having(
              (left) => left.value,
              'value',
              isA<EstimationFailure>().having(
                (f) => f.errorType,
                'errorType',
                EstimationErrorType.timeoutError,
              ),
            ),
          );
        });
      });

      test('does not count background time on a load more', () {
        fakeAsync((async) {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize + 1,
              estimateId: testEstimateId,
            ),
          );

          Either<Failure, List<CostEstimationLog>>? initial;
          unawaited(
            repository
                .fetchInitialLogs(testEstimateId)
                .then((value) => initial = value),
          );
          async.flushMicrotasks();
          expect(initial, isA<Right<Failure, List<CostEstimationLog>>>());

          fakeSupabaseWrapper.shouldDelayOperations = true;
          fakeSupabaseWrapper.completer = Completer<void>();

          Either<Failure, List<CostEstimationLog>>? result;
          unawaited(
            repository
                .loadMoreLogs(testEstimateId)
                .then((value) => result = value),
          );

          async.elapse(const Duration(seconds: 10));
          fakeAppLifecycle.setInForeground(false);
          async.elapse(const Duration(minutes: 1));
          fakeAppLifecycle.setInForeground(true);
          async.elapse(const Duration(seconds: 4));
          expect(
            result,
            isNull,
            reason: 'only 14 of the 15 seconds were spent in the foreground',
          );

          async.elapse(restOfCutoff);

          expect(result, isA<Left<Failure, List<CostEstimationLog>>>());
        });
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
    });
  });
}
