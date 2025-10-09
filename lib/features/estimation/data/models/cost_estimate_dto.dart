import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for CostEstimate entity.
///
/// This DTO represents the serialized form of a cost estimate as it appears
/// in the database or API responses. It handles the conversion between the
/// flat database structure and the domain entity's nested object structure.
///
/// The DTO separates markup configuration fields into individual properties
/// for database storage, while the domain entity groups them into a
/// MarkupConfiguration object for better encapsulation.
///
/// Details can be found in the detailed design document: https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#heading=h.p7ml049jmefm
class CostEstimateDto extends Equatable {
  /// Unique identifier for the cost estimate.
  final String id;

  /// ID of the project this estimate belongs to.
  final String projectId;

  /// Human-readable name for the estimate.
  final String estimateName;

  /// Optional description providing additional context about the estimate.
  final String? estimateDescription;

  /// ID of the user who created this estimate.
  final String creatorUserId;

  /// Type of markup configuration: 'overall' or 'granular'.
  /// Maps to [MarkupType] enum in domain layer.
  final String? markupType;

  /// Type of overall markup value: 'percentage' or 'amount'.
  /// Maps to [MarkupValueType] enum in domain layer.
  final String? overallMarkupValueType;

  /// Overall markup value as a decimal number.
  final double? overallMarkupValue;

  /// Type of material markup value: 'percentage' or 'amount'.
  /// Maps to [MarkupValueType] enum in domain layer.
  final String? materialMarkupValueType;

  /// Material markup value as a decimal number.
  final double? materialMarkupValue;

  /// Type of labor markup value: 'percentage' or 'amount'.
  /// Maps to [MarkupValueType] enum in domain layer.
  final String? laborMarkupValueType;

  /// Labor markup value as a decimal number.
  final double? laborMarkupValue;

  /// Type of equipment markup value: 'percentage' or 'amount'.
  /// Maps to [MarkupValueType] enum in domain layer.
  final String? equipmentMarkupValueType;

  /// Equipment markup value as a decimal number.
  final double? equipmentMarkupValue;

  /// Total calculated cost of the estimate.
  final double? totalCost;

  /// Whether the estimate is currently locked for editing.
  final bool isLocked;

  /// ID of the user who locked the estimate (if locked).
  final String? lockedByUserID;

  /// ISO 8601 timestamp when the estimate was locked.
  final String? lockedAt;

  /// ISO 8601 timestamp when the estimate was created.
  final String createdAt;

  /// ISO 8601 timestamp when the estimate was last updated.
  final String updatedAt;

  /// Creates a new [CostEstimateDto] instance.
  ///
  /// All parameters are required as they represent the complete state
  /// of a cost estimate as stored in the database.
  const CostEstimateDto({
    required this.id,
    required this.projectId,
    required this.estimateName,
    required this.estimateDescription,
    required this.creatorUserId,
    required this.markupType,
    required this.overallMarkupValueType,
    required this.overallMarkupValue,
    required this.materialMarkupValueType,
    required this.materialMarkupValue,
    required this.laborMarkupValueType,
    required this.laborMarkupValue,
    required this.equipmentMarkupValueType,
    required this.equipmentMarkupValue,
    required this.totalCost,
    required this.isLocked,
    required this.lockedByUserID,
    required this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [CostEstimateDto] from a JSON map.
  ///
  /// This factory method handles the conversion from the database/API JSON format
  /// to the DTO structure. It performs type conversion for numeric values and
  /// maps snake_case JSON keys to camelCase Dart properties.
  ///
  /// Throws [TypeError] if required fields are missing or have invalid types.
  factory CostEstimateDto.fromJson(Map<String, dynamic> json) {
    return CostEstimateDto(
      id: json['id'],
      projectId: json['project_id'],
      estimateName: json['estimate_name'],
      estimateDescription: json['estimate_description'],
      creatorUserId: json['creator_user_id'],
      markupType: json['markup_type'],
      overallMarkupValueType: json['overall_markup_value_type'],
      overallMarkupValue: json['overall_markup_value'] != null
          ? (json['overall_markup_value'] as num).toDouble()
          : null,
      materialMarkupValueType: json['material_markup_value_type'],
      materialMarkupValue: json['material_markup_value'] != null
          ? (json['material_markup_value'] as num).toDouble()
          : null,
      laborMarkupValueType: json['labor_markup_value_type'],
      laborMarkupValue: json['labor_markup_value'] != null
          ? (json['labor_markup_value'] as num).toDouble()
          : null,
      equipmentMarkupValueType: json['equipment_markup_value_type'],
      equipmentMarkupValue: json['equipment_markup_value'] != null
          ? (json['equipment_markup_value'] as num).toDouble()
          : null,
      totalCost: json['total_cost'] != null
          ? (json['total_cost'] as num).toDouble()
          : null,
      isLocked: json['is_locked'],
      lockedByUserID: json['locked_by_user_id'],
      lockedAt: json['locked_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  /// Converts this DTO to a JSON map.
  ///
  /// This method converts the DTO back to the database/API JSON format,
  /// mapping camelCase Dart properties to snake_case JSON keys.
  ///
  /// Returns a [Map<String, dynamic>] suitable for JSON serialization.
  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'estimate_name': estimateName,
    'estimate_description': estimateDescription,
    'creator_user_id': creatorUserId,
    'markup_type': markupType,
    'overall_markup_value_type': overallMarkupValueType,
    'overall_markup_value': overallMarkupValue,
    'material_markup_value_type': materialMarkupValueType,
    'material_markup_value': materialMarkupValue,
    'labor_markup_value_type': laborMarkupValueType,
    'labor_markup_value': laborMarkupValue,
    'equipment_markup_value_type': equipmentMarkupValueType,
    'equipment_markup_value': equipmentMarkupValue,
    'total_cost': totalCost,
    'is_locked': isLocked,
    'locked_by_user_id': lockedByUserID,
    'locked_at': lockedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  /// Converts this DTO to a domain [CostEstimate] entity.
  ///
  /// This method performs the transformation from the flat DTO structure
  /// to the domain entity's nested object structure. It:
  /// - Groups markup-related fields into a [MarkupConfiguration] object
  /// - Converts string enum values to proper enum types
  /// - Parses ISO 8601 timestamp strings to [DateTime] objects
  /// - Creates appropriate [LockStatus] based on the locked state
  ///
  /// Throws [FormatException] if timestamp strings are invalid.
  /// Throws [ArgumentError] if enum string values are unrecognized.
  CostEstimate toDomain() {
    return CostEstimate(
      id: id,
      projectId: projectId,
      estimateName: estimateName,
      estimateDescription: estimateDescription,
      creatorUserId: creatorUserId,
      markupConfiguration: MarkupConfiguration(
        overallType: _mapMarkupType(markupType ?? 'overall'),
        overallValue: MarkupValue(
          type: _mapMarkupValueType(overallMarkupValueType ?? 'percentage'),
          value: overallMarkupValue ?? 0,
        ),
        materialValue:
            materialMarkupValueType != null && materialMarkupValue != null
            ? MarkupValue(
                type: _mapMarkupValueType(
                  materialMarkupValueType ?? 'percentage',
                ),
                value: materialMarkupValue ?? 0,
              )
            : null,
        laborValue: laborMarkupValueType != null && laborMarkupValue != null
            ? MarkupValue(
                type: _mapMarkupValueType(laborMarkupValueType ?? 'percentage'),
                value: laborMarkupValue ?? 0,
              )
            : null,
        equipmentValue:
            equipmentMarkupValueType != null && equipmentMarkupValue != null
            ? MarkupValue(
                type: _mapMarkupValueType(
                  equipmentMarkupValueType ?? 'percentage',
                ),
                value: equipmentMarkupValue ?? 0,
              )
            : null,
      ),
      totalCost: totalCost ?? 0,
      lockStatus: isLocked
          ? LockStatus.locked(
              lockedByUserID ?? '',
              DateTime.parse(lockedAt ?? updatedAt),
            )
          : const LockStatus.unlocked(),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  MarkupType _mapMarkupType(String raw) {
    if (raw.isEmpty) {
      return MarkupType.overall;
    }

    switch (raw.toLowerCase()) {
      case 'overall':
        return MarkupType.overall;
      case 'granular':
        return MarkupType.granular;
      default:
        throw ArgumentError('Unknown MarkupType: $raw');
    }
  }

  MarkupValueType _mapMarkupValueType(String raw) {
    if (raw.isEmpty) {
      return MarkupValueType.percentage;
    }

    switch (raw.toLowerCase()) {
      case 'percentage':
        return MarkupValueType.percentage;
      case 'amount':
        return MarkupValueType.amount;
      default:
        throw ArgumentError('Unknown MarkupValueType: $raw');
    }
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    estimateName,
    estimateDescription,
    creatorUserId,
    markupType,
    overallMarkupValueType,
    overallMarkupValue,
    materialMarkupValueType,
    materialMarkupValue,
    laborMarkupValueType,
    laborMarkupValue,
    equipmentMarkupValueType,
    equipmentMarkupValue,
    totalCost,
    isLocked,
    lockedByUserID,
    lockedAt,
    createdAt,
    updatedAt,
  ];
}
