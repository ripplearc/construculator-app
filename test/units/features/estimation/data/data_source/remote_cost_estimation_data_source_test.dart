import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/estimation_test_data_map_factory.dart';

void main() {
  const String testProjectId = 'test-project-123';
  const String otherProjectId = 'other-project-456';
  const String otherProjectId2 = 'other-project';
  const String estimateId1 = 'estimate-1';
  const String estimateId2 = 'estimate-2';
  const String estimateId3 = 'estimate-3';
  const String estimateIdComplex = 'estimate-complex';
  const String userId1 = 'user-123';
  const String userId2 = 'user-456';
  const String userIdComplex = 'user-complex';
  const String userIdLocker = 'user-locker';
  const String estimateName1 = 'Initial Estimate';
  const String estimateName2 = 'Revised Estimate';
  const String estimateName3 = 'Project 1 Estimate';
  const String estimateName4 = 'Other Project Estimate';
  const String estimateName5 = 'Another Project 1 Estimate';
  const String estimateNameComplex = 'Complex Estimate';
  const String estimateDesc1 = 'First cost estimate for the project';
  const String estimateDesc2 = 'Updated cost estimate with changes';
  const String estimateDesc3 = 'Estimate for project 1';
  const String estimateDesc5 = 'Another estimate for project 1';
  const String estimateDescComplex = 'Estimate with all field types';
  const String markupTypeGranular = 'granular';
  const String markupValueTypeAmount = 'amount';
  const String tableName = 'cost_estimates';
  const String allColumns = '*';
  const String selectMethod = 'select';
  const String timestamp4 = '2024-01-10T09:15:30.456Z';
  const String timestamp5 = '2024-01-15T14:30:45.123Z';
  const double totalCost1 = 120000.0;
  const double totalCostComplex = 150000.75;
  const double overallMarkup3 = 7500.0;
  const double materialMarkup3 = 15.5;
  const double laborMarkup4 = 2500.0;
  const double equipmentMarkup2 = 7.5;
  const String errorMsgDbConnection = 'Database connection failed';
  const String errorMsgAuth = 'Authentication failed';
  const String errorMsgNetwork = 'Network connection failed';
  const String errorMsgTimeout = 'Request timeout';

  group('RemoteCostEstimationDataSource', () {
    late RemoteCostEstimationDataSource dataSource;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    setUp(() {
      fakeClock = FakeClockImpl();
      fakeSupabaseWrapper = FakeSupabaseWrapper(clock: fakeClock);
      dataSource = RemoteCostEstimationDataSource(
        supabaseWrapper: fakeSupabaseWrapper,
      );
    });

    tearDown(() {
      fakeSupabaseWrapper.reset();
    });

    group('getEstimations', () {
      test('should return cost estimations when data exists', () async {
        final data1 = EstimationTestDataMapFactory.createFakeEstimationData(
          id: estimateId1,
          estimateName: estimateName1,
          estimateDescription: estimateDesc1,
          creatorUserId: userId1,
        );
        final data2 = EstimationTestDataMapFactory.createFakeEstimationData(
          id: estimateId2,
          estimateName: estimateName2,
          estimateDescription: estimateDesc2,
          creatorUserId: userId2,
          totalCost: totalCost1,
          isLocked: true,
          lockedByUserId: userId2,
        );
        final expectedEstimations = [data1, data2];

        fakeSupabaseWrapper.addTableData(tableName, expectedEstimations);

        final result = await dataSource.getEstimations(testProjectId);

        final expectedDto1 = CostEstimateDto.fromJson(data1);
        final expectedDto2 = CostEstimateDto.fromJson(data2);

        expect(result, hasLength(2));
        expect(result[0], equals(expectedDto1));

        expect(result[1], equals(expectedDto2));
      });

      test('should return empty list when no estimations found', () async {
        final result = await dataSource.getEstimations(testProjectId);

        expect(result, isEmpty);
      });

      test(
        'should return empty list when no estimations for specific project',
        () async {
          final otherProjectEstimations = [
            EstimationTestDataMapFactory.createFakeEstimationData(
              projectId: otherProjectId,
            ),
          ];

          fakeSupabaseWrapper.addTableData(tableName, otherProjectEstimations);

          final result = await dataSource.getEstimations(testProjectId);

          expect(result, isEmpty);
        },
      );

      test(
        'should call supabaseWrapper.select with correct parameters',
        () async {
          fakeSupabaseWrapper.addTableData(tableName, []);

          await dataSource.getEstimations(testProjectId);

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
            selectMethod,
          );
          expect(methodCalls, hasLength(1));

          final call = methodCalls.first;
          expect(call['table'], equals(tableName));
          expect(
            call['filterColumn'],
            equals(DatabaseConstants.projectIdColumn),
          );
          expect(call['filterValue'], equals(testProjectId));
          expect(call['columns'], equals(allColumns));
        },
      );

      test(
        'should rethrow exception when supabaseWrapper.select throws',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
          fakeSupabaseWrapper.selectMultipleExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgDbConnection;

          expect(
            () => dataSource.getEstimations(testProjectId),
            throwsA(isA<supabase.PostgrestException>()),
          );
        },
      );

      test(
        'should rethrow auth exception when supabaseWrapper.select throws auth error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
          fakeSupabaseWrapper.selectMultipleExceptionType =
              SupabaseExceptionType.auth;
          fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgAuth;

          expect(
            () => dataSource.getEstimations(testProjectId),
            throwsA(isA<supabase.AuthException>()),
          );
        },
      );

      test(
        'should rethrow socket exception when supabaseWrapper.select throws socket error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
          fakeSupabaseWrapper.selectMultipleExceptionType =
              SupabaseExceptionType.socket;
          fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgNetwork;

          expect(
            () => dataSource.getEstimations(testProjectId),
            throwsA(isA<Exception>()),
          );
        },
      );

      test(
        'should rethrow timeout exception when supabaseWrapper.select throws timeout error',
        () async {
          fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
          fakeSupabaseWrapper.selectMultipleExceptionType =
              SupabaseExceptionType.timeout;
          fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgTimeout;

          expect(
            () => dataSource.getEstimations(testProjectId),
            throwsA(isA<Exception>()),
          );
        },
      );

      test(
        'should handle CostEstimateDto.fromJson correctly with all field types',
        () async {
          final estimationData =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: estimateIdComplex,
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
                createdAt: timestamp4,
                updatedAt: timestamp5,
              );

          fakeSupabaseWrapper.addTableData(tableName, [estimationData]);

          final result = await dataSource.getEstimations(testProjectId);

          expect(result, hasLength(1));
          final estimation = result.first;
          final expectedFromJsonDto = CostEstimateDto.fromJson(estimationData);

          expect(estimation, equals(expectedFromJsonDto));
        },
      );

      test('should filter estimations by project_id correctly', () async {
        final mixedEstimations = [
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: estimateId1,
            estimateName: estimateName3,
            estimateDescription: estimateDesc3,
          ),
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: estimateId2,
            projectId: otherProjectId2,
            estimateName: estimateName4,
          ),
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: estimateId3,
            estimateName: estimateName5,
            estimateDescription: estimateDesc5,
          ),
        ];

        fakeSupabaseWrapper.addTableData(tableName, mixedEstimations);

        final result = await dataSource.getEstimations(testProjectId);

        expect(result, hasLength(2));
        expect(
          result.every((estimation) => estimation.projectId == testProjectId),
          isTrue,
        );
        expect(
          result.map((e) => e.id),
          containsAll([estimateId1, estimateId3]),
        );
      });
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
  });
}
