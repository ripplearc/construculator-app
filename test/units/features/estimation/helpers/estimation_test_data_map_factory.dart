const String estimateIdDefault = 'estimate-default';
const String testProjectId = 'test-project-123';
const String estimateNameDefault = 'Default Estimate';
const String estimateDescDefault = 'Default estimate description';
const String userIdDefault = 'user-default';
const String markupTypeOverall = 'overall';
const String markupValueTypePercentage = 'percentage';
const double overallMarkupDefault = 15.0;
const double materialMarkupDefault = 10.0;
const double laborMarkupDefault = 20.0;
const double equipmentMarkupDefault = 5.0;
const double totalCostDefault = 100000.0;
const String emptyString = '';
const String timestampDefault = '2024-01-01T00:00:00.000Z';

/// Fixture factory that produces estimation records as map payloads for tests.
class EstimationTestDataMapFactory {
  /// Builds a map shaped like an estimation record, allowing targeted overrides.
  ///
  /// Only provide the fields you want to customize; all others fall back to
  /// sensible test defaults.
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
      'locked_by_user_id': lockedByUserId ?? emptyString,
      'locked_at': lockedAt ?? emptyString,
      'created_at': createdAt ?? timestampDefault,
      'updated_at': updatedAt ?? timestampDefault,
    };
  }
}
