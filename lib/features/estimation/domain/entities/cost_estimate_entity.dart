import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';

/// Represents a cost estimate for a construction project.
/// 
/// A cost estimate is a comprehensive calculation of the expected costs
/// for a construction project, including materials, labor, equipment, and
/// various markup configurations. It serves as the primary business entity
/// for cost estimation functionality in the application.
/// 
/// The estimate can be configured with different markup strategies:
/// - Overall markup: Single markup applied to the entire project
/// - Granular markup: Separate markups for materials, labor, and equipment
/// 
/// Estimates support locking mechanisms to prevent concurrent editing
/// and maintain data integrity during collaborative work.
/// 
/// Details can be found in the detailed design document: 
/// https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#bookmark=id.x13qk65itz6s
class CostEstimate {
  /// Unique identifier for this cost estimate.
  final String id;
  
  /// Identifier of the project this estimate belongs to.
  final String projectId;
  
  /// Human-readable name for the estimate.
  final String estimateName;
  
  /// Optional detailed description of the estimate.
  /// Provides additional context about the estimate's purpose or scope.
  final String? estimateDescription;
  
  /// Identifier of the user who created this estimate.
  final String creatorUserId;
  
  /// Configuration for markup calculations applied to this estimate.
  /// Defines how markups are calculated (overall vs granular) and their values.
  final MarkupConfiguration markupConfiguration;
  
  /// Total calculated cost of the estimate.
  /// May be null if the estimate hasn't been calculated yet.
  final double? totalCost;
  
  /// Current locking status of the estimate.
  /// Prevents concurrent editing and maintains data integrity.
  final LockStatus lockStatus;
  
  /// Timestamp when the estimate was first created.
  final DateTime createdAt;
  
  /// Timestamp when the estimate was last modified.
  final DateTime updatedAt;

  /// Creates a new [CostEstimate] instance.
  /// 
  /// [id], [projectId], [estimateName], [creatorUserId], [markupConfiguration],
  /// [lockStatus], [createdAt], and [updatedAt] are required parameters.
  /// 
  /// [estimateDescription] and [totalCost] are optional:
  /// - [estimateDescription] can be null if no additional context is needed
  /// - [totalCost] can be null if the estimate hasn't been calculated yet
  const CostEstimate({
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
