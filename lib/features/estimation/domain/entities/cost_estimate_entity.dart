import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';

class CostEstimate {
  final String id;
  final String projectId;
  final String estimateName;
  final String? estimateDescription;
  final String creatorUserId;
  final MarkupConfiguration markupConfiguration;
  final double? totalCost;
  final LockStatus lockStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  CostEstimate({
    required this.id,
    required this.projectId,
    required this.estimateName,
    this.estimateDescription,
    required this.creatorUserId,
    required this.markupConfiguration,
    this.totalCost,
    required this.lockStatus,
    required this.createdAt,
    required this.updatedAt,
  });
}
