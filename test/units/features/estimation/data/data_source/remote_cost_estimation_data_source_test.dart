import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_estimation_data_helper.dart';

void main() {
  // Test constants
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
  const String markupValueTypePercentage = 'percentage';
  const String markupValueTypeAmount = 'amount';
  const String tableName = 'cost_estimates';
  const String allColumns = '*';
  const String selectMethod = 'select';
  const String timestamp4 = '2024-01-10T09:15:30.456Z';
  const String timestamp5 = '2024-01-15T14:30:45.123Z';
  const double defaultTotalCost = 100000.0;
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
        // Arrange
        final expectedEstimations = [
          TestEstimationDataHelper.createFakeEstimationData(
            id: estimateId1,
            estimateName: estimateName1,
            estimateDescription: estimateDesc1,
            creatorUserId: userId1,
          ),
          TestEstimationDataHelper.createFakeEstimationData(
            id: estimateId2,
            estimateName: estimateName2,
            estimateDescription: estimateDesc2,
            creatorUserId: userId2,
            totalCost: totalCost1,
            isLocked: true,
            lockedByUserId: userId2,
          ),
        ];

        fakeSupabaseWrapper.addTableData(tableName, expectedEstimations);

        // Act
        final result = await dataSource.getEstimations(testProjectId);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, equals(estimateId1));
        expect(result[0].projectId, equals(testProjectId));
        expect(result[0].estimateName, equals(estimateName1));
        expect(result[0].totalCost, equals(defaultTotalCost));
        expect(result[0].isLocked, isFalse);

        expect(result[1].id, equals(estimateId2));
        expect(result[1].projectId, equals(testProjectId));
        expect(result[1].estimateName, equals(estimateName2));
        expect(result[1].totalCost, equals(totalCost1));
        expect(result[1].isLocked, isTrue);
        expect(result[1].lockedByUserID, equals(userId2));
      });

      test('should return empty list when no estimations found', () async {
        // Arrange - no data added to fake wrapper

        // Act
        final result = await dataSource.getEstimations(testProjectId);

        // Assert
        expect(result, isEmpty);
      });

      test('should return empty list when no estimations for specific project', () async {
        // Arrange
        final otherProjectEstimations = [
          TestEstimationDataHelper.createFakeEstimationData(
            projectId: otherProjectId,
          ),
        ];

        fakeSupabaseWrapper.addTableData(tableName, otherProjectEstimations);

        // Act
        final result = await dataSource.getEstimations(testProjectId);

        // Assert
        expect(result, isEmpty);
      });

      test('should call supabaseWrapper.select with correct parameters', () async {
        // Arrange
        fakeSupabaseWrapper.addTableData(tableName, []);

        // Act
        await dataSource.getEstimations(testProjectId);

        // Assert
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(selectMethod);
        expect(methodCalls, hasLength(1));
        
        final call = methodCalls.first;
        expect(call['table'], equals(tableName));
        expect(call['filterColumn'], equals(DatabaseConstants.projectIdColumn));
        expect(call['filterValue'], equals(testProjectId));
        expect(call['columns'], equals(allColumns));
      });

      test('should rethrow exception when supabaseWrapper.select throws', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgDbConnection;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(testProjectId),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('should rethrow auth exception when supabaseWrapper.select throws auth error', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.auth;
        fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgAuth;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(testProjectId),
          throwsA(isA<supabase.AuthException>()),
        );
      });

      test('should rethrow socket exception when supabaseWrapper.select throws socket error', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.socket;
        fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgNetwork;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(testProjectId),
          throwsA(isA<Exception>()),
        );
      });

      test('should rethrow timeout exception when supabaseWrapper.select throws timeout error', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.timeout;
        fakeSupabaseWrapper.selectMultipleErrorMessage = errorMsgTimeout;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(testProjectId),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle CostEstimateDto.fromJson correctly with all field types', () async {
        // Arrange
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
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

        // Act
        final result = await dataSource.getEstimations(testProjectId);

        // Assert
        expect(result, hasLength(1));
        final estimation = result.first;
        
        expect(estimation.id, equals(estimateIdComplex));
        expect(estimation.projectId, equals(testProjectId));
        expect(estimation.estimateName, equals(estimateNameComplex));
        expect(estimation.estimateDescription, equals(estimateDescComplex));
        expect(estimation.creatorUserId, equals(userIdComplex));
        expect(estimation.markupType, equals(markupTypeGranular));
        expect(estimation.overallMarkupValueType, equals(markupValueTypeAmount));
        expect(estimation.overallMarkupValue, equals(overallMarkup3));
        expect(estimation.materialMarkupValueType, equals(markupValueTypePercentage));
        expect(estimation.materialMarkupValue, equals(materialMarkup3));
        expect(estimation.laborMarkupValueType, equals(markupValueTypeAmount));
        expect(estimation.laborMarkupValue, equals(laborMarkup4));
        expect(estimation.equipmentMarkupValueType, equals(markupValueTypePercentage));
        expect(estimation.equipmentMarkupValue, equals(equipmentMarkup2));
        expect(estimation.totalCost, equals(totalCostComplex));
        expect(estimation.isLocked, isTrue);
        expect(estimation.lockedByUserID, equals(userIdLocker));
        expect(estimation.lockedAt, equals(timestamp5));
        expect(estimation.createdAt, equals(timestamp4));
        expect(estimation.updatedAt, equals(timestamp5));
      });

      test('should filter estimations by project_id correctly', () async {
        // Arrange
        final mixedEstimations = [
          TestEstimationDataHelper.createFakeEstimationData(
            id: estimateId1,
            estimateName: estimateName3,
            estimateDescription: estimateDesc3,
          ),
          TestEstimationDataHelper.createFakeEstimationData(
            id: estimateId2,
            projectId: otherProjectId2,
            estimateName: estimateName4,
          ),
          TestEstimationDataHelper.createFakeEstimationData(
            id: estimateId3,
            estimateName: estimateName5,
            estimateDescription: estimateDesc5,
          ),
        ];

        fakeSupabaseWrapper.addTableData(tableName, mixedEstimations);

        // Act
        final result = await dataSource.getEstimations(testProjectId);

        // Assert
        expect(result, hasLength(2));
        expect(result.every((estimation) => estimation.projectId == testProjectId), isTrue);
        expect(result.map((e) => e.id), containsAll([estimateId1, estimateId3]));
      });
    });

    group('createEstimation', () {
      test('should create cost estimation successfully', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
          id: estimateId1,
          estimateName: estimateName1,
          estimateDescription: estimateDesc1,
          creatorUserId: userId1,
          totalCost: totalCost1,
          isLocked: false,
        );
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        final result = await dataSource.createEstimation(estimationDto);

        expect(result.id, isNotEmpty);
        expect(result.projectId, equals(testProjectId));
        expect(result.estimateName, equals(estimateName1));
        expect(result.estimateDescription, equals(estimateDesc1));
        expect(result.creatorUserId, equals(userId1));
        expect(result.totalCost, equals(totalCost1));
        expect(result.isLocked, isFalse);

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first['data']['id'], equals(estimateId1));
      });

      test('should create locked cost estimation successfully', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
          id: estimateId1,
          estimateName: estimateName1,
          estimateDescription: estimateDesc1,
          creatorUserId: userId1,
          totalCost: totalCost1,
          isLocked: true,
          lockedByUserId: userId2,
        );
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        final result = await dataSource.createEstimation(estimationDto);

        expect(result.isLocked, isTrue);
        expect(result.lockedByUserID, equals(userId2));
      });

      test('should call supabaseWrapper.insert with correct parameters', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
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
        expect(call['data']['id'], equals(estimateId1));
        expect(call['data']['estimate_name'], equals(estimateName1));
        expect(call['data']['creator_user_id'], equals(userId1));
        expect(call['data']['total_cost'], equals(totalCost1));
      });

      test('should exclude id from JSON when id is empty', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
          id: '',
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
        expect(call['data'].containsKey('id'), isFalse);
        expect(call['data']['estimate_name'], equals(estimateName1));
        expect(call['data']['creator_user_id'], equals(userId1));
        expect(call['data']['total_cost'], equals(totalCost1));
      });

      test('should rethrow exception when supabaseWrapper.insert throws', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
          id: estimateId1,
        );
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.insertErrorMessage = errorMsgDbConnection;

        expect(
          () => dataSource.createEstimation(estimationDto),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('should rethrow auth exception when supabaseWrapper.insert throws auth error', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
          id: estimateId1,
        );
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.auth;
        fakeSupabaseWrapper.insertErrorMessage = errorMsgAuth;

        expect(
          () => dataSource.createEstimation(estimationDto),
          throwsA(isA<supabase.AuthException>()),
        );
      });

      test('should rethrow network exception when supabaseWrapper.insert throws network error', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
          id: estimateId1,
        );
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.unknown;
        fakeSupabaseWrapper.insertErrorMessage = errorMsgNetwork;

        expect(
          () => dataSource.createEstimation(estimationDto),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle CostEstimateDto with all field types', () async {
        final estimationData = TestEstimationDataHelper.createFakeEstimationData(
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
        final estimationDto = CostEstimateDto.fromJson(estimationData);

        final result = await dataSource.createEstimation(estimationDto);

        expect(result.id, isNotEmpty);
        expect(result.projectId, equals(testProjectId));
        expect(result.estimateName, equals(estimateNameComplex));
        expect(result.estimateDescription, equals(estimateDescComplex));
        expect(result.creatorUserId, equals(userIdComplex));
        expect(result.markupType, equals(markupTypeGranular));
        expect(result.overallMarkupValueType, equals(markupValueTypeAmount));
        expect(result.overallMarkupValue, equals(overallMarkup3));
        expect(result.materialMarkupValueType, equals(markupValueTypePercentage));
        expect(result.materialMarkupValue, equals(materialMarkup3));
        expect(result.laborMarkupValueType, equals(markupValueTypeAmount));
        expect(result.laborMarkupValue, equals(laborMarkup4));
        expect(result.equipmentMarkupValueType, equals(markupValueTypePercentage));
        expect(result.equipmentMarkupValue, equals(equipmentMarkup2));
        expect(result.totalCost, equals(totalCostComplex));
        expect(result.isLocked, isTrue);
        expect(result.lockedByUserID, equals(userIdLocker));
        expect(result.lockedAt, equals(timestamp5));
        expect(result.createdAt, isNotEmpty);
        expect(result.updatedAt, isNotEmpty);
      });
    });
  });
}
