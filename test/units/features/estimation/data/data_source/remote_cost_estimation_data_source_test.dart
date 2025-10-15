import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test constants
  const String testProjectId = 'test-project-123';
  const String otherProjectId = 'other-project-456';
  const String otherProjectId2 = 'other-project';
  const String estimateId1 = 'estimate-1';
  const String estimateId2 = 'estimate-2';
  const String estimateId3 = 'estimate-3';
  const String estimateIdComplex = 'estimate-complex';
  const String estimateIdDefault = 'estimate-default';
  const String userId1 = 'user-123';
  const String userId2 = 'user-456';
  const String userIdDefault = 'user-default';
  const String userIdComplex = 'user-complex';
  const String userIdLocker = 'user-locker';
  const String estimateName1 = 'Initial Estimate';
  const String estimateName2 = 'Revised Estimate';
  const String estimateName3 = 'Project 1 Estimate';
  const String estimateName4 = 'Other Project Estimate';
  const String estimateName5 = 'Another Project 1 Estimate';
  const String estimateNameComplex = 'Complex Estimate';
  const String estimateNameDefault = 'Default Estimate';
  const String estimateDesc1 = 'First cost estimate for the project';
  const String estimateDesc2 = 'Updated cost estimate with changes';
  const String estimateDesc3 = 'Estimate for project 1';
  const String estimateDesc5 = 'Another estimate for project 1';
  const String estimateDescComplex = 'Estimate with all field types';
  const String estimateDescDefault = 'Default estimate description';
  const String markupTypeOverall = 'overall';
  const String markupTypeGranular = 'granular';
  const String markupValueTypePercentage = 'percentage';
  const String markupValueTypeAmount = 'amount';
  const String tableName = 'cost_estimates';
  const String allColumns = '*';
  const String selectMethod = 'select';
  const String emptyString = '';
  const String defaultTimestamp = '2024-01-01T00:00:00.000Z';
  const String timestamp4 = '2024-01-10T09:15:30.456Z';
  const String timestamp5 = '2024-01-15T14:30:45.123Z';
  const double defaultOverallMarkup = 15.0;
  const double defaultMaterialMarkup = 10.0;
  const double defaultLaborMarkup = 20.0;
  const double defaultEquipmentMarkup = 5.0;
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

  /// Helper method to create fake cost estimation data with default values
  /// and ability to override specific fields
  Map<String, dynamic> createFakeEstimationData({
    String? id,
    String? projectId,
    String? estimateName,
    String? estimateDescription,
    String? creatorUserId,
    String? markupType,
    String? overallMarkupValueType,
    double? overallMarkupValue,
    String? materialMarkupValueType,
    double? materialMarkupValue,
    String? laborMarkupValueType,
    double? laborMarkupValue,
    String? equipmentMarkupValueType,
    double? equipmentMarkupValue,
    double? totalCost,
    bool? isLocked,
    String? lockedByUserId,
    String? lockedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return {
      'id': id ?? estimateIdDefault,
      'project_id': projectId ?? testProjectId,
      'estimate_name': estimateName ?? estimateNameDefault,
      'estimate_description': estimateDescription ?? estimateDescDefault,
      'creator_user_id': creatorUserId ?? userIdDefault,
      'markup_type': markupType ?? markupTypeOverall,
      'overall_markup_value_type': overallMarkupValueType ?? markupValueTypePercentage,
      'overall_markup_value': overallMarkupValue ?? defaultOverallMarkup,
      'material_markup_value_type': materialMarkupValueType ?? markupValueTypePercentage,
      'material_markup_value': materialMarkupValue ?? defaultMaterialMarkup,
      'labor_markup_value_type': laborMarkupValueType ?? markupValueTypePercentage,
      'labor_markup_value': laborMarkupValue ?? defaultLaborMarkup,
      'equipment_markup_value_type': equipmentMarkupValueType ?? markupValueTypePercentage,
      'equipment_markup_value': equipmentMarkupValue ?? defaultEquipmentMarkup,
      'total_cost': totalCost ?? defaultTotalCost,
      'is_locked': isLocked ?? false,
      'locked_by_user_id': lockedByUserId ?? emptyString,
      'locked_at': lockedAt ?? emptyString,
      'created_at': createdAt ?? defaultTimestamp,
      'updated_at': updatedAt ?? defaultTimestamp,
    };
  }
  
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
          createFakeEstimationData(
            id: estimateId1,
            estimateName: estimateName1,
            estimateDescription: estimateDesc1,
            creatorUserId: userId1,
          ),
          createFakeEstimationData(
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
          createFakeEstimationData(
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
        final estimationData = createFakeEstimationData(
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
          createFakeEstimationData(
            id: estimateId1,
            estimateName: estimateName3,
            estimateDescription: estimateDesc3,
          ),
          createFakeEstimationData(
            id: estimateId2,
            projectId: otherProjectId2,
            estimateName: estimateName4,
          ),
          createFakeEstimationData(
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
  });
}
