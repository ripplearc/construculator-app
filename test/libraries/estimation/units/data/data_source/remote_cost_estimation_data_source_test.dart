import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../helpers/estimation_test_data_map_factory.dart';

void main() {
  const String estimateId1 = 'estimate-1';
  const String estimateName1 = 'Initial Estimate';
  const String tableName = 'cost_estimates';
  const String errorMsgDbConnection = 'Database connection failed';

  group('RemoteCostEstimationDataSource', () {
    late RemoteCostEstimationDataSource dataSource;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    setUpAll(() {
      fakeClock = FakeClockImpl();
      fakeSupabaseWrapper = FakeSupabaseWrapper(clock: fakeClock);
      Modular.init(
        _TestAppModule(
          FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabaseWrapper),
        ),
      );
      dataSource =
          Modular.get<CostEstimationDataSource>()
              as RemoteCostEstimationDataSource;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    group('getEstimationById', () {
      test('should return the DTO for the matching row', () async {
        fakeSupabaseWrapper.addTableData(tableName, [
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: estimateId1,
            estimateName: estimateName1,
          ),
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: 'estimate-2',
            estimateName: 'Other Estimate',
          ),
        ]);

        final result = await dataSource.getEstimationById(estimateId1);

        expect(result!.id, equals(estimateId1));
        expect(result.estimateName, equals(estimateName1));
      });

      test('should return null when no row has the ID', () async {
        fakeSupabaseWrapper.addTableData(tableName, [
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: 'estimate-2',
          ),
        ]);

        final result = await dataSource.getEstimationById(estimateId1);

        expect(result, isNull);
      });

      test('should filter by the id column on the estimates table', () async {
        await dataSource.getEstimationById(estimateId1);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'selectSingle',
        );
        expect(methodCalls, hasLength(1));
        expect(
          methodCalls.first,
          equals({
            'method': 'selectSingle',
            'table': tableName,
            'columns': '*',
            'filterColumn': DatabaseConstants.idColumn,
            'filterValue': estimateId1,
          }),
        );
      });

      test('should rethrow exception when selectSingle throws', () async {
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectExceptionType =
            SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.selectErrorMessage = errorMsgDbConnection;

        await expectLater(
          () => dataSource.getEstimationById(estimateId1),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });
    });
  });
}

class _TestAppModule extends Module {
  final AppBootstrap appBootstrap;

  _TestAppModule(this.appBootstrap);

  @override
  List<Module> get imports => [EstimationLibraryModule(appBootstrap)];
}
