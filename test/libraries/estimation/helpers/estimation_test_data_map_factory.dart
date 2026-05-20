const String estimateIdDefault = 'estimate-1';
const String testProjectId = 'test-project-123';
const String estimateNameDefault = 'Initial Estimate';
const String estimateDescDefault = 'Initial cost estimate';
const String userIdDefault = 'user-123';

const String markupTypeOverall = 'overall';
const String markupTypeGranular = 'granular';
const String markupValueTypePercentage = 'percentage';
const String markupValueTypeAmount = 'amount';

const double overallMarkupDefault = 10.0;
const double materialMarkupDefault = 7.5;
const double laborMarkupDefault = 12.5;
const double equipmentMarkupDefault = 5.0;
const double totalCostDefault = 100000.0;

const String timestampDefault = '2024-01-01T10:00:00.000Z';

class EstimationTestDataMapFactory {
  static const String _defaultIsoTimestamp = timestampDefault;

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
      'overall_markup_value_type':
          overallMarkupValueType ?? markupValueTypePercentage,
      'overall_markup_value': overallMarkupValue ?? overallMarkupDefault,
      'material_markup_value_type':
          materialMarkupValueType ?? markupValueTypePercentage,
      'material_markup_value': materialMarkupValue ?? materialMarkupDefault,
      'labor_markup_value_type':
          laborMarkupValueType ?? markupValueTypePercentage,
      'labor_markup_value': laborMarkupValue ?? laborMarkupDefault,
      'equipment_markup_value_type':
          equipmentMarkupValueType ?? markupValueTypePercentage,
      'equipment_markup_value': equipmentMarkupValue ?? equipmentMarkupDefault,
      'total_cost': totalCost ?? totalCostDefault,
      'is_locked': isLocked ?? false,
      'locked_by_user_id': lockedByUserId,
      'locked_at': lockedAt,
      'created_at': createdAt ?? _defaultIsoTimestamp,
      'updated_at': updatedAt ?? _defaultIsoTimestamp,
    };
  }
}
