import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';

// Default constants used by the helper when specific fields are not provided
const String estimateIdDefault = 'estimate-default';
const String testProjectId = 'test-project-123';
const String estimateNameDefault = 'Default Estimate';
const String estimateDescDefault = 'Default estimate description';
const String userIdDefault = 'user-default';
const String markupTypeOverall = 'overall';
const String markupValueTypePercentage = 'percentage';
const double defaultOverallMarkup = 15.0;
const double defaultMaterialMarkup = 10.0;
const double defaultLaborMarkup = 20.0;
const double defaultEquipmentMarkup = 5.0;
const double defaultTotalCost = 100000.0;
const String emptyString = '';
const String defaultTimestamp = '2024-01-01T00:00:00.000Z';

/// Helper class to create fake cost estimation data for testing
class TestEstimationDataHelper {
  /// Creates a single fake cost estimation data with default values
  /// and ability to override specific fields
  static Map<String, dynamic> createFakeEstimationData({
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

  static CostEstimate createFakeEstimation({
    required String id,
    required String estimateName,
    double? totalCost,
  }) {
    return CostEstimate(
      id: id,
      projectId: testProjectId,
      estimateName: estimateName,
      estimateDescription: estimateDescDefault,
      creatorUserId: userIdDefault,
      markupConfiguration: const MarkupConfiguration(
        overallType: MarkupType.overall,
        overallValue: MarkupValue(
          type: MarkupValueType.percentage,
          value: 10.0,
        ),
      ),
      totalCost: totalCost,
      lockStatus: const LockStatus.unlocked(),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }
}
