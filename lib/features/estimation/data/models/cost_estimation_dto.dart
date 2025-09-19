import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums/markup_type_enum.dart';
import 'package:construculator/features/estimation/domain/entities/enums/markup_value_type_enum.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';

class CostEstimationDto {
  String id;
  String projectId;
  String estimateName;
  String estimateDescription;
  String creatorUserId;
  String overallMarkupValueType;
  double overallMarkupValue;
  String materialMarkupValueType;
  double materialMarkupValue;
  String laborMarkupValueType;
  double laborMarkupValue;
  String equipmentMarkupValueType;
  double equipmentMarkupValue;
  double totalCost;
  bool isLocked;
  String lockedByUserID;
  String lockedAt;
  String createdAt;
  String updatedAt;

  CostEstimationDto({
    required this.id,
    required this.projectId,
    required this.estimateName,
    required this.estimateDescription,
    required this.creatorUserId,
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

  factory CostEstimationDto.fromJson(Map<String, dynamic> json) {
    return CostEstimationDto(
      id: json['id'],
      projectId: json['project_id'],
      estimateName: json['estimate_name'],
      estimateDescription: json['estimate_description'],
      creatorUserId: json['creator_user_id'],
      overallMarkupValueType: json['overall_markup_value_type'],
      overallMarkupValue: (json['overall_markup_value'] as num).toDouble(),
      materialMarkupValueType: json['material_markup_value_type'],
      materialMarkupValue: (json['material_markup_value'] as num).toDouble(),
      laborMarkupValueType: json['labor_markup_value_type'],
      laborMarkupValue: (json['labor_markup_value'] as num).toDouble(),
      equipmentMarkupValueType: json['equipment_markup_value_type'],
      equipmentMarkupValue: (json['equipment_markup_value'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
      isLocked: json['is_locked'],
      lockedByUserID: json['locked_by_user_id'],
      lockedAt: json['locked_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'estimate_name': estimateName,
    'estimate_description': estimateDescription,
    'creator_user_id': creatorUserId,
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

  CostEstimate toDomain() {
    return CostEstimate(
      id: id,
      projectId: projectId,
      estimateName: estimateName,
      estimateDescription: estimateDescription,
      creatorUserId: creatorUserId,
      markupConfiguration: MarkupConfiguration(
        overallType: _mapMarkupType(overallMarkupValueType),
        overallValue: MarkupValue(
          type: _mapMarkupValueType(overallMarkupValueType),
          value: overallMarkupValue,
        ),
        materialValueType: _mapMarkupType(materialMarkupValueType),
        materialValue: MarkupValue(
          type: _mapMarkupValueType(materialMarkupValueType),
          value: materialMarkupValue,
        ),
        laborValueType: _mapMarkupType(laborMarkupValueType),
        laborValue: MarkupValue(
          type: _mapMarkupValueType(laborMarkupValueType),
          value: laborMarkupValue,
        ),
        equipmentValueType: _mapMarkupType(equipmentMarkupValueType),
        equipmentValue: MarkupValue(
          type: _mapMarkupValueType(equipmentMarkupValueType),
          value: equipmentMarkupValue,
        ),
      ),
      totalCost: totalCost,
      lockStatus: isLocked
          ? LockStatus.locked(lockedByUserID, DateTime.parse(lockedAt))
          : const LockStatus.unlocked(),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  MarkupType _mapMarkupType(String raw) {
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
    switch (raw.toLowerCase()) {
      case 'percentage':
        return MarkupValueType.percentage;
      case 'amount':
        return MarkupValueType.amount;
      default:
        throw ArgumentError('Unknown MarkupValueType: $raw');
    }
  }
}
