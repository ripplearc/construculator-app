import 'dart:io';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
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
  const String userId1 = 'user-123';
  const String userIdComplex = 'user-complex';
  const String userIdLocker = 'user-locker';
  const String estimateName1 = 'Initial Estimate';
  const String estimateNameComplex = 'Complex Estimate';
  const String estimateDesc1 = 'First cost estimate for the project';
  const String estimateDescComplex = 'Estimate with all field types';
  const String markupTypeGranular = 'granular';
  const String markupValueTypeAmount = 'amount';
  const String tableName = 'cost_estimates';
  const String timestamp5 = '2024-01-15T14:30:45.123Z';
  const double totalCost1 = 120000.0;
  const double totalCostComplex = 150000.75;
  const double overallMarkup3 = 7500.0;
  const double materialMarkup3 = 15.5;
  const double laborMarkup4 = 2500.0;
  const double equipmentMarkup2 = 7.5;
  const String errorMsgDbConnection = 'Database connection failed';
  const String errorMsgNetwork = 'Network connection failed';
  const String errorMsgTimeout = 'Request timeout';

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

    group('createEstimation', () {
      test('should create cost estimation successfully', () async {
        final estimationData =
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: '1',
              estimateName: estimateName1,
              estimateDescription: estimateDesc1,
              creatorUserId: userId1,
              totalCost: totalCost1,
              isLocked: false,
              createdAt: fakeClock.now().toIso8601String(),
              updatedAt: fakeClock.now().toIso8601String(),
            );
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        final result = await dataSource.createEstimation(estimationDto);

        expect(result, equals(estimationDto));
      });

      test(
        'should call supabaseWrapper.insert with correct parameters',
        () async {
          final estimationData =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: estimateId1,
                estimateName: estimateName1,
                creatorUserId: userId1,
                totalCost: totalCost1,
              );
          final estimationDto = CostEstimateDto.fromJson(estimationData);

          await dataSource.createEstimation(estimationDto);

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(call['table'], equals(tableName));
          expect(call['data']['estimate_name'], equals(estimateName1));
          expect(call['data']['creator_user_id'], equals(userId1));
          expect(call['data']['total_cost'], equals(totalCost1));
        },
      );

      test(
        'should rethrow exception when supabaseWrapper.insert throws',
        () async {
          final estimationData =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: estimateId1,
              );
          final estimationDto = CostEstimateDto.fromJson(estimationData);

          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.insertErrorMessage = errorMsgDbConnection;

          expect(
            () => dataSource.createEstimation(estimationDto),
            throwsA(isA<supabase.PostgrestException>()),
          );
        },
      );

      test(
        'should rethrow network exception when supabaseWrapper.insert throws network error',
        () async {
          final estimationData =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: estimateId1,
              );
          final estimationDto = CostEstimateDto.fromJson(estimationData);

          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.insertErrorMessage = errorMsgNetwork;

          expect(
            () => dataSource.createEstimation(estimationDto),
            throwsA(isA<SocketException>()),
          );
        },
      );

      test('should handle CostEstimateDto with all field types', () async {
        final estimationData =
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: '1',
              estimateName: estimateNameComplex,
              estimateDescription: estimateDescComplex,
              creatorUserId: userIdComplex,
              markupType: markupTypeGranular,
              overallMarkupValueType: markupValueTypeAmount,
              overallMarkupValue: overallMarkup3,
              materialMarkupValue: materialMarkup3,
              laborMarkupValueType: markupValueTypeAmount,
              laborMarkupValue: laborMarkup4,
              equipmentMarkupValue: equipmentMarkup2,
              totalCost: totalCostComplex,
              isLocked: true,
              lockedByUserId: userIdLocker,
              lockedAt: timestamp5,
              createdAt: fakeClock.now().toIso8601String(),
              updatedAt: fakeClock.now().toIso8601String(),
            );
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        final result = await dataSource.createEstimation(estimationDto);

        expect(result, equals(estimationDto));
      });
    });

    group('deleteEstimation', () {
      test(
        'should call supabaseWrapper.delete with correct parameters',
        () async {
          final estimationData =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: estimateId1,
                estimateName: estimateName1,
                estimateDescription: estimateDesc1,
                creatorUserId: userId1,
                totalCost: totalCost1,
                isLocked: false,
                createdAt: fakeClock.now().toIso8601String(),
                updatedAt: fakeClock.now().toIso8601String(),
              );
          fakeSupabaseWrapper.addTableData(tableName, [estimationData]);
          await dataSource.deleteEstimation(estimateId1);

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('delete');
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(call['table'], equals(tableName));
          expect(call['filterColumn'], equals('id'));
          expect(call['filterValue'], equals(estimateId1));
        },
      );

      test(
        'should rethrow exception when supabaseWrapper.delete throws',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.deleteErrorMessage = errorMsgDbConnection;

          expect(
            () => dataSource.deleteEstimation(estimateId1),
            throwsA(isA<supabase.PostgrestException>()),
          );
        },
      );

      test(
        'should rethrow network exception when supabaseWrapper.delete throws network error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.deleteErrorMessage = errorMsgNetwork;

          expect(
            () => dataSource.deleteEstimation(estimateId1),
            throwsA(isA<SocketException>()),
          );
        },
      );

      test(
        'should rethrow timeout exception when supabaseWrapper.delete throws timeout error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.deleteErrorMessage = errorMsgTimeout;

          expect(
            () => dataSource.deleteEstimation(estimateId1),
            throwsA(isA<Exception>()),
          );
        },
      );
    });

    group('changeLockStatus', () {
      test('should lock estimation and return updated DTO', () async {
        final estimationData =
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: estimateId1,
              estimateName: estimateName1,
              creatorUserId: userId1,
              isLocked: false,
            );
        fakeSupabaseWrapper.addTableData(tableName, [estimationData]);

        final result = await dataSource.changeLockStatus(
          estimationId: estimateId1,
          isLocked: true,
        );

        expect(result.isLocked, isTrue);
      });

      test('should unlock estimation and return updated DTO', () async {
        final estimationData =
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: estimateId1,
              estimateName: estimateName1,
              creatorUserId: userId1,
              isLocked: true,
              lockedByUserId: userId1,
              lockedAt: timestamp5,
            );
        fakeSupabaseWrapper.addTableData(tableName, [estimationData]);

        final result = await dataSource.changeLockStatus(
          estimationId: estimateId1,
          isLocked: false,
        );

        expect(result.isLocked, isFalse);
      });

      test(
        'should call supabaseWrapper.update with correct parameters when locking',
        () async {
          final estimationData =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: estimateId1,
                isLocked: false,
              );
          fakeSupabaseWrapper.addTableData(tableName, [estimationData]);

          await dataSource.changeLockStatus(
            estimationId: estimateId1,
            isLocked: true,
          );

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(call['table'], equals(tableName));
          expect(call['data']['is_locked'], isTrue);
          expect(call['filterColumn'], equals('id'));
          expect(call['filterValue'], equals(estimateId1));
        },
      );

      test(
        'should rethrow exception when supabaseWrapper.update throws',
        () async {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.updateErrorMessage = errorMsgDbConnection;

          await expectLater(
            () => dataSource.changeLockStatus(
              estimationId: estimateId1,
              isLocked: true,
            ),
            throwsA(isA<supabase.PostgrestException>()),
          );
        },
      );
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

    group('renameEstimation', () {
      const String newEstimateName = 'Updated Estimate Name';

      test('should rename estimation and return updated DTO', () async {
        final estimationData =
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: estimateId1,
              estimateName: estimateName1,
              creatorUserId: userId1,
            );
        fakeSupabaseWrapper.addTableData(tableName, [estimationData]);

        final result = await dataSource.renameEstimation(
          estimationId: estimateId1,
          newName: newEstimateName,
        );

        expect(result.estimateName, equals(newEstimateName));
      });

      test(
        'should call supabaseWrapper.update with correct parameters',
        () async {
          final estimationData =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: estimateId1,
                estimateName: estimateName1,
              );
          fakeSupabaseWrapper.addTableData(tableName, [estimationData]);

          await dataSource.renameEstimation(
            estimationId: estimateId1,
            newName: newEstimateName,
          );

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(
            call,
            equals({
              'method': 'update',
              'table': tableName,
              'data': {DatabaseConstants.estimateNameColumn: newEstimateName},
              'filterColumn': DatabaseConstants.idColumn,
              'filterValue': estimateId1,
            }),
          );
        },
      );

      test(
        'should rethrow exception when supabaseWrapper.update throws',
        () async {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.updateErrorMessage = errorMsgDbConnection;

          await expectLater(
            () => dataSource.renameEstimation(
              estimationId: estimateId1,
              newName: newEstimateName,
            ),
            throwsA(isA<supabase.PostgrestException>()),
          );
        },
      );
    });
  });
}

class _TestAppModule extends Module {
  final AppBootstrap appBootstrap;

  _TestAppModule(this.appBootstrap);

  @override
  List<Module> get imports => [EstimationLibraryModule(appBootstrap)];
}
