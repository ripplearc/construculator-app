import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
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
  group('CostEstimationLogBloc', () {
    late CostEstimationLogBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;
    late CostEstimationLogRepository repository;

    const testEstimateId = 'estimate-123';
    const defaultPageSize = 10;

    setUpAll(() {
      fakeClock = FakeClockImpl();
      final bootstrap = AppBootstrap(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
      );
      Modular.init(EstimationModule(bootstrap));

      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository = Modular.get<CostEstimationLogRepository>();
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      repository.dispose();
      bloc = CostEstimationLogBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    void seedLogTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(
        DatabaseConstants.costEstimationLogsTable,
        rows,
      );
    }

    group('Initialization', () {
      test('should start in initial state', () {
        expect(bloc.state, isA<CostEstimationLogInitial>());
      });
    });

    group('CostEstimationLogFetchInitial', () {
      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should emit loading then loaded with logs when fetch succeeds',
        build: () {
          seedLogTable([
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
          ]);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationLogFetchInitial(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<CostEstimationLogLoading>(),
          isA<CostEstimationLogLoaded>()
              .having((s) => s.logs.length, 'logs length', 2)
              .having((s) => s.hasMore, 'hasMore', false)
              .having((s) => s.isLoadingMore, 'isLoadingMore', false),
        ],
      );

      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should emit loading then loaded with hasMore true when full page is returned',
        build: () {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize,
              estimateId: testEstimateId,
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationLogFetchInitial(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<CostEstimationLogLoading>(),
          isA<CostEstimationLogLoaded>()
              .having((s) => s.logs.length, 'logs length', defaultPageSize)
              .having((s) => s.hasMore, 'hasMore', true),
        ],
      );

      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should emit loading then empty when no logs exist',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const CostEstimationLogFetchInitial(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<CostEstimationLogLoading>(),
          isA<CostEstimationLogEmpty>(),
        ],
      );

      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should emit loading then error when fetch fails with timeout',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationLogFetchInitial(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<CostEstimationLogLoading>(),
          isA<CostEstimationLogError>().having(
            (s) => (s.failure as EstimationFailure).errorType,
            'error type',
            EstimationErrorType.timeoutError,
          ),
        ],
      );

      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should emit loading then error when fetch fails with connection error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CostEstimationLogFetchInitial(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<CostEstimationLogLoading>(),
          isA<CostEstimationLogError>().having(
            (s) => (s.failure as EstimationFailure).errorType,
            'error type',
            EstimationErrorType.connectionError,
          ),
        ],
      );
    });

    group('CostEstimationLogLoadMore', () {
      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should emit loaded with isLoadingMore true then loaded with more logs when load succeeds',
        build: () {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize + 5,
              estimateId: testEstimateId,
            ),
          );
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const CostEstimationLogFetchInitial(estimateId: testEstimateId),
          );

          bloc.add(const CostEstimationLogLoadMore(estimateId: testEstimateId));
        },
        skip: 2,
        expect: () => [
          isA<CostEstimationLogLoaded>()
              .having((s) => s.logs.length, 'logs length', defaultPageSize)
              .having((s) => s.isLoadingMore, 'isLoadingMore', true)
              .having((s) => s.hasMore, 'hasMore', true),
          isA<CostEstimationLogLoaded>()
              .having((s) => s.logs.length, 'logs length', defaultPageSize + 5)
              .having((s) => s.isLoadingMore, 'isLoadingMore', false)
              .having((s) => s.hasMore, 'hasMore', false),
        ],
      );

      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should not emit anything when load more is called but state is not loaded',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const CostEstimationLogLoadMore(estimateId: testEstimateId),
        ),
        expect: () => [],
      );

      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should not emit anything when load more is called but hasMore is false',
        build: () {
          seedLogTable([
            LogTestDataFactory.createLogData(
              id: 'log-1',
              estimateId: testEstimateId,
              activity: 'costEstimationCreated',
            ),
          ]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const CostEstimationLogFetchInitial(estimateId: testEstimateId),
          );

          bloc.add(const CostEstimationLogLoadMore(estimateId: testEstimateId));
        },
        skip: 2,
        expect: () => [],
      );

      blocTest<CostEstimationLogBloc, CostEstimationLogState>(
        'should emit load more error when load more fails but keep existing data',
        build: () {
          seedLogTable(
            LogTestDataFactory.createLogDataList(
              count: defaultPageSize,
              estimateId: testEstimateId,
            ),
          );
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const CostEstimationLogFetchInitial(estimateId: testEstimateId),
          );

          await bloc.stream.firstWhere(
            (state) => state is CostEstimationLogLoaded,
          );

          fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
          fakeSupabaseWrapper.selectPaginatedExceptionType =
              SupabaseExceptionType.timeout;
          bloc.add(const CostEstimationLogLoadMore(estimateId: testEstimateId));
        },
        skip: 2,
        expect: () => [
          isA<CostEstimationLogLoaded>().having(
            (s) => s.isLoadingMore,
            'isLoadingMore',
            true,
          ),
          isA<CostEstimationLogLoadMoreError>()
              .having((s) => s.logs.length, 'logs length', 10)
              .having(
                (s) => (s.failure as EstimationFailure).errorType,
                'error type',
                EstimationErrorType.timeoutError,
              ),
        ],
      );
    });
  });
}
