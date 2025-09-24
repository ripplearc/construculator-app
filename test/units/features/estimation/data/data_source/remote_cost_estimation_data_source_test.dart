import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:test/test.dart';

void main() {
  group('RemoteCostEstimationDataSource', () {
    // Test constants
    const String _testProjectId = 'test-project-123';
    const String _otherProjectId = 'other-project-456';
    const String _otherProjectId2 = 'other-project';
    const String _estimateId1 = 'estimate-1';
    const String _estimateId2 = 'estimate-2';
    const String _estimateId3 = 'estimate-3';
    const String _estimateIdComplex = 'estimate-complex';
    const String _estimateIdDefault = 'estimate-default';
    const String _userId1 = 'user-123';
    const String _userId2 = 'user-456';
    const String _userIdDefault = 'user-default';
    const String _userIdComplex = 'user-complex';
    const String _userIdLocker = 'user-locker';
    const String _estimateName1 = 'Initial Estimate';
    const String _estimateName2 = 'Revised Estimate';
    const String _estimateName3 = 'Project 1 Estimate';
    const String _estimateName4 = 'Other Project Estimate';
    const String _estimateName5 = 'Another Project 1 Estimate';
    const String _estimateNameComplex = 'Complex Estimate';
    const String _estimateNameDefault = 'Default Estimate';
    const String _estimateDesc1 = 'First cost estimate for the project';
    const String _estimateDesc2 = 'Updated cost estimate with changes';
    const String _estimateDesc3 = 'Estimate for project 1';
    const String _estimateDesc5 = 'Another estimate for project 1';
    const String _estimateDescComplex = 'Estimate with all field types';
    const String _estimateDescDefault = 'Default estimate description';
    const String _markupTypeOverall = 'overall';
    const String _markupTypeGranular = 'granular';
    const String _markupValueTypePercentage = 'percentage';
    const String _markupValueTypeAmount = 'amount';
    const String _tableName = 'cost_estimates';
    const String _allColumns = '*';
    const String _selectMethod = 'select';
    const String _emptyString = '';
    const String _defaultTimestamp = '2024-01-01T00:00:00.000Z';
    const String _timestamp4 = '2024-01-10T09:15:30.456Z';
    const String _timestamp5 = '2024-01-15T14:30:45.123Z';
    const double _defaultOverallMarkup = 15.0;
    const double _defaultMaterialMarkup = 10.0;
    const double _defaultLaborMarkup = 20.0;
    const double _defaultEquipmentMarkup = 5.0;
    const double _defaultTotalCost = 100000.0;
    const double _totalCost1 = 120000.0;
    const double _totalCostComplex = 150000.75;
    const double _overallMarkup3 = 7500.0;
    const double _materialMarkup3 = 15.5;
    const double _laborMarkup4 = 2500.0;
    const double _equipmentMarkup2 = 7.5;
    const String _errorMsgDbConnection = 'Database connection failed';
    const String _errorMsgAuth = 'Authentication failed';
    const String _errorMsgNetwork = 'Network connection failed';
    const String _errorMsgTimeout = 'Request timeout';

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
        'id': id ?? _estimateIdDefault,
        'project_id': projectId ?? _testProjectId,
        'estimate_name': estimateName ?? _estimateNameDefault,
        'estimate_description': estimateDescription ?? _estimateDescDefault,
        'creator_user_id': creatorUserId ?? _userIdDefault,
        'markup_type': markupType ?? _markupTypeOverall,
        'overall_markup_value_type': overallMarkupValueType ?? _markupValueTypePercentage,
        'overall_markup_value': overallMarkupValue ?? _defaultOverallMarkup,
        'material_markup_value_type': materialMarkupValueType ?? _markupValueTypePercentage,
        'material_markup_value': materialMarkupValue ?? _defaultMaterialMarkup,
        'labor_markup_value_type': laborMarkupValueType ?? _markupValueTypePercentage,
        'labor_markup_value': laborMarkupValue ?? _defaultLaborMarkup,
        'equipment_markup_value_type': equipmentMarkupValueType ?? _markupValueTypePercentage,
        'equipment_markup_value': equipmentMarkupValue ?? _defaultEquipmentMarkup,
        'total_cost': totalCost ?? _defaultTotalCost,
        'is_locked': isLocked ?? false,
        'locked_by_user_id': lockedByUserId ?? _emptyString,
        'locked_at': lockedAt ?? _emptyString,
        'created_at': createdAt ?? _defaultTimestamp,
        'updated_at': updatedAt ?? _defaultTimestamp,
      };
    }

    group('getEstimations', () {

      test('should return cost estimations when data exists', () async {
        // Arrange
        final expectedEstimations = [
          createFakeEstimationData(
            id: _estimateId1,
            estimateName: _estimateName1,
            estimateDescription: _estimateDesc1,
            creatorUserId: _userId1,
          ),
          createFakeEstimationData(
            id: _estimateId2,
            estimateName: _estimateName2,
            estimateDescription: _estimateDesc2,
            creatorUserId: _userId2,
            totalCost: _totalCost1,
            isLocked: true,
            lockedByUserId: _userId2,
          ),
        ];

        fakeSupabaseWrapper.addTableData(_tableName, expectedEstimations);

        // Act
        final result = await dataSource.getEstimations(_testProjectId);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, equals(_estimateId1));
        expect(result[0].projectId, equals(_testProjectId));
        expect(result[0].estimateName, equals(_estimateName1));
        expect(result[0].totalCost, equals(_defaultTotalCost));
        expect(result[0].isLocked, isFalse);

        expect(result[1].id, equals(_estimateId2));
        expect(result[1].projectId, equals(_testProjectId));
        expect(result[1].estimateName, equals(_estimateName2));
        expect(result[1].totalCost, equals(_totalCost1));
        expect(result[1].isLocked, isTrue);
        expect(result[1].lockedByUserID, equals(_userId2));
      });

      test('should return empty list when no estimations found', () async {
        // Arrange - no data added to fake wrapper

        // Act
        final result = await dataSource.getEstimations(_testProjectId);

        // Assert
        expect(result, isEmpty);
      });

      test('should return empty list when no estimations for specific project', () async {
        // Arrange
        final otherProjectEstimations = [
          createFakeEstimationData(
            projectId: _otherProjectId,
          ),
        ];

        fakeSupabaseWrapper.addTableData(_tableName, otherProjectEstimations);

        // Act
        final result = await dataSource.getEstimations(_testProjectId);

        // Assert
        expect(result, isEmpty);
      });

      test('should call supabaseWrapper.select with correct parameters', () async {
        // Arrange
        fakeSupabaseWrapper.addTableData(_tableName, []);

        // Act
        await dataSource.getEstimations(_testProjectId);

        // Assert
        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(_selectMethod);
        expect(methodCalls, hasLength(1));
        
        final call = methodCalls.first;
        expect(call['table'], equals(_tableName));
        expect(call['filterColumn'], equals(DatabaseConstants.projectIdColumn));
        expect(call['filterValue'], equals(_testProjectId));
        expect(call['columns'], equals(_allColumns));
      });

      test('should rethrow exception when supabaseWrapper.select throws', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.selectMultipleErrorMessage = _errorMsgDbConnection;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(_testProjectId),
          throwsA(isA<supabase.PostgrestException>()),
        );
      });

      test('should rethrow auth exception when supabaseWrapper.select throws auth error', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.auth;
        fakeSupabaseWrapper.selectMultipleErrorMessage = _errorMsgAuth;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(_testProjectId),
          throwsA(isA<supabase.AuthException>()),
        );
      });

      test('should rethrow socket exception when supabaseWrapper.select throws socket error', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.socket;
        fakeSupabaseWrapper.selectMultipleErrorMessage = _errorMsgNetwork;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(_testProjectId),
          throwsA(isA<Exception>()),
        );
      });

      test('should rethrow timeout exception when supabaseWrapper.select throws timeout error', () async {
        // Arrange
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType = SupabaseExceptionType.timeout;
        fakeSupabaseWrapper.selectMultipleErrorMessage = _errorMsgTimeout;

        // Act & Assert
        expect(
          () => dataSource.getEstimations(_testProjectId),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle CostEstimateDto.fromJson correctly with all field types', () async {
        // Arrange
        final estimationData = createFakeEstimationData(
          id: _estimateIdComplex,
          estimateName: _estimateNameComplex,
          estimateDescription: _estimateDescComplex,
          creatorUserId: _userIdComplex,
          markupType: _markupTypeGranular,
          overallMarkupValueType: _markupValueTypeAmount,
          overallMarkupValue: _overallMarkup3,
          materialMarkupValue: _materialMarkup3,
          laborMarkupValueType: _markupValueTypeAmount,
          laborMarkupValue: _laborMarkup4,
          equipmentMarkupValue: _equipmentMarkup2,
          totalCost: _totalCostComplex,
          isLocked: true,
          lockedByUserId: _userIdLocker,
          lockedAt: _timestamp5,
          createdAt: _timestamp4,
          updatedAt: _timestamp5,
        );

        fakeSupabaseWrapper.addTableData(_tableName, [estimationData]);

        // Act
        final result = await dataSource.getEstimations(_testProjectId);

        // Assert
        expect(result, hasLength(1));
        final estimation = result.first;
        
        expect(estimation.id, equals(_estimateIdComplex));
        expect(estimation.projectId, equals(_testProjectId));
        expect(estimation.estimateName, equals(_estimateNameComplex));
        expect(estimation.estimateDescription, equals(_estimateDescComplex));
        expect(estimation.creatorUserId, equals(_userIdComplex));
        expect(estimation.markupType, equals(_markupTypeGranular));
        expect(estimation.overallMarkupValueType, equals(_markupValueTypeAmount));
        expect(estimation.overallMarkupValue, equals(_overallMarkup3));
        expect(estimation.materialMarkupValueType, equals(_markupValueTypePercentage));
        expect(estimation.materialMarkupValue, equals(_materialMarkup3));
        expect(estimation.laborMarkupValueType, equals(_markupValueTypeAmount));
        expect(estimation.laborMarkupValue, equals(_laborMarkup4));
        expect(estimation.equipmentMarkupValueType, equals(_markupValueTypePercentage));
        expect(estimation.equipmentMarkupValue, equals(_equipmentMarkup2));
        expect(estimation.totalCost, equals(_totalCostComplex));
        expect(estimation.isLocked, isTrue);
        expect(estimation.lockedByUserID, equals(_userIdLocker));
        expect(estimation.lockedAt, equals(_timestamp5));
        expect(estimation.createdAt, equals(_timestamp4));
        expect(estimation.updatedAt, equals(_timestamp5));
      });

      test('should filter estimations by project_id correctly', () async {
        // Arrange
        final mixedEstimations = [
          createFakeEstimationData(
            id: _estimateId1,
            estimateName: _estimateName3,
            estimateDescription: _estimateDesc3,
          ),
          createFakeEstimationData(
            id: _estimateId2,
            projectId: _otherProjectId2,
            estimateName: _estimateName4,
          ),
          createFakeEstimationData(
            id: _estimateId3,
            estimateName: _estimateName5,
            estimateDescription: _estimateDesc5,
          ),
        ];

        fakeSupabaseWrapper.addTableData(_tableName, mixedEstimations);

        // Act
        final result = await dataSource.getEstimations(_testProjectId);

        // Assert
        expect(result, hasLength(2));
        expect(result.every((estimation) => estimation.projectId == _testProjectId), isTrue);
        expect(result.map((e) => e.id), containsAll([_estimateId1, _estimateId3]));
      });
    });
  });
}
