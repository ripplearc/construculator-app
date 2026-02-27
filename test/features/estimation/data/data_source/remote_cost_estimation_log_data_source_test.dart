import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimation_log_dto.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/log_test_data_factory.dart';

void main() {
  group('RemoteCostEstimationLogDataSource', () {
    late CostEstimationLogDataSource dataSource;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    const testEstimateId = 'estimate-123';

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
      dataSource = Modular.get<CostEstimationLogDataSource>();
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    void seedLogTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(
        DatabaseConstants.costEstimationLogsTable,
        rows,
      );
    }

    group('getEstimationLogs', () {
      test('successfully fetches logs with correct parameters', () async {
        final testLogs = [
          LogTestDataFactory.createLogData(
            id: 'log-1',
            estimateId: testEstimateId,
            activity: 'costEstimationCreated',
            activityDetails: const {'name': 'New Estimation'},
          ),
          LogTestDataFactory.createLogData(
            id: 'log-2',
            estimateId: testEstimateId,
            activity: 'costEstimationRenamed',
            activityDetails: const {'oldName': 'Old', 'newName': 'New'},
          ),
        ];
        seedLogTable(testLogs);

        final expectedDtos = testLogs
            .map((data) => CostEstimationLogDto.fromJson(data))
            .toList();

        final result = await dataSource.getEstimationLogs(
          estimateId: testEstimateId,
          rangeFrom: 0,
          rangeTo: 9,
        );

        expect(result.length, 2);
        expect(result, expectedDtos);
      });

      test('uses correct table and filter parameters', () async {
        seedLogTable([
          LogTestDataFactory.createLogData(
            id: 'log-1',
            estimateId: testEstimateId,
            activity: 'costEstimationCreated',
          ),
        ]);

        await dataSource.getEstimationLogs(
          estimateId: testEstimateId,
          rangeFrom: 0,
          rangeTo: 9,
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectPaginated');
        expect(calls.length, 1);
        final call = calls.first;
        expect(call, {
          'table': DatabaseConstants.costEstimationLogsTable,
          'filterColumn': DatabaseConstants.estimateIdColumn,
          'filterValue': testEstimateId,
          'orderColumn': DatabaseConstants.loggedAtColumn,
          'ascending': false,
          'rangeFrom': 0,
          'rangeTo': 9,
          'method': 'selectPaginated',
          'columns': '*, user:user_profiles(*)',
        });
      });

      test('returns empty list when no logs exist', () async {
        final result = await dataSource.getEstimationLogs(
          estimateId: testEstimateId,
          rangeFrom: 0,
          rangeTo: 9,
        );

        expect(result, isEmpty);
      });

      test('converts JSON to CostEstimationLogDto correctly', () async {
        final testLog = LogTestDataFactory.createLogData(
          id: 'log-1',
          estimateId: testEstimateId,
          activity: 'costEstimationCreated',
          activityDetails: const {'name': 'Test'},
          firstName: 'Jane',
          lastName: 'Smith',
        );
        seedLogTable([testLog]);

        final expectedDto = CostEstimationLogDto.fromJson(testLog);

        final result = await dataSource.getEstimationLogs(
          estimateId: testEstimateId,
          rangeFrom: 0,
          rangeTo: 9,
        );

        expect(result.length, 1);
        final dto = result.first;
        expect(dto, isA<CostEstimationLogDto>());
        expect(dto, expectedDto);
      });

      test('propagates exceptions from supabase wrapper', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
        fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Network error';

        await expectLater(
          dataSource.getEstimationLogs(
            estimateId: testEstimateId,
            rangeFrom: 0,
            rangeTo: 9,
          ),
          throwsException,
        );
      });
    });
  });
}
